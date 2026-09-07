import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 🔄 Unified Native & Cross-Platform Orientation Controller
/// Forces hardware screen rotation into Landscape for Authentic UBT Exam Hall terminals.
class OrientationService {
  static const MethodChannel _channel = MethodChannel('com.epstopik.app/orientation');

  /// 🔒 Force hardware screen rotation into Landscape
  static Future<void> forceLandscape() async {
    if (!kIsWeb) {
      try {
        await _channel.invokeMethod('forceLandscape');
      } catch (_) {}
    }
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
  }

  /// 🔓 Restore normal screen orientation upon leaving exam hall
  static Future<void> unlockOrientation() async {
    if (!kIsWeb) {
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

  /// 📱 Force hardware screen rotation into Portrait
  static Future<void> forcePortrait() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}
  }

  /// 🔄 Toggle between Portrait and Landscape
  static Future<void> toggleOrientation(Orientation currentOrientation) async {
    if (currentOrientation == Orientation.landscape) {
      await forcePortrait();
    } else {
      await forceLandscape();
    }
  }
}
