import 'dart:io';

String uniqueFilePath(String basePath, String fileName) {
  int count = 1;
  String path = '$basePath/$fileName';
  String nameWithoutExt = fileName.split('.').first;
  String extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';

  while (File(path).existsSync()) {
    path = '$basePath/$nameWithoutExt($count)$extension';
    count++;
  }

  return path;
}

