let isLoading = false;
document.getElementById("scan-btn").addEventListener("click", reportSysInfo);

async function reportSysInfo() {
  if (isLoading) return;

  isLoading = true;
  const scanBtn = document.getElementById("scan-btn");
  const distroValue = document.getElementById("distro-value");
  const kernelValue = document.getElementById("kernel-value");

  scanBtn.textContent = "Scanning...";
  scanBtn.disabled = true;
  distroValue.textContent = kernelValue.textContent = "Fetching...";

  try {
    const response = await quark.invoke("reportSystemInfo", {});
    const systemInfo = JSON.parse(response);

    distroValue.textContent = systemInfo.distro;
    kernelValue.textContent = systemInfo.kernel;

    // // Remove loading classes
    // distroValue.classList.remove('loading');
    // kernelValue.classList.remove('loading');
  } catch (error) {
    console.error(error);
    // Add more stuff idk man?
  } finally {
    isLoading = false;
    scanBtn.textContent = "Scan Now";
    scanBtn.disabled = false;
  }
}
