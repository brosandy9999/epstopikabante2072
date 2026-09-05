import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/download_helper.dart';
import '../authentication/login_screen.dart';

/// Android Web Gatekeeper Screen
/// Blocks Android mobile browsers from directly running the exam to enforce FLAG_SECURE anti-screenshot protection.
/// Directs users to download or launch the official Android Native App (APK).
class AndroidWebGatekeeperScreen extends StatelessWidget {
  const AndroidWebGatekeeperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF042F2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Bar: Language Switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          LanguageService.instance.buildLanguageSwitcherWidget(),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Shield & Security Header
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 56,
                          color: Color(0xFF38BDF8),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Official Organization Title
                      Text(
                        'HRD Korea • EPS-TOPIK UBT Online',
                        style: TextStyle(
                          color: Colors.cyan.shade200,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Main Title
                      Text(
                        LanguageService.instance.trText(
                          ne: 'एन्ड्रोइड मोबाइलमा आधिकारिक एप अनिवार्य',
                          en: 'Official Android App Required on Mobile',
                          ko: '안드로이드 모바일 공식 전용 앱 필수',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        LanguageService.instance.trText(
                          ne: 'स्क्रिनसट रोक्न (Anti-Screenshot) र सुरक्षित परीक्षाको लागि वेब ब्राउजरमा रोक लगाइएको छ',
                          en: 'Web browser access is restricted to enforce 100% Anti-Screenshot and Anti-Cheat protection',
                          ko: '화면 캡처 방지(FLAG_SECURE) 및 시험 보안을 위해 모바일 웹 브라우저 실행이 제한됩니다',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Explanation Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155), width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                LanguageService.instance.trText(
                                  ne: 'मोबाइलको वेब ब्राउजरमा स्क्रिनसट रोक्न नमिल्ने भएकाले, परीक्षा प्रश्नहरूको गोपनीयता कायम राख्न एन्ड्रोइडमा आधिकारिक एप डाउनलोड गरी सञ्चालन गर्नुपर्ने हुन्छ।',
                                  en: 'Because mobile web browsers cannot block hardware screenshot capture, the official Android app is required to preserve exam confidentiality and fairness.',
                                  ko: '모바일 웹 브라우저에서는 하드웨어 캡처 차단이 불가능하므로, 문제 유출 방지 및 공정한 시험을 위해 안드로이드 전용 앱(APK) 설치가 필수입니다.',
                                ),
                                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Primary Action: Download APK Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF16A34A).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.download_for_offline_rounded, size: 26),
                          label: Text(
                            LanguageService.instance.trText(
                              ne: 'आधिकारिक Android APK डाउनलोड गर्नुहोस् (५८.७ MB)',
                              en: 'Download Official Android App (58.7 MB APK)',
                              ko: '공식 안드로이드 APK 다운로드 (58.7 MB)',
                            ),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            triggerApkDownload();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  LanguageService.instance.trText(
                                    ne: 'Android APK डाउनलोड सुरु भयो! कृपया डाउनलोड फोल्डर हेर्नुहोस्।',
                                    en: 'Download started! Please check your browser downloads.',
                                    ko: 'APK 다운로드가 시작되었습니다. 다운로드 폴더를 확인해 주세요.',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary Action: Open Installed App
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.launch_rounded, size: 20),
                          label: Text(
                            LanguageService.instance.trText(
                              ne: 'एप पहिले नै इन्स्टल छ भने: यहाँ थिचेर खोल्नुहोस्',
                              en: 'Already Installed? Tap to Launch App',
                              ko: '앱이 이미 설치되어 있다면: 앱 실행하기',
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            tryLaunchInstalledAndroidApp();
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3-Step Installation Guide
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LanguageService.instance.trText(
                                ne: 'सजिलो ३-चरण इन्स्टलेसन प्रक्रिया:',
                                en: 'Easy 3-Step Installation Guide:',
                                ko: '간편 3단계 설치 가이드:',
                              ),
                              style: const TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildStepRow(
                              '1',
                              Icons.download_rounded,
                              LanguageService.instance.trText(
                                ne: 'माथिको हरियो बटन थिची APK फाइल डाउनलोड गर्नुहोस्।',
                                en: 'Tap the green button above to download the APK file.',
                                ko: '상단 녹색 버튼을 눌러 APK 파일을 다운로드합니다.',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildStepRow(
                              '2',
                              Icons.touch_app_rounded,
                              LanguageService.instance.trText(
                                ne: 'डाउनलोड सकिएपछि फाइल खोली Install गर्नुहोस्। (Unknown Sources अनुमति दिनुहोस्)',
                                en: 'When download completes, tap the file and click Install. (Allow install from unknown sources if asked)',
                                ko: '다운로드 완료 후 파일을 열고 설치를 진행합니다. (출처를 알 수 없는 앱 허용)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildStepRow(
                              '3',
                              Icons.lock_person_rounded,
                              LanguageService.instance.trText(
                                ne: 'एप खोली १००% सुरक्षित परीक्षा हल, अडियो र सम्पूर्ण सुविधा प्रयोग गर्नुहोस्।',
                                en: 'Open the app and take your 100% secure, offline-ready UBT exam!',
                                ko: '설치된 앱을 실행하여 100% 보안 및 오프라인 시험을 시작합니다.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key App Features Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildPillBadge(Icons.security_rounded, LanguageService.instance.trText(ne: '१००% स्क्रिनसट लक', en: '100% Screenshot Block', ko: '화면 캡처 차단')),
                          _buildPillBadge(Icons.wifi_off_rounded, LanguageService.instance.trText(ne: 'अफलाइन परीक्षा हल', en: 'Offline Exam Terminal', ko: '오프라인 시험장')),
                          _buildPillBadge(Icons.headphones_rounded, LanguageService.instance.trText(ne: '६० च्याप्टरको अडियो', en: '60-Chapter Audio', ko: '전 단원 오디오')),
                          _buildPillBadge(Icons.cloud_done_rounded, LanguageService.instance.trText(ne: 'अटो क्लाउड सिङ्क', en: 'Auto Cloud Sync', ko: '자동 동기화')),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Discrete Admin / Teacher Portal Override Link
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                        ),
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                        label: Text(
                          LanguageService.instance.trText(
                            ne: 'शिक्षक / एडमिन वेब लगइन (प्रशासनिक पोर्टल)',
                            en: 'Teacher / Admin Web Portal (Management Only)',
                            ko: '교사 / 관리자 웹 포털 (관리 전용)',
                          ),
                          style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String stepNumber, IconData icon, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPillBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
