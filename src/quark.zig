const std = @import("std");
const quark_webview = @import("webview");
const quark_errors = @import("errors.zig");
const config = @import("config.zig");

pub const Quark = struct {
    webview: quark_webview.webview_t,
    config: config.QuarkConfig,

    pub fn new(quark_config: config.QuarkConfig) quark_errors.WebViewError!Quark {
        const wv = quark_webview.webview_create(@intFromBool(quark_config.debug), null);
        if (wv == null) return quark_errors.WebViewError.MissingDependency;

        var quark = Quark{
            .webview = wv,
            .config = quark_config
        };

        try quark.setTitle(quark_config.title);

        if (quark_config.html) |html| {
            try quark.setHtml(html);
        }

        return quark;
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

    fn setUrl(self: Quark, url: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_navigate(self.webview, url.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    } // make this use webview_set_html, what am I saying-
};
