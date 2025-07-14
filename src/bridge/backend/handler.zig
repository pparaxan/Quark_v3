//! This module handles incoming messages from the frontend, parsing
//! JSON payloads, routing commands to registered handlers, and managing
//! the command execution lifecycle.

const std = @import("std");
const webview = @import("webview");
const responses = @import("responses.zig");
const js_utils = @import("javascript.zig");
const errors = @import("../../errors.zig");
const WebViewError = errors.WebViewError;
const api = @import("api.zig");

/// Initializes the bridge handler.
///
/// Sets up the global command registry and response queue required
/// for bridge operation. Must be called before any bridge operations.
pub fn init(allocator: std.mem.Allocator) void {
    if (api.global_commands == null) {
        api.global_commands = std.ArrayList(api.CommandEntry).init(allocator);
        api.global_allocator = allocator;
    }
    responses.pending_responses = responses.ResponseQueue.init(allocator);
}

/// Deinitializes the response queue and command registry, freeing
/// associated memory. Should be called when the bridge is no
/// longer needed.
pub fn deinit() void {
    if (api.global_commands) |*commands| {
        for (commands.items) |entry| {
            api.global_allocator.free(entry.name);
        }
        commands.deinit();
        api.global_commands = null;
    }

    if (responses.pending_responses) |*queue| {
        queue.deinit();
        responses.pending_responses = null;
    }
}

/// [C] Callback function for handling bridge messages from the frontend.
///
/// This is the main entry point for all front to backend communication.
/// It receives raw JSON messages from the frontend, parses them, and routes
/// them to the appropriate command handlers.
pub fn bridgeCallback(_: [*c]const u8, req: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
    _ = arg;

    const request = std.mem.span(req);

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
            handleCommand(inner_parsed.value, temp_allocator);
            return;
        }
    }

    handleCommand(parsed.value, temp_allocator);
}

/// Processes a parsed command message and executes the appropriate handler.
///
/// Extracts command name, payload, and ID from the JSON message, locates
/// the registered handler, and executes it with the provided payload.
fn handleCommand(root: std.json.Value, temp_allocator: std.mem.Allocator) void {
    if (root != .object) {
        std.log.err("Bridge message is not a JSON object", .{});
        return;
    }

    const obj = root.object;
    const command_value = obj.get("command") orelse {
        std.log.err("No command found in the bridge message", .{});
        return;
    };

    if (command_value != .string) {
        std.log.err("Command value isn't a string", .{});
        return;
    }

    const command = command_value.string;
    const payload = obj.get("payload") orelse std.json.Value{ .null = {} };

    const id = if (obj.get("id")) |id_val|
        if (id_val == .string) id_val.string else ""
    else
        "";

    var handler: ?api.CommandHandler = null;
    for (api.global_commands.?.items) |entry| {
        if (std.mem.eql(u8, entry.name, command)) {
            handler = entry.handler;
            break;
        }
    }

    if (handler == null) {
        std.log.err("The '{s}' command wasn't found in the registry.", .{command});
        responses.sendUnsuccessfulResponse(id, "Command wasn't found.") catch {};
        return;
    }

    const payload_json = std.json.stringifyAlloc(temp_allocator, payload, .{ .whitespace = .minified }) catch |err| {
        std.log.err("Failed to serialize payload: {}", .{err});
        responses.sendUnsuccessfulResponse(id, "Failed to serialize payload.") catch {};
        return;
    };

    const result = handler.?(api.global_allocator, payload_json);
    defer api.global_allocator.free(result);

    responses.sendSuccessfulResponse(id, result) catch |err| {
        std.log.err("Failed to send successful response: {}", .{err});
        responses.sendUnsuccessfulResponse(id, "Failed to send response.") catch {};
    };
}
