function processCSS(stylesheet) {
    if (!stylesheet || !stylesheet.cssRules) return;

    try {
        for (let i = 0; i < stylesheet.cssRules.length; i++) {
            const rule = stylesheet.cssRules[i];
            if (rule.style) {
                for (let prop of rule.style) {
                    const value = rule.style.getPropertyValue(prop);
                    if (value.includes('url(')) {
                        const newValue = replaceURL_CSS(value);
                        if (newValue !== value) {
                            rule.style.setProperty(prop, newValue);
                        }
                    }
                }
            }
        }
    } catch (e) {
        console.log('CSS processing error:', e);
    }
}

function replaceURL_CSS(cssValue) {
    return cssValue.replace(/url\(['"]?([^'")]+)['"]?\)/g, function(match, url) {
        if (window.__QUARK_VFS__[url]) {
            const asset = window.__QUARK_VFS__[url];
            const byteCharacters = atob(asset.data);
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const blob = new Blob([byteArray], {
                type: asset.mimeType
            });
            const blobUrl = URL.createObjectURL(blob);
            return 'url(' + blobUrl + ')';
        }
        return match;
    });
}
