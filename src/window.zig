const std = @import("std");
const webview = @import("webview");
const config = @import("config.zig");
const errors = @import("errors.zig");
const WebViewError = errors.WebViewError;
pub const frontend = @import("frontend");

pub const QuarkWindow = struct {
    handle: webview.webview_t,
    config: config.WindowConfig,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn create(window_config: config.WindowConfig) (WebViewError || error{OutOfMemory})!Self {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

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
        self.set_title() catch |err| @panic(@errorName(err));
        self.setup_gvfs() catch |err| @panic(@errorName(err));
        self.load_entrypoint() catch |err| @panic(@errorName(err));
    }

    fn set_title(self: *Self) WebViewError!void {
        return check_error(webview.webview_set_title(self.handle, self.config.title));
    }

    fn setup_gvfs(self: *Self) !void {
        var vfs = try @import("VFS/backend/qvfs.zig").QuarkVirtualFileSystem.init(self.allocator);
        defer vfs.deinit();

        const js_injection = try vfs.generate_injection_code();
        defer self.allocator.free(js_injection);

        const null_terminated = try self.allocator.allocSentinel(u8, js_injection.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, js_injection);

        try check_error(webview.webview_init(self.handle, null_terminated.ptr));
    }

    fn load_entrypoint(self: *Self) !void {
        const html_content = frontend.get("index.html") orelse return WebViewError.Unspecified; // temp?
        const null_terminated = try self.allocator.allocSentinel(u8, html_content.len, 0);
        defer self.allocator.free(null_terminated);
        @memcpy(null_terminated, html_content);

        try check_error(webview.webview_set_html(self.handle, null_terminated.ptr));
    }

    pub fn run(self: Self) WebViewError!void {
        return check_error(webview.webview_run(self.handle));
    }

    pub fn destroy(self: Self) !void { // not needed but needed, if that made sense.
        try check_error(webview.webview_destroy(self.handle));
    }
};

fn check_error(code: c_int) WebViewError!void {
    if (code != webview.WEBVIEW_ERROR_OK) {
        return errors.map_error(code);
    }
}
