//! Quark - Build lightweight, efficient desktop applications via a web frontend.
//!
//! This is the main entry point for the Quark framework, providing a high-level
//! API for creating desktop applications using web technologies. This framework
//! bridges web frontends with native system capabilities through a command system.

// *: DOC COMMENTS, WORKING IN PROGRESS.

const std = @import("std");
const bridge = @import("bridge/backend/api.zig");

pub const WindowConfig = @import("config.zig").WindowConfig;
pub const WindowHint = @import("config.zig").WindowHint;
pub const QuarkWindow = @import("window.zig").QuarkWindow;

/// Creates a new Quark application with the specified configuration.
///
/// This is the primary entry point for creating Quark applications.
/// The window will be configured according to the provided WindowConfig
/// but will not be displayed until executeWindow is called.
pub fn createWindow(config: WindowConfig) !QuarkWindow {
    return QuarkWindow.create(config);
}

/// Executes the main event loop for a Quark window.
///
/// This function displays the window and starts the main event loop,
/// blocking until the window is closed. Should be called after
/// createWindow and any necessary setup.
pub fn executeWindow(window: *QuarkWindow) !void {
    return window.run();
}

/// Registers a command handler for front to backend communication.
///
/// This function allow the frontend to invoke native backend functionality.
/// The handler will be called when the frontend invokes the specified command.
pub fn registerCommand(name: []const u8, handler: bridge.CommandHandler) !void {
    return bridge.register(name, handler);
}

/// Calls a registered command from the backend to the frontend.
///
/// This allows backend code to invoke commands, [..] add more stuff here
pub fn callCommand(function_name: []const u8, args: []const u8) !void {
    return bridge.call(function_name, args);
}

/// Emits an event to the frontend.
///
/// This allows the backend to push data like notifications to the frontend.
pub fn emitCommand(event_name: []const u8, data: []const u8) !void {
    return bridge.emit(event_name, data);
}
