import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;

class DownloadService {
  static Future<String> savePdf(Uint8List bytes, String fileName) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return 'PDF downloaded successfully';
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<String> saveCsv(String csvContent, String fileName) async {
    try {
      final blob = html.Blob([csvContent]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return 'CSV downloaded successfully';
    } catch (e) {
      throw Exception('Failed to save CSV: $e');
    }
  }

  static Future<String> saveJson(Map<String, dynamic> data, String fileName) async {
    try {
      final jsonContent = jsonEncode(data);
      final blob = html.Blob([jsonContent]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      return 'JSON downloaded successfully';
    } catch (e) {
      throw Exception('Failed to save JSON: $e');
    }
  }
}