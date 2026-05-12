import 'dart:io';
import 'dart:typed_data';

class FileSaveHelper {
  static Future<void> saveFile(String path, Uint8List bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}
