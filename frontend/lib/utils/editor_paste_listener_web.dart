import 'dart:js_interop';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as webapi;
import 'package:flutter_quill/flutter_quill.dart' as quill;

dynamic addImagePasteListener(quill.QuillController controller) {
  void handler(webapi.ClipboardEvent event) {
    final files = event.clipboardData?.files;
    if (files == null || files.length == 0) return;
    for (int i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null || !file.type.startsWith('image/')) continue;
      event.preventDefault();
      final reader = webapi.FileReader();
      void onLoad(webapi.Event _) {
        final jsResult = reader.result;
        if (jsResult == null) return;
        final dataUri = (jsResult as JSString).toDart;
        final index = controller.selection.baseOffset;
        final safeIndex = index < 0 ? 0 : index;
        controller.document.insert(safeIndex, '\n');
        controller.document.insert(safeIndex + 1, quill.BlockEmbed.image(dataUri));
        controller.document.insert(safeIndex + 2, '\n');
      }
      reader.onload = onLoad.toJS;
      reader.readAsDataURL(file);
      return;
    }
  }
  final jsListener = handler.toJS;
  webapi.window.addEventListener('paste', jsListener);
  return jsListener;
}

void removeImagePasteListener(dynamic listener) {
  if (listener == null) return;
  webapi.window.removeEventListener('paste', listener);
}
