import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'language_service.dart';
import 'storage_service.dart';
import 'web_reload_helper.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseDate;
  final String releaseNotesNe;
  final String releaseNotesEn;
  final String releaseNotesKo;
  final String apkUrl;
  final String webUrl;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseDate,
    required this.releaseNotesNe,
    required this.releaseNotesEn,
    required this.releaseNotesKo,
    required this.apkUrl,
    required this.webUrl,
    this.isMandatory = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latestVersion']?.toString() ?? '2.4.0',
      latestBuildNumber: (json['latestBuildNumber'] as num?)?.toInt() ?? 24,
      releaseDate: json['releaseDate']?.toString() ?? '',
      releaseNotesNe: json['releaseNotes']?.toString() ?? 'नयाँ फिचर तथा कार्यसम्पादन सुधार।',
      releaseNotesEn: json['releaseNotesEn']?.toString() ?? 'New features and bug fixes.',
      releaseNotesKo: json['releaseNotesKo']?.toString() ?? '새로운 기능 및 버그 수정.',
      apkUrl: json['apkUrl']?.toString() ?? 'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_ubt_2026.apk',
      webUrl: json['webUrl']?.toString() ?? 'https://brosandy9999.github.io/epstopikabante2072/',
      isMandatory: json['isMandatory'] as bool? ?? false,
    );
  }

  String getLocalizedNotes() {
    if (LanguageService.instance.isKorean) return releaseNotesKo;
    if (LanguageService.instance.isEnglish) return releaseNotesEn;
    return releaseNotesNe;
  }
}

class UpdateService extends ChangeNotifier {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  static const String currentVersion = '2.4.0';
  static const int currentBuildNumber = 24;

  static const String primaryManifestUrl =
      'https://topik-abante.web.app/data/version_manifest.json';
  static const String fallbackManifestUrl =
      'https://raw.githubusercontent.com/brosandy9999/epstopikabante2072/main/data/version_manifest.json';

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  AppUpdateInfo? _updateInfo;
  AppUpdateInfo? get updateInfo => _updateInfo;

  DateTime? _lastChecked;
  DateTime? get lastChecked => _lastChecked;

  bool get hasUpdateAvailable {
    if (_updateInfo == null) return false;
    return _updateInfo!.latestBuildNumber > currentBuildNumber;
  }

  void init() {
    final lastCheckedStr = StorageService.instance.getString('eps_last_update_check');
    if (lastCheckedStr != null && lastCheckedStr.isNotEmpty) {
      _lastChecked = DateTime.tryParse(lastCheckedStr);
    }
    // Perform background check on startup
    checkForUpdates(silent: true);
  }

  Future<AppUpdateInfo?> checkForUpdates({bool silent = false, BuildContext? context}) async {
    _isChecking = true;
    notifyListeners();

    AppUpdateInfo? info;

    try {
      final uri = Uri.parse('$primaryManifestUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          info = AppUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {
      // Try fallback URL
      try {
        final fallbackUri = Uri.parse('$fallbackManifestUrl?t=${DateTime.now().millisecondsSinceEpoch}');
        final response = await http.get(fallbackUri).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            info = AppUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
          }
        }
      } catch (_) {}
    }

    _isChecking = false;
    _lastChecked = DateTime.now();
    StorageService.instance.setString('eps_last_update_check', _lastChecked!.toIso8601String());

    if (info != null) {
      _updateInfo = info;
    }
    notifyListeners();

    if (context != null && context.mounted) {
      if (hasUpdateAvailable) {
        showUpdateDialog(context, updateInfo: _updateInfo);
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: '✅ तपाईंको एप नवीनतम संस्करण (v$currentVersion) मा छ!',
                      en: '✅ Your app is up to date (v$currentVersion)!',
                      ko: '✅ 앱이 최신 버전(v$currentVersion)입니다!',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return info;
  }

  void performUpdate() {
    if (kIsWeb) {
      reloadBrowserPage();
    } else {
      final url = _updateInfo?.apkUrl ??
          'https://brosandy9999.github.io/epstopikabante2072/apk/eps_topik_ubt_2026.apk';
      openBrowserUrl(url);
    }
  }

  void showUpdateDialog(BuildContext context, {AppUpdateInfo? updateInfo}) {
    final info = updateInfo ?? _updateInfo;
    if (info == null) return;

    showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.instance.trText(
                        ne: '🚀 नयाँ अपडेट उपलब्ध छ!',
                        en: '🚀 New Update Available!',
                        ko: '🚀 새로운 업데이트 가능!',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v$currentVersion ➔ v${info.latestVersion}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LanguageService.instance.trText(
                        ne: 'नवीनतम सुधार र नयाँ प्रश्नहरूका लागि अपडेट गर्नुहोस्।',
                        en: 'Update now for the latest features and fixes.',
                        ko: '최신 기능과 문항 개선을 위해 업데이트하세요.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              LanguageService.instance.trText(
                ne: '📌 यस अपडेटमा गरिएका सुधारहरू (Release Notes):',
                en: '📌 What\'s New in this Release:',
                ko: '📌 업데이트 주요 내용:',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.getLocalizedNotes(),
                  style: const TextStyle(fontSize: 12, height: 1.45, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          if (!info.isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                LanguageService.instance.trText(
                  ne: 'पछि गर्ने (Later)',
                  en: 'Later',
                  ko: '나중에',
                ),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              performUpdate();
            },
            icon: Icon(kIsWeb ? Icons.refresh_rounded : Icons.download_rounded, size: 18),
            label: Text(
              kIsWeb
                  ? LanguageService.instance.trText(
                      ne: 'अहिले रिफ्रेस गर्नुहोस् (Refresh App)',
                      en: 'Refresh App Now',
                      ko: '지금 새로고침',
                    )
                  : LanguageService.instance.trText(
                      ne: 'अहिले अपडेट गर्नुहोस् (Update Now)',
                      en: 'Update Now (1-Click)',
                      ko: '지금 업데이트',
                    ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
