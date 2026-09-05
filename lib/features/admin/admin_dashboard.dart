import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../settings/universal_settings_dialog.dart';
import 'import_workflow_screen.dart';
import 'user_management_screen.dart';
import 'results_analytics_screen.dart';
import 'admin_study_manager_screen.dart';
import 'admin_question_set_screen.dart';
import 'institute_profile_screen.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/auth_service.dart';

/// Phase 10: Admin Dashboard & Phase 20: User Management
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  List<String> get _menuItems => [
    LanguageService.instance.trText(ne: 'ड्यासबोर्ड', en: 'Dashboard', ko: '대시보드'),
    LanguageService.instance.trText(ne: 'उपलब्ध सेटहरू', en: 'Available Sets', ko: '모의고사 세트'),
    LanguageService.instance.trText(ne: 'नयाँ सेट सिर्जना', en: 'Create Set', ko: '새 세트 생성'),
    LanguageService.instance.trText(ne: 'थोक आयात', en: 'Bulk Import', ko: '일괄 가져오기'),
    LanguageService.instance.trText(ne: 'विद्यार्थी व्यवस्थापन', en: 'Student Management', ko: '수험생 관리'),
    LanguageService.instance.trText(ne: 'नतिजा तथा एनालिटिक्स', en: 'Analytics & Results', ko: '시험 결과 및 통계'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.instance.trText(
                        ne: 'EPS-TOPIK एडमिन पोर्टल',
                        en: 'EPS-TOPIK Admin Portal',
                        ko: 'EPS-TOPIK 관리자 포털',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _menuItems[_selectedIndex],
                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            actions: [
              // Language Switcher in Admin Header
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: AppLanguage.values.map((lang) {
                    final isSel = LanguageService.instance.currentLanguage == lang;
                    return InkWell(
                      onTap: () => LanguageService.instance.setLanguage(lang),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.amber : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${lang.flag} ${lang.code.toUpperCase()}',
                          style: TextStyle(
                            color: isSel ? Colors.black87 : Colors.white,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminStudyManagerScreen()),
                  );
                },
                icon: const Icon(Icons.school, size: 16),
                label: Text(LanguageService.instance.trText(ne: 'अध्ययन सामग्री', en: 'Study Materials', ko: '교재 관리'), style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.apartment),
                tooltip: LanguageService.instance.trText(ne: 'इन्स्टिच्युट प्रोफाइल', en: 'Institute Profile', ko: '학원 프로필'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InstituteProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: LanguageService.instance.trText(ne: 'सेटिङ', en: 'Settings', ko: '설정'),
                onPressed: () => showUniversalSettingsDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: LanguageService.instance.trText(ne: 'लगआउट', en: 'Logout', ko: '로그아웃'),
                onPressed: () => AuthService.confirmAndLogout(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            color: Colors.grey.shade50,
            width: double.infinity,
            alignment: Alignment.topCenter,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildContentArea(),
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.teal.shade800,
            unselectedItemColor: Colors.grey.shade700,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 16,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard_rounded),
                label: LanguageService.instance.trText(ne: 'ड्यासबोर्ड', en: 'Dashboard', ko: '대시보드'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined),
                activeIcon: const Icon(Icons.menu_book_rounded),
                label: LanguageService.instance.trText(ne: 'सेटहरू', en: 'Test Sets', ko: '세트 관리'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_circle_outline_rounded),
                activeIcon: const Icon(Icons.add_circle_rounded),
                label: LanguageService.instance.trText(ne: 'सेट सिर्जना', en: 'Create Set', ko: '세트 생성'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.cloud_upload_outlined),
                activeIcon: const Icon(Icons.cloud_upload_rounded),
                label: LanguageService.instance.trText(ne: 'थोक आयात', en: 'Bulk Import', ko: '가져오기'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline_rounded),
                activeIcon: const Icon(Icons.people_alt_rounded),
                label: LanguageService.instance.trText(ne: 'विद्यार्थी', en: 'Students', ko: '수험생'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.analytics_outlined),
                activeIcon: const Icon(Icons.analytics_rounded),
                label: LanguageService.instance.trText(ne: 'नतिजा', en: 'Results', ko: '결과 통계'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentArea() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return const AdminQuestionSetScreen();
      case 2:
        return const AdminQuestionSetScreen(initialOpenCreate: true);
      case 3:
        return const ImportWorkflowScreen();
      case 4:
        return const UserManagementScreen();
      case 5:
        return const ResultsAnalyticsScreen();
      default:
        return Center(
          child: Text(
            LanguageService.instance.trText(ne: 'तयार हुँदैछ...', en: 'Loading...', ko: '로딩 중...'),
            style: const TextStyle(fontSize: 22, color: Colors.grey),
          ),
        );
    }
  }

  Widget _buildOverviewTab() {
    final questions = QuestionBankService.instance.getFull40ExamQuestions();
    final students = AuthService.instance.students;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LanguageService.instance.trText(
              ne: 'प्रणालीको समग्र अवस्था',
              en: 'System Overview & Live Status',
              ko: '시스템 현황 및 요약',
            ),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
          ),
          const SizedBox(height: 6),
          Text(
            LanguageService.instance.trText(
              ne: 'EPS-TOPIK UBT परीक्षा प्लेटफर्मको समग्र अवस्था तथा तथ्याङ्क',
              en: 'EPS-TOPIK UBT Exam Platform Overall Status & Telemetry',
              ko: 'EPS-TOPIK UBT 시험 플랫폼 전체 현황 및 실시간 데이터',
            ),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard(
                LanguageService.instance.trText(ne: 'कुल प्रश्नहरू', en: 'Total Questions', ko: '총 문항수'),
                '${questions.length} ' + LanguageService.instance.trText(ne: 'वटा', en: 'Items', ko: '문항'),
                LanguageService.instance.trText(ne: '२० Reading + २० Listening', en: '20 Reading + 20 Listening', ko: '읽기 20 + 듣기 20'),
                Icons.quiz,
                Colors.blue,
              ),
              _buildStatCard(
                LanguageService.instance.trText(ne: 'दर्ता भएका विद्यार्थी', en: 'Registered Students', ko: '등록 수험생'),
                '${students.length} ' + LanguageService.instance.trText(ne: 'जना', en: 'Candidates', ko: '명'),
                LanguageService.instance.trText(ne: 'लगइन तथा परीक्षा दिन योग्य', en: 'Active Candidates', ko: '응시 가능 수험생'),
                Icons.people,
                Colors.teal,
              ),
              _buildStatCard(
                LanguageService.instance.trText(ne: 'परीक्षा समय सीमा', en: 'Exam Duration', ko: '시험 시간'),
                '50 ' + LanguageService.instance.trText(ne: 'मिनेट', en: 'Minutes', ko: '분'),
                LanguageService.instance.trText(ne: 'Auto-Submit सहित', en: 'Auto-Submit Included', ko: '자동 제출 포함'),
                Icons.timer,
                Colors.orange,
              ),
              _buildStatCard(
                LanguageService.instance.trText(ne: 'पूर्णाङ्क (Full Marks)', en: 'Full Marks', ko: '총점'),
                '100 ' + LanguageService.instance.trText(ne: 'अङ्क', en: 'Marks', ko: '점'),
                LanguageService.instance.trText(
                  ne: 'प्रत्येक प्रश्न २.५ अङ्क (उत्तीर्णाङ्क ५०)',
                  en: '2.5 pts each (Pass: 50)',
                  ko: '문항당 2.5점 (합격선 50)',
                ),
                Icons.score,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 30),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageService.instance.trText(
                      ne: 'सिस्टममा हाल उपलब्ध मोडहरू',
                      en: 'Available System Modes',
                      ko: '지원 시험 및 학습 모드',
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.red),
                    title: Text(LanguageService.instance.tr('strict_exam_mode')),
                    subtitle: Text(LanguageService.instance.tr('strict_exam_desc')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.school, color: Colors.green),
                    title: Text(LanguageService.instance.tr('study_practice_mode')),
                    subtitle: Text(LanguageService.instance.tr('study_practice_desc')),
                  ),
                  ListTile(
                    leading: const Icon(Icons.vpn_key, color: Colors.teal),
                    title: Text(LanguageService.instance.trText(
                      ne: 'प्रयोगकर्ता व्यवस्थापन तथा पासवर्ड रिसेट',
                      en: 'User Management & Credentials Control',
                      ko: '수험생 계정 관리 및 비밀번호 변경',
                    )),
                    subtitle: Text(LanguageService.instance.trText(
                      ne: 'एडमिन र विद्यार्थीहरूको युजरनेम तथा पासवर्ड परिवर्तन गर्न मिल्ने सुरक्षित सुविधा',
                      en: 'Secure credential updates for both institute admins and students',
                      ko: '관리자 및 수험생 아이디, 비밀번호를 자유롭게 변경 및 관리',
                    )),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String mainValue, String sub, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const SizedBox(height: 6),
          Text(mainValue, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
