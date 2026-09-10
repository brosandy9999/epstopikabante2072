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
  return const DeviceApkInfo(
    architecture: DetectedAndroidArchitecture.phone64Bit,
    downloadUrl: kGithubApkPhone64BitUrl,
    titleNe: 'Android Phone (६४-बिट)',
    titleEn: 'Android Phone (64-bit)',
    titleKo: '안드로이드 스마트폰 (64비트)',
    sizeText: '२०.७ MB',
    deviceLabel: 'Android Smartphone',
  );
}

void triggerApkDownload([String? specificUrl]) {
  // Mobile/Desktop native fallback
}

void tryLaunchInstalledAndroidApp() {
  // Mobile/Desktop native fallback
}

void triggerJsonFileDownload(String filename, String content) {
  // Mobile/Desktop native fallback
}
