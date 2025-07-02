document.addEventListener('DOMContentLoaded', function() {
    console.log('Document Object Model has loaded, processing existing elements...');

    document.querySelectorAll('link[rel="stylesheet"][href]').forEach(link => {
        const href = link.getAttribute('href');
        if (window.__QUARK_VFS__[href]) {
            const asset = window.__QUARK_VFS__[href];
            const blob = createBlob(asset);
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);

            link.addEventListener('load', function() {
                setTimeout(() => processCSS(this.sheet), 0);
            });
        }
    });

    document.querySelectorAll('script[src]').forEach(script => {
        const src = script.getAttribute('src');
        if (window.__QUARK_VFS__[src]) {
            const asset = window.__QUARK_VFS__[src];
            const blob = createBlob(asset);
            const url = URL.createObjectURL(blob);

            const newScript = document.createElement('script');
            newScript.src = url;
            script.parentNode.replaceChild(newScript, script);
        }
    });

    setTimeout(() => {
        for (let i = 0; i < document.styleSheets.length; i++) {
            processCSS(document.styleSheets[i]);
        }
    }, 100);
});
