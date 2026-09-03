import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_playback_service.dart';

/// Cross-platform Korean Text-To-Speech / Audio pronunciation helper.
/// Safe for web and mobile, and passes Flutter test VM runner.
class KoreanTtsService {
  static final KoreanTtsService instance = KoreanTtsService._internal();
  KoreanTtsService._internal();

  Future<void> speakKorean(String koreanText) async {
    if (koreanText.trim().isEmpty) return;

    try {
      await AudioPlaybackService.instance.playKoreanSpeech(koreanText);
    } catch (e) {
      debugPrint('[KoreanTtsService] Error speaking: $e');
    }
  }
}
