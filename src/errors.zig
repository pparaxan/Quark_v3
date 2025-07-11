const lib_webview = @import("webview");

pub const WebViewError = error{
    MissingDependency,
    Canceled,
    InvalidState,
    InvalidArgument,
    Unspecified,
    Duplicate,
    NotFound,
};

pub fn mapWebviewError(err: anytype) WebViewError {
    return switch (err) {
        lib_webview.WEBVIEW_ERROR_MISSING_DEPENDENCY => WebViewError.MissingDependency,
        lib_webview.WEBVIEW_ERROR_CANCELED => WebViewError.Canceled,
        lib_webview.WEBVIEW_ERROR_INVALID_STATE => WebViewError.InvalidState,
        lib_webview.WEBVIEW_ERROR_INVALID_ARGUMENT => WebViewError.InvalidArgument,
        lib_webview.WEBVIEW_ERROR_UNSPECIFIED => WebViewError.Unspecified,
        lib_webview.WEBVIEW_ERROR_DUPLICATE => WebViewError.Duplicate,
        lib_webview.WEBVIEW_ERROR_NOT_FOUND => WebViewError.NotFound,
        else => unreachable,
    };
}

pub fn checkError(code: c_int) WebViewError!void {
    if (code != lib_webview.WEBVIEW_ERROR_OK) {
        return mapWebviewError(code);
    }
}
