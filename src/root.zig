const std = @import("std");
const fmt = std.fmt;
const quark_webview = @import("webview");
const quark_errors = @import("errors.zig");

pub const WebView = struct {
    webview: quark_webview.webview_t,
    const Self = @This();

    pub const DispatchCallback = fn(view: WebView, data: ?*anyopaque) void;

    pub fn create(debug: bool, external_window: ?*anyopaque) Self {
        return Self{
            .webview = quark_webview.webview_create(@intFromBool(debug), external_window),
        };
    }

    pub fn run(self: Self) quark_errors.WebViewError!void {
        const code = quark_webview.webview_run(self.webview);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn terminate(self: Self) quark_errors.WebViewError!void {
        const code = quark_webview.webview_terminate(self.webview);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn dispatch(self: Self, callback: DispatchCallback, data: ?*anyopaque) quark_errors.WebViewError!void {
        const trampoline = struct {
            fn function(w: quark_webview.webview_t, arg: ?*anyopaque) callconv(.C) void {
                const view = WebView{ .webview = w };
                callback(view, arg);
            }
        };
        const code = quark_webview.webview_dispatch(self.webview, trampoline.function, data);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn getWindow(self: Self) ?*anyopaque {
        return quark_webview.webview_get_window(self.webview);
    }

    pub fn setTitle(self: Self, title: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_title(self.webview, title.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn setSize(self: Self, width: i32, height: i32, hint: u32) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_size(self.webview, width, height, hint);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn setHtml(self: Self, html: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_set_html(self.webview, html.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn navigate(self: Self, url: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_navigate(self.webview, url.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn init(self: Self, js: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_init(self.webview, js.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn eval(self: Self, js: [:0]const u8) quark_errors.WebViewError!void {
        const code = quark_webview.webview_eval(self.webview, js.ptr);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }

    pub fn destroy(self: Self) quark_errors.WebViewError!void {
        const code = quark_webview.webview_destroy(self.webview);
        if (code != quark_webview.WEBVIEW_ERROR_OK) return quark_errors.mapError(code);
    }
};
