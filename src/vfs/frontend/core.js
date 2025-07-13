/**
 * Quark Virtual File System is a module that lives inside your webview
 * that intercepts asset requests and serves them from embedded data,
 * eliminating the need for network access or disk I/O.
 *
 * @version 1.0.0
 */

window.__QUARK_VFS__ = {}; // Global registry shared with all [frontend] files that's in QVFS
