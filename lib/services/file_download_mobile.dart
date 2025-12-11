import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class FileDownloadService {
  static Future<String?> downloadBytes(Uint8List bytes, String filename, String mimeType) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> downloadText(String content, String filename) async {
    final bytes = utf8.encode(content);
    return await downloadBytes(Uint8List.fromList(bytes), filename, 'text/plain');
  }
}