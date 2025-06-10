const std = @import("std");
pub const quark_webview = @import("webview");
pub const quark_errors = @import("errors.zig");
const config = @import("config.zig");
pub const frontend = @import("frontend"); // check build.zig for more details about this.
const uri_protocol = @import("URI/protocol.zig");
// const uri_mime = @import("URI/mime.zig").URIMime;
const uri_mime = @import("URI/mime.zig");

pub const Quark = struct {
    webview: quark_webview.webview_t,
    config: config.QuarkConfig,

    // pub fn new(quark_config: config.QuarkConfig) quark_errors.WebViewError!Quark {
    //     const wv = quark_webview.webview_create(@intFromBool(quark_config.debug), null);
    //     if (wv == null) return quark_errors.WebViewError.MissingDependency;

    //     var quark = Quark{
    //         .webview = wv,
    //         .config = quark_config
    //     };

    //     try quark.setTitle(quark_config.title);

    //     try uri_protocol.URIProtocol(&quark);

    //     const entry = "index.html";
    //     const html = frontend.get(entry) orelse @panic("Missing entrypoint: index.html");

    //     try quark.setHtml(@ptrCast(html));
    //     return quark;
    // }

    pub fn new(quark_config: config.QuarkConfig) (quark_errors.WebViewError || error{OutOfMemory})!Quark {
        const wv = quark_webview.webview_create(@intFromBool(quark_config.debug), null);
        if (wv == null) return quark_errors.WebViewError.MissingDependency;

        var quark = Quark{
            .webview = wv,
            .config = quark_config
        };

        try quark.setTitle(quark_config.title);

        try uri_protocol.URIProtocol(&quark);

        const entry = "index.html";
        const html = frontend.get(entry) orelse @panic("Missing entrypoint: index.html");

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        const processed_html = try mimeToBase64(allocator, html);
        defer allocator.free(processed_html);

        const null_terminated = try allocator.allocSentinel(u8, processed_html.len, 0);
        defer allocator.free(null_terminated);
        @memcpy(null_terminated, processed_html);

        try quark.setHtml(null_terminated[0..processed_html.len :0]);
        return quark;
    }

    fn mimeToBase64(allocator: std.mem.Allocator, content: []const u8) error{OutOfMemory}![]u8 {
        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        var i: usize = 0;
        while (i < content.len) {
            if (i + 8 < content.len and std.mem.startsWith(u8, content[i..], "quark://")) {
                var url_end = i + 8;
                while (url_end < content.len) {
                    const char = content[url_end];
                    if (char == '"' or char == '\'' or char == ' ' or char == '>' or char == '\n' or char == '\r' or char == ')') {
                        break;
                    }
                    url_end += 1;
                }

                const path = content[i+8..url_end];
                std.debug.print("Processing quark:// URL: {s}\n", .{path});

                if (frontend.get(path)) |resource_data| {
                    const resource_mime_type = uri_mime.URIMimeType(path);

                    const processed_resource_data = try mimeToBase64(allocator, resource_data);
                    defer allocator.free(processed_resource_data);

                    const encoder = std.base64.standard.Encoder;
                    const encoded_len = encoder.calcSize(processed_resource_data.len);
                    const encoded = try allocator.alloc(u8, encoded_len);
                    defer allocator.free(encoded);

                    _ = encoder.encode(encoded, processed_resource_data);

                    const data_url = try std.fmt.allocPrint(
                        allocator,
                        "data:{s};base64,{s}", // I swear if this becomes a problem in the future, I'll @panic
                        .{ resource_mime_type, encoded }
                    );
                    defer allocator.free(data_url);

                    try result.appendSlice(data_url);
                    std.debug.print("Replaced with data URL (mime: {s})\n", .{resource_mime_type});
                    i = url_end;
                } else {
                    @panic("Put the 'quark://' URI at the start of your imported files!!");
                }
            } else {
                try result.append(content[i]);
                i += 1;
            }
        }

        return result.toOwnedSlice();
    }

    pub fn run(self: Quark) quark_errors.WebViewError!void {
        // This is a workaround, looks like the "GTK" in webkit2gtk has bad code,
        // `webview_set_size()` fails before `webview_run()` because the window hasn't
        // realized that the config is set yet.
        const code = quark_webview.webview_run(self.webview);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    fn setSizeInternal(self: Quark) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_size(
            self.webview,
            @as(c_int, @intCast(self.config.width)),
            @as(c_int, @intCast(self.config.height)),
            @as(c_uint, @intFromEnum(self.config.resizable))
        );
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    fn setTitle(self: Quark, title: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_title(self.webview, title.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    fn setHtml(self: Quark, html: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_html(self.webview, html.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn destroy(self: Quark) quark_errors.WebViewError!void {
        const code = quark_webview.webview_destroy(self.webview);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }
};
