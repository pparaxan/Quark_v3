const std = @import("std");
const webview = @import("webview");
const responses = @import("responses.zig");
const js_utils = @import("javascript.zig");
const errors = @import("../../errors.zig");
const WebViewError = errors.WebViewError;
const api = @import("api.zig");

pub fn init(allocator: std.mem.Allocator) void {
    if (api.global_commands == null) {
        api.global_commands = std.ArrayList(api.CommandEntry).init(allocator);
        api.global_allocator = allocator;
    }
    responses.pending_responses = responses.ResponseQueue.init(allocator);
}

pub fn deinit() void {
    if (responses.pending_responses) |*queue| {
        queue.deinit();
        responses.pending_responses = null;
    }
}

pub fn bridge_callback(_: [*c]const u8, req: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
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
            handle_command(inner_parsed.value, temp_allocator);
            return;
        }
    }

    handle_command(parsed.value, temp_allocator);
}

fn handle_command(root: std.json.Value, temp_allocator: std.mem.Allocator) void {
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
        std.log.err("Command '{s}' not found in registry", .{command});
        responses.sendUnsuccessfulResponse(id, "Command not found") catch {};
        return;
    }

    const payload_json = std.json.stringifyAlloc(temp_allocator, payload, .{ .whitespace = .minified }) catch |err| {
        std.log.err("Failed to serialize payload: {}", .{err});
        responses.sendUnsuccessfulResponse(id, "Failed to serialize payload") catch {};
        return;
    };

    const result = handler.?(api.global_allocator, payload_json);

    responses.sendSuccessfulResponse(id, result) catch |err| {
        std.log.err("Failed to send successful response: {}", .{err});
        responses.sendUnsuccessfulResponse(id, "Failed to send response") catch {};
    };
}
