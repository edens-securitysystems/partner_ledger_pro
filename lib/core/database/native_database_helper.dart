import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class NativeDatabaseHelper {
  static Future<QueryExecutor> openFile(String dbPath) async {
    final file = File(dbPath);
    return NativeDatabase.createInBackground(file);
  }
}
