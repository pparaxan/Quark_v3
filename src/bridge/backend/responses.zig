const std = @import("std");
const handler = @import("handler.zig");
const errors = @import("../../errors.zig");
const api = @import("api.zig");
const js_utils = @import("javascript.zig");
const webview = @import("webview");

pub var pending_responses: ?ResponseQueue = null;

pub const ResponseQueue = struct {
    responses: std.ArrayList(PendingResponse),
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    pub const PendingResponse = struct {
        id: []const u8,
        data: []const u8,
        is_error: bool,
        timestamp: i64,
    };

    pub fn init(allocator: std.mem.Allocator) ResponseQueue {
        return ResponseQueue{
            .responses = std.ArrayList(PendingResponse).init(allocator),
            .mutex = std.Thread.Mutex{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ResponseQueue) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.responses.items) |response| {
            self.allocator.free(response.id);
            self.allocator.free(response.data);
        }
        self.responses.deinit();
    }

    pub fn push(self: *ResponseQueue, id: []const u8, data: []const u8, is_error: bool) !void {
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

    pub fn poll(self: *ResponseQueue) ?PendingResponse {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.responses.items.len == 0) return null;
        return self.responses.orderedRemove(0);
    }
};
fn sendResponse(id: []const u8, data: []const u8, is_success: bool) !void {
    var temp_arena = std.heap.ArenaAllocator.init(api.global_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const escaped_data = try js_utils.javascriptEscapeString(temp_allocator, data);
    const escaped_id = try js_utils.javascriptEscapeString(temp_allocator, id);

    const success_str = if (is_success) "true" else "false";
    const error_type = if (is_success) "successful" else "error";

    const js_response = try std.fmt.allocPrint(temp_allocator,
        "try {{ if (window.__QUARK_BRIDGE_HANDLE_RESPONSE__) {{ window.__QUARK_BRIDGE_HANDLE_RESPONSE__('{s}', {s}, '{s}'); }} }} catch(e) {{ console.error('Failed to deliver {s} response:', e); }}",
        .{ escaped_id, success_str, escaped_data, error_type });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_response.len, 0);
    @memcpy(null_terminated, js_response);

    const window_handle = @as(*anyopaque, @ptrCast(api.global_window.?));
    try errors.checkError(webview.webview_eval(window_handle, null_terminated.ptr));
}

pub fn sendSuccessfulResponse(id: []const u8, data: []const u8) !void {
    try sendResponse(id, data, true);
}

pub fn sendUnsuccessfulResponse(id: []const u8, error_msg: []const u8) !void {
    try sendResponse(id, error_msg, false);
}
