const std = @import("std");
const Quark = @import("../quark.zig");
const handler = @import("handler.zig");

pub fn URIProtocol(self: *Quark.Quark) Quark.quark_errors.WebViewError!void {
    _ = Quark.quark_webview.webview_bind(
        self.webview,
        "__quark", // change?
        handler.URIProtocolHandler,
        @ptrCast(self)
    );
    return;
}
