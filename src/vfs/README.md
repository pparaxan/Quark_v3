<img src="../../assets/branding/quark_white.svg" width="78px" align="left">

### `Quark Virtual File System`

<a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript" target="_blank"><img src="https://img.shields.io/badge/made%20in-pure%20javascript-F7DF1E?style=for-the-badge&logoColor=white"/></a>

QVFS is a module that creates a virtual filesystem inside your webview that intercepts asset requests and serves them from embedded data, eliminating the need for network access or disk I/O.

## How it Works

### Runtime Virtual Filesystem
QVFS injects a global object at runtime, `window.__QUARK_VFS__`, containing all your assets as base64 data.

### Transparent Asset Interception
<!-- (fetch, createElement, XMLHttpRequest) -->
Overrides webview APIs to catch asset requests and serve from the virtual filesystem instead.

## Features

- **Transparent Operation**: Works with standard HTML/CSS without changes.
- **Zero Network Dependency**: All assets are loaded from in-memory blobs.
- **Immutable by Design**: Assets can't be lost or modified after building the application.
