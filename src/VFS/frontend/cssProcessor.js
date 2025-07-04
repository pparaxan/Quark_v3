function processCssStylesheet(stylesheet) {
    if (!stylesheet || !stylesheet.cssRules) return;

    try {
        for (let ruleIndex = 0; ruleIndex < stylesheet.cssRules.length; ruleIndex++) {
            const cssRule = stylesheet.cssRules[ruleIndex];

            if (cssRule.style) {
                for (let cssProperty of cssRule.style) {
                    const propertyValue = cssRule.style.getPropertyValue(cssProperty);

                    if (propertyValue.includes('url(')) {
                        const processedValue = replaceCssUrlReferences(propertyValue);

                        if (processedValue !== propertyValue) {
                            cssRule.style.setProperty(cssProperty, processedValue);
                        }
                    }
                }
            }
        }
    } catch (processingError) {
        console.log('[QVFS] CSS processing error:', processingError);
    }
}

function replaceCssUrlReferences(cssValue) {
    return cssValue.replace(/url\(['"]?([^'")]+)['"]?\)/g, function(fullMatch, assetUrl) {
        if (window.__QUARK_VFS__[assetUrl]) {
            const asset = window.__QUARK_VFS__[assetUrl];
            const byteCharacters = atob(asset.content);
            const byteNumbers = new Array(byteCharacters.length);

            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }

            const byteArray = new Uint8Array(byteNumbers);
            const assetBlob = new Blob([byteArray], { type: asset.mimeType });
            const blobUrl = URL.createObjectURL(assetBlob);

            return 'url(' + blobUrl + ')';
        }

        return fullMatch;
    });
}
