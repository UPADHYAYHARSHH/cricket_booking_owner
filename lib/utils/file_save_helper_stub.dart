import 'dart:typed_data';

abstract class FileSaveHelper {
  static Future<void> saveFile(String path, Uint8List bytes) async {
    throw UnimplementedError();
  }
}
