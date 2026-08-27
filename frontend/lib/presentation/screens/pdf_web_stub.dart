// Stub for non-web platforms — all functions are no-ops or return safe defaults.
void registerPdfViewFactory(String viewId, String containerId, String blobUrl) {}
void revokeBlobUrl(String url) {}
String createBlobUrl(List<int> bytes) => '';
