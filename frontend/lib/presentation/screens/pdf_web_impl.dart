// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:ui_web' as ui;
import 'dart:html' as html;

void registerPdfViewFactory(String viewId, String containerId, String blobUrl) {
  ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final container = html.DivElement()
      ..id = containerId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'auto'
      ..style.backgroundColor = '#525659';

    final js = '''
      (async function waitForContainer() {
        const containerId = '$containerId';
        await new Promise((resolve) => {
          if (document.getElementById(containerId)) { resolve(); return; }
          const observer = new MutationObserver(() => {
            if (document.getElementById(containerId)) {
              observer.disconnect();
              resolve();
            }
          });
          observer.observe(document.body, { childList: true, subtree: true });
        });
        let attempts = 0;
        while (!window.pdfJsReady && attempts < 100) {
          await new Promise(resolve => setTimeout(resolve, 100));
          attempts++;
        }
        const pdfjsLib = window.pdfjsLib;
        if (!pdfjsLib) {
          const el = document.getElementById(containerId);
          if (el) el.innerHTML = '<p style="color:white;text-align:center;padding:20px;">Failed to load PDF viewer</p>';
          return;
        }
        let scale = 1.5;
        const container = document.getElementById(containerId);
        try {
          const loadingTask = pdfjsLib.getDocument('$blobUrl');
          const pdf = await loadingTask.promise;
          const numPages = pdf.numPages;
          async function renderAllPages(newScale) {
            container.innerHTML = '';
            for (let pageNum = 1; pageNum <= numPages; pageNum++) {
              const page = await pdf.getPage(pageNum);
              const viewport = page.getViewport({ scale: newScale });
              const canvas = document.createElement('canvas');
              canvas.style.display = 'block';
              canvas.style.margin = '16px auto';
              canvas.style.boxShadow = '0 2px 8px rgba(0,0,0,0.4)';
              canvas.height = viewport.height;
              canvas.width = viewport.width;
              container.appendChild(canvas);
              const ctx = canvas.getContext('2d');
              await page.render({ canvasContext: ctx, viewport: viewport }).promise;
            }
          }
          await renderAllPages(scale);
          container.addEventListener('wheel', function(e) {
            if (e.ctrlKey) {
              e.preventDefault();
              if (e.deltaY < 0) { scale = Math.min(scale + 0.25, 4.0); }
              else { scale = Math.max(scale - 0.25, 0.5); }
              renderAllPages(scale);
            }
          }, { passive: false });
        } catch (err) {
          console.error('[PDF.js] error:', err);
        }
      })();
    ''';
    final script = html.ScriptElement()..text = js;
    html.document.body!.append(script);
    return container;
  });
}

void revokeBlobUrl(String url) {
  html.Url.revokeObjectUrl(url);
}

String createBlobUrl(List<int> bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  return html.Url.createObjectUrlFromBlob(blob);
}
