//! Quark Virtual File System is a module that lives inside your webview
//! that intercepts asset requests and serves them from embedded data,
//! eliminating the need for network access or disk I/O.

// No need for the `binder` library.
pub const api = @embedFile("api.js");
pub const handler = @embedFile("handler.js");
pub const index = @embedFile("index.js");
pub const processor = @embedFile("processor.js");
