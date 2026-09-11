import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class PlatformAudioController {
  AudioPlayer? _player;
  StreamSubscription? _completeSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  File? _tempAudioFile;

  Future<void> play({
    required String source,
    required int sessionId,
    required void Function(bool) onPlayingChanged,
    required void Function(Duration) onPositionChanged,
    required void Function(Duration) onDurationChanged,
    required void Function() onCompleted,
  }) async {
    await stop();

    _player = AudioPlayer();

    _completeSub = _player?.onPlayerComplete.listen((_) {
      onPlayingChanged(false);
      onCompleted();
    });

    _posSub = _player?.onPositionChanged.listen((pos) {
      onPositionChanged(pos);
    });

    _durSub = _player?.onDurationChanged.listen((dur) {
      onDurationChanged(dur);
    });

    var clean = source.trim();

    Source audioSource;
    if (clean.startsWith('data:') || clean.startsWith('blob:')) {
      final commaIdx = clean.indexOf(',');
      final base64Part = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
      final cleanBase64 = base64Part.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(cleanBase64);
      _tempAudioFile = File('${Directory.systemTemp.path}/eps_uploaded_$sessionId.mp3');
      await _tempAudioFile!.writeAsBytes(bytes, flush: true);
      audioSource = DeviceFileSource(_tempAudioFile!.path);
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      audioSource = UrlSource(clean);
    } else if (clean.startsWith('file://')) {
      var p = clean.replaceFirst('file:///', '').replaceFirst('file://', '');
      p = Uri.decodeComponent(p);
      audioSource = DeviceFileSource(p);
    } else if (RegExp(r'^[a-zA-Z]:[\/]').hasMatch(clean) || (clean.startsWith('/') && !clean.startsWith('/assets'))) {
      audioSource = DeviceFileSource(clean);
    } else {
      var assetPath = clean.startsWith('assets/') ? clean.replaceFirst('assets/', '') : clean;
      audioSource = AssetSource(assetPath);
    }

    try {
      await _player?.play(audioSource);
      onPlayingChanged(true);
    } catch (e) {
      debugPrint('[MobileAudio] play() failed: $e, source: ${clean.length > 60 ? '${clean.substring(0, 60)}...' : clean}');
      onPlayingChanged(false);
      rethrow;
    }
  }

  Future<void> stop() async {
    _completeSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub = null;
    _posSub = null;
    _durSub = null;

    if (_player != null) {
      try {
        await _player?.stop();
        await _player?.dispose();
      } catch (_) {}
      _player = null;
    }

    if (_tempAudioFile != null) {
      try {
        if (_tempAudioFile!.existsSync()) {
          _tempAudioFile!.deleteSync();
        }
      } catch (_) {}
      _tempAudioFile = null;
    }
  }

  Future<void> seek(Duration pos) async {
    try {
      await _player?.seek(pos);
    } catch (_) {}
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player?.setPlaybackRate(rate);
    } catch (_) {}
  }

  void dispose() {
    stop();
  }
}
