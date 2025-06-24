const std = @import("std");
const quark_webview = @import("webview");
const quark_errors = @import("errors.zig");
const config = @import("config.zig");
pub const frontend = @import("frontend"); // check build.zig for more details about this.
const mime = @import("mime.zig");
const vfs = @import("VFS/linker.zig");

pub const Quark = struct {
    webview: quark_webview.webview_t,
    config: config.QuarkConfig,

    pub fn createWindow(quark_config: config.QuarkConfig) (quark_errors.WebViewError || error{OutOfMemory})!Quark {
        const wv = quark_webview.webview_create(@intFromBool(quark_config._debug), null);
        if (wv == null) return quark_errors.WebViewError.MissingDependency;

        var quark = Quark{ .webview = wv, .config = quark_config };

        try checkError(quark_webview.webview_set_title(quark.webview, quark_config._title));
        try QuarkVirtualFileSystem(&quark);

        const html = frontend.get("index.html") orelse @panic("Missing entrypoint: src/<frontend>/index.html");

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        const null_terminated = try allocator.allocSentinel(u8, html.len, 0);
        defer allocator.free(null_terminated);
        @memcpy(null_terminated, html);

        try checkError(quark_webview.webview_set_html(quark.webview, null_terminated[0..html.len :0].ptr));
        return quark;
    }

    pub fn execWindow(self: Quark) quark_errors.WebViewError!void {
        // This is a workaround, looks like the "GTK" in webkit2gtk has bad code,
        // `webview_set_size()` fails before `webview_run()` because the window hasn't
        // realized that the config is set yet.
        return checkError(quark_webview.webview_run(self.webview));
    }

    // fn setSize(self: Quark) quark_errors.WebViewError!void {
    //     return checkError(quark_webview.webview_set_size(
    //         self.webview,
    //         @as(c_int, @intCast(self.config.width)),
    //         @as(c_int, @intCast(self.config.height)),
    //         @as(c_uint, @intFromEnum(self.config.resizable))
    //     ));
    // }

    // pub fn destroyWindow(self: Quark) quark_errors.WebViewError!void {
    //     return checkError(quark_webview.webview_destroy(self.webview));
    // }
};

fn QuarkVirtualFileSystem(quark: *Quark) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var js_code = std.ArrayList(u8).init(allocator);
    defer js_code.deinit();

    const vfs_modules = [_][]const u8{ vfs.api, vfs.handler, vfs.index, vfs.processor };

    for (vfs_modules) |module_content| {
        try js_code.appendSlice(module_content);
    }

    for (frontend.resources) |resource| {
        const escaped_data = try base64(allocator, resource.path);
        defer allocator.free(escaped_data);

        const mime_type = mime.mimeType(resource.file);

        try js_code.writer().print(
            \\window.__QUARK_VFS__["{s}"] = {{
            \\  data: "{s}",
            \\  mimeType: "{s}"
            \\}};
            \\
        , .{ resource.file, escaped_data, mime_type });
    }

    const null_terminated = try allocator.allocSentinel(u8, js_code.items.len, 0);
    defer allocator.free(null_terminated);
    @memcpy(null_terminated, js_code.items);

    try checkError(quark_webview.webview_init(quark.webview, null_terminated[0..js_code.items.len :0].ptr));
}

fn base64(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
    const encoder = std.base64.standard.Encoder;
    const encoded_len = encoder.calcSize(data.len);
    const encoded = try allocator.alloc(u8, encoded_len);

    _ = encoder.encode(encoded, data);
    return encoded;
}

fn checkError(code: c_int) quark_errors.WebViewError!void {
    // _ = self;
    if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
}
