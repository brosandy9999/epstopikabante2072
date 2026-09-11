import 'dart:html' as html;
import 'package:flutter/material.dart';

/// High speed CDN Download URLs
const String kGithubApkTabA32BitUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_armv7.apk';
const String kGithubApkPhone64BitUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_latest.apk';
const String kGithubApkUniversalUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_latest.apk';
const String kGithubWebUrl =
    'https://brosandy9999.github.io/epstopikabante2072/';

enum DevicePlatformType {
  androidPhone64Bit,
  samsungTab32Bit,
  androidUniversal,
  windowsDesktop,
  appleIos,
  otherDesktop,
}

class AppDownloadOption {
  final DevicePlatformType type;
  final String titleNe;
  final String titleEn;
  final String titleKo;
  final String subtitleNe;
  final String subtitleEn;
  final String subtitleKo;
  final String downloadUrl;
  final String sizeText;
  final String deviceLabel;
  final IconData icon;
  final bool isApk;
  final bool isPwa;
  final bool isWeb;

  const AppDownloadOption({
    required this.type,
    required this.titleNe,
    required this.titleEn,
    required this.titleKo,
    required this.subtitleNe,
    required this.subtitleEn,
    required this.subtitleKo,
    required this.downloadUrl,
    required this.sizeText,
    required this.deviceLabel,
    required this.icon,
    this.isApk = true,
    this.isPwa = false,
    this.isWeb = false,
  });
}

const AppDownloadOption kAndroidPhone64Option = AppDownloadOption(
  type: DevicePlatformType.androidPhone64Bit,
  titleNe: 'Android Phone (६४-बिट कम्प्रेस्ड APK)',
  titleEn: 'Android Phone (64-bit arm64-v8a)',
  titleKo: '안드로이드 스마트폰 (64비트 최적화)',
  subtitleNe: 'Samsung, Xiaomi, Realme, Poco, Vivo, Oppo आदी आधुनिक फोनका लागि',
  subtitleEn: 'Optimized lightweight build for modern Android smartphones (arm64-v8a)',
  subtitleKo: '최신 안드로이드 스마트폰 전용 초경량 압축 최적화 버전',
  downloadUrl: kGithubApkPhone64BitUrl,
  sizeText: '61.9 MB (Compressed)',
  deviceLabel: 'Android Smartphone (64-bit)',
  icon: Icons.smartphone_rounded,
  isApk: true,
);

const AppDownloadOption kSamsungTab32Option = AppDownloadOption(
  type: DevicePlatformType.samsungTab32Bit,
  titleNe: 'Samsung Galaxy Tab A & ३२-बिट APK',
  titleEn: 'Samsung Galaxy Tab A & 32-bit',
  titleKo: '삼성 갤럭시 탭 A 및 32비트',
  subtitleNe: 'Galaxy Tab A (SM-T290/T295/T510) तथा पुराना ३२-बिट डिभाइसका लागि',
  subtitleEn: 'Specially built for Galaxy Tab A & 32-bit armeabi-v7a tablets',
  subtitleKo: '삼성 갤럭시 탭 A 및 32비트 태블릿 전용 버전',
  downloadUrl: kGithubApkTabA32BitUrl,
  sizeText: '59.7 MB (Compressed)',
  deviceLabel: 'Samsung Galaxy Tab A / 32-bit Tablet',
  icon: Icons.tablet_android_rounded,
  isApk: true,
);

const AppDownloadOption kUniversalAndroidOption = AppDownloadOption(
  type: DevicePlatformType.androidUniversal,
  titleNe: 'Official Android APK (सबै डिभाइस)',
  titleEn: 'Official Android APK (Latest)',
  titleKo: '공식 안드로이드 APK (최신버전)',
  subtitleNe: 'कुनै पनि एन्ड्रोइड स्मार्टफोन वा ट्याब्लेटमा १००% चल्ने आधिकारिक APK',
  subtitleEn: 'Official release APK package for any Android device',
  subtitleKo: '모든 안드로이드 스마트폰 및 태블릿 지원 공식 배포본',
  downloadUrl: kGithubApkUniversalUrl,
  sizeText: '61.9 MB (Latest)',
  deviceLabel: 'Universal Android Device',
  icon: Icons.android_rounded,
  isApk: true,
);

const AppDownloadOption kWindowsDesktopOption = AppDownloadOption(
  type: DevicePlatformType.windowsDesktop,
  titleNe: 'Windows PC / ल्यापटप (Web UBT Hall)',
  titleEn: 'Windows PC / Laptop (Web & PWA)',
  titleKo: '윈도우 PC / 노트북 (웹 UBT 시험장)',
  subtitleNe: 'कम्प्युटरको ठूलो स्क्रिनमा १००% रियल UBT एक्जाम हल सिधै खोल्नुहोस्',
  subtitleEn: 'Run real full-screen EPS-TOPIK UBT exam simulator on PC',
  subtitleKo: 'PC 및 노트북에서 실제 시험장과 동일한 풀스크린 모드 실행',
  downloadUrl: kGithubWebUrl,
  sizeText: 'Instant Web',
  deviceLabel: 'Windows Computer / Laptop',
  icon: Icons.laptop_windows_rounded,
  isApk: false,
  isWeb: true,
  isPwa: true,
);

const AppDownloadOption kAppleIosOption = AppDownloadOption(
  type: DevicePlatformType.appleIos,
  titleNe: 'Apple iPhone / iPad (PWA App)',
  titleEn: 'Apple iPhone / iPad (PWA Web App)',
  titleKo: '애플 아이폰 / 아이패드 (홈 화면 추가)',
  subtitleNe: 'Safari मा खोलेर Share बटन (📤) थिची "Add to Home Screen" गर्नुहोस्',
  subtitleEn: 'Open in Safari and tap Share -> "Add to Home Screen"',
  subtitleKo: '사파리(Safari)에서 공유 버튼(📤) 누른 후 "홈 화면에 추가"',
  downloadUrl: kGithubWebUrl,
  sizeText: 'Instant PWA',
  deviceLabel: 'Apple iPhone / iPad',
  icon: Icons.phone_iphone_rounded,
  isApk: false,
  isPwa: true,
);

List<AppDownloadOption> getAllDownloadOptions() {
  return const [
    kAndroidPhone64Option,
    kSamsungTab32Option,
    kUniversalAndroidOption,
    kWindowsDesktopOption,
    kAppleIosOption,
  ];
}

/// Smartly detect user agent, hardware, and screen size
AppDownloadOption getDetectedApkInfo() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  final platform = (html.window.navigator.platform ?? '').toLowerCase();

  // 1. Check for Apple iOS (iPhone, iPad, iPod)
  final isIos = ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod') ||
      (platform.contains('mac') &&
          html.window.navigator.maxTouchPoints != null &&
          (html.window.navigator.maxTouchPoints ?? 0) > 1);

  if (isIos) {
    return kAppleIosOption;
  }

  // 2. Check for Samsung Tablet / 32-bit indicators
  final isSamsungTab = ua.contains('sm-t') || // SM-T290, SM-T295, SM-T510, etc.
      ua.contains('sm-x') || // Galaxy Tab A9/A8
      ua.contains('gt-p') || // Older Galaxy Tab
      ua.contains('gt-n') || // Galaxy Note Tab
      (ua.contains('samsung') && ua.contains('tab')) ||
      (ua.contains('tablet') && !ua.contains('arm64') && !ua.contains('aarch64')) ||
      ua.contains('armeabi') ||
      ua.contains('armv7');

  if (isSamsungTab) {
    return kSamsungTab32Option;
  }

  // 3. Check for Android 64-bit Phone
  final isAndroidMobile = ua.contains('android') || ua.contains('mobile');
  final is64Bit = ua.contains('arm64') ||
      ua.contains('aarch64') ||
      ua.contains('x86_64') ||
      isAndroidMobile;

  if (isAndroidMobile && is64Bit) {
    return kAndroidPhone64Option;
  }

  // 4. Check for Windows / Desktop PC
  final isWindows = ua.contains('windows') || platform.contains('win');
  final isDesktop = (isWindows ||
          (platform.contains('mac') && !isIos) ||
          (platform.contains('linux') && !ua.contains('android'))) &&
      !ua.contains('mobile');

  if (isWindows || isDesktop) {
    return kWindowsDesktopOption;
  }

  // 5. Fallback Universal Android
  return kUniversalAndroidOption;
}

/// Trigger direct APK binary download according to device or explicit URL
void triggerApkDownload([String? specificUrl]) {
  final targetUrl = specificUrl ?? getDetectedApkInfo().downloadUrl;
  final filename = targetUrl.split('/').last.split('?').first;
  try {
    final anchor = html.AnchorElement(href: targetUrl)
      ..setAttribute('download', filename.isNotEmpty ? filename : 'eps_topik_ubt.apk')
      ..setAttribute('target', '_blank')
      ..setAttribute('rel', 'noopener noreferrer')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    html.window.open(targetUrl, '_blank');
  }
}

void tryLaunchInstalledAndroidApp() {
  try {
    html.window.location.href =
        'intent://open#Intent;scheme=epstopik;package=com.example.eps_topik_app;end';
  } catch (_) {
    triggerApkDownload();
  }
}

void triggerJsonFileDownload(String filename, String content) {
  try {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (_) {}
}
