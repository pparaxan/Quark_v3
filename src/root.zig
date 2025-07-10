const std = @import("std");

pub const WindowConfig = @import("config.zig").WindowConfig;
pub const WindowHint = @import("config.zig").WindowHint;
pub const QuarkWindow = @import("window.zig").QuarkWindow;
pub const CommandHandler = @import("window.zig").CommandHandler;

pub fn create_window(config: WindowConfig) !QuarkWindow {
    return QuarkWindow.create(config);
}

pub fn execute_window(window: *QuarkWindow) !void {
    return window.run();
}

pub fn register_command(window: *QuarkWindow, name: []const u8, handler: CommandHandler) !void {
    return window.register_command(name, handler);
}

pub fn call_frontend(window: *QuarkWindow, function_name: []const u8, args: []const u8) !void {
    return window.call_frontend(function_name, args);
}

pub fn emit_event(window: *QuarkWindow, event_name: []const u8, data: []const u8) !void {
    return window.emit_event(event_name, data);
}
