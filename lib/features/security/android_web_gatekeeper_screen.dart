import '../../core/services/platform_detector.dart';
import '../../core/widgets/device_download_modal.dart';
import '../authentication/login_screen.dart';
import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/download_helper.dart';

/// EPS-TOPIK Official Coursebook (한국어 표준교재 2026) Themed Gatekeeper Screen
class AndroidWebGatekeeperScreen extends StatelessWidget {
  final bool showBackButton;
  const AndroidWebGatekeeperScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isAndroidWeb && showBackButton,
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.06),
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE11D48), Color(0xFF0D9488)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'EPS-TOPIK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '한국어 표준교재 2026',
                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LanguageService.instance.buildLanguageSwitcherWidget(),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF0FDF4),
                  Color(0xFFFFF1F2),
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '고용노동부',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HRD Korea 한국산업인력공단',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCoursebookCoverBadge(
                              bookNum: '1',
                              labelKo: '일상생활 한국어',
                              labelNe: 'दैनिक जीवन कोरियन (पाठ १~३०)',
                              labelEn: 'Daily Life Korean (Ch 1~30)',
                              primaryColor: const Color(0xFFE11D48),
                              accentColor: const Color(0xFFFDA4AF),
                              bgGradient: const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                            ),
                            const SizedBox(width: 12),
                            _buildCoursebookCoverBadge(
                              bookNum: '2',
                              labelKo: '직장생활 한국어',
                              labelNe: 'कार्यक्षेत्र कोरियन (पाठ ३१~६०)',
                              labelEn: 'Workplace Korean (Ch 31~60)',
                              primaryColor: const Color(0xFF0D9488),
                              accentColor: const Color(0xFF6EE7B7),
                              bgGradient: const [Color(0xFFF0FDF4), Color(0xFFCCFBF1)],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            LanguageService.instance.trText(
                              ne: '고용허가제 한국어능력시험 대비 • आधिकारिक मानक पाठ्यपुस्तक',
                              en: 'EPS-TOPIK Preparation • Official Standard Textbook',
                              ko: '고용허가제 한국어능력시험 대비 • 한국어 표준교재',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          LanguageService.instance.trText(
                            ne: '한국어 표준교재\nEPS-TOPIK UBT आधिकारिक एप',
                            en: '한국어 표준교재\nOfficial EPS-TOPIK UBT Mobile App',
                            ko: '한국어 표준교재 2026\n공식 EPS-TOPIK UBT 모바일 앱',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          LanguageService.instance.trText(
                            ne: 'कोरियाली भाषा मानक पाठ्यपुस्तकका सम्पूर्ण ६० पाठ, पुस्तकभित्रै बज्ने ओरिजिनल अडियो, र १००% वास्तविक UBT एक्जाम हल अब तपाईंको मोबाइलमा!',
                            en: 'All 60 standard textbook chapters with in-print audio player and real 100% offline UBT exam hall on your phone!',
                            ko: '한국어 표준교재 전 60과 수록, 교재 내 오디오 즉시 재생, 100% 실전 UBT 시험장 환경 지원!',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildPillBadge(Icons.menu_book_rounded, LanguageService.instance.trText(ne: '६० पाठको पूर्ण किताब', en: 'Full 60 Chapters', ko: '60과 표준교재'), const Color(0xFFE11D48)),
                            _buildPillBadge(Icons.headphones_rounded, LanguageService.instance.trText(ne: 'ओरिजिनल अडियो ट्र्याक', en: 'In-Print Audio Player', ko: '교재 내장 오디오'), const Color(0xFF0D9488)),
                            _buildPillBadge(Icons.wifi_off_rounded, LanguageService.instance.trText(ne: '१००% अफलाइन मोड', en: '100% Offline Hall', ko: '100% 오프라인'), const Color(0xFF2563EB)),
                            _buildPillBadge(Icons.quiz_rounded, LanguageService.instance.trText(ne: '४०+ UBT सेटहरू', en: '40+ Real UBT Sets', ko: '40+ 실전 UBT'), const Color(0xFF7C3AED)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 1. Detected Device Card
                        Builder(
                          builder: (context) {
                            final detected = getDetectedApkInfo();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withOpacity(0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(detected.icon, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCCFBF1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                LanguageService.instance.trText(
                                                  ne: '🎯 पहिचान भएको डिभाइस: ${detected.deviceLabel}',
                                                  en: '🎯 Detected: ${detected.deviceLabel}',
                                                  ko: '🎯 감지된 기기: ${detected.deviceLabel}',
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF0F766E),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.folder_zip_rounded, color: Color(0xFF34D399), size: 12),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    detected.sizeText,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          LanguageService.instance.trText(
                                            ne: detected.subtitleNe,
                                            en: detected.subtitleEn,
                                            ko: detected.subtitleKo,
                                          ),
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // 2. Primary Recommended Action Button
                        Builder(
                          builder: (context) {
                            final detected = getDetectedApkInfo();
                            final isKorean = LanguageService.instance.isKorean;
                            final isEnglish = LanguageService.instance.isEnglish;
                            final label = detected.isApk
                                ? (isKorean
                                    ? '${detected.titleKo} 다운로드 (${detected.sizeText})'
                                    : (isEnglish
                                        ? 'Download ${detected.titleEn} (${detected.sizeText})'
                                        : '${detected.titleNe} डाउनलोड (${detected.sizeText})'))
                                : (detected.type == DevicePlatformType.appleIos
                                    ? (isKorean ? '🍎 아이폰/아이패드 (홈 화면 추가)' : (isEnglish ? '🍎 iPhone / iPad (Add to Home Screen)' : '🍎 iPhone/iPad मा सिधै चलाउनुहोस् (PWA)'))
                                    : (isKorean ? '💻 풀스크린 웹 시험장 실행' : (isEnglish ? '💻 Launch Fullscreen PC Hall' : '💻 PC Fullscreen UBT हल सुरु गर्नुहोस्')));

                            return Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D9488), Color(0xFF059669)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  if (detected.isApk) {
                                    triggerApkDownload(detected.downloadUrl);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          LanguageService.instance.trText(
                                            ne: '📥 ${detected.titleNe} (${detected.sizeText}) डाउनलोड सुरु भयो!',
                                            en: '📥 ${detected.titleEn} (${detected.sizeText}) download started!',
                                            ko: '📥 ${detected.titleKo} (${detected.sizeText}) 다운로드가 시작되었습니다!',
                                          ),
                                        ),
                                        backgroundColor: const Color(0xFF0D9488),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  } else {
                                    showDeviceDownloadModal(context);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(detected.isApk ? Icons.download_for_offline_rounded : detected.icon, size: 28),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            label,
                                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            LanguageService.instance.trText(
                                              ne: 'तपाईंको डिभाइसको लागि १००% उपयुक्त • सेफ र अफलाइन रेडी',
                                              en: 'Auto-selected for your device • 100% Safe & Offline Ready',
                                              ko: '기기 맞춤 최적화 • 100% 안전 및 오프라인 지원',
                                            ),
                                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 3. Direct APK Packages & Sizes Breakdown Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF0284C7), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    LanguageService.instance.trText(
                                      ne: '📦 आधिकारिक APK डाउनलोड र साइजहरू:',
                                      en: '📦 Official APK Downloads & Sizes:',
                                      ko: '📦 공식 APK 다운로드 및 파일 용량:',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildApkDownloadRow(
                                context: context,
                                icon: Icons.smartphone_rounded,
                                iconColor: const Color(0xFF0D9488),
                                titleNe: 'Android Smartphones (६४-बिट)',
                                titleEn: 'Android Smartphones (64-bit arm64)',
                                titleKo: '안드로이드 스마트폰 (64비트 최적화)',
                                sizeBadge: '61.9 MB (Compressed)',
                                descNe: 'Samsung, Redmi, Realme, Oppo, Vivo, OnePlus आदी',
                                url: kGithubApkPhone64BitUrl,
                              ),
                              const Divider(height: 16, color: Color(0xFFF1F5F9)),
                              _buildApkDownloadRow(
                                context: context,
                                icon: Icons.tablet_android_rounded,
                                iconColor: const Color(0xFF2563EB),
                                titleNe: 'Samsung Galaxy Tab A (३२-बिट)',
                                titleEn: 'Samsung Galaxy Tab A (32-bit armv7)',
                                titleKo: '삼성 갤럭시 탭 A (32비트 태블릿)',
                                sizeBadge: '59.7 MB (Compressed)',
                                descNe: 'Galaxy Tab A (SM-T290/T295/T510) र पुराना डिभाइस',
                                url: kGithubApkTabA32BitUrl,
                              ),
                              const Divider(height: 16, color: Color(0xFFF1F5F9)),
                              _buildApkDownloadRow(
                                context: context,
                                icon: Icons.android_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                titleNe: 'Official Universal APK (सबै डिभाइस)',
                                titleEn: 'Universal Release APK (All Devices)',
                                titleKo: '공식 범용 안드로이드 APK (통합버전)',
                                sizeBadge: '61.9 MB (Latest)',
                                descNe: 'कुनै पनि एन्ड्रोइड डिभाइसमा सिधै चल्ने आधिकारिक भर्सन',
                                url: kGithubApkUniversalUrl,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.offline_pin_rounded, color: Color(0xFF16A34A), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        LanguageService.instance.trText(
                                          ne: '💡 सबै APK उच्च कम्प्रेस (Compressed) गरिएका छन्। थोरै मोबाइल डेटामा चाँडै डाउनलोड हुन्छन् र इन्टरनेट बिना १००% अफलाइन चल्छन्।',
                                          en: '💡 All APKs are high-efficiency compressed for ultra-fast downloads with full offline support.',
                                          ko: '💡 전 버전 초경량 압축 적용: 데이터 절약 및 100% 완전 오프라인 지원.',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFF15803D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Other Devices Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 1,
                              shadowColor: Colors.black.withOpacity(0.04),
                            ),
                            icon: const Icon(Icons.devices_rounded, size: 20, color: Color(0xFF0D9488)),
                            label: Text(
                              LanguageService.instance.trText(
                                ne: '📲 अन्य डिभाइसहरू (PC UBT Hall, iPhone iOS PWA, QR Code)',
                                en: '📲 Other Devices (PC Hall, iPhone iOS PWA, QR Code)',
                                ko: '📲 기타 기기 (PC 시험장, 아이폰 PWA, QR 코드)',
                              ),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              showDeviceDownloadModal(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.language_rounded, size: 18, color: Color(0xFFE11D48)),
                            label: Text(
                              LanguageService.instance.trText(
                                ne: '🌐 वेब पोर्टलबाट सिधै लगइन गर्नुहोस् (Web Portal)',
                                en: '🌐 Continue on Web Portal / Direct Login',
                                ko: '🌐 웹 포털에서 계속하기 / 바로 로그인',
                              ),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              if (showBackButton) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildFeatureCard(
                          icon: Icons.auto_stories_rounded,
                          accentColor: const Color(0xFFE11D48),
                          bgGradient: const [Color(0xFFFFF1F2), Color(0xFFFFFFFF)],
                          title: LanguageService.instance.trText(
                            ne: '표준교재 ६० पाठको पूर्ण अध्ययन र अडियो',
                            en: '60 Standard Textbook Chapters & In-Print Audios',
                            ko: '한국어 표준교재 전 60과 수록 및 교재 내 오디오',
                          ),
                          desc: LanguageService.instance.trText(
                            ne: 'पाठ १ देखि ६० सम्मका प्रत्येक वार्तालाप (대화), शब्दावली (어휘), र लिसनिङ अडियोहरू पुस्तकभित्रै १-ट्यापमा सुन्न सकिने।',
                            en: 'Chapters 1 to 60 with built-in in-print audio player for dialogues, vocabulary, and listening tracks.',
                            ko: '1과부터 60과까지 대화, 어휘, 듣기 지문이 교재 페이지 내에서 바로 재생됩니다.',
                          ),
                        ),
                        _buildFeatureCard(
                          icon: Icons.timer_outlined,
                          accentColor: const Color(0xFF0D9488),
                          bgGradient: const [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
                          title: LanguageService.instance.trText(
                            ne: '१००% वास्तविक EPS UBT एक्जाम हल',
                            en: '100% Authentic EPS UBT Exam Hall',
                            ko: '100% 실전 EPS UBT 시험장 환경',
                          ),
                          desc: LanguageService.instance.trText(
                            ne: 'HRD Korea को परीक्षा जस्तै Reading र Listening प्रश्नहरू, स्वचालित टाइमर, र तुरून्तै नतिजा विश्लेषण।',
                            en: 'Exact layout with real timers, Reading/Listening split, and instant score analysis.',
                            ko: '실제 시험과 동일한 타이머, 읽기/듣기 화면 분할, 즉각적인 성적 분석.',
                          ),
                        ),
                        _buildFeatureCard(
                          icon: Icons.wifi_off_rounded,
                          accentColor: const Color(0xFF2563EB),
                          bgGradient: const [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                          title: LanguageService.instance.trText(
                            ne: '१००% अफलाइन मोड (Zero Data Offline)',
                            en: '100% Offline Mode (Zero Data)',
                            ko: '완전한 오프라인 모드 지원',
                          ),
                          desc: LanguageService.instance.trText(
                            ne: 'इन्टरनेट नभए पनि सबै ६० पाठका अडियोहरू र परीक्षा सेटहरू जुनसुकै बेला निर्बाध अभ्यास गर्नुहोस्।',
                            en: 'Practice exams and listen to audios anytime, anywhere without internet.',
                            ko: '인터넷 연결 없이도 모든 시험 및 오디오 학습 무제한 이용.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 14,
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
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.install_mobile_rounded, color: Color(0xFF0D9488), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    LanguageService.instance.trText(
                                      ne: 'एप इन्स्टल गर्ने ३ सरल तरिका:',
                                      en: 'Easy 3-Step Installation Guide:',
                                      ko: '간편 3단계 설치 가이드:',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStepRow(
                                '1',
                                const Color(0xFFE11D48),
                                LanguageService.instance.trText(
                                  ne: 'माथिको हरियो बटन थिचेर आफ्नो डिभाइसको APK फाइल डाउनलोड गर्नुहोस्।',
                                  en: 'Tap the download button above to get the APK file for your device.',
                                  ko: '상단의 버튼을 눌러 기기 맞춤 APK를 다운로드합니다.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                '2',
                                const Color(0xFF0D9488),
                                LanguageService.instance.trText(
                                  ne: 'डाउनलोड सकिएपछि फाइल खोली Install थिच्नुहोस्। (Unknown Sources अनुमति दिनुहोस्)',
                                  en: 'When download completes, open the file and tap Install. (Allow Unknown Sources if prompted)',
                                  ko: '다운로드가 완료되면 파일을 열고 설치를 진행합니다. (출처를 알 수 없는 앱 허용)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                '3',
                                const Color(0xFF2563EB),
                                LanguageService.instance.trText(
                                  ne: 'एप खोली १००% अफलाइन UBT हल र ६० पाठका अडियोहरू निर्बाध अभ्यास गर्नुहोस्!',
                                  en: 'Launch the app and enjoy full offline exams, 60 textbook audios, and all features!',
                                  ko: '앱을 실행하여 오프라인 시험과 교재 오디오를 편리하게 학습하세요!',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0D9488)),
                                  const SizedBox(width: 6),
                                  Text(
                                    LanguageService.instance.trText(
                                      ne: '대한민국 고용노동부 • HRD Korea 한국산업인력공단 표준교재 연계',
                                      en: 'Ministry of Employment and Labor • HRD Korea Standard Curriculum',
                                      ko: '고용노동부 • 한국산업인력공단 한국어 표준교재 연계',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '© 2026 EPS-TOPIK 한국어 표준교재 Online UBT System. All rights reserved.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursebookCoverBadge({
    required String bookNum,
    required String labelKo,
    required String labelNe,
    required String labelEn,
    required Color primaryColor,
    required Color accentColor,
    required List<Color> bgGradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '제$bookNum권',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  bookNum,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              labelKo,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              LanguageService.instance.trText(ne: labelNe, en: labelEn, ko: labelKo),
              style: TextStyle(
                color: primaryColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: color.withOpacity(0.95), fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color accentColor,
    required List<Color> bgGradient,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApkDownloadRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String titleNe,
    required String titleEn,
    required String titleKo,
    required String sizeBadge,
    required String descNe,
    required String url,
  }) {
    final lang = LanguageService.instance;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      lang.trText(ne: titleNe, en: titleEn, ko: titleKo),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      sizeBadge,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                descNe,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            triggerApkDownload(url);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang.trText(
                    ne: '📥 $titleNe ($sizeBadge) डाउनलोड सुरु भयो!',
                    en: '📥 $titleEn ($sizeBadge) download started!',
                    ko: '📥 $titleKo ($sizeBadge) 다운로드가 시작되었습니다!',
                  ),
                ),
                backgroundColor: const Color(0xFF0D9488),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, size: 14),
              const SizedBox(width: 4),
              Text(
                lang.trText(ne: 'डाउनलोड', en: 'Download', ko: '다운로드'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(String number, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: color,
          child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5, height: 1.35)),
        ),
      ],
    );
  }
}
