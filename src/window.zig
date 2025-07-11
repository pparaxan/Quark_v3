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

pub const QuarkWindow = struct {
    handle: webview.webview_t,
    config: config.WindowConfig,
    allocator: std.mem.Allocator,

    const Self = @This();

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

    fn initialize(self: *Self) WebViewError!void {
        self.setTitle() catch |err| @panic(@errorName(err));
        self.setSize() catch |err| @panic(@errorName(err));
        self.setupGVFS() catch |err| @panic(@errorName(err));
        self.loadEntryPoint() catch |err| @panic(@errorName(err));
        self.setupBridge() catch |err| @panic(@errorName(err));
    }

    fn setupBridge(self: *Self) !void {
        const bridge_js = @embedFile("bridge/frontend/core.js");
        const null_terminated = try self.allocator.allocSentinel(u8, bridge_js.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, bridge_js);

        try errors.checkError(webview.webview_init(self.handle, null_terminated.ptr));
        try errors.checkError(webview.webview_bind(self.handle, "quark_bridge_handler", bridge_handler.bridge_callback, null));
    }

    fn setTitle(self: *Self) WebViewError!void {
        return errors.checkError(webview.webview_set_title(self.handle, self.config.title));
    }

    fn setupGVFS(self: *Self) !void {
        var vfs = try @import("vfs/backend/qvfs.zig").QuarkVirtualFileSystem.init(self.allocator);
        defer vfs.deinit();

        const js_injection = try vfs.generate_injection_code();
        defer self.allocator.free(js_injection);

        const null_terminated = try self.allocator.allocSentinel(u8, js_injection.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, js_injection);

        try errors.checkError(webview.webview_init(self.handle, null_terminated.ptr));
    }

    fn loadEntryPoint(self: *Self) !void {
        const html_content = frontend.get("index.html") orelse return WebViewError.Unspecified;
        const null_terminated = try self.allocator.allocSentinel(u8, html_content.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, html_content);

        try errors.checkError(webview.webview_set_html(self.handle, null_terminated.ptr));
    }

    fn setSize(self: Self) WebViewError!void {
        return errors.checkError(webview.webview_set_size(
            self.handle,
            @intCast(self.config.width),
            @intCast(self.config.height),
            @intFromEnum(self.config.size_hint),
        ));
    }

    pub fn run(self: *Self) WebViewError!void {
        bridge.global_window = self.handle;
        defer bridge.global_window = null;

        return errors.checkError(webview.webview_run(self.handle));
    }

    pub fn destroy(self: *Self) WebViewError!void {
        try errors.checkError(webview.webview_destroy(self.handle));
        bridge_handler.deinit();
        _ = global_gpa.deinit();
    }
};
