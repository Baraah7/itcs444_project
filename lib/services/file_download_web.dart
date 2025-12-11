import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

class FileDownloadService {
  static void downloadBytes(Uint8List bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static void downloadText(String content, String filename) {
    final bytes = utf8.encode(content);
    downloadBytes(Uint8List.fromList(bytes), filename, 'text/plain');
  }
}