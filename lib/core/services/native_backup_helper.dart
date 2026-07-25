import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeBackupFile(String fileName, List<int> bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = await File('${dir.path}/$fileName').writeAsBytes(bytes);
  return file.path;
}
