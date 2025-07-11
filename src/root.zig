const std = @import("std");
const bridge = @import("bridge/backend/api.zig");

pub const WindowConfig = @import("config.zig").WindowConfig;
pub const WindowHint = @import("config.zig").WindowHint;
pub const QuarkWindow = @import("window.zig").QuarkWindow;

pub fn create_window(config: WindowConfig) !QuarkWindow {
    return QuarkWindow.create(config);
}

pub fn execute_window(window: *QuarkWindow) !void {
    return window.run();
}

pub fn register_command(name: []const u8, handler: bridge.CommandHandler) !void {
    return bridge.register_command(name, handler);
}

pub fn call_frontend(function_name: []const u8, args: []const u8) !void {
    return bridge.call_frontend(function_name, args);
}

pub fn emit_event(event_name: []const u8, data: []const u8) !void {
    return bridge.emit_event(event_name, data);
}
