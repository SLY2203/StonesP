import 'package:flutter/foundation.dart';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart' as saver;

class FileSaver {
  static void saveFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    if (kIsWeb) {
      saver.saveFileBytes(bytes, filename, mimeType);
    }
  }

  static void openUrl(String url) {
    if (kIsWeb) {
      saver.openUrlInNewTab(url);
    }
  }
}
