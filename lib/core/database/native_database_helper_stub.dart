import 'package:drift/drift.dart';

class NativeDatabaseHelper {
  static Future<QueryExecutor> openFile(String dbPath) async {
    throw UnsupportedError('Native database not available on web');
  }
}
