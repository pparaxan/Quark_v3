document.addEventListener('DOMContentLoaded', function() {
    console.log('[QVFS] DOM loaded, processing existing elements...');

    document.querySelectorAll('link[rel="stylesheet"][href]').forEach(linkElement => {
        const hrefAttribute = linkElement.getAttribute('href');

        if (window.__QUARK_VFS__[hrefAttribute]) {
            const asset = window.__QUARK_VFS__[hrefAttribute];
            const assetBlob = createAssetBlob(asset);
            const blobUrl = URL.createObjectURL(assetBlob);
            linkElement.setAttribute('href', blobUrl);

            linkElement.addEventListener('load', function() {
                setTimeout(() => processCssStylesheet(this.sheet), 0);
            });
        }
    });

    document.querySelectorAll('script[src]').forEach(scriptElement => {
        const srcAttribute = scriptElement.getAttribute('src');

        if (window.__QUARK_VFS__[srcAttribute]) {
            const asset = window.__QUARK_VFS__[srcAttribute];
            const assetBlob = createAssetBlob(asset);
            const blobUrl = URL.createObjectURL(assetBlob);

            const newScriptElement = document.createElement('script');
            newScriptElement.src = blobUrl;
            scriptElement.parentNode.replaceChild(newScriptElement, scriptElement);
        }
    });

    setTimeout(() => {
        for (let stylesheetIndex = 0; stylesheetIndex < document.styleSheets.length; stylesheetIndex++) {
            processCssStylesheet(document.styleSheets[stylesheetIndex]);
        }
    }, 100);
});

function createAssetBlob(asset) {
    const byteCharacters = atob(asset.content);
    const byteNumbers = new Array(byteCharacters.length);

    for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
    }

    const byteArray = new Uint8Array(byteNumbers);
    return new Blob([byteArray], { type: asset.mimeType });
}
