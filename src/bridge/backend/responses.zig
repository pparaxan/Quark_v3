//! This module manages the response lifecycle for bridged commands, including
//! queuing, delivery. It provides both successful and error responses used to
//! be sent to frontend.

const std = @import("std");
const handler = @import("handler.zig");
const errors = @import("../../errors.zig");
const api = @import("api.zig");
const js_utils = @import("javascript.zig");
const webview = @import("webview");

pub var pending_responses: ?ResponseQueue = null;

/// This struct holds responses Quark will send to the frontend, from the backend.
/// It provides a concurrent-safe mechanism for queuing and delivering
/// responses to the frontend, also includes timestamp tracking for
/// debugging and monitoring purposes.
pub const ResponseQueue = struct {
    responses: std.ArrayList(PendingResponse),
    mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,

    /// This struct represents one queued response
    pub const PendingResponse = struct {
        id: []const u8,
        data: []const u8,
        is_error: bool,
        timestamp: i64,
    };

    /// Sets up the response queue with the specified allocator.
    pub fn init(allocator: std.mem.Allocator) ResponseQueue {
        return ResponseQueue{
            .responses = std.ArrayList(PendingResponse).init(allocator),
            .mutex = std.Thread.Mutex{},
            .allocator = allocator,
        };
    }

    /// Cleans up the response queue and frees all pending responses.
    pub fn deinit(self: *ResponseQueue) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.responses.items) |response| {
            self.allocator.free(response.id);
            self.allocator.free(response.data);
        }
        self.responses.deinit();
    }

    /// Adds a response to the queue in a thread-safe manner.
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

    /// Retrieves and removes the next response from the queue.
    pub fn poll(self: *ResponseQueue) ?PendingResponse {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.responses.items.len == 0) return null;
        return self.responses.orderedRemove(0);
    }
};

/// This function is used to construct the appropriate JavaScript code
/// that'll deliver the response to the frontend. It escapes the ID and data,
/// wraps it in a try-catch, and sends it to the window via `webview_eval`.
fn sendResponse(id: []const u8, data: []const u8, is_success: bool) !void {
    var temp_arena = std.heap.ArenaAllocator.init(api.global_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const escaped_data = try js_utils.javascriptEscapeString(temp_allocator, data);
    const escaped_id = try js_utils.javascriptEscapeString(temp_allocator, id);

    const success_str = if (is_success) "true" else "false";
    const error_type = if (is_success) "successful" else "error";

    const js_response = try std.fmt.allocPrint(temp_allocator, "try {{ if (window.__QUARK_BRIDGE_HANDLE_RESPONSE__) {{ window.__QUARK_BRIDGE_HANDLE_RESPONSE__('{s}', {s}, '{s}'); }} }} catch(e) {{ console.error('Failed to deliver {s} response:', e); }}", .{ escaped_id, success_str, escaped_data, error_type });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_response.len, 0);
    @memcpy(null_terminated, js_response);

    const window_handle = @as(*anyopaque, @ptrCast(api.global_window.?));
    try errors.checkError(webview.webview_eval(window_handle, null_terminated.ptr));
}

/// Public helper used to sends a successful response to the frontend.
pub fn sendSuccessfulResponse(id: []const u8, data: []const u8) !void {
    try sendResponse(id, data, true);
}

/// Public helper used to sends a failed response to the frontend.
pub fn sendUnsuccessfulResponse(id: []const u8, error_msg: []const u8) !void {
    try sendResponse(id, error_msg, false);
}
