import 'dart:html' as html;
import 'package:flutter/foundation.dart';

bool get isAndroidWeb {
  if (!kIsWeb) return false;
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final platform = (html.window.navigator.platform ?? '').toLowerCase();
    
    // Explicit Android check in user-agent or platform
    if (ua.contains('android') || platform.contains('android') || platform.contains('linux arm') || platform.contains('linux aarch64')) {
      return true;
    }
    
    // Fallback: Check if mobile device that is not iOS / macOS / Windows
    final isIOS = ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod') || (platform.contains('mac') && (html.window.navigator.maxTouchPoints ?? 0) > 1);
    final isWindows = ua.contains('windows') || platform.contains('win');
    final isMac = ua.contains('macintosh') || platform.contains('mac');
    
    if (isIOS || isWindows || isMac) {
      return false;
    }
    
    // Mobile touch device
    if (ua.contains('mobile') || ua.contains('phone') || (html.window.navigator.maxTouchPoints ?? 0) > 0 && html.window.screen != null && (html.window.screen!.width ?? 1000) < 950) {
      return true;
    }
  } catch (_) {}
  
  return defaultTargetPlatform == TargetPlatform.android;
}

bool get isIOSWeb {
  if (!kIsWeb) return false;
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final platform = (html.window.navigator.platform ?? '').toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod') || (platform.contains('mac') && (html.window.navigator.maxTouchPoints ?? 0) > 1);
  } catch (_) {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}

bool get isMobileWeb => isAndroidWeb || isIOSWeb;
