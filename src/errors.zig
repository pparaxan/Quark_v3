pub const WebViewError = error{
    MissingDependency,
    Canceled,
    InvalidState,
    InvalidArgument,
    Unspecified,
    Duplicate,
    NotFound,
};

pub fn map_error(err: anytype) WebViewError {
    const lib = @import("webview");
    return switch (err) {
        lib.WEBVIEW_ERROR_MISSING_DEPENDENCY => WebViewError.MissingDependency,
        lib.WEBVIEW_ERROR_CANCELED => WebViewError.Canceled,
        lib.WEBVIEW_ERROR_INVALID_STATE => WebViewError.InvalidState,
        lib.WEBVIEW_ERROR_INVALID_ARGUMENT => WebViewError.InvalidArgument,
        lib.WEBVIEW_ERROR_UNSPECIFIED => WebViewError.Unspecified,
        lib.WEBVIEW_ERROR_DUPLICATE => WebViewError.Duplicate,
        lib.WEBVIEW_ERROR_NOT_FOUND => WebViewError.NotFound,
        else => unreachable,
    };
}
