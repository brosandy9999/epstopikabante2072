import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_helper.dart';

/// Single-Audio Exclusive Playback Service
/// Guarantees that only ONE audio plays at any time across the entire application.
/// Supports Base64 data URLs, Cloud storage links (Google Drive, Dropbox, Firebase),
/// Local filesystem paths (Windows/Mobile/Desktop), Asset paths, and Korean TTS.
class AudioPlaybackService {
  static final AudioPlaybackService instance = AudioPlaybackService._internal();

  AudioPlaybackService._internal() {
    _initPlayer();
  }

  AudioPlayer? _player;
  int _playbackSessionId = 0;
  Completer<void>? _currentCompleter;
  StreamSubscription? _completeSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  /// Global state notifiers
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentAudioSourceNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);

  bool get isPlaying => isPlayingNotifier.value;
  String? get currentSource => currentAudioSourceNotifier.value;
  Duration get position => positionNotifier.value;
  Duration get duration => durationNotifier.value;

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _completeSubscription?.cancel();
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();

      _completeSubscription = _player?.onPlayerComplete.listen((_) {
        isPlayingNotifier.value = false;
        currentAudioSourceNotifier.value = null;
        positionNotifier.value = Duration.zero;
        if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
          _currentCompleter!.complete();
        }
      });

      _positionSubscription = _player?.onPositionChanged.listen((pos) {
        positionNotifier.value = pos;
      });

      _durationSubscription = _player?.onDurationChanged.listen((dur) {
        durationNotifier.value = dur;
      });
    } catch (e) {
      debugPrint('[AudioPlaybackService] Player init error: $e');
      _player = null;
    }
  }

  /// Converts Google Drive or Dropbox links to direct streamable audio links
  String normalizeAudioUrl(String input) {
    var clean = input.trim();
    if (clean.isEmpty) return clean;

    // Google Drive share link -> direct download/stream link
    // e.g. https://drive.google.com/file/d/FILE_ID/view?usp=sharing
    final gDriveRegex = RegExp(r'https?://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = gDriveRegex.firstMatch(clean);
    if (match != null) {
      final fileId = match.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }

    // Google Drive open?id= link
    final gDriveOpenRegex = RegExp(r'https?://drive\.google\.com/(?:open|uc)\?(?:.*&)?id=([a-zA-Z0-9_-]+)');
    final matchOpen = gDriveOpenRegex.firstMatch(clean);
    if (matchOpen != null) {
      final fileId = matchOpen.group(1);
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }

    // Dropbox share link -> direct download
    if (clean.contains('dropbox.com')) {
      if (clean.contains('?dl=0')) {
        return clean.replaceAll('?dl=0', '?raw=1');
      } else if (!clean.contains('?raw=1') && !clean.contains('?dl=1')) {
        return clean.contains('?') ? '$clean&raw=1' : '$clean?raw=1';
      }
    }

    return clean;
  }

  /// Changes playback speed
  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player?.setPlaybackRate(rate);
    } catch (_) {}
  }

  /// Seek to position in the current track
  Future<void> seek(Duration position) async {
    try {
      await _player?.seek(position);
    } catch (_) {}
  }

  /// Stops any currently playing audio immediately
  Future<void> stop() async {
    _playbackSessionId++; // Invalidate any ongoing transition
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }
    _currentCompleter = null;

    try {
      await _player?.stop();
    } catch (_) {}

    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
  }

  /// Speaks Korean text using Korean TTS with exclusive single-playback
  Future<void> playKoreanSpeech(String koreanText) async {
    final cleanText = koreanText.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleanText.isEmpty) return;

    final sessionId = ++_playbackSessionId;
    await stop();

    final completer = Completer<void>();
    _currentCompleter = completer;

    try {
      final encoded = Uri.encodeComponent(cleanText);
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=$encoded';
      
      _player ??= AudioPlayer();
      if (_playbackSessionId != sessionId) return;

      currentAudioSourceNotifier.value = 'tts:$cleanText';
      isPlayingNotifier.value = true;
      await _player?.play(UrlSource(url));
    } catch (e) {
      debugPrint('[AudioPlaybackService] TTS Error: $e');
      isPlayingNotifier.value = false;
      currentAudioSourceNotifier.value = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Plays Korean speech and returns a Future that completes when playback finishes
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

  /// Plays an uploaded audio file (Data URL, network URL, local disk path, or asset) with exclusive single-playback
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
      _player ??= AudioPlayer();
      if (_playbackSessionId != sessionId) return;

      currentAudioSourceNotifier.value = clean;
      isPlayingNotifier.value = true;

      // 1. Data URL (Base64) or Blob URL
      if (clean.startsWith('data:') || clean.startsWith('blob:')) {
        if (clean.startsWith('blob:')) {
          await _player?.play(UrlSource(clean));
        } else {
          final source = await getSourceFromDataUrl(clean, sessionId);
          if (_playbackSessionId != sessionId) return;
          await _player?.play(source);
        }
      }
      // 2. Network URL (HTTP / HTTPS)
      else if (clean.startsWith('http://') || clean.startsWith('https://')) {
        final directUrl = normalizeAudioUrl(clean);
        await _player?.play(UrlSource(directUrl));
      }
      // 3. File URI (file://...)
      else if (clean.startsWith('file://')) {
        var filePath = clean.replaceFirst('file:///', '');
        if (filePath.startsWith('file://')) {
          filePath = filePath.replaceFirst('file://', '');
        }
        filePath = Uri.decodeComponent(filePath);
        await _player?.play(DeviceFileSource(filePath));
      }
      // 4. Windows / Local absolute file path (e.g. C:\... or C:/... or /...)
      else if (RegExp(r'^[a-zA-Z]:[\/]').hasMatch(clean) || (clean.startsWith('/') && !clean.startsWith('/assets'))) {
        await _player?.play(DeviceFileSource(clean));
      }
      // 5. Bundled Flutter Asset
      else {
        var assetPath = clean;
        if (assetPath.startsWith('assets/')) {
          assetPath = assetPath.replaceFirst('assets/', '');
        }
        await _player?.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('[AudioPlaybackService] playAudioUrl failed: $e, source: ${clean.length > 80 ? '${clean.substring(0, 80)}...' : clean}');
      isPlayingNotifier.value = false;
      currentAudioSourceNotifier.value = null;
      if (!completer.isCompleted) completer.complete();

      // Attempt fallback to TTS if text is provided
      if (fallbackKoreanText != null && fallbackKoreanText.trim().isNotEmpty) {
        debugPrint('[AudioPlaybackService] Falling back to Korean TTS...');
        await playKoreanSpeech(fallbackKoreanText);
      }
    }
  }

  /// Plays audio and waits until finished
  Future<void> playAudioUrlAndWait(String audioUrl, {String? fallbackKoreanText, Duration defaultMaxWait = const Duration(seconds: 40)}) async {
    await playAudioUrl(audioUrl, fallbackKoreanText: fallbackKoreanText);
    if (_currentCompleter != null) {
      try {
        await _currentCompleter!.future.timeout(defaultMaxWait);
      } catch (_) {}
    }
  }

  /// Disposes audio player
  void dispose() {
    _completeSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
    isPlayingNotifier.value = false;
    currentAudioSourceNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
  }
}
