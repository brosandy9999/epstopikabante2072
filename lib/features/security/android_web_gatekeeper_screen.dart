import '../../core/services/platform_detector.dart';
import '../../core/widgets/device_download_modal.dart';
import '../authentication/login_screen.dart';
import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/download_helper.dart';

/// Minimalist & Premium EPS-TOPIK Gatekeeper & App Launcher Screen
class AndroidWebGatekeeperScreen extends StatelessWidget {
  final bool showBackButton;
  const AndroidWebGatekeeperScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isAndroidWeb && showBackButton,
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          final detected = getDetectedApkInfo();
          final lang = LanguageService.instance;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.school_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EPS-TOPIK UBT 2026',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: lang.buildLanguageSwitcherWidget(),
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. App Icon & Title
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lang.trText(
                          ne: '한국어 표준교재 • EPS-TOPIK UBT',
                          en: 'Standard Korean • EPS-TOPIK UBT',
                          ko: '한국어 표준교재 • EPS-TOPIK UBT',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.trText(
                          ne: '६० पाठको पूर्ण किताब, ओरिजिनल अडियो, र १००% अफलाइन UBT परीक्षा हल',
                          en: 'Full 60 chapters with audio & 100% offline real UBT exam hall',
                          ko: '전 60과 수록, 교재 내 오디오, 100% 오프라인 실전 UBT 시험장',
                        ),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // 2. Main Smart Action Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            // Device detection pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(detected.icon, size: 16, color: const Color(0xFF0D9488)),
                                const SizedBox(width: 6),
                                Text(
                                  lang.trText(
                                    ne: 'सिफारिस: ${detected.deviceLabel} (${detected.sizeText})',
                                    en: 'Recommended: ${detected.deviceLabel} (${detected.sizeText})',
                                    ko: '추천: ${detected.deviceLabel} (${detected.sizeText})',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Primary CTA Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: Icon(detected.isApk ? Icons.download_rounded : detected.icon, size: 22),
                                label: Text(
                                  detected.isApk
                                      ? lang.trText(
                                          ne: 'एप डाउनलोड गर्नुहोस् (${detected.sizeText})',
                                          en: 'Download App (${detected.sizeText})',
                                          ko: '앱 다운로드 (${detected.sizeText})',
                                        )
                                      : lang.trText(
                                          ne: 'UBT हल सुरु गर्नुहोस्',
                                          en: 'Launch UBT Hall',
                                          ko: 'UBT 시험장 실행',
                                        ),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                onPressed: () {
                                  if (detected.isApk) {
                                    triggerApkDownload(detected.downloadUrl);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(lang.trText(
                                          ne: '📥 डाउनलोड सुरु भयो (${detected.sizeText})',
                                          en: '📥 Download started (${detected.sizeText})',
                                          ko: '📥 다운로드 시작 (${detected.sizeText})',
                                        )),
                                        backgroundColor: const Color(0xFF1E3A8A),
                                      ),
                                    );
                                  } else {
                                    showDeviceDownloadModal(context);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Other Devices Button
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF334155),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.devices_rounded, size: 16, color: Color(0xFF0D9488)),
                                label: Text(
                                  lang.trText(
                                    ne: 'अन्य डिभाइसहरू (PC, Tab, iOS PWA)',
                                    en: 'Other Devices (PC, Tab, iOS PWA)',
                                    ko: '기타 기기 (PC, 태블릿, iOS PWA)',
                                  ),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => showDeviceDownloadModal(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Direct Web Login Link
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        icon: const Icon(Icons.language_rounded, size: 16),
                        label: Text(
                          lang.trText(
                            ne: '🌐 वेब पोर्टलबाट सिधै लगइन गर्नुहोस्',
                            en: '🌐 Direct Login via Web Portal',
                            ko: '🌐 웹 포털에서 바로 로그인',
                          ),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 18),

                      // 4. Compact 3 Features Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeaturePill(
                              icon: Icons.menu_book,
                              color: const Color(0xFFE11D48),
                              label: lang.trText(ne: '६० पाठ किताब', en: '60 Chapters', ko: '60과 교재'),
                            ),
                            Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                            _buildFeaturePill(
                              icon: Icons.headphones,
                              color: const Color(0xFF0D9488),
                              label: lang.trText(ne: 'ओरिजिनल अडियो', en: 'Book Audio', ko: '교재 오디오'),
                            ),
                            Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                            _buildFeaturePill(
                              icon: Icons.wifi_off_rounded,
                              color: const Color(0xFF2563EB),
                              label: lang.trText(ne: '१००% अफलाइन', en: 'Offline Ready', ko: '오프라인'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Minimal footer
                      Text(
                        lang.trText(
                          ne: '고용노동부 • HRD Korea 한국산업인력공단 표준교재 연계',
                          en: 'Ministry of Employment & Labor • HRD Korea Curriculum',
                          ko: '고용노동부 • 한국산업인력공단 한국어 표준교재 연계',
                        ),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturePill({required IconData icon, required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}
