import 'package:audioplayers/audioplayers.dart';
import 'audio_helper_stub.dart'
    if (dart.library.html) 'audio_helper_web.dart';

Future<Source> getSourceFromDataUrl(String dataUrl, int sessionId) {
  return getAudioSourceFromDataUrl(dataUrl, sessionId);
}
