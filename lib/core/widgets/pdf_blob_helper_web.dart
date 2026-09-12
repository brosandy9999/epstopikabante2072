import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Uint8List?> fetchWebBlobBytes(String blobUrl) async {
  try {
    final request = await html.HttpRequest.request(
      blobUrl,
      responseType: 'arraybuffer',
    );
    if (request.status == 200 && request.response != null) {
      final byteBuffer = request.response as ByteBuffer;
      return Uint8List.view(byteBuffer);
    }
  } catch (e) {
    // Error loading blob
  }
  return null;
}

void openExternalUrlInNewTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}
