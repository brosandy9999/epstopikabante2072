import '../../core/services/platform_detector.dart';
import '../../core/widgets/device_download_modal.dart';
import '../authentication/login_screen.dart';
import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/download_helper.dart';

/// EPS-TOPIK Official Coursebook (한국어 표준교재 2026) Themed Gatekeeper Screen
/// Designed with the official HRD Korea Standard Textbook Cover Color Combination:
/// - Crisp clean porcelain white background with soft pastel pink & emerald teal wave gradients
/// - Book 1 (일상생활 한국어 1권 - Rose/Magenta) & Book 2 (직장생활 한국어 2권 - Emerald/Teal) motifs
/// - Official HRD Korea & Ministry of Employment and Labor (고용노동부) typography & emblems
/// - 1-Click Device-Smart APK Download & Full Offline Coursebook + UBT Hall access
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
                // HRD Book Style Emblem
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
                        // Official HRD Korea Coursebook Header Badges
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

                        // Dual Book Cover Visual Cards (Book 1 Rose Pink & Book 2 Emerald Green)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Book 1 Badge Card
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
                            // Book 2 Badge Card
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

                        // Coursebook Title Header
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

                        // Big Title in Bold Coursebook Typography
                        Text(
                          LanguageService.instance.trText(
                            ne: '한국어 표준교재
EPS-TOPIK UBT आधिकारिक एप',
                            en: '한국어 표준교재
Official EPS-TOPIK UBT Mobile App',
                            ko: '한국어 표준교재 2026
공식 EPS-TOPIK UBT 모바일 앱',
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

                        // Subtitle
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

                        // Pill Badges with Pastel Textbook Tones
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

                        // Smart Device Auto-Detection Card (Textbook Styled)
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
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                detected.sizeText,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
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

                        // Primary Action 1: Official HRD Gradient Smart Download Button
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
                              height: 56,
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
                                    Icon(detected.isApk ? Icons.download_for_offline_rounded : detected.icon, size: 26),
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

                        const SizedBox(height: 12),

                        // Action 2: Choose another device APK / All Platform Modal
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
                                ne: '📲 अन्य डिभाइसहरूको लिंक छान्नुहोस् (Samsung Tab, 64-bit, PC, iOS)',
                                en: '📲 Select Another Device (Samsung Tab, 64-bit, PC, iOS)',
                                ko: '📲 다른 기기용 다운로드 (삼성 탭, 64비트, PC, iOS)',
                              ),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              showDeviceDownloadModal(context);
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Action 3: Web Portal / Direct Login
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

                        // Textbook Feature Highlights (White cards with colored book ribbon accents)
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

                        // 3-Step Installation Guide (Clean Textbook Card)
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

                        // Official Agency Endorsement & Copyright Footer
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
