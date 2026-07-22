import 'dart:io';

export 'dart:io' show File;

PlatformFile createPlatformFile(String path) => PlatformFile(path);

class PlatformFile {
  final String path;
  const PlatformFile(this.path);

  File get file => File(path);
}
