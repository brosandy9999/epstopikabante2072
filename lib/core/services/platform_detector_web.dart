// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

bool get isAndroidWeb {
  if (!kIsWeb) return false;
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final platform = (html.window.navigator.platform ?? '').toLowerCase();
    final appVersion = (html.window.navigator.appVersion ?? '').toLowerCase();
    final maxTouch = html.window.navigator.maxTouchPoints ?? 0;
    final screenW = html.window.screen?.width ?? 1200;
    final screenH = html.window.screen?.height ?? 800;
    final innerW = html.window.innerWidth ?? 1200;

    // 1. Check iOS first
    final isIOS = ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod') ||
        (platform.contains('mac') && maxTouch > 1);
    if (isIOS) return false;

    // 2. Check Genuine Desktop OS with 0 touch points
    final isWindowsDesktop = (ua.contains('windows') || platform.contains('win')) && maxTouch == 0;
    final isMacDesktop = (ua.contains('macintosh') || platform.contains('mac')) && maxTouch == 0;
    final isLinuxDesktop = (platform.contains('linux') || ua.contains('linux')) &&
        !ua.contains('android') &&
        !platform.contains('android') &&
        maxTouch == 0;

    if (isWindowsDesktop || isMacDesktop || isLinuxDesktop) {
      return false;
    }

    // 3. Android and all mobile touch indicators
    if (ua.contains('android') ||
        platform.contains('android') ||
        appVersion.contains('android') ||
        platform.contains('linux arm') ||
        platform.contains('linux aarch64') ||
        ua.contains('samsung') ||
        ua.contains('redmi') ||
        ua.contains('xiaomi') ||
        ua.contains('oppo') ||
        ua.contains('vivo') ||
        ua.contains('realme') ||
        ua.contains('oneplus') ||
        ua.contains('huawei') ||
        ua.contains('pixel') ||
        ua.contains('mobile') ||
        ua.contains('phone') ||
        (maxTouch > 0 && (screenW < 1000 || innerW < 1000 || screenH < 1000))) {
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
    final maxTouch = html.window.navigator.maxTouchPoints ?? 0;
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod') || (platform.contains('mac') && maxTouch > 1);
  } catch (_) {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}

bool get isMobileWeb {
  if (!kIsWeb) return false;
  try {
    final ua = html.window.navigator.userAgent.toLowerCase();
    final maxTouch = html.window.navigator.maxTouchPoints ?? 0;
    final screenW = html.window.screen?.width ?? 1200;
    final innerW = html.window.innerWidth ?? 1200;

    if (isAndroidWeb || isIOSWeb || ua.contains('mobile') || (maxTouch > 0 && (screenW < 980 || innerW < 980))) {
      return true;
    }
  } catch (_) {}
  return isAndroidWeb || isIOSWeb;
}
