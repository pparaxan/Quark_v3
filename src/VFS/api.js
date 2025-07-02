const originalCreateElement = document.createElement;

document.createElement = function(tagName) {
    const element = originalCreateElement.call(this, tagName);

    if (tagName.toLowerCase() === 'link') {
        const originalSetAttribute = element.setAttribute;
        let isStylesheet = false;

        element.setAttribute = function(name, value) {
            if (name === 'rel' && value === 'stylesheet') {
                isStylesheet = true;
                this.addEventListener('load', function() {
                    setTimeout(() => processCSS(this.sheet), 0);
                });
            }

            if (name === 'href' && window.__QUARK_VFS__[value]) {
                const asset = window.__QUARK_VFS__[value];
                const blob = createBlob(asset);
                const url = URL.createObjectURL(blob);
                return originalSetAttribute.call(this, name, url);
            }

            return originalSetAttribute.call(this, name, value);
        };
    }

    if (tagName.toLowerCase() === 'script') {
        const originalSetAttribute = element.setAttribute;

        element.setAttribute = function(name, value) {
            if (name === 'src' && window.__QUARK_VFS__[value]) {
                const asset = window.__QUARK_VFS__[value];
                const blob = createBlob(asset);
                const url = URL.createObjectURL(blob);
                return originalSetAttribute.call(this, name, url);
            }

            return originalSetAttribute.call(this, name, value);
        };
    }

    return element;
};

const originalFetch = window.fetch;
window.fetch = function(resource, options) {
    const url = resource.toString();

    if (!url.startsWith('http') && !url.startsWith('//') && window.__QUARK_VFS__[url]) {
        const asset = window.__QUARK_VFS__[url];
        const blob = createBlob(asset);

        return Promise.resolve(new Response(blob, {
            status: 200,
            statusText: 'OK',
            headers: {
                'Content-Type': asset.mimeType
            }
        }));
    }

    return originalFetch.call(this, resource, options);
};

// Utility function to create blob from assets that's in Quark's VFS
function createBlob(asset) {
    const byteCharacters = atob(asset.data);
    const byteNumbers = new Array(byteCharacters.length);
    for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
    }
    const byteArray = new Uint8Array(byteNumbers);
    return new Blob([byteArray], {
        type: asset.mimeType
    });
}
