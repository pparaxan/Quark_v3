//! This module provides the fundamental bridge API for bidirectional communication
//! in Quark applications. It manages command registration, execution, and event
//! emission across the backend-frontend boundary.

const std = @import("std");
const webview = @import("webview");
const QuarkWindow = @import("../../window.zig").QuarkWindow;
const bridge_handler = @import("handler.zig");
const js_utils = @import("javascript.zig");
const errors = @import("../../errors.zig");

pub const CommandHandler = *const fn (std.mem.Allocator, []const u8) []const u8;
pub const CommandRegistry = std.HashMap([]const u8, CommandHandler, std.hash_map.StringContext, std.hash_map.default_max_load_percentage);

pub var global_commands: ?std.ArrayList(CommandEntry) = null;
pub var global_allocator: std.mem.Allocator = undefined;
pub var global_window: ?*anyopaque = null;

pub const CommandEntry = struct {
    name: []const u8,
    handler: CommandHandler,
};

/// Registers a backend function as a callable command from the frontend.
///
/// Commands registered with this function can be invoked from the frontend
/// using the bridge system. The handler will receive JSON payload data and
/// must return a JSON response string.
pub fn register(name: []const u8, handler: CommandHandler) !void {
    const owned_name = try global_allocator.dupe(u8, name);
    errdefer global_allocator.free(owned_name);
    try global_commands.?.append(CommandEntry{
        .name = owned_name,
        .handler = handler,
    });
}

/// Executes a JavaScript function in the frontend, from the backend.
///
/// This function allows backend code to call JavaScript functions in the
/// frontend.
pub fn call(window: *QuarkWindow, function_name: []const u8, args: []const u8) !void {
    if (window.handle == null) {
        return errors.WebViewError.Unspecified;
    }

    var temp_arena = std.heap.ArenaAllocator.init(window.allocator); // make this a function?
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const js_call = try std.fmt.allocPrint(temp_allocator, "try {{ if (typeof {s} === 'function') {{ {s}({s}); }} }} catch(e) {{ console.error('Frontend call error:', e); }}", .{ function_name, function_name, args });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_call.len, 0);
    @memcpy(null_terminated, js_call);

    try errors.checkError(webview.webview_eval(window.handle, null_terminated.ptr));
}

/// Emits custom events to the frontend.
///
/// Events provide a way for the backend to push data/notifications to the
/// frontend.
pub fn emit(window: *QuarkWindow, event_name: []const u8, data: []const u8) !void {
    if (window.handle == null) {
        return errors.WebViewError.Unspecified;
    }

    var temp_arena = std.heap.ArenaAllocator.init(window.allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();

    const js_emit = try std.fmt.allocPrint(temp_allocator, "try {{ if (window.__QUARK_EVENTS__) {{ window.__QUARK_EVENTS__.emit('{s}', {s}); }} }} catch(e) {{ console.error('Event emit error:', e); }}", .{ event_name, data });

    const null_terminated = try temp_allocator.allocSentinel(u8, js_emit.len, 0);
    @memcpy(null_terminated, js_emit);

    try errors.checkError(webview.webview_eval(window.handle, null_terminated.ptr));
}
