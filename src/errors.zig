pub const WebViewError = error{
    MissingDependency,
    Canceled,
    InvalidState,
    InvalidArgument,
    Unspecified,
    Duplicate,
    NotFound,
};

pub fn mapError(code: anytype) WebViewError {
    const b = @import("webview");
    return switch (code) {
        b.WEBVIEW_ERROR_MISSING_DEPENDENCY => WebViewError.MissingDependency,
        b.WEBVIEW_ERROR_CANCELED => WebViewError.Canceled,
        b.WEBVIEW_ERROR_INVALID_STATE => WebViewError.InvalidState,
        b.WEBVIEW_ERROR_INVALID_ARGUMENT => WebViewError.InvalidArgument,
        b.WEBVIEW_ERROR_UNSPECIFIED => WebViewError.Unspecified,
        b.WEBVIEW_ERROR_DUPLICATE => WebViewError.Duplicate,
        b.WEBVIEW_ERROR_NOT_FOUND => WebViewError.NotFound,
        else => unreachable,
    };
}
