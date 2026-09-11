import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_helper.dart';

/// Single-Audio Exclusive Playback Service
/// Guarantees that only ONE audio plays at any time across the entire application.
/// Supports Base64 data URLs, Cloud storage links (Google Drive, Dropbox, Firebase),
/// Local filesystem paths (Windows/Mobile/Desktop), Asset paths, and Korean TTS.
class AudioPlaybackService {
  static final AudioPlaybackService instance = AudioPlaybackService._internal();

  AudioPlaybackService._internal();

  final PlatformAudioController _controller = PlatformAudioController();
  int _playbackSessionId = 0;
  Completer<void>? _currentCompleter;

  /// Global state notifiers
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentAudioSourceNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);

  bool get isPlaying => isPlayingNotifier.value;
  String? get currentSource => currentAudioSourceNotifier.value;
  Duration get position => positionNotifier.value;
  Duration get duration => durationNotifier.value;

  /// Converts Google Drive or Dropbox links to direct streamable audio links
  String normalizeAudioUrl(String input) {
    var clean = input.trim();
    if (clean.isEmpty) return clean;

    final gDriveRegex = RegExp(r'https?://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = gDriveRegex.firstMatch(clean);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }

    final gDriveOpenRegex = RegExp(r'https?://drive\.google\.com/(?:open|uc)\?(?:.*&)?id=([a-zA-Z0-9_-]+)');
    final matchOpen = gDriveOpenRegex.firstMatch(clean);
    if (matchOpen != null) {
      final fileId = matchOpen.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }

    if (clean.contains('dropbox.com')) {
      if (clean.contains('?dl=0')) {
        return clean.replaceAll('?dl=0', '?raw=1');
      } else if (!clean.contains('?raw=1') && !clean.contains('?dl=1')) {
        return clean.contains('?') ? '$clean&raw=1' : '$clean?raw=1';
      }
    }

    return clean;
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      await _controller.setPlaybackRate(rate);
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _controller.seek(position);
    } catch (_) {}
  }

  Future<void> stop() async {
    _playbackSessionId++;
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }
    _currentCompleter = null;

    try {
      await _controller.stop();
    } catch (_) {}

    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
  }

  Future<void> playKoreanSpeech(String koreanText) async {
    final cleanText = koreanText.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleanText.isEmpty) return;

    final encoded = Uri.encodeComponent(cleanText);
    final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=$encoded';
    await playAudioUrl(url);
  }

  Future<void> playKoreanSpeechAndWait(String koreanText) async {
    final cleanText = koreanText.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleanText.isEmpty) return;

    await playKoreanSpeech(cleanText);
    if (_currentCompleter != null) {
      final estimatedSec = (cleanText.length * 0.18 + 1.5).clamp(2.5, 30.0);
      final timeoutDuration = Duration(milliseconds: (estimatedSec * 1000).round());
      try {
        await _currentCompleter!.future.timeout(timeoutDuration);
      } catch (_) {}
    }
  }

  Future<void> playAudioUrl(String audioUrl, {String? fallbackKoreanText}) async {
    var clean = audioUrl.trim();
    if (clean.isEmpty) {
      if (fallbackKoreanText != null && fallbackKoreanText.trim().isNotEmpty) {
        await playKoreanSpeech(fallbackKoreanText);
      }
      return;
    }

    final sessionId = ++_playbackSessionId;
    await stop();

    final completer = Completer<void>();
    _currentCompleter = completer;

    try {
      final directUrl = normalizeAudioUrl(clean);
      currentAudioSourceNotifier.value = directUrl;

      await _controller.play(
        source: directUrl,
        sessionId: sessionId,
        onPlayingChanged: (playing) {
          isPlayingNotifier.value = playing;
        },
        onPositionChanged: (pos) {
          positionNotifier.value = pos;
        },
        onDurationChanged: (dur) {
          durationNotifier.value = dur;
        },
        onCompleted: () {
          currentAudioSourceNotifier.value = null;
          positionNotifier.value = Duration.zero;
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      debugPrint('[AudioPlaybackService] playAudioUrl failed: $e, source: ${clean.length > 80 ? "${clean.substring(0, 80)}..." : clean}');
      isPlayingNotifier.value = false;
      currentAudioSourceNotifier.value = null;
      if (!completer.isCompleted) completer.complete();

      if (fallbackKoreanText != null && fallbackKoreanText.trim().isNotEmpty) {
        debugPrint('[AudioPlaybackService] Falling back to Korean TTS...');
        await playKoreanSpeech(fallbackKoreanText);
      }
    }
  }

  Future<void> playAudioUrlAndWait(String audioUrl, {String? fallbackKoreanText, Duration defaultMaxWait = const Duration(seconds: 40)}) async {
    await playAudioUrl(audioUrl, fallbackKoreanText: fallbackKoreanText);
    if (_currentCompleter != null) {
      try {
        await _currentCompleter!.future.timeout(defaultMaxWait);
      } catch (_) {}
    }
  }

  void dispose() {
    _controller.dispose();
    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
  }
}
