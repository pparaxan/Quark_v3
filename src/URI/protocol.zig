const std = @import("std");
const Quark = @import("../quark.zig");
const handler = @import("handler.zig");

pub fn URIProtocol(self: *Quark.Quark) Quark.quark_errors.WebViewError!void {
    // const interceptor = "interceptor.js";
    const interceptor = @embedFile("interceptor.js");
    const code = Quark.quark_webview.webview_bind(
        self.webview,
        "__quark", // change?
        handler.URIProtocolHandler,
        @ptrCast(self)
    );
    if (code != Quark.quark_webview.WEBVIEW_ERROR_OK) return Quark.quark_errors.mapError(code);

    const eval_code = Quark.quark_webview.webview_eval(self.webview, interceptor);
    if (eval_code != Quark.quark_webview.WEBVIEW_ERROR_OK) return Quark.quark_errors.mapError(eval_code);
}
