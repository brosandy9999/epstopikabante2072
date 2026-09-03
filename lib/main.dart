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
import 'features/settings/settings_screen.dart';
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

  // 3. Restore saved users / credentials
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
  void _showAccountDetailsModal(BuildContext context, AppUser s) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.manage_accounts, color: Color(0xFF1E3A8A), size: 24),
                          SizedBox(width: 8),
                          Text(
                            "मेरो खाता तथा सेटिङहरू (Account)",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Student Avatar & Identity Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Text(
                            s.name.isNotEmpty ? s.name[0] : 'S',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "दर्ता नं: ${s.registrationNo ?? '01234567'}  •  ID: ${s.username}",
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(s.batch.split(' ')[0] + ' ' + s.batch.split(' ')[1], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('सक्रिय खाता (Active)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Allowed Sector Info
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.factory, size: 16, color: Color(0xFF1E3A8A))),
                    title: const Text("औद्योगिक क्षेत्र (Sector)", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: Text(s.sector, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),

                  // Language Selection
                  const Text("🌐 भाषा चयन गर्नुहोस् (Language):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildLangChoiceChip('नेपाली', AppLanguage.nepali),
                      _buildLangChoiceChip('English', AppLanguage.english),
                      _buildLangChoiceChip('한국어', AppLanguage.korean),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions: Password, Preferences, Logout
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                          icon: const Icon(Icons.lock_reset, size: 16),
                          label: const Text("पासवर्ड परिवर्तन", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text("थप प्राथमिकताहरू", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmUserLogout(context);
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text("खाताबाट लगआउट गर्नुहोस् (Logout)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _currentTab = 4; // Start on Dashboard by default, or tap any tab
  int _gridColumnsOverride = 0; // 0 = Auto, 1 = Single column, 2 = 2 columns, 3 = 3 columns
  double _uiScale = 1.0;
  double _pinchBaseScale = 1.0;
  bool _directScrollZoomEnabled = false;

  List<String> _getTabTitles() => [
    LanguageService.instance.tr('tab_profile'),
    LanguageService.instance.tr('tab_exam'),
    LanguageService.instance.tr('tab_study'),
    LanguageService.instance.tr('tab_result'),
    LanguageService.instance.tr('tab_dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        final s = widget.student ?? AuthService.instance.students.first;
        final allSets = QuestionBankService.instance.getAllMockSets();
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 850;
        final tabTitles = _getTabTitles();

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
                        'नेपाल-कोरिया भाषा अध्ययन तथा UBT परीक्षा केन्द्र • ${s.name}',
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
                      tooltip: 'जुम घटाउनुहोस्',
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
                      tooltip: 'जुम बढाउनुहोस् (१ स्तम्भ)',
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
                tooltip: '📦 इन-एप अफलाइन भण्डारण',
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
                    label: const Text('सुपर एडमिन पोर्टल', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                tooltip: 'सेटिङ (भाषा, पासवर्ड, प्रोफाइल फोटो)',
                onPressed: () => showUniversalSettingsDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'लगआउट',
                onPressed: () {
                  AuthService.instance.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timer_outlined),
                activeIcon: Icon(Icons.timer_rounded),
                label: 'UBT Exam',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_outlined),
                activeIcon: Icon(Icons.auto_stories_rounded),
                label: 'Study Practice',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_special_outlined),
                activeIcon: Icon(Icons.folder_special_rounded),
                label: 'Resource',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radio_button_checked, size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Text("आजको दैनिक लाइभ परीक्षा (TODAY'S LIVE EXAM)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11)),
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
                    _buildLiveBadge(Icons.quiz, '४० प्रश्नहरू (२० R + २० L)'),
                    _buildLiveBadge(Icons.assignment_turned_in, 'पूर्णाङ्क १०० / उत्तीर्णाङ्क ५०'),
                    _buildLiveBadge(Icons.security, 'एन्टी-चीट लक'),
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
                            label: const Text('लाइभ परीक्षा सुरु गर्नुहोस् (Start Exam)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
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
                                content: Text(isDownloaded ? 'अफलाइन क्यासबाट हटाइयो।' : '✅ लाइभ परीक्षा इन-एप अफलाइन प्रयोगका लागि सुरक्षित गरियो!'),
                                backgroundColor: isDownloaded ? Colors.blueGrey : Colors.teal,
                              ),
                            );
                          },
                          icon: Icon(isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 18, color: Colors.amber),
                          label: Text(
                            isDownloaded ? '✅ अफलाइन तयार (In-App)' : '⬇️ अफलाइन सेभ गर्नुहोस्',
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
            title: const Row(
              children: [
                Icon(Icons.offline_pin, color: Color(0xFF0F766E), size: 26),
                SizedBox(width: 10),
                Text('सुरक्षित इन-एप अफलाइन भण्डारण', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Color(0xFF1E3A8A), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '🔒 यहाँ डाउनलोड गरिएका सबै परीक्षा सेटहरू र पुस्तकहरू एप भित्रै सुरक्षित रहन्छन्। इन्टरनेट नहुँदा पनि तपाईं एपमै बसेर १००% अफलाइन परीक्षा दिन सक्नुहुन्छ। यो बाहिर एक्सपोर्ट हुँदैन।',
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
                              const Text('अफलाइन परीक्षा सेटहरू', style: TextStyle(fontSize: 11, color: Colors.black54)),
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
                              const Text('अफलाइन पुस्तकहरू', style: TextStyle(fontSize: 11, color: Colors.black54)),
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
                        const SnackBar(content: Text('✅ सबै परीक्षा सेटहरू अफलाइन अध्ययनका लागि डाउनलोड भए!'), backgroundColor: Colors.teal),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('⚡ सबै परीक्षा सेटहरू १-क्लिकमा डाउनलोड गर्नुहोस्'),
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
                        const SnackBar(content: Text('✅ सबै पुस्तकहरू अफलाइन अध्ययनका लागि डाउनलोड भए!'), backgroundColor: Colors.teal),
                      );
                    },
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('⚡ सबै पुस्तकहरू १-क्लिकमा डाउनलोड गर्नुहोस्'),
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
                        const SnackBar(content: Text('अफलाइन क्यास पूर्ण रूपमा खाली गरियो।')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('🗑️ अफलाइन क्यास खाली गर्नुहोस् (Clear Cache)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('बन्द गर्नुहोस्'),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 अध्ययन रिसोर्स केन्द्र (Resources - Book • Meaning • Grammar • Flashcard • Video)',
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
              child: const Text('खोल्नुहोस्'),
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
            child: const Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("실전 시험 모드 (Official UBT Exam Mode)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("४० प्रश्नहरू • ५० मिनेट • पूर्णाङ्क १०० • उत्तीर्णाङ्क ५० • कडा एन्टी-चीट नियम",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("परीक्षा दिन चाहेको सेट छान्नुहोस्:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        label: const Text("परीक्षा सुरु"),
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
            child: const Row(
              children: [
                Icon(Icons.auto_stories, color: Colors.white, size: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("अध्ययन तथा अभ्यास मोड (Study & Practice Mode)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("तत्काल सहि/गलत उत्तर • नेपालीमा विस्तृत व्याख्या • कोरियाली अडियो संवाद",
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
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📚 EPS-TOPIK अध्ययन केन्द्र (Study Hub)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('पाठ्यपुस्तक १ र २ • व्याकरण नियम • आवश्यक मिनिङ बैंक • सूचना', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("अभ्यास गर्न चाहेको सेट छान्नुहोस्:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        label: const Text("अभ्यास सुरु"),
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
                      const Text("मेरो विगत परीक्षा इतिहास तथा कमजोरी समीक्षा",
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🧠 AI कमजोरी विश्लेषण तथा स्मार्ट अभ्यास',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'कुन विषयमा गल्ती भयो हेर्नुहोस् र कमजोर प्रश्नहरू मात्र अभ्यास गर्नुहोस्',
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
              child: const Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("अहिलेसम्म कुनै परीक्षा दिनुभएको छैन।", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text("परीक्षा हलबाट कुनै पनि सेट सुरु गर्नुहोस्!", style: TextStyle(color: Colors.black54)),
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
                                a.isPassed ? "합격 (Pass)" : "불합격 (Fail)",
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
                              label: const Text("📄 आधिकारिक स्कोरकार्ड (PDF / Print)"),
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
                              label: const Text("🔍 कमजोरी समीक्षा (Review Mistakes)"),
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

  Widget _buildLangChoiceChip(String label, AppLanguage lang) {
    final currentLang = LanguageService.instance.currentLanguage;
    final isSel = currentLang == lang;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      selected: isSel,
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) {
        setState(() {
          LanguageService.instance.setLanguage(lang);
        });
      },
    );
  }

  void _confirmUserLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text('लगआउट पुष्टि गर्नुहोस्'),
          ],
        ),
        content: const Text('के तपाईं आफ्नो खाताबाट लगआउट गर्न निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.instance.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('हो, लगआउट गर्नुहोस्'),
          ),
        ],
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
                        const Text(
                          "환영합니다! (स्वागत छ)",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_edu, size: 14, color: Color(0xFF1E3A8A)),
                              SizedBox(width: 4),
                              Text("विगत नतिजा तथा समीक्षा",
                                  style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold)),
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
                      const Expanded(
                        child: Text(
                          "EPS-TOPIK बहु Mock Test सेटहरू (Available Test Sets)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "सेट १ देखि ५ सम्मका आधिकारिक प्रश्न सेटहरू — जुनसुकै सेट छानेर परीक्षा वा अभ्यास सुरु गर्नुहोस्:",
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
                label: const Text("सबै सेट पोर्टल"),
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
                        'स्क्रीन जुम र अटोमेटिक ग्रिड (Zoom: ${(_uiScale * 100).round()}%)',
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
                                _directScrollZoomEnabled ? '🖱️ माउस स्क्रल जुम: ON' : '🖱️ माउस स्क्रल जुम (Ctrl + Wheel)',
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
                      _buildGridColChip(0, '🔄 अटो ग्रिड'),
                      _buildGridColChip(1, '🔲 १ स्तम्भ (एउटा मात्र ठूलो कार्ड)'),
                      _buildGridColChip(2, '▦ २ स्तम्भ'),
                      if (!isMobile) _buildGridColChip(3, '▤ ३ स्तम्भ'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Color(0xFF1E3A8A), size: 22),
                    tooltip: 'जुम घटाउनुहोस् (Zoom Out)',
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
                    tooltip: 'जुम बढाउनुहोस् (Zoom In to Single Card)',
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
                    label: const Text('रिसेट १००%', style: TextStyle(fontSize: 11)),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.casino, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '🎲 अनन्त र्‍यान्डम परीक्षा (Random Blueprint Exam)',
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
                child: const Text('४० नयाँ प्रश्नहरू', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'असीमित नयाँ मोडल सेट (Infinite Unique Mock Tests)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'सयौं प्रश्नहरूबाट हरेक पटक स्वतः आधिकारिक EPS-TOPIK ब्लुप्रिन्ट अनुसार नयाँ २० रिडिङ र २० लिसनिङ प्रश्नहरू छानेर अनन्त परीक्षा सेट तयार हुन्छ।',
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
              label: const Text(
                '🎲 नयाँ र्‍यान्डम परीक्षा सुरु गर्नुहोस् (Start Random Exam)',
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
                    child: const Text(
                      "미응시 (नयाँ सेट)",
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
            const Row(
              children: [
                Icon(Icons.quiz_outlined, size: 14, color: Colors.blueGrey),
                SizedBox(width: 4),
                Text("४० प्रश्न (२० Reading + २० Listening)", style: TextStyle(fontSize: 11, color: Colors.black87)),
                Spacer(),
                Icon(Icons.timer_outlined, size: 14, color: Colors.blueGrey),
                SizedBox(width: 4),
                Text("५० मिनेट", style: TextStyle(fontSize: 11, color: Colors.black87)),
                Spacer(),
                Icon(Icons.star_outline, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text("पूर्णाङ्क १०० (उत्तीर्णाङ्क ५०)", style: TextStyle(fontSize: 11, color: Colors.black87)),
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
                              ? "स्टार्ट Exam (Strict)"
                              : "स्टार्ट Exam (Study)",
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
                            const SnackBar(content: Text('अफलाइन क्यासबाट सेट हटाइयो।')),
                          );
                        } else {
                          await OfflineDownloadService.instance.downloadSet(set);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ परीक्षा सेट इन-एप अफलाइन प्रयोगका लागि सुरक्षित गरियो!'), backgroundColor: Colors.teal),
                          );
                        }
                        setState(() {});
                      },
                      icon: Icon(isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 18),
                      label: Text(isDownloaded ? '✅ अफलाइन' : '⬇️ डाउनलोड', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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

  // -----------------------------------------------------------------
  // 3. MODE OVERVIEW CARDS (Exam Mode & Study Mode)
  // -----------------------------------------------------------------
  Widget _buildModesSection(AppUser s, bool isMobile) {
    final examCard = Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.computer, size: 28, color: Color(0xFF1E3A8A)),
                ),
                Chip(
                  label: const Text("실전 모의고사", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "UBT Real Exam Mode",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),
            const Text(
              "वास्तविक HRDK परीक्षा जस्तै ५० मिनेटको टाइमिङ, ४० वटा प्रश्न (२० Reading + २० Listening), अडियो लक र Strict Anti-cheat सहितको परीक्षा हल।",
              style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 13),
            ),
            const Divider(height: 28),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Text("कुल प्रश्न: ४० वटा (पूर्णाङ्क १००, उत्तीर्णाङ्क ५०)", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text("समय: ५० मिनेट (काउन्टडाउन र Auto-Submit)", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text("सेक्युरिटी: Full Screen र Audio Play limit", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  final firstSet = QuestionBankService.instance.getAllMockSets().first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RealUbtExamHallScreen(student: s, mockSet: firstSet)),
                  ).then((_) => setState(() {}));
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("पहिलो सेटबाट सुरु गर्नुहोस् (Start Exam)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );

    final studyCard = Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.school, size: 28, color: Colors.teal),
                ),
                Chip(
                  label: const Text("연습 / 학습 모드", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: Colors.teal.shade50,
                  labelStyle: TextStyle(color: Colors.teal.shade900),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Study & Practice Mode",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 8),
            const Text(
              "परीक्षाको दबाब बिना सिक्ने मोड। प्रत्येक प्रश्नको उत्तर छान्नेबित्तिकै सही/गलत थाहा हुनेछ र किन सही भयो भनेर नेपाली/कोरियनमा व्याख्या पढ्न पाइनेछ।",
              style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 13),
            ),
            const Divider(height: 28),
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.teal, size: 16),
                SizedBox(width: 8),
                Text("तत्काल उत्तर र व्याख्या (Instant Explanations)", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.hourglass_disabled, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text("समयको कुनै दबाब छैन (Self-paced Learning)", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.auto_stories_outlined, color: Colors.purple, size: 16),
                SizedBox(width: 8),
                Text("शब्दावली र व्याकरण सुधार गर्ने उत्तम अभ्यास", style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  final firstSet = QuestionBankService.instance.getAllMockSets().first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StudyModeScreen(mockSet: firstSet)),
                  ).then((_) => setState(() {}));
                },
                icon: const Icon(Icons.menu_book),
                label: const Text("पहिलो सेट अभ्यास गर्नुहोस् (Start Study)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          examCard,
          const SizedBox(height: 20),
          studyCard,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: examCard),
          const SizedBox(width: 25),
          Expanded(child: studyCard),
        ],
      );
    }
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
        title: const Text("परीक्षाबाट बाहिरिन चाहनुहुन्छ?"),
        content: const Text("यदि तपाईं अहिले बाहिरिनुभयो भने तपाईंको चालु परीक्षा बीचमै रोकिनेछ। के तपाईं निश्चित हुनुहुन्छ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("परीक्षा जारी राख्नुहोस्")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Pop back to Student Portal
            },
            child: const Text("बाहिरिनुहोस् (Exit)"),
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
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF1E3A8A), size: 28),
            SizedBox(width: 10),
            Text("परीक्षा सबमिट गर्नुहुन्छ?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("विद्यार्थी: ${widget.student?.name ?? 'राम बहादुर'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("दर्ता नम्बर: ${widget.student?.registrationNo ?? '01234567'}"),
            const Divider(height: 20),
            Text("• कुल प्रश्न: $totalQuestions वटा"),
            Text("• हल गरिएका प्रश्न: $attempted वटा", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text("• नछोएका प्रश्न: $unattempted वटा", style: TextStyle(color: unattempted > 0 ? Colors.red : Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              "के तपाईं परीक्षा समाप्त गरी नतिजा कार्ड (Scorecard) हेर्न निश्चित हुनुहुन्छ?",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("परीक्षा जारी राख्नुहोस्"),
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
            child: const Text("सबमिट गर्नुहोस् (View Result)"),
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
                        tooltip: "परीक्षा छोड्नुहोस् (Exit Exam)",
                        onPressed: _confirmExitExam,
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("수험번호: ${widget.student?.registrationNo ?? '01234567'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          Text("성명: ${widget.student?.name ?? 'राम बहादुर'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(width: 25),
                      Chip(
                        label: Text(
                          isReading ? "읽기 (Reading 1-20)" : "듣기 (Listening 21-40)",
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pinch, size: 14, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 4),
                            Text('पिन्च गरी जुम गर्नुहोस् (Pinch to Zoom)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
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
                    label: const Text("이전 (अघिल्लो)", style: TextStyle(fontSize: 15)),
                  ),

                  // CENTER: Pull-up / Clickable All Questions Sheet (खिचेपछि/क्लिक गरेपछि खुल्ने)
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
                            const Text(
                              "전체문항 (सबै प्रश्नहरू)",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "हल: ${_selectedAnswers.length}/40",
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
                                "문항 ${_currentQuestionIndex + 1} / 40",
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
                          _currentQuestionIndex < _questions.length - 1 ? "다음 (पछिल्लो)" : "최종 제출 (सबमिट)", 
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
                      const Text(
                        "전체문항 (सबै ४० प्रश्नहरूको तालिका)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          "हल गरिएको: ${_selectedAnswers.length} / 40",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: "बन्द गर्नुहोस्",
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
                  _buildLegendItem(const Color(0xFF1E3A8A), "हल भइसकेको (Answered)", textColor: Colors.white),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.grey.shade200, "बाँकी (Unanswered)", textColor: Colors.black87),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.red, "हालको प्रश्न (Active)", textColor: Colors.white),
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
                    const Row(
                      children: [
                        Icon(Icons.grid_view, color: Color(0xFF1E3A8A), size: 22),
                        SizedBox(width: 10),
                        Text(
                          '전체문항 (दुई खण्ड ग्रिड: Reading & Listening)',
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
            tooltip: "सबै प्रश्नहरूको ग्रिड",
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
                    _buildFilterChip("전체 (सबै ४०)", StudyFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip("읽기 (Reading २०)", StudyFilter.reading),
                    const SizedBox(width: 8),
                    _buildFilterChip("듣기 (Listening २०)", StudyFilter.listening),
                    const SizedBox(width: 14),
                    _buildBadge("हल: ${_userAnswers.length}/${filteredList.length}", Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildBadge("सहि: $correctCount", Colors.green),
                    const SizedBox(width: 8),
                    _buildBadge("गलत: $incorrectCount", Colors.red),
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
                        (q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)) ? "읽기 (Reading)" : "듣기 (Listening)",
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pinch, size: 13, color: Color(0xFF0F766E)),
                          SizedBox(width: 4),
                          Text('पिन्च गरी जुम गर्नुहोस्', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
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
              label: Text(isMobile ? "अघिल्लो" : "◀ अघिल्लो प्रश्न"),
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
                    : "▲ प्रश्न सूची (सबै प्रश्नहरू) • [문항 ${_currentIndex + 1}/${filteredList.length}]",
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
              label: Text(isMobile ? "अर्को" : "अर्को प्रश्न ▶"),
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
