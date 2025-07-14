// Scans a stylesheet's CSS rules and rewrites `url(...)` references to use blob URLs from QVFS
function processCssStylesheet(stylesheet) {
  if (!stylesheet || !stylesheet.cssRules) return;

  try {
    for (
      let ruleIndex = 0;
      ruleIndex < stylesheet.cssRules.length;
      ruleIndex++
    ) {
      const cssRule = stylesheet.cssRules[ruleIndex];

      // Only process style rules
      if (cssRule.style) {
        for (let cssProperty of cssRule.style) {
          const propertyValue = cssRule.style.getPropertyValue(cssProperty);

          // Only process rules with a `url(...)` in them
          if (propertyValue.includes("url(")) {
            const processedValue = replaceCssUrlReferences(propertyValue);

            if (processedValue !== propertyValue) {
              cssRule.style.setProperty(cssProperty, processedValue);
            }
          }
        }
      }
    }
  } catch (processingError) {
    console.log("[QVFS] CSS processing error:", processingError);
  }
}

// Replaces `url(...)` in a CSS string with `url(blob:...)` if said asset exists in QVFS
function replaceCssUrlReferences(cssValue) {
  return cssValue.replace(
    /url\(['"]?([^'")]+)['"]?\)/g,
    function (fullMatch, assetUrl) {
      const asset = window.__QUARK_VFS__[assetUrl];
      if (asset) {
        const byteCharacters = atob(asset.content);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        const assetBlob = new Blob([byteArray], { type: asset.mimeType });
        const blobUrl = URL.createObjectURL(assetBlob);

        return "url(" + blobUrl + ")";
      }

      return fullMatch;
    },
  );
}
