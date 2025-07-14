// Define the global Quark Bridge interface.
window.__QUARK_BRIDGE__ = {
  /**
   * Invokes a backend command via the bridge.
   *
   * @param {string} command - Name of the backend function to invoke.
   * @param {object} payload - JSON-serializable payload sent to the backend.
   * @returns {Promise<any>} - Either resolves with a response from the backend, or rejects on error.
   */
  invoke: function (command, payload) {
    return new Promise((resolve, reject) => {
      // Generate a unique ID to correlate the request with a response.
      const id = Math.random().toString(36).slice(2, 11);

      // Construct the bridge message in the expected JSON format.
      const message = JSON.stringify({
        id: id,
        command: command,
        payload: payload || {},
      });

      // Ensure the global callback registry exists.
      window.__QUARK_BRIDGE_CALLBACKS__ =
        window.__QUARK_BRIDGE_CALLBACKS__ || {};

      // Register the request's promise callbacks under the unique ID.
      window.__QUARK_BRIDGE_CALLBACKS__[id] = {
        resolve,
        reject,
      };

      // Send the message to the backend through the bridge handler.
      window.quark_bridge_handler(message);
    });
  },

  /**
   * Emits an event to the backend.
   *
   * Unlike invoke, this doesn’t wait for a response.
   *
   * @param {string} event - Event name.
   * @param {object} data - JSON-serializable event data sent to the backend.
   */
  emit: function (event, data) {
    const message = JSON.stringify({
      type: "event",
      event: event,
      data: data || {},
    });

    // Again, sends the message to backend via the bridge handler.
    window.quark_bridge_handler(message);
  },
};

// Expose the bridge via a convenient alias.
window.quark = window.__QUARK_BRIDGE__;

/**
 * Called by the backend to deliver a response to a previously invoked command.
 *
 * @param {string} id - The request ID to match with pending promises.
 * @param {boolean} success - Whether the response represents a success or failure.
 * @param {any} data - The actual response data or error message.
 */
window.__QUARK_BRIDGE_HANDLE_RESPONSE__ = function (id, success, data) {
  const callback = window.__QUARK_BRIDGE_CALLBACKS__[id];
  if (callback) {
    if (success) {
      callback.resolve(data);
    } else {
      callback.reject(new Error(data));
    }
    // Once handled, clean up the callback reference.
    delete window.__QUARK_BRIDGE_CALLBACKS__[id];
  }
};
