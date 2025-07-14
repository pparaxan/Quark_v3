// Wait until the DOM content is fully loaded before modifying elements
document.addEventListener("DOMContentLoaded", function () {
  // Process all <link rel="stylesheet" href="..."> elements
  document
    .querySelectorAll('link[rel="stylesheet"][href]')
    .forEach((linkElement) => {
      const hrefAttribute = linkElement.getAttribute("href");

      // Check if this stylesheet is in the Quark Virtual File System (QVFS)
      if (window.__QUARK_VFS__[hrefAttribute]) {
        const asset = window.__QUARK_VFS__[hrefAttribute];

        // Convert asset content to a Blob and generate a blob URL
        const assetBlob = createAssetBlob(asset);
        const blobUrl = URL.createObjectURL(assetBlob);

        // Replace the href with the generated blob URL
        linkElement.setAttribute("href", blobUrl);

        // After the stylesheet is loaded, process its contents (e.g., for inlined URLs)
        linkElement.addEventListener("load", function () {
          setTimeout(() => processCssStylesheet(this.sheet), 0);
        });
      }
    });

  // Process all <script src="..."> elements
  document.querySelectorAll("script[src]").forEach((scriptElement) => {
    const srcAttribute = scriptElement.getAttribute("src");

    // If the script is found in the QVFS, replace it with a new blob-based script
    if (window.__QUARK_VFS__[srcAttribute]) {
      const asset = window.__QUARK_VFS__[srcAttribute];
      const assetBlob = createAssetBlob(asset);
      const blobUrl = URL.createObjectURL(assetBlob);

      // Create a new <script> element using the blob URL
      const newScriptElement = document.createElement("script");
      newScriptElement.src = blobUrl;

      // Replace the old script tag with the new one
      scriptElement.parentNode.replaceChild(newScriptElement, scriptElement);
    }
  });

  // Delay to ensure stylesheets are attached, then process all of them for internal `url(...)` references
  setTimeout(() => {
    for (
      let stylesheetIndex = 0;
      stylesheetIndex < document.styleSheets.length;
      stylesheetIndex++
    ) {
      processCssStylesheet(document.styleSheets[stylesheetIndex]);
    }
  }, 100);
});

// Utility: Converts a base64-encoded QVFS asset into a Blob
function createAssetBlob(asset) {
  const byteCharacters = atob(asset.content);
  const byteNumbers = new Array(byteCharacters.length);

  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i);
  }

  const byteArray = new Uint8Array(byteNumbers);
  return new Blob([byteArray], { type: asset.mimeType });
}
