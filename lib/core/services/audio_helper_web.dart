import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PlatformAudioController {
  html.AudioElement? _audio;
  StreamSubscription? _timeUpdateSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _loadedSub;
  String? _currentBlobUrl;

  Future<void> play({
    required String source,
    required int sessionId,
    required void Function(bool) onPlayingChanged,
    required void Function(Duration) onPositionChanged,
    required void Function(Duration) onDurationChanged,
    required void Function() onCompleted,
  }) async {
    await stop();

    String playUrl = source.trim();

    // If Base64 Data URL, convert to Blob URL for instant native audio streaming
    if (playUrl.startsWith('data:audio/') ||
        playUrl.startsWith('data:application/octet-stream') ||
        (playUrl.startsWith('data:') && playUrl.contains('base64,'))) {
      try {
        final commaIdx = playUrl.indexOf(',');
        final base64Part = commaIdx != -1 ? playUrl.substring(commaIdx + 1) : playUrl;
        final cleanBase64 = base64Part.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        
        String mimeType = 'audio/mpeg';
        if (playUrl.startsWith('data:audio/wav')) {
          mimeType = 'audio/wav';
        } else if (playUrl.startsWith('data:audio/ogg')) {
          mimeType = 'audio/ogg';
        } else if (playUrl.startsWith('data:audio/mp4') || playUrl.startsWith('data:audio/x-m4a')) {
          mimeType = 'audio/mp4';
        }

        final blob = html.Blob([bytes], mimeType);
        _currentBlobUrl = html.Url.createObjectUrlFromBlob(blob);
        playUrl = _currentBlobUrl!;
      } catch (e) {
        debugPrint('[WebAudio] Base64 to Blob conversion error: $e');
      }
    } else if (!playUrl.startsWith('http://') &&
        !playUrl.startsWith('https://') &&
        !playUrl.startsWith('blob:')) {
      // In Flutter Web, assets are served at assets/assets/... or assets/...
      if (playUrl.startsWith('assets/assets/')) {
        playUrl = playUrl;
      } else if (playUrl.startsWith('assets/')) {
        playUrl = 'assets/$playUrl';
      } else {
        playUrl = 'assets/assets/$playUrl';
      }
    }

    final audio = html.AudioElement(playUrl)..autoplay = true;
    _audio = audio;

    _loadedSub = audio.onLoadedMetadata.listen((_) {
      final dur = audio.duration;
      if (dur != null && !dur.isNaN && !dur.isInfinite) {
        onDurationChanged(Duration(milliseconds: (dur * 1000).round()));
      }
    });

    _timeUpdateSub = audio.onTimeUpdate.listen((_) {
      final curr = audio.currentTime;
      if (curr != null && !curr.isNaN) {
        onPositionChanged(Duration(milliseconds: (curr * 1000).round()));
      }
    });

    _endedSub = audio.onEnded.listen((_) {
      onPlayingChanged(false);
      onCompleted();
    });

    audio.onError.listen((e) {
      debugPrint('[WebAudio] AudioElement error loading: $playUrl');
      // If assets/assets/... failed, retry with assets/...
      if (playUrl.startsWith('assets/assets/')) {
        final altUrl = playUrl.replaceFirst('assets/assets/', 'assets/');
        debugPrint('[WebAudio] Retrying with alt URL: $altUrl');
        audio.src = altUrl;
        audio.load();
        audio.play().catchError((err) {
          debugPrint('[WebAudio] Alt play failed: $err');
          onPlayingChanged(false);
          onCompleted();
        });
      } else {
        onPlayingChanged(false);
        onCompleted();
      }
    });

    try {
      await audio.play();
      onPlayingChanged(true);
    } catch (e) {
      debugPrint('[WebAudio] play() failed: $e, url: ${playUrl.length > 60 ? '${playUrl.substring(0, 60)}...' : playUrl}');
      onPlayingChanged(false);
      onCompleted();
    }
  }

  Future<void> stop() async {
    _timeUpdateSub?.cancel();
    _endedSub?.cancel();
    _loadedSub?.cancel();
    _timeUpdateSub = null;
    _endedSub = null;
    _loadedSub = null;

    if (_audio != null) {
      try {
        _audio?.pause();
        _audio?.currentTime = 0;
        _audio?.remove();
      } catch (_) {}
      _audio = null;
    }

    if (_currentBlobUrl != null) {
      try {
        html.Url.revokeObjectUrl(_currentBlobUrl!);
      } catch (_) {}
      _currentBlobUrl = null;
    }
  }

  Future<void> seek(Duration pos) async {
    if (_audio != null) {
      try {
        _audio?.currentTime = pos.inMilliseconds / 1000.0;
      } catch (_) {}
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    if (_audio != null) {
      try {
        _audio?.playbackRate = rate;
      } catch (_) {}
    }
  }

  void dispose() {
    stop();
  }
}
