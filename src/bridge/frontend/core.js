window.__QUARK_BRIDGE__ = {
   invoke: function (command, payload) {
      return new Promise((resolve, reject) => {
        const id = Math.random().toString(36).slice(2, 11);
         const message = JSON.stringify({
            id: id,
            command: command,
            payload: payload || {}
         });

         window.__QUARK_BRIDGE_CALLBACKS__ = window.__QUARK_BRIDGE_CALLBACKS__ || {};
         window.__QUARK_BRIDGE_CALLBACKS__[id] = {
            resolve,
            reject
         };

         window.quark_bridge_handler(message);
      });
   },

   emit: function (event, data) {
      const message = JSON.stringify({
         type: 'event',
         event: event,
         data: data || {}
      });
      window.quark_bridge_handler(message);
   }
};

window.quark = window.__QUARK_BRIDGE__;

window.__QUARK_BRIDGE_HANDLE_RESPONSE__ = function (id, success, data) {
   const callback = window.__QUARK_BRIDGE_CALLBACKS__[id];
   if (callback) {
      if (success) {
         callback.resolve(data);
      } else {
         callback.reject(new Error(data));
      }
      delete window.__QUARK_BRIDGE_CALLBACKS__[id];
   }
};

console.log("Quark Bridge initialized.");
