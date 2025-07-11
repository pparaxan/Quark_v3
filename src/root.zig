const std = @import("std");
const bridge = @import("bridge/backend/api.zig");

pub const WindowConfig = @import("config.zig").WindowConfig;
pub const WindowHint = @import("config.zig").WindowHint;
pub const QuarkWindow = @import("window.zig").QuarkWindow;

pub fn createWindow(config: WindowConfig) !QuarkWindow {
    return QuarkWindow.create(config);
}

pub fn executeWindow(window: *QuarkWindow) !void {
    return window.run();
}

pub fn registerCommand(name: []const u8, handler: bridge.CommandHandler) !void {
    return bridge.register(name, handler);
}

pub fn callCommand(function_name: []const u8, args: []const u8) !void {
    return bridge.call(function_name, args);
}

pub fn emitCommand(event_name: []const u8, data: []const u8) !void {
    return bridge.emit(event_name, data);
}
