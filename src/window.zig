const std = @import("std");
const webview = @import("webview");
const config = @import("config.zig");
const errors = @import("errors.zig");
const WebViewError = errors.WebViewError;
pub const frontend = @import("frontend");

pub const CommandHandler = *const fn (std.mem.Allocator, []const u8) []const u8;
pub const CommandRegistry = std.HashMap([]const u8, CommandHandler, std.hash_map.StringContext, std.hash_map.default_max_load_percentage);

pub const CommandEntry = struct {
    name: []const u8,
    handler: CommandHandler,
};

const ResponseQueue = struct {
    responses: std.ArrayList(PendingResponse),
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    const PendingResponse = struct {
        id: []const u8,
        data: []const u8,
        is_error: bool,
        timestamp: i64,
    };

    fn init(allocator: std.mem.Allocator) ResponseQueue {
        return ResponseQueue{
            .responses = std.ArrayList(PendingResponse).init(allocator),
            .mutex = std.Thread.Mutex{},
            .allocator = allocator,
        };
    }

    fn deinit(self: *ResponseQueue) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.responses.items) |response| {
            self.allocator.free(response.id);
            self.allocator.free(response.data);
        }
        self.responses.deinit();
    }

    fn push(self: *ResponseQueue, id: []const u8, data: []const u8, is_error: bool) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const owned_id = try self.allocator.dupe(u8, id);
        const owned_data = try self.allocator.dupe(u8, data);

        try self.responses.append(.{
            .id = owned_id,
            .data = owned_data,
            .is_error = is_error,
            .timestamp = std.time.timestamp(),
        });
    }

    fn poll(self: *ResponseQueue) ?PendingResponse {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.responses.items.len == 0) return null;
        return self.responses.orderedRemove(0);
    }
};

var global_commands: ?std.ArrayList(CommandEntry) = null;
var global_allocator: std.mem.Allocator = undefined;
var response_queue: ?ResponseQueue = null;
var global_window: ?*QuarkWindow = null;

pub const QuarkWindow = struct {
    handle: webview.webview_t,
    config: config.WindowConfig,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    command_arena: std.heap.ArenaAllocator,

    const Self = @This();

    pub fn create(window_config: config.WindowConfig) (WebViewError || error{OutOfMemory})!Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        var command_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

        if (global_commands == null) {
            global_commands = std.ArrayList(CommandEntry).init(std.heap.page_allocator);
            global_allocator = std.heap.page_allocator;
            response_queue = ResponseQueue.init(std.heap.page_allocator);
        }

        const handle = webview.webview_create(@intFromBool(window_config.debug_mode), null);
        if (handle == null) {
            arena.deinit();
            command_arena.deinit();
            return WebViewError.MissingDependency;
        }

        var window = Self{
            .handle = handle,
            .config = window_config,
            .allocator = std.heap.page_allocator,
            .arena = arena,
            .command_arena = command_arena,
        };

        try window.initialize();
        return window;
    }

    fn initialize(self: *Self) (WebViewError || error{OutOfMemory})!void {
        try self.set_title();
        try self.set_size();
        try self.load_entrypoint();
        try self.setup_gvfs();
        try self.setup_bridge();
    }

    fn setup_bridge(self: *Self) !void {
        const bridge_js = @embedFile("bridge/frontend/core.js");
        const null_terminated = try self.allocator.allocSentinel(u8, bridge_js.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, bridge_js);

        try check_error(webview.webview_init(self.handle, null_terminated.ptr));
        try check_error(webview.webview_bind(self.handle, "quark_bridge_handler", bridge_callback, null));
    }

    pub fn register_command(_: *Self, name: []const u8, handler: CommandHandler) !void {
        const owned_name = try global_allocator.dupe(u8, name);
        errdefer global_allocator.free(owned_name);
        try global_commands.?.append(CommandEntry{
            .name = owned_name,
            .handler = handler,
        });
    }

    pub fn call_frontend(self: *Self, function_name: []const u8, args: []const u8) !void {
        if (self.handle == null) {
            return WebViewError.Unspecified;
        }

        var temp_arena = std.heap.ArenaAllocator.init(self.allocator);
        defer temp_arena.deinit();
        const temp_allocator = temp_arena.allocator();

        const js_call = try std.fmt.allocPrint(temp_allocator,
            "try {{ if (typeof {s} === 'function') {{ {s}({s}); }} }} catch(e) {{ console.error('Frontend call error:', e); }}",
            .{ function_name, function_name, args });

        const null_terminated = try temp_allocator.allocSentinel(u8, js_call.len, 0);
        @memcpy(null_terminated, js_call);

        try check_error(webview.webview_eval(self.handle, null_terminated.ptr));
    }

    pub fn emit_event(self: *Self, event_name: []const u8, data: []const u8) !void {
        var temp_arena = std.heap.ArenaAllocator.init(self.allocator);
        defer temp_arena.deinit();
        const temp_allocator = temp_arena.allocator();

        const js_emit = try std.fmt.allocPrint(temp_allocator,
            "try {{ if (window.__QUARK_EVENTS__) {{ window.__QUARK_EVENTS__.emit('{s}', {s}); }} }} catch(e) {{ console.error('Event emit error:', e); }}",
            .{ event_name, data });

        const null_terminated = try temp_allocator.allocSentinel(u8, js_emit.len, 0);
        @memcpy(null_terminated, js_emit);

        try check_error(webview.webview_eval(self.handle, null_terminated.ptr));
    }

    fn set_title(self: *Self) WebViewError!void {
        return check_error(webview.webview_set_title(self.handle, self.config.title));
    }

    fn setup_gvfs(self: *Self) !void {
        var vfs = try @import("VFS/backend/qvfs.zig").QuarkVirtualFileSystem.init(self.allocator);
        defer vfs.deinit();

        const js_injection = try vfs.generate_injection_code();
        defer self.allocator.free(js_injection);

        const null_terminated = try self.allocator.allocSentinel(u8, js_injection.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, js_injection);

        try check_error(webview.webview_init(self.handle, null_terminated.ptr));
    }

    fn load_entrypoint(self: *Self) !void {
        const html_content = frontend.get("index.html") orelse return WebViewError.Unspecified;
        const null_terminated = try self.allocator.allocSentinel(u8, html_content.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, html_content);

        try check_error(webview.webview_set_html(self.handle, null_terminated.ptr));
    }

    fn set_size(self: Self) WebViewError!void {
        return check_error(webview.webview_set_size(
            self.handle,
            @intCast(self.config.width),
            @intCast(self.config.height),
            @intFromEnum(self.config.size_hint),
        ));
    }

    pub fn run(self: *Self) WebViewError!void {
        global_window = self;
        defer global_window = null;

        return check_error(webview.webview_run(self.handle));
    }

    pub fn destroy(self: *Self) !void {
        try check_error(webview.webview_destroy(self.handle));
        self.arena.deinit();
        self.command_arena.deinit();

        if (response_queue) |*queue| {
            queue.deinit();
            response_queue = null;
        }
    }
};

fn bridge_callback(_: [*c]const u8, req: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
    _ = arg;

    if (global_window == null) {
        std.log.err("Bridge callback: no global window", .{});
        return;
    }

    const window_ptr = global_window.?;

    if (req == null) {
        std.log.err("Bridge callback: null request", .{});
        return;
    }

    const request = std.mem.span(req);
    std.log.info("Bridge callback received: {s}", .{request});
    var temp_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const parsed = std.json.parseFromSlice(std.json.Value, temp_allocator, request, .{}) catch |err| {
        std.log.err("Failed to parse bridge message: {}", .{err});
        return;
    };

    if (parsed.value == .array and parsed.value.array.items.len > 0) {
        const first_item = parsed.value.array.items[0];
        if (first_item == .string) {
            const inner_parsed = std.json.parseFromSlice(std.json.Value, temp_allocator, first_item.string, .{}) catch |err| {
                std.log.err("Failed to parse inner bridge message: {}", .{err});
                return;
            };
            handle_command(window_ptr, inner_parsed.value, temp_allocator);
            return;
        }
    }

    handle_command(window_ptr, parsed.value, temp_allocator);
}

fn queue_response(id: []const u8, data: []const u8, is_error: bool) !void {
    if (response_queue) |*queue| {
        try queue.push(id, data, is_error);
    }
}

fn handle_command(window: *QuarkWindow, root: std.json.Value, temp_allocator: std.mem.Allocator) void {
    if (root != .object) {
        std.log.err("Bridge message is not a JSON object", .{});
        return;
    }

    const obj = root.object;
    const command_value = obj.get("command") orelse {
        std.log.err("No command found in bridge message", .{});
        return;
    };

    if (command_value != .string) {
        std.log.err("Command value is not a string", .{});
        return;
    }

    const command = command_value.string;
    const payload = obj.get("payload") orelse std.json.Value{ .null = {} };

    const id = if (obj.get("id")) |id_val|
        if (id_val == .string) id_val.string else ""
    else "";

    std.log.info("Processing command: {s} with id: {s}", .{ command, id });

    var handler: ?CommandHandler = null;
    for (global_commands.?.items) |entry| {
        if (std.mem.eql(u8, entry.name, command)) {
            handler = entry.handler;
            break;
        }
    }

    if (handler == null) {
        std.log.err("Command '{s}' not found in registry", .{command});
        queue_response(id, "Command not found", true) catch {};
        return;
    }

    const payload_json = std.json.stringifyAlloc(temp_allocator, payload, .{ .whitespace = .minified }) catch |err| {
        std.log.err("Failed to serialize payload: {}", .{err});
        queue_response(id, "Failed to serialize payload", true) catch {};
        return;
    };

    std.log.info("Calling handler for command: {s}", .{command});
    const result = handler.?(global_allocator, payload_json);
    std.log.info("Handler returned: {s}", .{result});

    send_success_response_direct(window, id, result) catch |err| {
        std.log.err("Failed to send response: {}", .{err});
    };
}

fn send_success_response_direct(window: *QuarkWindow, id: []const u8, data: []const u8) !void {
    if (window.handle == null) {
        std.log.err("Window handle is null", .{});
        return WebViewError.Unspecified;
    }

    if (id.len == 0) {
        std.log.err("Response ID is empty", .{});
        return;
    }

    var temp_arena = std.heap.ArenaAllocator.init(global_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const escaped_data = try escape_string_for_javascript(temp_allocator, data);
    const escaped_id = try escape_string_for_javascript(temp_allocator, id);

    const js_response = try std.fmt.allocPrint(temp_allocator,
        "try {{ if (window.__QUARK_BRIDGE_HANDLE_RESPONSE__) {{ window.__QUARK_BRIDGE_HANDLE_RESPONSE__('{s}', true, '{s}'); }} }} catch(e) {{ console.error('Response error:', e); }}",
        .{ escaped_id, escaped_data });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_response.len, 0);
    @memcpy(null_terminated, js_response);

    try check_error(webview.webview_eval(window.handle, null_terminated.ptr));
}

pub fn process_pending_responses(window: *QuarkWindow) !void {
    if (response_queue) |*queue| {
        while (queue.poll()) |response| {
            defer {
                global_allocator.free(response.id);
                global_allocator.free(response.data);
            }

            if (response.is_error) {
                try send_error_response_safe(window, response.id, response.data);
            } else {
                try send_success_response_safe(window, response.id, response.data);
            }
        }
    }
}

fn send_success_response_safe(window: *QuarkWindow, id: []const u8, data: []const u8) !void {
    var temp_arena = std.heap.ArenaAllocator.init(global_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const escaped_data = try escape_for_javascript(temp_allocator, data);
    const escaped_id = try escape_string_for_javascript(temp_allocator, id);

    const js_response = try std.fmt.allocPrint(temp_allocator,
        "try {{ if (window.__QUARK_BRIDGE_HANDLE_RESPONSE__) {{ window.__QUARK_BRIDGE_HANDLE_RESPONSE__('{s}', true, {s}); }} }} catch(e) {{ console.error('Response error:', e); }}",
        .{ escaped_id, escaped_data });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_response.len, 0);
    @memcpy(null_terminated, js_response);

    try check_error(webview.webview_eval(window.handle, null_terminated.ptr));
}

fn send_error_response_safe(window: *QuarkWindow, id: []const u8, error_msg: []const u8) !void {
    var temp_arena = std.heap.ArenaAllocator.init(global_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const escaped_error = try escape_for_javascript(temp_allocator, error_msg);
    const escaped_id = try escape_string_for_javascript(temp_allocator, id);

    const js_response = try std.fmt.allocPrint(temp_allocator,
        "try {{ if (window.__QUARK_BRIDGE_HANDLE_RESPONSE__) {{ window.__QUARK_BRIDGE_HANDLE_RESPONSE__('{s}', false, {s}); }} }} catch(e) {{ console.error('Error response error:', e); }}",
        .{ escaped_id, escaped_error });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_response.len, 0);
    @memcpy(null_terminated, js_response);

    try check_error(webview.webview_eval(window.handle, null_terminated.ptr));
}

fn escape_string_for_javascript(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    for (input) |char| {
        switch (char) {
            '\n' => try result.appendSlice("\\n"),
            '\r' => try result.appendSlice("\\r"),
            '\t' => try result.appendSlice("\\t"),
            '\\' => try result.appendSlice("\\\\"),
            '"' => try result.appendSlice("\\\""),
            '\'' => try result.appendSlice("\\'"),
            else => try result.append(char),
        }
    }
    return result.toOwnedSlice();
}

fn escape_for_javascript(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    const is_json = std.mem.startsWith(u8, input, "{") or std.mem.startsWith(u8, input, "[");

    if (!is_json) {
        try result.append('"');
    }

    for (input) |char| {
        switch (char) {
            '\n' => try result.appendSlice("\\n"),
            '\r' => try result.appendSlice("\\r"),
            '\t' => try result.appendSlice("\\t"),
            '\\' => try result.appendSlice("\\\\"),
            '"' => try result.appendSlice("\\\""),
            '\'' => try result.appendSlice("\\'"),
            else => try result.append(char),
        }
    }

    if (!is_json) {
        try result.append('"');
    }

    return result.toOwnedSlice();
}

fn check_error(code: c_int) WebViewError!void {
    if (code != webview.WEBVIEW_ERROR_OK) {
        return errors.map_error(code);
    }
}
