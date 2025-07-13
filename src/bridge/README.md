<img src="../../assets/branding/quark_white.svg" width="78px" align="left">

### `Quark Bridge`

QB is a bidirectional communication layer that connects backends coded in Zig to WebView powered frontends. It provides a lightweight command/event system that allows the Zig side of things to:

- **Expose backend functions** that the frontend can call by name.
- **Invoke frontend JavaScript functions** directly from Zig.
- **Emit events** from the backend that the frontend can listen to.

---

### `registerCommand("name", handler)`

Registers a new command that the frontend can invoke.

- `name`: The name of the command you're giving `handler` to.
- `handler`: The backend function you're registering.

```zig
try api.register("openFile", openFileHandler);
```

### `callCommand(function_name, args)`

Calls a JavaScript function in the frontend from Zig.

- **`function_name`**: The function name the JS you're calling.
- **`args`**: A JSON-formatted string representing the arguments to pass to the JavaScript function.

```zig
try api.call("showPopup", "{\"message\":\"Hello World!\"}");
```

### `emitCommand(event_name, data)`

Fires a custom event to the frontend event bus `window.__QUARK_EVENTS__`.

- **`event_name`**: The string for the event you want to trigger on the frontend.
- **`data`**: JSON-formatted string containing the payload or details associated with the event.

```zig
try api.emit("dataReceived", "{\"id\":42}");
```
