import 'dart:io';

class ExportFileHelper {
  static Future<void> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }

  static Future<int> getFileSize(String path) async {
    final file = File(path);
    return file.length();
  }
}
