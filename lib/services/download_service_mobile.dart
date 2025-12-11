import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  static Future<String> savePdf(Uint8List bytes, String fileName) async {
    try {
      final file = await _getDownloadFile(fileName);
      await file.writeAsBytes(bytes);
      return 'PDF saved to ${file.path}';
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<String> saveCsv(String csvContent, String fileName) async {
    try {
      final file = await _getDownloadFile(fileName);
      await file.writeAsString(csvContent);
      return 'CSV saved to ${file.path}';
    } catch (e) {
      throw Exception('Failed to save CSV: $e');
    }
  }

  static Future<String> saveJson(Map<String, dynamic> data, String fileName) async {
    try {
      final jsonContent = jsonEncode(data);
      final file = await _getDownloadFile(fileName);
      await file.writeAsString(jsonContent);
      return 'JSON saved to ${file.path}';
    } catch (e) {
      throw Exception('Failed to save JSON: $e');
    }
  }

  static Future<File> _getDownloadFile(String fileName) async {
    if (Platform.isAndroid) {
      // Request storage permission for Android only
      try {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          throw Exception('Storage permission denied');
        }
      } catch (e) {
        // Fallback if permission handler fails
        print('Permission request failed: $e');
      }
      
      // Use public Downloads folder
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return File(path.join(downloadsDir.path, fileName));
    } else {
      // For Windows, macOS, Linux - use user Downloads folder
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Could not access Downloads directory');
      }
      return File(path.join(downloadsDir.path, fileName));
    }
  }
}