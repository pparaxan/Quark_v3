//! Error handling for Quark operations.
//!
//! This module provides error mapping and checking functions to convert
//! between the underlying webview library's C error codes and Zig's
//! native error handling system.

const lib_webview = @import("webview");

/// Error types that can occur during webview operations.
///
/// These errors map directly to the underlying webview library's
/// error codes, providing a Zig-native error handling interface.
/// https://github.com/webview/webview/blob/master/core/include/webview/errors.h#L45
pub const WebViewError = error{
    /// Required system dependency is missing
    MissingDependency,
    /// Operation was canceled by the user or system
    Canceled,
    /// Webview is in an invalid state for the requested operation
    InvalidState,
    /// An invalid argument was passed to the webview function
    InvalidArgument,
    /// An unspecified error occurred.
    Unspecified,
    /// Duplicate resource or operation attempted
    Duplicate,
    /// Requested resource was not found
    NotFound,
};

/// Maps webview library error codes to Zig WebViewError enum.
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

/// Checks a webview operation result code and returns error if failed.
pub fn checkError(code: c_int) WebViewError!void {
    if (code != lib_webview.WEBVIEW_ERROR_OK) {
        return mapWebviewError(code);
    }
}
