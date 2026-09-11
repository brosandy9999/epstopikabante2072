import 'package:flutter/material.dart';
import '../services/download_helper.dart';
import '../services/language_service.dart';

/// Shows an intelligent, interactive device-specific download dialog / modal
void showDeviceDownloadModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) => const _DeviceDownloadSheet(),
  );
}

class _DeviceDownloadSheet extends StatelessWidget {
  const _DeviceDownloadSheet();

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final detected = getDetectedApkInfo();
    final allOptions = getAllDownloadOptions();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 580,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600
            ? (MediaQuery.of(context).size.width - 560) / 2
            : 0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.install_mobile_rounded, color: Color(0xFF4ADE80), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.trText(
                          ne: '📲 डिभाइस अनुसार एप डाउनलोड',
                          en: '📲 Download App by Device',
                          ko: '📲 기기별 맞춤 앱 다운로드',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        lang.trText(
                          ne: 'तपाईंको डिभाइसको लागि १००% उपयुक्त भर्सन छान्नुहोस्',
                          en: 'Choose the version optimized for your specific device',
                          ko: '사용 중인 기기에 가장 최적화된 버전을 선택하세요',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Detected Device Highlight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF064E3B).withOpacity(0.85),
                          const Color(0xFF065F46).withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Text(
                                    lang.trText(
                                      ne: 'तपाईंको डिभाइस (सिफारिस गरिएको)',
                                      en: 'Your Device (Recommended)',
                                      ko: '현재 기기 (추천 버전)',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                detected.sizeText,
                                style: const TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(detected.icon, color: const Color(0xFF34D399), size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.trText(
                                      ne: detected.titleNe,
                                      en: detected.titleEn,
                                      ko: detected.titleKo,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    lang.trText(
                                      ne: detected.subtitleNe,
                                      en: detected.subtitleEn,
                                      ko: detected.subtitleKo,
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFA7F3D0),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: Icon(
                              detected.isApk ? Icons.download_rounded : Icons.open_in_new_rounded,
                              size: 20,
                            ),
                            label: Text(
                              detected.isApk
                                  ? lang.trText(
                                      ne: '📥 अहिले डाउनलोड गर्नुहोस् (${detected.sizeText})',
                                      en: '📥 Download Now (${detected.sizeText})',
                                      ko: '📥 지금 다운로드 (${detected.sizeText})',
                                    )
                                  : (detected.type == DevicePlatformType.appleIos
                                      ? lang.trText(
                                          ne: '🍎 iPhone/iPad PWA गाइड हेर्नुहोस्',
                                          en: '🍎 View iPhone/iPad PWA Steps',
                                          ko: '🍎 아이폰/아이패드 설치 가이드',
                                        )
                                      : lang.trText(
                                          ne: '💻 Fullscreen Web UBT सुरु गर्नुहोस्',
                                          en: '💻 Launch Fullscreen Web Hall',
                                          ko: '💻 풀스크린 웹 시험장 실행',
                                        )),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _handleOptionAction(context, detected);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 2. All Available Platform Downloads Section
                  Text(
                    lang.trText(
                      ne: '📦 सबै डिभाइसहरूको विकल्प (All Platform Downloads)',
                      en: '📦 All Platform Downloads',
                      ko: '📦 모든 기기별 다운로드 옵션',
                    ),
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List of options
                  ...allOptions.map((opt) {
                    final isCurrentDetected = opt.type == detected.type;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isCurrentDetected
                            ? const Color(0xFF1E293B).withOpacity(0.9)
                            : const Color(0xFF1E293B).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentDetected ? const Color(0xFF10B981) : const Color(0xFF334155),
                          width: isCurrentDetected ? 1.2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrentDetected
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(opt.icon, color: isCurrentDetected ? const Color(0xFF34D399) : Colors.white70, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang.trText(
                                  ne: opt.titleNe,
                                  en: opt.titleEn,
                                  ko: opt.titleKo,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrentDetected ? const Color(0xFF065F46) : Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                opt.sizeText,
                                style: TextStyle(
                                  color: isCurrentDetected ? const Color(0xFF6EE7B7) : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            lang.trText(
                              ne: opt.subtitleNe,
                              en: opt.subtitleEn,
                              ko: opt.subtitleKo,
                            ),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentDetected ? const Color(0xFF16A34A) : const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _handleOptionAction(context, opt);
                          },
                          child: Text(
                            opt.isApk
                                ? lang.trText(ne: 'डाउनलोड', en: 'Get APK', ko: '다운로드')
                                : lang.trText(ne: 'खोल्नुहोस्', en: 'Open', ko: '열기'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOptionAction(BuildContext context, AppDownloadOption opt) {
    final lang = LanguageService.instance;

    if (opt.isApk) {
      triggerApkDownload(opt.downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.trText(
                    ne: '📥 ${opt.titleNe} (${opt.sizeText}) डाउनलोड सुरु भयो! Downloads फोल्डर हेर्नुहोस्।',
                    en: '📥 ${opt.titleEn} (${opt.sizeText}) download started! Check downloads.',
                    ko: '📥 ${opt.titleKo} (${opt.sizeText}) 다운로드가 시작되었습니다!',
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (opt.type == DevicePlatformType.appleIos) {
      _showIosGuideDialog(context);
    } else {
      // Web / Windows
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.trText(
              ne: '💻 कम्प्युटरमा Fullscreen UBT हल सुरु भएको छ। F11 थिचेर फुलस्क्रिन गर्नुहोस्।',
              en: '💻 Launching PC Fullscreen Hall. Press F11 for full immersion.',
              ko: '💻 PC 풀스크린 시험장이 준비되었습니다. F11 키로 전체화면 전환이 가능합니다.',
            ),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );
    }
  }

  void _showIosGuideDialog(BuildContext context) {
    final lang = LanguageService.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.apple_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lang.trText(
                  ne: 'iPhone / iPad मा चलाउने तरिका',
                  en: 'How to install on iPhone / iPad',
                  ko: '아이폰 / 아이패드 설치 가이드',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.trText(
                ne: 'Apple iOS मा APK इन्स्टल हुँदैन। Safari ब्राउजरबाट सिधै इन्स्टल गर्नुहोस्:',
                en: 'Apple iOS does not use APK files. Install directly via Safari PWA:',
                ko: '애플 iOS는 APK를 지원하지 않으므로 사파리(Safari)에서 홈 화면에 추가하세요:',
              ),
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            _buildIosStep('1', lang.trText(ne: 'Safari ब्राउजरमा यो लिङ्क खोल्नुहोस्।', en: 'Open this link in Safari browser.', ko: '사파리(Safari) 브라우저에서 사이트에 접속합니다.')),
            _buildIosStep('2', lang.trText(ne: 'तलको Share बटन (📤) थिच्नुहोस्।', en: 'Tap the Share icon (📤) at the bottom.', ko: '하단의 공유 아이콘(📤)을 누릅니다.')),
            _buildIosStep('3', lang.trText(ne: '"Add to Home Screen" (होम स्क्रिनमा थप्नुहोस्) रोज्नुहोस्।', en: 'Select "Add to Home Screen".', ko: '"홈 화면에 추가"를 선택합니다.')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang.trText(ne: 'बुझें (Done)', en: 'Got it', ko: '확인'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF38BDF8),
            child: Text(number, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
