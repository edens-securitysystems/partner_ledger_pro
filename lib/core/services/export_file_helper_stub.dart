class ExportFileHelper {
  static Future<void> writeBytes(String path, List<int> bytes) async {
    throw UnsupportedError('File operations not available on web');
  }

  static Future<int> getFileSize(String path) async {
    throw UnsupportedError('File operations not available on web');
  }
}
