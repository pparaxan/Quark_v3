(function() { // generated with AI, ~~doubt there's a need for this~~ except for testing et al.
    const originalFetch = window.fetch;
    window.fetch = function(url, options) {
        if (typeof url === 'string' && url.startsWith('quark://')) {
            const path = url.substring('quark://'.length);
            return window.__quark(path).then(result => {
                if (result.success) {
                    return new Response(result.data, {
                        status: 200,
                        headers: {
                            'Content-Type': result.mimeType
                        }
                    });
                } else {
                    return Promise.reject(new Error('Resource not found'));
                }
            });
        }
        return originalFetch.call(this, url, options);
    };
})();
