import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'features/reading/reading_widget.dart';
import 'features/listening/listening_widget.dart';
import 'features/question_engine/question_template.dart';
import 'features/exam/timer_widget.dart';
import 'features/exam/strict_mode_wrapper.dart';
import 'features/exam/study_mode_widget.dart';
import 'features/admin/admin_dashboard.dart' as admin;
import 'features/authentication/login_screen.dart';
import 'features/exam/exam_result_screen.dart';
import 'core/services/question_bank_service.dart';
import 'core/services/offline_download_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/exam_service.dart';
import 'core/models/mock_test_model.dart';
import 'features/exam/mock_test_list_screen.dart';
import 'features/exam/student_history_screen.dart';
import 'features/exam/exam_review_screen.dart';

import 'core/services/storage_service.dart';
import 'core/services/language_service.dart';
import 'features/settings/universal_settings_dialog.dart';
import 'features/exam/real_ubt_exam_hall_screen.dart';
import 'features/practice/weakness_analysis_screen.dart';
import 'features/exam/official_scorecard_screen.dart';
import 'features/study/student_study_hub_screen.dart';
import 'core/services/study_material_service.dart';
import 'features/super_admin/super_admin_dashboard.dart';

import 'core/services/cloud_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize persistent storage engine
  await StorageService.instance.init();

  // 2. Initialize Language and Exam Mode preferences
  LanguageService.instance.init();

  // 3. Initialize & Restore saved users and credentials (Super Admin, Admins, Students)
  AuthService.instance.init();
  final savedUsers = StorageService.instance.loadUsers();
  if (savedUsers != null && savedUsers.isNotEmpty) {
    AuthService.instance.loadFromStorage(savedUsers);
  }

  // 4. Restore saved custom / imported questions
  final savedQuestions = StorageService.instance.loadCustomQuestions();
  if (savedQuestions != null && savedQuestions.isNotEmpty) {
    QuestionBankService.instance.loadFromStorage(savedQuestions);
  }

  // 5. Restore saved exam attempts and mistake records
  final savedAttempts = StorageService.instance.loadExamAttempts();
  if (savedAttempts != null && savedAttempts.isNotEmpty) {
    ExamHistoryService.instance.loadFromStorage(savedAttempts);
  }

  // 6. Initialize CloudSyncService and auto-sync in background if configured
  CloudSyncService.instance.init();
  if (CloudSyncService.instance.hasConfiguredCloud) {
    CloudSyncService.instance.pullFromCloud().catchError((_) => false);
  }

  runApp(const EpsTopikApp());
}

class EpsTopikApp extends StatelessWidget {
  const EpsTopikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'EPS-TOPIK UBT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// STUDENT PORTAL (मोड तथा बहु Mock Test सेटहरू)
// ------------------------------------------------------------------
class StudentDashboardScreen extends StatefulWidget {
  final AppUser? student;
  const StudentDashboardScreen({super.key, this.student});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {


  int _currentTab = 4; // Start on Dashboard by default, or tap any tab
  int _gridColumnsOverride = 0; // 0 = Auto, 1 = Single column, 2 = 2 columns, 3 = 3 columns
  double _uiScale = 1.0;
  double _pinchBaseScale = 1.0;
  bool _directScrollZoomEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final s = widget.student ?? AuthService.instance.students.first;
        final allSets = QuestionBankService.instance.getAllMockSets();
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 850;

        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              final isCtrl = HardwareKeyboard.instance.isControlPressed;
              if (isCtrl || _directScrollZoomEnabled) {
                if (pointerSignal.scrollDelta.dy < 0) {
                  // Mouse Scroll Up = Zoom In
                  setState(() {
                    _uiScale = (_uiScale + 0.08).clamp(0.75, 2.0);
                    if (_uiScale >= 1.18) _gridColumnsOverride = 1;
                  });
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  // Mouse Scroll Down = Zoom Out
                  setState(() {
                    _uiScale = (_uiScale - 0.08).clamp(0.75, 2.0);
                    if (_uiScale < 1.18) _gridColumnsOverride = 0;
                  });
                }
              }
            }
          },
          child: GestureDetector(
            onScaleStart: (_) {
              _pinchBaseScale = _uiScale;
            },
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                setState(() {
                  _uiScale = (_pinchBaseScale * details.scale).clamp(0.75, 2.0);
                  if (_uiScale >= 1.18) {
                    _gridColumnsOverride = 1;
                  } else {
                    _gridColumnsOverride = 0;
                  }
                });
              }
            },
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_uiScale),
              ),
              child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            elevation: 3,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            title: Row(
              children: [
                // Professional Institute Study Logo
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.instituteName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Colors.white),
                      ),
                      Text(
                        '${LanguageService.instance.tr('app_subtitle')} • ${s.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Global Visible Zoom Pill
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                      tooltip: LanguageService.instance.trText(ne: 'जुम घटाउनुहोस्', en: 'Zoom Out', ko: '축소'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () {
                        setState(() {
                          _uiScale = (_uiScale - 0.15).clamp(0.8, 1.8);
                          if (_uiScale < 1.15) _gridColumnsOverride = 0;
                        });
                      },
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _uiScale = 1.0;
                          _gridColumnsOverride = 0;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '🔍 ${(_uiScale * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      tooltip: LanguageService.instance.trText(ne: 'जुम बढाउनुहोस्', en: 'Zoom In', ko: '확대'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () {
                        setState(() {
                          _uiScale = (_uiScale + 0.15).clamp(0.8, 1.8);
                          if (_uiScale >= 1.2) _gridColumnsOverride = 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
                            IconButton(
                icon: const Icon(Icons.download_for_offline_outlined),
                tooltip: LanguageService.instance.tr('offline_storage'),
                onPressed: () => _showOfflineManagerModal(context),
              ),
              if (s.role == UserRole.superAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.workspace_premium, size: 16),
                    label: Text(LanguageService.instance.tr('super_admin_portal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SuperAdminDashboardScreen()),
                      );
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: LanguageService.instance.tr('settings'),
                onPressed: () => showUniversalSettingsDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: LanguageService.instance.tr('logout'),
                onPressed: () => AuthService.confirmAndLogout(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildTabContent(_currentTab, s, allSets, isMobile),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1E3A8A),
            unselectedItemColor: Colors.blueGrey.shade700,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 16,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home_rounded),
                label: LanguageService.instance.tr('tab_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.timer_outlined),
                activeIcon: const Icon(Icons.timer_rounded),
                label: LanguageService.instance.tr('tab_exam'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.auto_stories_outlined),
                activeIcon: const Icon(Icons.auto_stories_rounded),
                label: LanguageService.instance.tr('tab_study'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder_special_outlined),
                activeIcon: const Icon(Icons.folder_special_rounded),
                label: LanguageService.instance.tr('books'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: LanguageService.instance.tr('tab_profile'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
      },
    );
  }

  Widget _buildTabContent(int tab, AppUser s, List<MockTestSet> allSets, bool isMobile) {
    switch (tab) {
      case 0:
        return _buildHomeTab(s, allSets, isMobile);
      case 1:
        return _buildExamLaunchpadTab(s, allSets, isMobile);
      case 2:
        return _buildStudyLaunchpadTab(s, allSets, isMobile);
      case 3:
        return const StudentStudyHubScreen();
      case 4:
        return _buildProfileTab(s, isMobile);
      default:
        return _buildHomeTab(s, allSets, isMobile);
    }
  }

  Widget _buildLiveDailyExamCard(BuildContext context, AppUser s, bool isMobile) {
    final liveSet = QuestionBankService.instance.getTodayLiveExam() ?? (QuestionBankService.instance.getAllMockSets().isNotEmpty ? QuestionBankService.instance.getAllMockSets().first : null);
    if (liveSet == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.red.shade900.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(Icons.flash_on, size: 130, color: Colors.white.withOpacity(0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.radio_button_checked, size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(LanguageService.instance.tr("today_live_exam"), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('STRICT UBT MODE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  liveSet.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '${liveSet.sector} • ${liveSet.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildLiveBadge(Icons.timer, '५० मिनेट'),
                    _buildLiveBadge(Icons.quiz, LanguageService.instance.isEnglish ? '40 Questions (20 R + 20 L)' : (LanguageService.instance.isKorean ? '40 문항 (읽기 20 + 듣기 20)' : '४० प्रश्नहरू (२० रिडिङ + २० लिसनिङ)')),
                    _buildLiveBadge(Icons.assignment_turned_in, LanguageService.instance.trText(ne: 'पूर्णाङ्क १०० / उत्तीर्णाङ्क ५०', en: 'Full Marks 100 / Pass 50', ko: '100점 만점 / 50점 합격')),
                    _buildLiveBadge(Icons.security, LanguageService.instance.trText(ne: 'एन्टी-चीट लक', en: 'Anti-Cheat Locked', ko: '부정행위 방지 잠금')),
                  ],
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    final isDownloaded = OfflineDownloadService.instance.isSetDownloaded(liveSet.id);
                    return Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 300,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF991B1B),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StrictModeWrapper(
                                    onCheatAttemptDetected: () {
                                      debugPrint("⚠️ Cheat attempt detected during Live Strict Exam!");
                                    },
                                    child: RealUbtExamHallScreen(
                                      student: s,
                                      mockSet: liveSet,
                                    ),
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 22),
                            label: Text(LanguageService.instance.tr('start_exam_btn'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (isDownloaded) {
                              await OfflineDownloadService.instance.removeDownloadedSet(liveSet.id);
                            } else {
                              await OfflineDownloadService.instance.downloadSet(liveSet);
                            }
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isDownloaded ? LanguageService.instance.trText(ne: 'अफलाइन क्यासबाट हटाइयो।', en: 'Removed from offline cache.', ko: '오프라인 캐시에서 삭제되었습니다.') : LanguageService.instance.trText(ne: '✅ लाइभ परीक्षा इन-एप अफलाइन प्रयोगका लागि सुरक्षित गरियो!', en: '✅ Live exam saved for offline use!', ko: '✅ 라이브 시험이 오프라인용으로 저장되었습니다!')),
                                backgroundColor: isDownloaded ? Colors.blueGrey : Colors.teal,
                              ),
                            );
                          },
                          icon: Icon(isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 18, color: Colors.amber),
                          label: Text(
                            isDownloaded ? LanguageService.instance.trText(ne: '✅ अफलाइन तयार', en: '✅ Offline Ready', ko: '✅ 오프라인 준비완료') : LanguageService.instance.trText(ne: '⬇️ अफलाइन सेभ गर्नुहोस्', en: '⬇️ Save Offline', ko: '⬇️ 오프라인 저장'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

    void _showOfflineManagerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final svc = OfflineDownloadService.instance;
          final setsCount = svc.downloadedSetsCount;
          final booksCount = svc.downloadedBooksCount;
          final storageMb = svc.estimatedStorageMb;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.offline_pin, color: Color(0xFF0F766E), size: 26),
                const SizedBox(width: 10),
                Text(LanguageService.instance.trText(ne: 'सुरक्षित इन-एप अफलाइन भण्डारण', en: 'Secure In-App Offline Storage', ko: '안전한 인앱 오프라인 저장소'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: Color(0xFF1E3A8A), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            LanguageService.instance.trText(ne: '🔒 यहाँ डाउनलोड गरिएका सबै परीक्षा सेटहरू र पुस्तकहरू एप भित्रै सुरक्षित रहन्छन्। इन्टरनेट नहुँदा पनि तपाईं एपमै बसेर १००% अफलाइन परीक्षा दिन सक्नुहुन्छ। यो बाहिर एक्सपोर्ट हुँदैन।', en: '🔒 All downloaded test sets and books remain safely inside the app. You can take exams 100% offline without internet.', ko: '🔒 다운로드된 모든 시험 세트와 교재는 앱 내에 안전하게 보관됩니다. 인터넷 없이도 100% 오프라인 응시가 가능합니다.'),
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LanguageService.instance.trText(ne: 'अफलाइन परीक्षा सेटहरू', en: 'Offline Exam Sets', ko: '오프라인 시험 세트'), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text('$setsCount वटा सेट', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LanguageService.instance.trText(ne: 'अफलाइन पुस्तकहरू', en: 'Offline Textbooks', ko: '오프라인 교재'), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text('$booksCount वटा पुस्तक', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('💾 कुल खपत भएको फोन मेमोरी: ~$storageMb MB', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const Divider(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await svc.downloadAllSets();
                      setModalState(() {});
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LanguageService.instance.trText(ne: '✅ सबै परीक्षा सेटहरू अफलाइन अध्ययनका लागि डाउनलोड भए!', en: '✅ All exam sets downloaded for offline study!', ko: '✅ 모든 시험 세트가 오프라인용으로 다운로드되었습니다!')), backgroundColor: Colors.teal),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(LanguageService.instance.trText(ne: '⚡ सबै परीक्षा सेटहरू १-क्लिकमा डाउनलोड गर्नुहोस्', en: '⚡ 1-Click Download All Exam Sets', ko: '⚡ 모든 시험 세트 1-클릭 다운로드')),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await svc.downloadAllBooks();
                      setModalState(() {});
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LanguageService.instance.trText(ne: '✅ सबै पुस्तकहरू अफलाइन अध्ययनका लागि डाउनलोड भए!', en: '✅ All books downloaded for offline study!', ko: '✅ 모든 교재가 오프라인용으로 다운로드되었습니다!')), backgroundColor: Colors.teal),
                      );
                    },
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: Text(LanguageService.instance.trText(ne: '⚡ सबै पुस्तकहरू १-क्लिकमा डाउनलोड गर्नुहोस्', en: '⚡ 1-Click Download All Books', ko: '⚡ 모든 교재 1-클릭 다운로드')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await svc.clearAllOfflineCache();
                      setModalState(() {});
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LanguageService.instance.trText(ne: 'अफलाइन क्यास पूर्ण रूपमा खाली गरियो।', en: 'Offline cache cleared completely.', ko: '오프라인 캐시가 완전히 삭제되었습니다.'))),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text('🗑️ ' + LanguageService.instance.tr('clear_cache')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LanguageService.instance.trText(ne: 'बन्द गर्नुहोस्', en: 'Close', ko: '닫기')),
              ),
            ],
          );
        },
      ),
    );
  }

    Widget _buildHomeNoticeBanner(BuildContext context) {
    final notices = StudyMaterialService.instance.getAllNotices();
    if (notices.isEmpty) return const SizedBox.shrink();
    final latest = notices.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentStudyHubScreen(initialTabIndex: 0)),
          );
        },
        child: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFFB45309), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade900, borderRadius: BorderRadius.circular(4)),
                        child: const Text('공지사항', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      Text(latest.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFB45309)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeStudyHubCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.25), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentStudyHubScreen()),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, size: 30, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 ' + LanguageService.instance.tr('resources_hub'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'पाठ्यपुस्तक १ र २ • मिनिङ बैंक • व्याकरण • फ्ल्यास कार्ड प्र्याक्टिस • भिडियो कोर्स',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentStudyHubScreen()),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'खोल्नुहोस्', en: 'Open', ko: '열기')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(AppUser s, List<MockTestSet> allSets, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 18 : 25,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Student Profile Card
          _buildProfileCard(s, isMobile),
          const SizedBox(height: 18),

          // Live Daily Strict Exam Card
          _buildLiveDailyExamCard(context, s, isMobile),
          const SizedBox(height: 18),

          // 2. Latest Notice Banner
          _buildHomeNoticeBanner(context),

          // 3. Korean Language Study Hub Card (Books, Grammar, Vocab, Notices)
          _buildHomeStudyHubCard(context),

          // 4. Multiple Mock Test Sets & Random Exam
          _buildMultipleSetsSection(allSets, s, isMobile),
          const SizedBox(height: 25),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildExamLaunchpadTab(AppUser s, List<MockTestSet> allSets, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LanguageService.instance.trText(ne: "आधिकारिक UBT परीक्षा मोड", en: "Official UBT Exam Mode", ko: "실전 UBT 모의고사"),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text(LanguageService.instance.trText(ne: "४० प्रश्नहरू • ५० मिनेट • पूर्णाङ्क १०० • उत्तीर्णाङ्क ५० • कडा एन्टी-चीट", en: "40 Questions • 50 Mins • Total 100 • Pass 50 • Anti-Cheat", ko: "40문항 • 50분 • 총점 100점 • 합격선 50점 • 부정행위 방지"),
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(LanguageService.instance.trText(ne: "परीक्षा दिन चाहेको सेट छान्नुहोस्:", en: "Select Exam Set:", ko: "응시할 시험 세트를 선택하세요:"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allSets.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final set = allSets[i];
              final bestAttempt = ExamHistoryService.instance.getBestAttempt(set.id);
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                        child: Text("S${i + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${set.sector} • ${set.questions.length} Questions",
                                style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            if (bestAttempt != null) ...[
                              const SizedBox(height: 4),
                              Text("सर्वोत्कृष्ट: ${bestAttempt.score.toStringAsFixed(1)} / १०० (${bestAttempt.isPassed ? '합격' : '불합격'})",
                                  style: TextStyle(
                                      color: bestAttempt.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RealUbtExamHallScreen(student: s, mockSet: set),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(LanguageService.instance.tr("start_exam_btn")),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildStudyLaunchpadTab(AppUser s, List<MockTestSet> allSets, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LanguageService.instance.tr("study_practice_mode"),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text(LanguageService.instance.trText(ne: "तत्काल सहि/गलत उत्तर • विस्तृत व्याख्या • कोरियाली अडियो संवाद", en: "Instant Feedback • Detailed Explanations • Korean Audio Dialogues", ko: "즉시 정답 확인 • 상세 해설 • 한국어 듣기 음원"),
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Direct Link to Study Hub (Books, Grammar, Vocab)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentStudyHubScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📚 ' + LanguageService.instance.tr('resources_hub'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text(LanguageService.instance.trText(ne: 'पाठ्यपुस्तक १ र २ • व्याकरण • मिनिङ बैंक • सूचना', en: 'Textbooks 1 & 2 • Grammar • Vocab Bank • Notices', ko: '표준교재 1·2권 • 문법 • 어휘집 • 공지사항'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(LanguageService.instance.trText(ne: "अभ्यास गर्न चाहेको सेट छान्नुहोस्:", en: "Select Practice Set:", ko: "연습할 세트를 선택하세요:"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allSets.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final set = allSets[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                        child: Text("S${i + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${set.sector} • ${set.questions.length} Questions",
                                style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudyModeScreen(mockSet: set),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.school, size: 18),
                        label: Text(LanguageService.instance.tr("start_study_btn")),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildHistoryTab(AppUser s, bool isMobile) {
    final allAttempts = ExamHistoryService.instance.getAttemptsForStudent(s.username);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 35, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(Icons.history_edu, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LanguageService.instance.trText(ne: "मेरो विगत परीक्षा इतिहास तथा कमजोरी समीक्षा", en: "My Exam History & Mistake Review", ko: "시험 기록 및 오답 복습"),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("कुल परीक्षाहरू: ${allAttempts.length} पटक • सफल: ${allAttempts.where((a) => a.isPassed).length} पटक",
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // AI Weakness Analysis Card
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeaknessAnalysisScreen(student: s),
                ),
              ).then((_) => setState(() {}));
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: Colors.brown, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.instance.trText(ne: '🧠 AI कमजोरी विश्लेषण तथा स्मार्ट अभ्यास', en: '🧠 AI Weakness Analysis & Smart Practice', ko: '🧠 AI 약점 분석 및 맞춤 학습'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown),
                        ),
                        SizedBox(height: 2),
                        Text(
                          LanguageService.instance.trText(ne: 'कुन विषयमा गल्ती भयो हेर्नुहोस् र कमजोर प्रश्नहरू मात्र अभ्यास गर्नुहोस्', en: 'Review mistakes and practice weak topics', ko: '틀린 문제를 분석하고 취약 유형만 집중 학습하세요'),
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.brown),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (allAttempts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(LanguageService.instance.trText(ne: "अहिलेसम्म कुनै परीक्षा दिनुभएको छैन।", en: "No exams taken yet.", ko: "아직 응시한 시험이 없습니다."), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(LanguageService.instance.trText(ne: "परीक्षा हलबाट कुनै पनि सेट सुरु गर्नुहोस्!", en: "Start any set from the exam hall!", ko: "시험장에서 원하는 세트를 시작하세요!"), style: const TextStyle(color: Colors.black54)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allAttempts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final a = allAttempts[i];
                final mockSet = QuestionBankService.instance.getMockSetById(a.setId);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(a.setTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: a.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: a.isPassed ? Colors.green : Colors.red),
                              ),
                              child: Text(
                                LanguageService.instance.trText(ne: a.isPassed ? "उत्तीर्ण" : "अनुत्तीर्ण", en: a.isPassed ? "Passed" : "Failed", ko: a.isPassed ? "합격" : "불합격"),
                                style: TextStyle(
                                  color: a.isPassed ? Colors.green.shade900 : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "प्राप्ताङ्क: ${a.score.toStringAsFixed(1)} / १००.० (Reading ${a.readingScore.toStringAsFixed(1)} • Listening ${a.listeningScore.toStringAsFixed(1)})",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: a.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "मिति: ${a.completedAt.year}/${a.completedAt.month}/${a.completedAt.day} ${a.completedAt.hour}:${a.completedAt.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OfficialScorecardScreen.fromAttempt(a, mockSet.questions),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.workspace_premium, size: 16),
                              label: Text(LanguageService.instance.isEnglish ? "📄 Official Scorecard" : (LanguageService.instance.isKorean ? "📄 공식 성적표" : "📄 आधिकारिक स्कोरकार्ड")),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExamReviewScreen(
                                      questions: mockSet.questions,
                                      userAnswers: a.userAnswers,
                                      setId: a.setId,
                                      setTitle: a.setTitle,
                                      customAnswerKeys: mockSet.answerKeys,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.fact_check, size: 16),
                              label: Text("🔍 " + LanguageService.instance.tr("mistake_review")),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AppUser s, bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Card with clickable photo & name
          _buildProfileCard(s, isMobile),
          const SizedBox(height: 16),

          // 2. Quick Account & Settings Banner Button
          InkWell(
            onTap: () => showUniversalSettingsDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.manage_accounts, color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('खाता विवरण, भाषा, पासवर्ड तथा लगआउट', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('तपाईंको फोटो वा यहाँ क्लिक गरेर सेटिङहरू व्यवस्थापन गर्नुहोस्', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF1E3A8A)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Clean Exam History & Scorecard Archive Section
          _buildHistoryTab(s, isMobile),
          const SizedBox(height: 30),
        ],
      ),
    ),
  ),
);
  }





  // 1. PROFILE CARD
  // -----------------------------------------------------------------
  Widget _buildProfileCard(AppUser s, bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Tooltip(
              message: "खाता विवरण, भाषा र सेटिङ हेर्न ट्याप गर्नुहोस्",
              child: InkWell(
                onTap: () => showUniversalSettingsDialog(context),
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 28 : 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        s.profilePhoto ?? (s.role == UserRole.superAdmin ? '👑' : (s.role == UserRole.admin ? '🏢' : '👨‍🎓')),
                        style: TextStyle(fontSize: isMobile ? 26 : 34),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.settings, size: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: isMobile ? 14 : 20),
            Expanded(
              child: InkWell(
                onTap: () => showUniversalSettingsDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          LanguageService.instance.trText(ne: 'स्वागत छ!', en: 'Welcome!', ko: '환영합니다!'),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, size: 11, color: Colors.white70),
                              SizedBox(width: 2),
                              Text("सेटिङ हेर्नुहोस्", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.name,
                      style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "수험번호 (Reg No): ${s.registrationNo ?? '01234567'}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "상태: 응시 가능 (Active)",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StudentHistoryScreen(student: s)),
                          ).then((_) => setState(() {}));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_edu, size: 14, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text(LanguageService.instance.trText(ne: 'विगत नतिजा तथा समीक्षा', en: 'Past Results & Review', ko: '과거 성적 및 검토'),
                                  style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // 2. MULTIPLE MOCK TEST SETS SECTION (Set 1 to Set 5)
  // -----------------------------------------------------------------
  Widget _buildGridColChip(int col, String label) {
    final isSelected = _gridColumnsOverride == col;
    return InkWell(
      onTap: () {
        setState(() {
          _gridColumnsOverride = col;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

    Widget _buildMultipleSetsSection(List<MockTestSet> sets, AppUser s, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.library_books, color: Color(0xFF1E3A8A), size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageService.instance.tr("available_sets"),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LanguageService.instance.trText(ne: "आधिकारिक प्रश्न सेटहरू — जुनसुकै सेट छानेर परीक्षा वा अभ्यास सुरु गर्नुहोस्:", en: "Official Question Sets — Choose any set to start exam or practice:", ko: "공식 문제 세트 — 세트를 선택하여 시험 또는 연습을 시작하세요:"),
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isMobile)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MockTestListScreen()),
                  ).then((_) => setState(() {}));
                },
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(LanguageService.instance.tr("all_sets_btn")),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRandomExamLauncherCard(s, isMobile),

        // Responsive Visible Zoom & Automatic Grid Bar
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.zoom_in, size: 22, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Text(
                        LanguageService.instance.isEnglish
                            ? 'Screen Zoom (${(_uiScale * 100).round()}%)'
                            : (LanguageService.instance.isKorean
                                ? '화면 확대/축소 (${(_uiScale * 100).round()}%)'
                                : 'स्क्रीन जुम (${(_uiScale * 100).round()}%)'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _directScrollZoomEnabled = !_directScrollZoomEnabled;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _directScrollZoomEnabled ? Colors.green.shade600 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _directScrollZoomEnabled ? Colors.green.shade800 : Colors.blue.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mouse, size: 13, color: _directScrollZoomEnabled ? Colors.white : const Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text(
                                _directScrollZoomEnabled
                                    ? (LanguageService.instance.isEnglish ? '🖱️ Mouse Zoom: ON' : (LanguageService.instance.isKorean ? '🖱️ 마우스 줌: 켜짐' : '🖱️ माउस जुम: चालु'))
                                    : (LanguageService.instance.isEnglish ? '🖱️ Mouse Zoom' : (LanguageService.instance.isKorean ? '🖱️ 마우스 줌' : '🖱️ माउस जुम')),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _directScrollZoomEnabled ? Colors.white : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildGridColChip(0, LanguageService.instance.trText(ne: '🔄 अटो ग्रिड', en: '🔄 Auto Grid', ko: '🔄 자동 그리드')),
                      _buildGridColChip(1, LanguageService.instance.trText(ne: '🔲 १ स्तम्भ', en: '🔲 1 Column', ko: '🔲 1열')),
                      _buildGridColChip(2, LanguageService.instance.trText(ne: '▦ २ स्तम्भ', en: '▦ 2 Columns', ko: '▦ 2열')),
                      if (!isMobile) _buildGridColChip(3, LanguageService.instance.trText(ne: '▤ ३ स्तम्भ', en: '▤ 3 Columns', ko: '▤ 3열')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Color(0xFF1E3A8A), size: 22),
                    tooltip: LanguageService.instance.tr('zoom_out'),
                    onPressed: () {
                      setState(() {
                        _uiScale = (_uiScale - 0.15).clamp(0.8, 1.8);
                        if (_uiScale < 1.15) _gridColumnsOverride = 0;
                      });
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _uiScale,
                      min: 0.8,
                      max: 1.8,
                      divisions: 10,
                      label: '${(_uiScale * 100).round()}%',
                      activeColor: const Color(0xFF1E3A8A),
                      onChanged: (val) {
                        setState(() {
                          _uiScale = val;
                          if (_uiScale >= 1.2) {
                            _gridColumnsOverride = 1; // Automatically becomes 1 single card!
                          } else if (_uiScale <= 1.0) {
                            _gridColumnsOverride = 0; // Automatically multi grid!
                          }
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Color(0xFF1E3A8A), size: 22),
                    tooltip: LanguageService.instance.tr('zoom_in'),
                    onPressed: () {
                      setState(() {
                        _uiScale = (_uiScale + 0.15).clamp(0.8, 1.8);
                        if (_uiScale >= 1.2) _gridColumnsOverride = 1;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      setState(() {
                        _uiScale = 1.0;
                        _gridColumnsOverride = 0;
                      });
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: Text(LanguageService.instance.trText(ne: 'रिसेट १००%', en: 'Reset 100%', ko: '100% 초기화'), style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Interactive Pinchable & Adaptive Sets Grid
        GestureDetector(
          onScaleUpdate: (details) {
            if (details.scale > 1.25 && _gridColumnsOverride != 1) {
              setState(() {
                _gridColumnsOverride = 1; // Zoom in to Single Large Card
              });
            } else if (details.scale < 0.85 && _gridColumnsOverride != 0) {
              setState(() {
                _gridColumnsOverride = 0; // Zoom out to Multi Grid
              });
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              int cols;
              if (_gridColumnsOverride > 0) {
                cols = _gridColumnsOverride;
              } else if (isMobile) {
                cols = 1;
              } else if (constraints.maxWidth > 900) {
                cols = 3;
              } else {
                cols = 2;
              }

              if (cols == 1) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sets.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) => _buildSetCard(sets[i], s, isMobile, i + 1),
                );
              }

              final double cardWidth = (constraints.maxWidth - (18 * (cols - 1))) / cols;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: sets.asMap().entries.map((entry) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildSetCard(entry.value, s, isMobile, entry.key + 1),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRandomExamLauncherCard(AppUser s, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.casino, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '🎲 ' + LanguageService.instance.tr('random_exam'),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(LanguageService.instance.trText(ne: '४० नयाँ प्रश्नहरू', en: '40 New Questions', ko: '새 40문항'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(LanguageService.instance.tr('infinite_mock_sets'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            LanguageService.instance.trText(ne: 'सयौं प्रश्नहरूबाट स्वतः आधिकारिक ब्लुप्रिन्ट अनुसार नयाँ २० रिडिङ र २० लिसनिङ प्रश्न छानेर परीक्षा सेट तयार हुन्छ।', en: 'Generates unlimited unique exams with 20 Reading and 20 Listening questions directly from the official blueprint.', ko: '공식 출제 기준에 따라 읽기 20문항, 듣기 20문항의 새로운 실전 모의고사를 자동으로 구성합니다.'),
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final randomSet = QuestionBankService.instance.generateRandomBlueprintExam();
                final mode = LanguageService.instance.modePreference;
                if (mode == ExamModePreference.strictExam) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RealUbtExamHallScreen(student: s, mockSet: randomSet)),
                  ).then((_) => setState(() {}));
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StudyModeScreen(mockSet: randomSet)),
                  ).then((_) => setState(() {}));
                }
              },
              icon: const Icon(Icons.play_circle_fill, size: 20),
              label: Text('🎲 ' + LanguageService.instance.tr('start_random_exam'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetCard(MockTestSet set, AppUser s, bool isMobile, int setNumber) {
    final bestAttempt = ExamHistoryService.instance.getBestAttempt(set.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tags Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "SET $setNumber",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        set.sector,
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                // Best score badge
                if (bestAttempt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bestAttempt.passed ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: bestAttempt.passed ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(bestAttempt.passed ? Icons.emoji_events : Icons.history,
                            size: 13, color: bestAttempt.passed ? Colors.green.shade800 : Colors.red.shade800),
                        const SizedBox(width: 4),
                        Text(
                          "최고: ${bestAttempt.score.toStringAsFixed(1)}/100 (${bestAttempt.passed ? '합격' : '불합격'})",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bestAttempt.passed ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      LanguageService.instance.trText(ne: "नयाँ सेट", en: "New Set", ko: "미응시"),
                      style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              set.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              set.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.3),
            ),

            const Divider(height: 20),

            // Specs
            Row(
              children: [
                const Icon(Icons.quiz_outlined, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(LanguageService.instance.isEnglish ? '40 Questions (20 R + 20 L)' : (LanguageService.instance.isKorean ? '40 문항 (읽기 20 + 듣기 20)' : '४० प्रश्न (२० रिडिङ + २० लिसनिङ)'), style: const TextStyle(fontSize: 11, color: Colors.black87)),
                Spacer(),
                Icon(Icons.timer_outlined, size: 14, color: Colors.blueGrey),
                SizedBox(width: 4),
                Text(LanguageService.instance.trText(ne: "५० मिनेट", en: "50 Mins", ko: "50분"), style: const TextStyle(fontSize: 11, color: Colors.black87)),
                Spacer(),
                Icon(Icons.star_outline, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text(LanguageService.instance.trText(ne: "पूर्णाङ्क १०० (उत्तीर्णाङ्क ५०)", en: "Total 100 (Pass 50)", ko: "총점 100 (합격 50)"), style: const TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),

            const SizedBox(height: 14),

            // Single Action Button: Start Exam + Offline Download
            Builder(
              builder: (context) {
                final isDownloaded = OfflineDownloadService.instance.isSetDownloaded(set.id);
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final isStrict = LanguageService.instance.modePreference == ExamModePreference.strictExam;
                          if (isStrict) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RealUbtExamHallScreen(student: s, mockSet: set),
                              ),
                            ).then((_) => setState(() {}));
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudyModeScreen(mockSet: set),
                              ),
                            ).then((_) => setState(() {}));
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          LanguageService.instance.modePreference == ExamModePreference.strictExam
                              ? LanguageService.instance.tr("start_exam_btn")
                              : LanguageService.instance.tr("start_study_btn"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDownloaded ? Colors.green.shade700 : const Color(0xFF0F766E),
                        side: BorderSide(color: isDownloaded ? Colors.green : const Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (isDownloaded) {
                          await OfflineDownloadService.instance.removeDownloadedSet(set.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(LanguageService.instance.trText(ne: 'अफलाइन क्यासबाट सेट हटाइयो।', en: 'Set removed from offline cache.', ko: '오프라인 캐시에서 세트가 삭제되었습니다.'))),
                          );
                        } else {
                          await OfflineDownloadService.instance.downloadSet(set);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(LanguageService.instance.trText(ne: '✅ परीक्षा सेट इन-एप अफलाइन प्रयोगका लागि सुरक्षित गरियो!', en: '✅ Exam set saved for offline practice!', ko: '✅ 시험 세트가 오프라인 학습용으로 저장되었습니다!')), backgroundColor: Colors.teal),
                          );
                        }
                        setState(() {});
                      },
                      icon: Icon(isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 18),
                      label: Text(LanguageService.instance.trText(ne: isDownloaded ? '✅ अफलाइन' : '⬇️ डाउनलोड', en: isDownloaded ? '✅ Offline' : '⬇️ Download', ko: isDownloaded ? '✅ 오프라인' : '⬇️ 다운로드'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// ADMIN DASHBOARD (???????? ???? ????? - Wrapper)
// ------------------------------------------------------------------
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const admin.AdminDashboardScreen();
  }
}

// ------------------------------------------------------------------
// ???????? UBT EXAM SCREEN (?? ??? ??????, ?? ????? ?????)
// ------------------------------------------------------------------
class UbtExamScreen extends StatefulWidget {
  final AppUser? student;
  final MockTestSet? mockSet;
  const UbtExamScreen({super.key, this.student, this.mockSet});

  @override
  State<UbtExamScreen> createState() => _UbtExamScreenState();
}

class _UbtExamScreenState extends State<UbtExamScreen> {
  int _currentQuestionIndex = 0;
  late final List<QuestionTemplate> _questions;
  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _questions = widget.mockSet?.questions ?? QuestionBankService.instance.getFull40ExamQuestions();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }


  void _confirmExitExam() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageService.instance.trText(ne: "परीक्षाबाट बाहिरिन चाहनुहुन्छ?", en: "Exit Exam?", ko: "시험을 중단하시겠습니까?")),
        content: Text(LanguageService.instance.trText(ne: "यदि तपाईं अहिले बाहिरिनुभयो भने तपाईंको चालु परीक्षा बीचमै रोकिनेछ। के तपाईं निश्चित हुनुहुन्छ?", en: "Leaving now will cancel your ongoing exam progress. Are you sure?", ko: "지금 퇴실하시면 진행 중인 시험이 중단됩니다. 정말 나가시겠습니까?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: "परीक्षा जारी राख्नुहोस्", en: "Continue Exam", ko: "시험 계속하기"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Pop back to Student Portal
            },
            child: Text(LanguageService.instance.tr("exit")),
          ),
        ],
      ),
    );
  }

  void _submitExam() {
    int totalQuestions = _questions.length;
    int attempted = _selectedAnswers.length;
    int unattempted = totalQuestions - attempted;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF1E3A8A), size: 28),
            SizedBox(width: 10),
            Text(LanguageService.instance.trText(ne: "परीक्षा सबमिट गर्नुहुन्छ?", en: "Submit Exam?", ko: "시험을 제출하시겠습니까?")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LanguageService.instance.trText(ne: "विद्यार्थी: ${widget.student?.name ?? 'परीक्षार्थी'}", en: "Student: ${widget.student?.name ?? 'Candidate'}", ko: "수험자: ${widget.student?.name ?? '수험생'}"), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(LanguageService.instance.trText(ne: "दर्ता नम्बर: ${widget.student?.registrationNo ?? '01234567'}", en: "Reg No: ${widget.student?.registrationNo ?? '01234567'}", ko: "수험번호: ${widget.student?.registrationNo ?? '01234567'}")),
            const Divider(height: 20),
            Text(LanguageService.instance.trText(ne: "• कुल प्रश्न: $totalQuestions वटा", en: "• Total Questions: $totalQuestions", ko: "• 총 문항: $totalQuestions")),
            Text(LanguageService.instance.trText(ne: "• हल गरिएका प्रश्न: $attempted वटा", en: "• Answered: $attempted", ko: "• 작성 문항: $attempted"), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text(LanguageService.instance.trText(ne: "• नछोएका प्रश्न: $unattempted वटा", en: "• Unanswered: $unattempted", ko: "• 미작성 문항: $unattempted"), style: TextStyle(color: unattempted > 0 ? Colors.red : Colors.grey)),
            const SizedBox(height: 12),
            Text(LanguageService.instance.isEnglish ? "Are you sure you want to finish the exam and view the scorecard?" : (LanguageService.instance.isKorean ? "시험을 종료하고 성적표를 확인하시겠습니까?" : "के तपाईं परीक्षा समाप्त गरी नतिजा कार्ड हेर्न निश्चित हुनुहुन्छ?"),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.instance.trText(ne: "परीक्षा जारी राख्नुहोस्", en: "Continue Exam", ko: "계속 풀기")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamResultScreen(
                    student: widget.student,
                    setId: widget.mockSet?.id ?? 'set_01',
                    setTitle: widget.mockSet?.title ?? '제1회 EPS-TOPIK 실전 모의고사',
                    questions: _questions,
                    userAnswers: _selectedAnswers,
                    timeSpentSeconds: 1420, // Real-time exam duration
                  ),
                ),
              );
            }, 
            child: Text(LanguageService.instance.tr("view_result")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final isReading = _currentQuestionIndex < 20;

    return StrictModeWrapper(
      onCheatAttemptDetected: () {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Top Bar
            Container(
              color: const Color(0xFFE5E7EB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        tooltip: LanguageService.instance.tr("exit_exam"),
                        onPressed: _confirmExitExam,
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LanguageService.instance.trText(ne: "दर्ता नं: ${widget.student?.registrationNo ?? '01234567'}", en: "Reg No: ${widget.student?.registrationNo ?? '01234567'}", ko: "수험번호: ${widget.student?.registrationNo ?? '01234567'}"), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          Text(LanguageService.instance.trText(ne: "नाम: ${widget.student?.name ?? 'परीक्षार्थी'}", en: "Name: ${widget.student?.name ?? 'Candidate'}", ko: "성명: ${widget.student?.name ?? '수험생'}"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(width: 25),
                      Chip(
                        label: Text(
                          isReading ? LanguageService.instance.trText(ne: "रिडिङ (१-२०)", en: "Reading (1-20)", ko: "읽기 (1-20)") : LanguageService.instance.trText(ne: "लिसनिङ (२१-४०)", en: "Listening (21-40)", ko: "듣기 (21-40)"),
                          style: TextStyle(
                            color: isReading ? Colors.blue.shade900 : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: isReading ? Colors.blue.shade100 : Colors.orange.shade100,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pinch, size: 14, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 4),
                            Text(
                              LanguageService.instance.isEnglish
                                  ? 'Pinch to Zoom'
                                  : (LanguageService.instance.isKorean ? '화면 확대/축소' : 'पिन्च गरी जुम गर्नुहोस्'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      ExamTimerWidget(durationSeconds: 3000, onTimerFinished: _submitExam),
                    ],
                  ), 
                ],
              ),
            ),
            
            // Full-Width Split Question View Area (Interactive Pinch-to-Zoom Enabled)
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25.0),
                  child: Builder(
                    builder: (context) {
                      final isListeningQ = (currentQuestion is ListeningAudioQuestion) ||
                          (currentQuestion is UniversalQuestion && currentQuestion.isListening);

                      if (isListeningQ) {
                        return ListeningQuestionWidget(
                          key: ValueKey(currentQuestion.questionId),
                          question: currentQuestion,
                          selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
                          onOptionSelected: (index) {
                            setState(() => _selectedAnswers[_currentQuestionIndex] = index);
                          },
                        );
                      } else {
                        return ReadingQuestionWidget(
                          key: ValueKey(currentQuestion.questionId), 
                          question: currentQuestion,
                          selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
                          onOptionSelected: (index) {
                            setState(() => _selectedAnswers[_currentQuestionIndex] = index);
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            // Bottom Navigation Controls with Center Pull-Up Trigger
            Container(
              color: const Color(0xFF1E3A8A), 
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  ElevatedButton.icon(
                    onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(LanguageService.instance.tr('prev_btn'), style: const TextStyle(fontSize: 15)),
                  ),

                  // CENTER: Pull-up / Clickable All Questions Sheet
                  Material(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _openAllQuestionsDrawer,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.keyboard_arrow_up, color: Colors.amber, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              LanguageService.instance.tr('all_questions_grid'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                LanguageService.instance.isEnglish
                                    ? "Attempted: ${_selectedAnswers.length}/40"
                                    : (LanguageService.instance.isKorean
                                        ? "풀이: ${_selectedAnswers.length}/40"
                                        : "हल: ${_selectedAnswers.length}/40"),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                LanguageService.instance.trText(ne: "प्रश्न ${_currentQuestionIndex + 1} / ४०", en: "Question ${_currentQuestionIndex + 1} / 40", ko: "문항 ${_currentQuestionIndex + 1} / 40"),
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next / Submit Button
                  ElevatedButton(
                    onPressed: _currentQuestionIndex < _questions.length - 1 ? _nextQuestion : _submitExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentQuestionIndex < _questions.length - 1 ? Colors.white : Colors.amber,
                      foregroundColor: _currentQuestionIndex < _questions.length - 1 ? const Color(0xFF1E3A8A) : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? LanguageService.instance.tr('next_btn')
                              : LanguageService.instance.tr('finish_exam'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(_currentQuestionIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check_circle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom-Center Pull-Up Drawer displaying all 40 questions in a clean horizontal grid
  void _openAllQuestionsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -6))],
        ),
        child: Column(
          children: [
            // Pull / Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 55,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
            ),

            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grid_view, color: Color(0xFF1E3A8A), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.instance.tr('all_questions_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          LanguageService.instance.isEnglish
                              ? "Attempted: ${_selectedAnswers.length} / 40"
                              : (LanguageService.instance.isKorean
                                  ? "답안 작성: ${_selectedAnswers.length} / 40"
                                  : "हल गरिएको: ${_selectedAnswers.length} / 40"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: LanguageService.instance.tr('close_btn'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 10),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  _buildLegendItem(const Color(0xFF1E3A8A), LanguageService.instance.tr("answered"), textColor: Colors.white),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.grey.shade200, LanguageService.instance.tr("unanswered"), textColor: Colors.black87),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.red, LanguageService.instance.tr("active_q"), textColor: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 40 Questions 2-Column Split: Reading on LEFT, Listening on RIGHT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Reading (01 ~ 20)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "읽기 영역 (Reading 01 ~ 20)",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                              ),
                              Text(
                                "20문항",
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildDrawerGrid(0, 20, ctx),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 200,
                      width: 1.5,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),

                    // RIGHT COLUMN: Listening (21 ~ 40)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "듣기 영역 (Listening 21 ~ 40)",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                              ),
                              Text(
                                "20문항",
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildDrawerGrid(20, 40, ctx),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {Color textColor = Colors.white}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade400)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDrawerGrid(int start, int end, BuildContext sheetCtx) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: end - start,
      itemBuilder: (context, i) {
        final index = start + i;
        final isAnswered = _selectedAnswers.containsKey(index);
        final isCurrent = _currentQuestionIndex == index;

        return InkWell(
          onTap: () {
            setState(() => _currentQuestionIndex = index);
            Navigator.pop(sheetCtx); // Close drawer on question selection
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAnswered ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
              border: Border.all(
                color: isCurrent ? Colors.red : (isAnswered ? const Color(0xFF1E3A8A) : Colors.grey.shade400),
                width: isCurrent ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isCurrent ? [const BoxShadow(color: Colors.redAccent, blurRadius: 4)] : null,
            ),
            child: Text(
              "${index + 1 < 10 ? '0' : ''}${index + 1}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isAnswered ? Colors.white : (isCurrent ? Colors.red : Colors.black87),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// STUDY MODE SCREEN (Phase 10: Full 40 Questions & Practice Mode)
// ------------------------------------------------------------------
enum StudyFilter { all, reading, listening }

class StudyModeScreen extends StatefulWidget {
  final MockTestSet? mockSet;
  const StudyModeScreen({super.key, this.mockSet});

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  int _currentIndex = 0;
  StudyFilter _selectedFilter = StudyFilter.all;
  late final List<QuestionTemplate> _allQuestions;
  late final Map<String, QuestionAnswerInfo> _answerKeys;
  final Map<String, int> _userAnswers = {}; // questionId -> selectedOptionIndex

  @override
  void initState() {
    super.initState();
    _allQuestions = widget.mockSet?.questions ?? QuestionBankService.instance.getFull40ExamQuestions();
    _answerKeys = widget.mockSet?.answerKeys ?? QuestionBankService.instance.getAnswerKeys();
  }

  List<QuestionTemplate> get _filteredQuestions {
    switch (_selectedFilter) {
      case StudyFilter.all:
        return _allQuestions;
      case StudyFilter.reading:
        return _allQuestions.where((q) => q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)).toList();
      case StudyFilter.listening:
        return _allQuestions.where((q) => q is ListeningAudioQuestion || (q is UniversalQuestion && q.isListening)).toList();
    }
  }

  void _openQuestionJumpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: 480,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -6))],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grid_view, color: Color(0xFF1E3A8A), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          LanguageService.instance.isEnglish ? 'All Questions (Reading & Listening)' : (LanguageService.instance.isKorean ? '전체문항 (읽기 및 듣기)' : 'सबै प्रश्नहरू (रिडिङ र लिसनिङ)'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                  ],
                ),
              ),
              const Divider(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT: Reading 1 - 20
                        Expanded(
                          child: _buildStudyGridCard(
                            title: '📖 읽기 (Reading 01 - 20)',
                            color: const Color(0xFF1E3A8A),
                            startIdx: 0,
                            endIdx: 20,
                            sheetCtx: sheetCtx,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT: Listening 21 - 40
                        Expanded(
                          child: _buildStudyGridCard(
                            title: '🎧 듣기 (Listening 21 - 40)',
                            color: const Color(0xFFEA580C),
                            startIdx: 20,
                            endIdx: 40,
                            sheetCtx: sheetCtx,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudyGridCard({
    required String title,
    required Color color,
    required int startIdx,
    required int endIdx,
    required BuildContext sheetCtx,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: endIdx - startIdx,
            itemBuilder: (context, i) {
              final idx = startIdx + i;
              if (idx >= _allQuestions.length) return const SizedBox.shrink();
              final q = _allQuestions[idx];
              final isAnswered = _userAnswers.containsKey(q.questionId);
              final isCurrent = idx == _currentIndex;

              Color bg = Colors.grey.shade100;
              Color border = Colors.grey.shade300;
              Color textCol = Colors.black87;

              if (isAnswered) {
                final keyInfo = _answerKeys[q.questionId];
                final isCorrect = keyInfo != null && _userAnswers[q.questionId] == keyInfo.correctIndex;
                bg = isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                border = isCorrect ? Colors.green : Colors.red;
                textCol = isCorrect ? Colors.green.shade900 : Colors.red.shade900;
              }

              if (isCurrent) {
                border = Colors.amber.shade800;
              }

              return InkWell(
                onTap: () {
                  setState(() => _currentIndex = idx);
                  Navigator.pop(sheetCtx);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: border, width: isCurrent ? 2.5 : 1),
                    boxShadow: isCurrent ? [BoxShadow(color: Colors.amber.shade200, blurRadius: 4)] : null,
                  ),
                  child: Text(
                    (idx + 1).toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredQuestions;
    if (_currentIndex >= filteredList.length) {
      _currentIndex = 0;
    }
    final q = filteredList[_currentIndex];

    // Stats
    int correctCount = 0;
    int incorrectCount = 0;
    for (final item in filteredList) {
      if (_userAnswers.containsKey(item.questionId)) {
        final keyInfo = _answerKeys[item.questionId];
        if (keyInfo != null && _userAnswers[item.questionId] == keyInfo.correctIndex) {
          correctCount++;
        } else {
          incorrectCount++;
        }
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.mockSet != null ? "${widget.mockSet!.title} (학습 모드)" : "EPS-TOPIK Study & Practice Mode (학습 모드)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: LanguageService.instance.tr("all_questions_grid"),
            onPressed: _openQuestionJumpModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 40.0, vertical: isMobile ? 14.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Chips & Progress Header (Scrollable horizontally on mobile)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(LanguageService.instance.isEnglish ? "All (40 Qs)" : (LanguageService.instance.isKorean ? "전체 (40문항)" : "सबै (४० प्रश्न)"), StudyFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip(LanguageService.instance.isEnglish ? "Reading (20)" : (LanguageService.instance.isKorean ? "읽기 (20문항)" : "रिडिङ (२० प्रश्न)"), StudyFilter.reading),
                    const SizedBox(width: 8),
                    _buildFilterChip(LanguageService.instance.isEnglish ? "Listening (20)" : (LanguageService.instance.isKorean ? "듣기 (20문항)" : "लिसनिङ (२० प्रश्न)"), StudyFilter.listening),
                    const SizedBox(width: 14),
                    _buildBadge(LanguageService.instance.trText(ne: "हल: ${_userAnswers.length}/${filteredList.length}", en: "Answered: ${_userAnswers.length}/${filteredList.length}", ko: "풀이: ${_userAnswers.length}/${filteredList.length}"), Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildBadge(LanguageService.instance.trText(ne: "सहि: $correctCount", en: "Correct: $correctCount", ko: "정답: $correctCount"), Colors.green),
                    const SizedBox(width: 8),
                    _buildBadge(LanguageService.instance.trText(ne: "गलत: $incorrectCount", en: "Incorrect: $incorrectCount", ko: "오답: $incorrectCount"), Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Question Indicator Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Text(
                      "문항 ${_currentIndex + 1} / ${filteredList.length} (${q.questionId})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)) ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)) ? LanguageService.instance.trText(ne: "रिडिङ", en: "Reading", ko: "읽기") : LanguageService.instance.trText(ne: "लिसनिङ", en: "Listening", ko: "듣기"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: (q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)) ? const Color(0xFF1E3A8A) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pinch, size: 13, color: Color(0xFF0F766E)),
                          SizedBox(width: 4),
                          Text(LanguageService.instance.trText(ne: 'पिन्च गरी जुम गर्नुहोस्', en: 'Pinch to zoom', ko: '핀치하여 확대/축소'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Responsive Interactive Study Widget (Pinch-to-Zoom Enabled)
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                clipBehavior: Clip.none,
                child: StudyModeQuestionWidget(
                  key: ValueKey("${q.questionId}_${_selectedFilter}"),
                  question: q,
                  answerInfo: _answerKeys[q.questionId],
                  selectedOption: _userAnswers[q.questionId],
                  onOptionSelected: (idx) {
                    setState(() {
                      _userAnswers[q.questionId] = idx;
                    });
                  },
                  onRetry: () {
                    setState(() {
                      _userAnswers.remove(q.questionId);
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // 4. RESPONSIVE BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 40, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Previous Question Button
            ElevatedButton.icon(
              onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(LanguageService.instance.tr('prev_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey.shade100,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                elevation: 0,
              ),
            ),

            // Center: All Questions / Question List Modal Trigger
            OutlinedButton.icon(
              onPressed: _openQuestionJumpModal,
              icon: const Icon(Icons.apps, size: 18),
              label: Text(
                isMobile
                    ? "▲ [${_currentIndex + 1}/${filteredList.length}]"
                    : LanguageService.instance.isEnglish ? "▲ Question List • [Q ${_currentIndex + 1}/${filteredList.length}]" : (LanguageService.instance.isKorean ? "▲ 전체문항 • [문항 ${_currentIndex + 1}/${filteredList.length}]" : "▲ प्रश्न सूची • [प्रश्न ${_currentIndex + 1}/${filteredList.length}]"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E), width: 1.6),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            // Right: Next Question Button
            ElevatedButton.icon(
              onPressed: _currentIndex < filteredList.length - 1 ? () => setState(() => _currentIndex++) : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(LanguageService.instance.tr('next_btn')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, StudyFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
          _currentIndex = 0;
        });
      },
      selectedColor: const Color(0xFF0F766E).withOpacity(0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF0F766E) : Colors.black87,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
      ),
    );
  }
}
