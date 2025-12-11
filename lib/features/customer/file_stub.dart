// Stub file for web platform
// This file is used when compiling for web to avoid dart:io dependency

class File {
  final String path;
  File(this.path);
  Future<File> writeAsString(String contents) async {
    throw UnimplementedError('File operations not supported on web');
  }
}

