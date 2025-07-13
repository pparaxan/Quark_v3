//! Core window management and webview integration for Quark applications.
//!
//! This module provides the QuarkWindow struct, which encapsulates a webview
//! instance with associated configuration, bridging, and lifecycle management.
//! It handles the integration between the frontend and native backend.
// ^?
const std = @import("std");
const webview = @import("webview");
const config = @import("config.zig");
const errors = @import("errors.zig");
const WebViewError = errors.WebViewError;
pub const frontend = @import("frontend");
const bridge = @import("bridge/backend/api.zig");
const bridge_handler = @import("bridge/backend/handler.zig");
const api = @import("bridge/backend/api.zig");

pub const CommandHandler = api.CommandHandler;

var global_gpa: std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
}) = .{};

/// QuarkWindow manages the complete lifecycle of a Quark application, including
/// window (webview) creation, bridge between the back and fontend, virtual file
/// system integration, and event loop execution.
pub const QuarkWindow = struct {
    handle: webview.webview_t,
    config: config.WindowConfig,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// [..]
    ///
    /// This function initializes the webview with the config from WindowConfig,
    /// initializes all of the window subsystems, and prepares the window for execution.
    pub fn create(window_config: config.WindowConfig) (WebViewError || error{OutOfMemory})!Self {
        const allocator = global_gpa.allocator();

        bridge_handler.init(allocator);

        const handle = webview.webview_create(@intFromBool(window_config.debug_mode), null);
        if (handle == null) return WebViewError.MissingDependency;

        var window = Self{
            .handle = handle,
            .config = window_config,
            .allocator = allocator,
        };

        try window.initialize();
        return window;
    }

    /// Initializes all window subsystems.
    ///
    /// Sets up giving the window a title and size, sets up the virtual
    /// file system, loads the main index.html from the src_quark folder,
    /// and configures the frontend-backend bridge.
    fn initialize(self: *Self) WebViewError!void {
        self.setTitle() catch |err| @panic(@errorName(err));
        self.setSize() catch |err| @panic(@errorName(err));
        self.setupGVFS() catch |err| @panic(@errorName(err));
        self.loadEntryPoint() catch |err| @panic(@errorName(err));
        self.setupBridge() catch |err| @panic(@errorName(err));
    }

    /// Sets up the JavaScript-Zig bridge for frontend-backend communication.
    ///
    /// [..]
    fn setupBridge(self: *Self) !void {
        const bridge_js = @embedFile("bridge/frontend/core.js");
        const null_terminated = try self.allocator.allocSentinel(u8, bridge_js.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, bridge_js);

        try errors.checkError(webview.webview_init(self.handle, null_terminated.ptr));
        try errors.checkError(webview.webview_bind(self.handle, "quark_bridge_handler", bridge_handler.bridgeCallback, null));
    }

    /// Sets the window title from WindowConfig.
    fn setTitle(self: *Self) WebViewError!void {
        return errors.checkError(webview.webview_set_title(self.handle, self.config.title));
    }

    /// Sets up the Quark Virtual File System, used for serving the frontend assets.
    /// Read the README [here](src/vfs/README.md).
    ///
    /// Initializes the virtual file system and injects the necessary JavaScript
    /// code to handle asset loading from the embedded frontend resources.
    // Work on this
    fn setupGVFS(self: *Self) !void {
        var vfs = try @import("vfs/backend/qvfs.zig").QuarkVirtualFileSystem.init(self.allocator);
        defer vfs.asset_registry.deinit();

        const js_injection = try vfs.generateInjectionCode();
        defer self.allocator.free(js_injection);

        const null_terminated = try self.allocator.allocSentinel(u8, js_injection.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, js_injection);

        try errors.checkError(webview.webview_init(self.handle, null_terminated.ptr));
    }

    /// Loads the main index.html entry point to be used for the application.
    ///
    /// Retrieves the index.html file from the embedded resources library
    /// "binder", get it's contents and set it as the webview's HTML content.
    // reword this later?
    fn loadEntryPoint(self: *Self) !void {
        const html_content = frontend.get("index.html") orelse return WebViewError.Unspecified;
        const null_terminated = try self.allocator.allocSentinel(u8, html_content.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, html_content);

        try errors.checkError(webview.webview_set_html(self.handle, null_terminated.ptr));
    }

    /// Sets the window size and resize behavior from WindowConfig.
    fn setSize(self: Self) WebViewError!void {
        return errors.checkError(webview.webview_set_size(
            self.handle,
            @intCast(self.config.width),
            @intCast(self.config.height),
            @intFromEnum(self.config.size_hint),
        ));
    }

    /// Starts the main event loop and displays the window.
    ///
    /// This function blocks until the window is closed, processing
    /// everything from the `create` function.
    pub fn run(self: *Self) WebViewError!void {
        bridge.global_window = self.handle;
        defer bridge.global_window = null;

        return errors.checkError(webview.webview_run(self.handle));
    }

    /// Destroys the window and cleans up all resources.
    ///
    /// This function should be called when the window is no longer needed
    /// to ensure proper cleanup of the webview handle and associated resources.
    pub fn destroy(self: *Self) WebViewError!void {
        try errors.checkError(webview.webview_destroy(self.handle));
        bridge_handler.deinit();
        _ = global_gpa.deinit();
    }
};
