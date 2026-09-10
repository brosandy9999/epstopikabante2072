import '../../core/services/platform_detector.dart';
import '../authentication/login_screen.dart';
import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/download_helper.dart';

/// EPS-TOPIK Mobile App & Features Showcase Screen
/// Highlights all the powerful features of the EPS-TOPIK Mobile App,
/// including Real UBT Exam Simulation, 60-Chapter Audio, 100% Offline Mode,
/// AI Weakness Analysis, and provides direct 1-click APK download + Web Portal access.
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
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EPS-TOPIK UBT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            actions: [
              // Language Switcher
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
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF042F2E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hero App Badge & Stars
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade400, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                LanguageService.instance.trText(
                                  ne: '⭐ ४.९ / ५.० • नेपालभरिका विद्यार्थीहरूको रोजाइ',
                                  en: '⭐ 4.9 / 5.0 • Rated Top EPS-TOPIK Platform',
                                  ko: '⭐ 4.9 / 5.0 • 수험생 만족도 1위 플랫폼',
                                ),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // App Icon & Glow
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withOpacity(0.4),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 52,
                            color: Color(0xFF38BDF8),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Organization & App Title
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

                        // Main Header Title
                        Text(
                          LanguageService.instance.trText(
                            ne: 'EPS-TOPIK UBT आधिकारिक एप र सुविधाहरू',
                            en: 'Official EPS-TOPIK UBT App & Features',
                            ko: 'EPS-TOPIK UBT 공식 모바일 앱 및 주요 기능',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          LanguageService.instance.trText(
                            ne: 'कोरियन भाषा परीक्षा (EPS-TOPIK) को १००% पूर्ण तयारी, अफलाइन परीक्षा हल र ६० वटै च्याप्टरको अडियो अब तपाईंको हातमा!',
                            en: '100% Complete preparation for EPS-TOPIK with real offline exam hall and full 60 textbook audios directly on your phone!',
                            ko: '100% 실전 UBT 시험장, 오프라인 모드, 표준교재 60과 전 음원 수록 완벽 대비!',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Quick Stats / Badges Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildPillBadge(Icons.phone_android_rounded, LanguageService.instance.trText(ne: '१९.५ MB छिटो एप', en: '19.5 MB Fast APK', ko: '19.5 MB 초경량')),
                            _buildPillBadge(Icons.wifi_off_rounded, LanguageService.instance.trText(ne: '१००% अफलाइन हल', en: '100% Offline Hall', ko: '100% 오프라인')),
                            _buildPillBadge(Icons.headphones_rounded, LanguageService.instance.trText(ne: '६० च्याप्टर अडियो', en: '60-Chapter Audio', ko: '60과 전 트랙 오디오')),
                            _buildPillBadge(Icons.quiz_rounded, LanguageService.instance.trText(ne: '४०+ UBT सेटहरू', en: '40+ UBT Sets', ko: '40+ 실전 세트')),
                            _buildPillBadge(Icons.cloud_done_rounded, LanguageService.instance.trText(ne: 'अटो क्लाउड सिङ्क', en: 'Auto Cloud Sync', ko: '클라우드 자동동기화')),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Primary Action 1: Download APK Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              triggerApkDownload();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LanguageService.instance.trText(
                                      ne: '📥 Android APK डाउनलोड सुरु भयो! कृपया डाउनलोड फोल्डर हेर्नुहोस्।',
                                      en: '📥 Download started! Please check your downloads folder.',
                                      ko: '📥 APK 다운로드가 시작되었습니다. 다운로드 폴더를 확인해 주세요.',
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download_for_offline_rounded, size: 28),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LanguageService.instance.trText(
                                          ne: 'आधिकारिक Android App (APK) डाउनलोड गर्नुहोस्',
                                          en: 'Download Official Android App (APK)',
                                          ko: '공식 안드로이드 APK 다운로드 (19.5 MB)',
                                        ),
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        LanguageService.instance.trText(
                                          ne: '१९.५ MB • छिटो डाउनलोड • १००% सुरक्षित',
                                          en: '19.5 MB • Fast Download • 100% Safe & Offline Ready',
                                          ko: '19.5 MB • 빠른 다운로드 • 100% 오프라인 지원',
                                        ),
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Secondary Action 2: Open Installed App
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.launch_rounded, size: 20),
                            label: Text(
                              LanguageService.instance.trText(
                                ne: '📱 एप पहिले नै इन्स्टल छ? सिधै यहाँ थिचेर खोल्नुहोस्',
                                en: '📱 App Already Installed? Tap Here to Open',
                                ko: '📱 이미 설치하셨나요? 여기를 눌러 앱 바로 열기',
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              tryLaunchInstalledAndroidApp();
                            },
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Section Title: Key Features Showcase
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              LanguageService.instance.trText(
                                ne: '🌟 EPS-TOPIK एपका मुख्य विशेषता तथा सुविधाहरू:',
                                en: '🌟 Key App Features & Capabilities:',
                                ko: '🌟 EPS-TOPIK 앱의 핵심 기능 및 혜택:',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 6 Rich Feature Cards Grid
                        _buildFeatureCard(
                          icon: Icons.computer_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          title: LanguageService.instance.trText(
                            ne: '१. वास्तविक UBT/CBT परीक्षा हल (Real UBT Simulation)',
                            en: '1. Official Real UBT Exam Simulation',
                            ko: '1. 한국산업인력공단 표준 UBT 실전 시험장',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'HRD Korea को आधिकारिक परीक्षा ढाँचा: २० रिडिङ + २० लिसनिङ (कुल ४० प्रश्नहरू), ५० मिनेट टाइमर, प्रश्न नेभिगेसन, अडियो प्लेयर र वास्तविक परीक्षा हल जस्तै वातावरण।',
                            en: 'Exact HRD Korea standard format: 20 Reading + 20 Listening (40 Questions), 50-minute timer, question palette, audio player, and real exam atmosphere.',
                            ko: '읽기 20문항 + 듣기 20문항(총 40문항), 50분 타이머, 음원 재생기 등 실제 시험과 100% 동일한 환경 제공.',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildFeatureCard(
                          icon: Icons.headphones_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: LanguageService.instance.trText(
                            ne: '२. ६० च्याप्टरको कोरियन अडियो र पुस्तकहरू (60-Chapter Audio)',
                            en: '2. Full 60 Textbook Chapters & Native Audio',
                            ko: '2. 60과 표준교재 전 단원 고음질 오디오 수록',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'EPS-TOPIK का आधिकारिक पाठ्यपुस्तकहरू (Book 1 & 2) का सबै ६० वटै च्याप्टरका स्पष्ट कोरियन अडियो ट्र्याकहरू इन-एप सुन्न र पढ्न सकिने।',
                            en: 'Access complete standard Korean textbooks (Book 1 & 2) and listen to all 60 chapter audio tracks with native Korean pronunciation.',
                            ko: '표준교재 1권 및 2권의 모든 60개 단원 원어민 음원을 앱에서 바로 청취 및 학습 가능.',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildFeatureCard(
                          icon: Icons.wifi_off_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: LanguageService.instance.trText(
                            ne: '३. १००% अफलाइन परीक्षा र अध्ययन (100% Offline Mode)',
                            en: '3. 100% Offline Exam Terminal & Books',
                            ko: '3. 인터넷 없는 100% 오프라인 학습 지원',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'इन्टरनेट नहुँदा पनि जुनसुकै ठाउँमा पूर्ण परीक्षा दिन र पुस्तकहरू पढ्न सकिने। १-क्लिकमा सबै परीक्षा सेट र पुस्तकहरू सुरक्षित अफलाइन भण्डारणमा डाउनलोड हुन्छ।',
                            en: 'Take full exams and read textbooks anywhere without internet. 1-click download saves all exam sets and books securely on your device.',
                            ko: '인터넷 연결 없이도 언제 어디서나 모의고사 응시 및 교재 학습 가능. 1-클릭으로 모든 세트 오프라인 저장.',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildFeatureCard(
                          icon: Icons.insights_rounded,
                          iconColor: const Color(0xFFA855F7),
                          title: LanguageService.instance.trText(
                            ne: '४. स्मार्ट कमजोरी विश्लेषण र स्कोरकार्ड (Instant Scorecard & AI Review)',
                            en: '4. Instant Scorecard & Mistake Review Notebook',
                            ko: '4. 즉각적인 성적표 및 오답노트 취약점 분석',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'परीक्षा सम्पन्न हुनासाथ तत्काल आधिकारिक अङ्क (Scorecard), विधागत प्रतिशत र गल्ती भएका प्रश्नहरूको विस्तृत नेपाली व्याख्या सहितको रिभ्यु नोट।',
                            en: 'Instant official scorecards, category-wise breakdown percentages, and detailed mistake review notes with explanations.',
                            ko: '시험 종료 즉시 공식 성적표 발급, 영역별 점수 통계 및 틀린 문제 오답노트 자동 생성.',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildFeatureCard(
                          icon: Icons.category_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: LanguageService.instance.trText(
                            ne: '५. विधागत अभ्यास र शब्द भण्डार (Targeted Practice & Vocab)',
                            en: '5. Targeted Category Practice & Vocabulary Bank',
                            ko: '5. 유형별 집중 훈련 및 어휘/문법 학습',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'व्याकरण (Grammar), सांकेतिक चिन्ह (Signs/Graphs), तस्वीर सम्बन्धी प्रश्नहरू र औद्योगिक शब्दावलीको विधागत अभ्यास।',
                            en: 'Practice specific topics like Korean grammar, road/workplace signs, graphs, pictures, and industrial vocabulary sets.',
                            ko: '문법, 표지판/그래프, 그림 문제, 직무별 어휘 등 부족한 영역만 골라서 집중 연습.',
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildFeatureCard(
                          icon: Icons.cloud_sync_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          title: LanguageService.instance.trText(
                            ne: '६. अटो क्लाउड सिङ्क्रोनाइजेसन (Instant Cloud Sync)',
                            en: '6. Auto Cloud Sync Across Mobile & PC',
                            ko: '6. 모바일 및 PC 간 완벽한 클라우드 자동 동기화',
                          ),
                          description: LanguageService.instance.trText(
                            ne: 'मोबाइल र कम्प्युटर/वेब बीच विद्यार्थीको प्रगति, परीक्षा अङ्क र अध्ययन विवरण स्वचालित रूपमा सिङ्क हुन्छ।',
                            en: 'Exam history, scores, and learning progress seamlessly sync across your mobile phone, tablet, and computer browser.',
                            ko: '휴대폰, 태블릿, PC 브라우저 간 시험 이력과 학습 진도가 실시간 자동 동기화.',
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 3-Step Installation Guide Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.install_mobile_rounded, color: Color(0xFF10B981), size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    LanguageService.instance.trText(
                                      ne: 'सजिलो ३-चरण इन्स्टलेसन प्रक्रिया:',
                                      en: 'Easy 3-Step Installation Guide:',
                                      ko: '간편 3단계 설치 가이드:',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFF1F5F9),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStepRow(
                                '1',
                                LanguageService.instance.trText(
                                  ne: 'माथिको हरियो बटन थिची APK फाइल डाउनलोड गर्नुहोस्। (मात्र १९.५ MB)',
                                  en: 'Tap the green button above to download the APK file. (Only 19.5 MB)',
                                  ko: '상단 녹색 버튼을 눌러 APK 파일을 다운로드합니다. (19.5 MB)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                '2',
                                LanguageService.instance.trText(
                                  ne: 'डाउनलोड सकिएपछि फाइल खोली Install गर्नुहोस्। (Unknown Sources अनुमति दिनुहोस्)',
                                  en: 'When download completes, open the file and tap Install. (Allow install from unknown sources if prompted)',
                                  ko: '다운로드 완료 후 파일을 열고 설치를 진행합니다. (출처를 알 수 없는 앱 허용)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                '3',
                                LanguageService.instance.trText(
                                  ne: 'एप खोली १००% सुरक्षित परीक्षा हल, ६० च्याप्टरको अडियो र सम्पूर्ण सुविधा प्रयोग गर्नुहोस्।',
                                  en: 'Launch the app and enjoy full offline exams, 60 textbook audios, and all features!',
                                  ko: '설치된 앱을 실행하여 100% 오프라인 UBT 시험과 60과 음원 학습을 시작하세요!',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom Action Row
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.download_rounded, size: 24),
                            label: Text(
                              LanguageService.instance.trText(
                                ne: 'आधिकारिक Android APK डाउनलोड गर्नुहोस् (१९.५ MB)',
                                en: 'Download Official Android App (19.5 MB APK)',
                                ko: '공식 안드로이드 APK 다운로드 (19.5 MB)',
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
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Security Notice Banner (Strict Android Lock - No web bypass on Android)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade600, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  LanguageService.instance.trText(
                                    ne: '🔒 एन्ड्रोइड मोबाइलमा कडा परीक्षा हल (Strict Exam Mode), एन्टी-चीट र अडियो इन्जिनको सुरक्षाका लागि आधिकारिक APK एप अनिवार्य गरिएको छ।',
                                    en: '🔒 Official Android APK is required on Android devices for Strict Exam Mode and Offline Audio support.',
                                    ko: '🔒 안드로이드 기기에서는 엄격한 시험 모드 및 음원 지원을 위해 공식 APK 설치가 필수입니다.',
                                  ),
                                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (showBackButton)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF38BDF8)),
                              label: Text(
                                LanguageService.instance.trText(
                                  ne: '← पछाडि फर्कनुहोस् (Back)',
                                  en: '← Go Back',
                                  ko: '← 뒤로 가기',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        // App Footer Notice
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Text(
                                LanguageService.instance.trText(
                                  ne: 'EPS-TOPIK UBT आधिकारिक एप • १००% सुरक्षित तथा अफलाइन सहायता',
                                  en: 'Official EPS-TOPIK UBT App • 100% Safe & Offline Ready',
                                  ko: 'EPS-TOPIK UBT 공식 앱 • 100% 안전 및 오프라인 지원',
                                ),
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
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
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String stepNumber, String description) {
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
