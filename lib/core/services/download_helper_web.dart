import 'dart:html' as html;

/// High speed CDN Download URLs
const String kGithubApkTabA32BitUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/app-armeabi-v7a-release.apk';
const String kGithubApkPhone64BitUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/app-arm64-v8a-release.apk';
const String kGithubApkUniversalUrl =
    'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_ubt_2026.apk';

enum DetectedAndroidArchitecture {
  samsungTab32Bit,
  phone64Bit,
  universal,
}

class DeviceApkInfo {
  final DetectedAndroidArchitecture architecture;
  final String downloadUrl;
  final String titleNe;
  final String titleEn;
  final String titleKo;
  final String sizeText;
  final String deviceLabel;

  const DeviceApkInfo({
    required this.architecture,
    required this.downloadUrl,
    required this.titleNe,
    required this.titleEn,
    required this.titleKo,
    required this.sizeText,
    required this.deviceLabel,
  });
}

DeviceApkInfo getDetectedApkInfo() {
  final ua = html.window.navigator.userAgent.toLowerCase();

  // Check for Samsung Tablet / 32-bit indicators
  final isSamsungTab = ua.contains('sm-t') || // SM-T290, SM-T295, SM-T510, etc.
      ua.contains('sm-x') || // Galaxy Tab A9/A8
      ua.contains('gt-p') || // Older Galaxy Tab
      ua.contains('gt-n') || // Galaxy Note Tab
      (ua.contains('samsung') && ua.contains('tab')) ||
      (ua.contains('tablet') && !ua.contains('arm64') && !ua.contains('aarch64')) ||
      ua.contains('armeabi') ||
      ua.contains('armv7');

  if (isSamsungTab) {
    return const DeviceApkInfo(
      architecture: DetectedAndroidArchitecture.samsungTab32Bit,
      downloadUrl: kGithubApkTabA32BitUrl,
      titleNe: 'Samsung Galaxy Tab A (३२-बिट)',
      titleEn: 'Samsung Galaxy Tab A (32-bit)',
      titleKo: '삼성 갤럭시 탭 A (32비트)',
      sizeText: '१८.५ MB',
      deviceLabel: 'Samsung Galaxy Tab A / 32-bit Tablet',
    );
  }

  // Check for 64-bit Phone
  final is64BitPhone = ua.contains('arm64') ||
      ua.contains('aarch64') ||
      ua.contains('x86_64') ||
      ua.contains('mobile') ||
      ua.contains('android');

  if (is64BitPhone) {
    return const DeviceApkInfo(
      architecture: DetectedAndroidArchitecture.phone64Bit,
      downloadUrl: kGithubApkPhone64BitUrl,
      titleNe: 'Android Phone (६४-बिट)',
      titleEn: 'Android Phone (64-bit)',
      titleKo: '안드로이드 스마트폰 (64비트)',
      sizeText: '२०.७ MB',
      deviceLabel: 'Android Smartphone (64-bit)',
    );
  }

  return const DeviceApkInfo(
    architecture: DetectedAndroidArchitecture.universal,
    downloadUrl: kGithubApkUniversalUrl,
    titleNe: 'Universal All-in-One (सबै डिभाइस)',
    titleEn: 'Universal All-in-One (All Devices)',
    titleKo: '통합 올인원 APK (모든 기기)',
    sizeText: '५७.५ MB',
    deviceLabel: 'Universal Android Device',
  );
}

/// Trigger direct APK binary download according to device or explicit URL
void triggerApkDownload([String? specificUrl]) {
  final targetUrl = specificUrl ?? getDetectedApkInfo().downloadUrl;
  final filename = targetUrl.split('/').last;
  try {
    final anchor = html.AnchorElement(href: targetUrl)
      ..setAttribute('download', filename)
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
