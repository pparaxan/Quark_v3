<img src="../../assets/branding/quark_white.svg" width="78px" align="left">

### `Quark Bridge`

QB is a robust bidirectional communication bridge between Zig (backend) and the WebView (frontend), enabling command execution and event handling for Quark desktop applications.

## Functions
<!-- Explain this better in the "comment" branch -->

### `register_command(name, handler)`
Register a backend function as a callable command from the frontend.

### `call_frontend(window, function_name, args)`
Execute a JavaScript function in the frontend from the backend.

### `emit_event(window, event_name, data)`
Emit custom events to the frontend event system.
