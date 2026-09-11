import 'dart:convert';
import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';

Future<Source> getAudioSourceFromDataUrl(String dataUrl, int sessionId) async {
  try {
    final base64Part = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
    final bytes = base64Decode(base64Part.trim());
    final blob = html.Blob([bytes], 'audio/mpeg');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    return UrlSource(blobUrl);
  } catch (_) {
    return UrlSource(dataUrl);
  }
}
