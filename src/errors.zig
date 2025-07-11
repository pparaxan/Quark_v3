const libwebview = @import("webview");

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
        libwebview.WEBVIEW_ERROR_MISSING_DEPENDENCY => WebViewError.MissingDependency,
        libwebview.WEBVIEW_ERROR_CANCELED => WebViewError.Canceled,
        libwebview.WEBVIEW_ERROR_INVALID_STATE => WebViewError.InvalidState,
        libwebview.WEBVIEW_ERROR_INVALID_ARGUMENT => WebViewError.InvalidArgument,
        libwebview.WEBVIEW_ERROR_UNSPECIFIED => WebViewError.Unspecified,
        libwebview.WEBVIEW_ERROR_DUPLICATE => WebViewError.Duplicate,
        libwebview.WEBVIEW_ERROR_NOT_FOUND => WebViewError.NotFound,
        else => unreachable,
    };
}

pub fn checkError(code: c_int) WebViewError!void {
    if (code != libwebview.WEBVIEW_ERROR_OK) {
        return mapWebviewError(code);
    }
}
