// Quark Virtual File System is a module that lives inside your webview
// that intercepts asset requests and serves them from embedded data,
// eliminating the need for network access or disk I/O. The frontend
// catches any asset requests and serves them from the backend instead.
// QVFS[-js] is currently at version 0.1.1

window.__QUARK_VFS__ = {}; // Sends the backend data to the frontend.

console.log("Quark Virtual File System initialized");
