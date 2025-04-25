const std = @import("std");
const fmt = std.fmt;
const webview = @import("webview_trans");

pub const WebView = struct {
    webview: webview.webview_t,
    const Self = @This();

    pub const WebViewError = error {
        MissingDependency,
        Canceled,
        InvalidState,
        InvalidArgument,
        Unspecified,
        Duplicate,
        NotFound,
    };

    pub const DispatchCallback = fn(view: WebView, data: ?*anyopaque) void;

    pub fn create(debug: bool, external_window: ?*anyopaque) Self {
        return Self{
            .webview = webview.webview_create(@intFromBool(debug), external_window),
        };
    }

    pub fn run(self: Self) WebViewError!void {
        const code = webview.webview_run(self.webview);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn terminate(self: Self) WebViewError!void {
        const code = webview.webview_terminate(self.webview);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn dispatch(self: Self, callback: DispatchCallback, data: ?*anyopaque) WebViewError!void {
        const trampoline = struct {
            fn function(w: webview.webview_t, arg: ?*anyopaque) callconv(.C) void {
                const view = WebView{ .webview = w };
                callback(view, arg);
            }
        };
        const code = webview.webview_dispatch(self.webview, trampoline.function, data);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn getWindow(self: Self) ?*anyopaque {
        return webview.webview_get_window(self.webview);
    }

    pub fn setTitle(self: Self, title: [:0]const u8) WebViewError!void {
        const code = webview.webview_set_title(self.webview, title.ptr);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn setSize(self: Self, width: i32, height: i32, hint: u32) WebViewError!void {
        const code = webview.webview_set_size(self.webview, width, height, hint);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn setHtml(self: Self, html: [:0]const u8) WebViewError!void {
        const code = webview.webview_set_html(self.webview, html.ptr);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn navigate(self: Self, url: [:0]const u8) WebViewError!void {
        const code = webview.webview_navigate(self.webview, url.ptr);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn init(self: Self, js: [:0]const u8) WebViewError!void {
        const code = webview.webview_init(self.webview, js.ptr);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn eval(self: Self, js: [:0]const u8) WebViewError!void {
        const code = webview.webview_eval(self.webview, js.ptr);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

    pub fn destroy(self: Self) WebViewError!void {
        const code = webview.webview_destroy(self.webview);
        if (code != webview.WEBVIEW_ERROR_OK) return mapError(code);
    }

};

fn mapError(code: webview.webview_error_t) WebView.WebViewError {
    return switch (code) {
        webview.WEBVIEW_ERROR_MISSING_DEPENDENCY => WebView.WebViewError.MissingDependency,
        webview.WEBVIEW_ERROR_CANCELED => WebView.WebViewError.Canceled,
        webview.WEBVIEW_ERROR_INVALID_STATE => WebView.WebViewError.InvalidState,
        webview.WEBVIEW_ERROR_INVALID_ARGUMENT => WebView.WebViewError.InvalidArgument,
        webview.WEBVIEW_ERROR_UNSPECIFIED => WebView.WebViewError.Unspecified,
        webview.WEBVIEW_ERROR_DUPLICATE => WebView.WebViewError.Duplicate,
        webview.WEBVIEW_ERROR_NOT_FOUND => WebView.WebViewError.NotFound,
        else => unreachable,
    };
}
