(function() {
    'use strict';

    const originalFetch = window.fetch;
    const originalCreateElement = document.createElement;

    // Intercept fetch requests for virtual assets
    window.fetch = function(resource, options) {
        const url = resource.toString();

        if (isVirtualAsset(url)) {
            return createVirtualResponse(url);
        }

        return originalFetch.call(this, resource, options);
    };

    // Intercept DOM element creation for asset loading
    document.createElement = function(tagName) {
        const element = originalCreateElement.call(this, tagName);

        if (tagName.toLowerCase() === 'link') {
            interceptLinkElement(element);
        } else if (tagName.toLowerCase() === 'script') {
            interceptScriptElement(element);
        }

        return element;
    };

    function isVirtualAsset(url) {
        return !url.startsWith('http') &&
            !url.startsWith('//') &&
            window.__QUARK_VFS__[url];
    }

    function createVirtualResponse(url) {
        const asset = window.__QUARK_VFS__[url];
        const assetBlob = createAssetBlob(asset);

        return Promise.resolve(new Response(assetBlob, {
            status: 200,
            statusText: 'OK',
            headers: {
                'Content-Type': asset.mimeType
            }
        }));
    }

    function interceptLinkElement(linkElement) {
        const originalSetAttribute = linkElement.setAttribute;
        let isStylesheet = false;

        linkElement.setAttribute = function(attributeName, attributeValue) {
            if (attributeName === 'rel' && attributeValue === 'stylesheet') {
                isStylesheet = true;
                this.addEventListener('load', function() {
                    setTimeout(() => processCssStylesheet(this.sheet), 0);
                });
            }

            if (attributeName === 'href' && window.__QUARK_VFS__[attributeValue]) {
                const asset = window.__QUARK_VFS__[attributeValue];
                const assetBlob = createAssetBlob(asset);
                const blobUrl = URL.createObjectURL(assetBlob);
                return originalSetAttribute.call(this, attributeName, blobUrl);
            }

            return originalSetAttribute.call(this, attributeName, attributeValue);
        };
    }

    function interceptScriptElement(scriptElement) {
        const originalSetAttribute = scriptElement.setAttribute;

        scriptElement.setAttribute = function(attributeName, attributeValue) {
            if (attributeName === 'src' && window.__QUARK_VFS__[attributeValue]) {
                const asset = window.__QUARK_VFS__[attributeValue];
                const assetBlob = createAssetBlob(asset);
                const blobUrl = URL.createObjectURL(assetBlob);
                return originalSetAttribute.call(this, attributeName, blobUrl);
            }

            return originalSetAttribute.call(this, attributeName, attributeValue);
        };
    }

    function createAssetBlob(asset) {
        const byteCharacters = atob(asset.content);
        const byteNumbers = new Array(byteCharacters.length);

        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        return new Blob([byteArray], {
            type: asset.mimeType
        });
    }
})();
