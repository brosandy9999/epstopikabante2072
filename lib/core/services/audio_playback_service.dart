import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Single-Audio Exclusive Playback Service
/// Guarantees that only ONE audio plays at any time across the entire application.
/// Any previous audio (TTS or MP3) is strictly stopped before new audio starts.
class AudioPlaybackService {
  static final AudioPlaybackService instance = AudioPlaybackService._internal();
  AudioPlaybackService._internal() {
    _initPlayer();
  }

  AudioPlayer? _player;
  int _playbackSessionId = 0;
  StreamSubscription? _completeSubscription;

  /// Global state notifiers
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentAudioSourceNotifier = ValueNotifier<String?>(null);

  bool get isPlaying => isPlayingNotifier.value;
  String? get currentSource => currentAudioSourceNotifier.value;

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _completeSubscription?.cancel();
      _completeSubscription = _player?.onPlayerComplete.listen((_) {
        isPlayingNotifier.value = false;
        currentAudioSourceNotifier.value = null;
      });
    } catch (_) {
      _player = null;
    }
  }

  /// Stops any currently playing audio immediately
  Future<void> stop() async {
    _playbackSessionId++; // Invalidate any ongoing transition
    try {
      await _player?.stop();
    } catch (_) {}
    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
  }

  /// Speaks Korean text using Korean TTS with exclusive single-playback
  Future<void> playKoreanSpeech(String koreanText) async {
    final cleanText = koreanText.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleanText.isEmpty) return;

    final sessionId = ++_playbackSessionId;
    await stop();

    try {
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=${Uri.encodeComponent(cleanText)}';
      
      _player ??= AudioPlayer();
      if (_playbackSessionId != sessionId) return; // Another sound was triggered

      currentAudioSourceNotifier.value = 'tts:$cleanText';
      isPlayingNotifier.value = true;
      await _player?.play(UrlSource(url));
    } catch (_) {
      isPlayingNotifier.value = false;
      currentAudioSourceNotifier.value = null;
    }
  }

  /// Plays an uploaded audio file (Data URL, network URL, or asset) with exclusive single-playback
  Future<void> playAudioUrl(String audioUrl) async {
    final clean = audioUrl.trim();
    if (clean.isEmpty) return;

    final sessionId = ++_playbackSessionId;
    await stop();

    try {
      _player ??= AudioPlayer();
      if (_playbackSessionId != sessionId) return; // Another sound was triggered

      currentAudioSourceNotifier.value = clean;
      isPlayingNotifier.value = true;

      if (clean.startsWith('data:audio') || clean.startsWith('data:application')) {
        final base64Part = clean.contains(',') ? clean.split(',')[1] : clean;
        final bytes = base64Decode(base64Part);
        await _player?.play(BytesSource(bytes));
      } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
        await _player?.play(UrlSource(clean));
      } else {
        await _player?.play(AssetSource(clean));
      }
    } catch (_) {
      isPlayingNotifier.value = false;
      currentAudioSourceNotifier.value = null;
    }
  }

  /// Disposes audio player
  void dispose() {
    _completeSubscription?.cancel();
    _completeSubscription = null;
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
  }
}
