import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

Future<Source> getAudioSourceFromDataUrl(String dataUrl, int sessionId) async {
  final base64Part = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
  final bytes = base64Decode(base64Part.trim());
  final tempFile = File('${Directory.systemTemp.path}/eps_audio_${sessionId}.mp3');
  await tempFile.writeAsBytes(bytes, flush: true);
  return DeviceFileSource(tempFile.path);
}
