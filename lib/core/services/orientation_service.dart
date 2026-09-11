import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'orientation_helper.dart';

/// Unified Native & Cross-Platform Orientation & Fullscreen Controller
/// Forces hardware screen rotation into Landscape + Fullscreen for Authentic UBT Exam Hall terminals.
class OrientationService {
  static const MethodChannel _channel = MethodChannel('com.epstopik.app/orientation');

  /// Force hardware & browser screen rotation into Landscape + Fullscreen on all devices
  static Future<void> forceLandscape() async {
    // 1. Web browser fullscreen & landscape lock
    if (kIsWeb) {
      try {
        await lockWebLandscape();
      } catch (_) {}
    } else {
      try {
        await _channel.invokeMethod('forceLandscape');
      } catch (_) {}
    }

    // 2. Flutter Native System UI (Immersive Fullscreen) & Device Orientation Lock
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
  }

  /// Restore normal screen orientation & system UI upon leaving exam hall
  static Future<void> unlockOrientation() async {
    if (kIsWeb) {
      try {
        await exitWebFullscreen();
      } catch (_) {}
    } else {
      try {
        await _channel.invokeMethod('unlockOrientation');
      } catch (_) {}
    }

    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
  }

  /// Force hardware screen rotation into Portrait
  static Future<void> forcePortrait() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}
  }

  /// Toggle between Portrait and Landscape
  static Future<void> toggleOrientation(Orientation currentOrientation) async {
    if (currentOrientation == Orientation.landscape) {
      await forcePortrait();
    } else {
      await forceLandscape();
    }
  }
}
