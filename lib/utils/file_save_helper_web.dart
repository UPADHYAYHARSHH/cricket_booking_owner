import 'dart:typed_data';

class FileSaveHelper {
  static Future<void> saveFile(String path, Uint8List bytes) async {
    // On Web, we use Printing.sharePdf so this won't be called,
    // but the class must exist for conditional imports.
  }
}
