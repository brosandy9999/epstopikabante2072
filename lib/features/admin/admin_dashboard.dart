import 'package:flutter/material.dart';
import '../settings/universal_settings_dialog.dart';
import 'question_editor.dart';
import 'import_workflow_screen.dart';
import 'user_management_screen.dart';
import 'results_analytics_screen.dart';
import 'admin_study_manager_screen.dart';
import 'admin_question_set_screen.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/auth_service.dart';
import '../question_engine/question_template.dart';

/// Phase 10: Admin Dashboard (रुल ८६) & Phase 20: User Management
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _menuItems = [
    'Overview (ड्यासबोर्ड)',
    'Question Sets (प्रश्न सेटहरू)',
    'Create 40Q Set (नयाँ सेट निर्माण)',
    'Bulk Import (थोक आयात)',
    'Students & Batches (विद्यार्थी)',
    'Results & Export (नतिजा तथा Excel)',
  ];

  @override
  Widget build(BuildContext context) {
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
                const Text('EPS-TOPIK Admin Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminStudyManagerScreen()),
              );
            },
            icon: const Icon(Icons.school, size: 18),
            label: const Text('📚 सामग्री तथा सूचना व्यवस्थापन'),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "सेटिङ (भाषा, पासवर्ड, प्रोफाइल फोटो)",
            onPressed: () => showUniversalSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              AuthService.instance.logout();
              Navigator.pop(context);
            },
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: "ड्यासबोर्ड",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: "प्रश्न सेटहरू",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: "नयाँ सेट",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            activeIcon: Icon(Icons.cloud_upload_rounded),
            label: "थोक आयात",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: "विद्यार्थी",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: "नतिजा",
          ),
        ],
      ),
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
        return const ImportWorkflowScreen(); // Phase 12: Import PDF/Excel Workflow
      case 4:
        return const UserManagementScreen(); // Phase 20: Admin & Student Credentials
      case 5:
        return const ResultsAnalyticsScreen(); // Phase 18: Student Results & Analytics
      default:
        return Center(
          child: Text(
            ' - तयार हुँदैछ...',
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
          Text('सिस्टम ओभरभ्यू (System Overview)', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
          const SizedBox(height: 6),
          const Text('EPS-TOPIK UBT परीक्षा प्लेटफर्मको समग्र अवस्था', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard('कुल प्रश्नहरू (Total Questions)', '${questions.length} वटा', '२० Reading + २० Listening', Icons.quiz, Colors.blue),
              _buildStatCard('दर्ता भएका विद्यार्थी (Students)', '${students.length} जना', 'लगइन गर्न योग्य', Icons.people, Colors.teal),
              _buildStatCard('परीक्षाको समय (Exam Duration)', '५० मिनेट', 'Auto-Submit सहित', Icons.timer, Colors.orange),
              _buildStatCard('पूर्णाङ्क (Full Marks)', '१०० अङ्क', 'प्रत्येक प्रश्न २.५ अङ्क (उत्तीर्णाङ्क ५०)', Icons.score, Colors.purple),
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
                  Text('सिस्टममा हाल उपलब्ध मोडहरू', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                  const Divider(height: 20),
                  const ListTile(
                    leading: Icon(Icons.lock, color: Colors.red),
                    title: Text('Strict Exam Mode (अफिसियल परीक्षा मोड)'),
                    subtitle: Text('फुल स्क्रिन, ५० मिनेट काउन्टडाउन, अडियो २ पटक मात्र बज्ने, किबोर्ड/माउस ब्लकिङ'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.school, color: Colors.green),
                    title: Text('Study Mode (अभ्यास मोड)'),
                    subtitle: Text('उत्तर छानेपछि तुरुन्तै सही/गलत देखिने र स्पष्ट व्याख्या (Explanation) पढ्न पाइने'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.vpn_key, color: Colors.teal),
                    title: Text('User Management & Password Reset'),
                    subtitle: Text('एडमिन र विद्यार्थीहरूको युजरनेम तथा पासवर्ड परिवर्तन गर्न मिल्ने सुरक्षित सुविधा'),
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
          CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
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

  Widget _buildQuestionBankTab() {
    final questions = QuestionBankService.instance.getFull40ExamQuestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('प्रश्न बैंक (Question Bank -  Questions)', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                const SizedBox(height: 4),
                const Text('आधिकारिक EPS-TOPIK UBT ४० प्रश्नहरूको पूर्ण सूची (२० Reading + २० Listening)', 
                  style: TextStyle(color: Colors.grey)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.add),
              label: const Text('नयाँ प्रश्न थप्नुहोस्'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
            )
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final isReading = q is ReadingTextQuestion;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(isReading ? 'READING (읽기)' : 'LISTENING (듣기)'),
                            backgroundColor: isReading ? Colors.blue.shade50 : Colors.orange.shade50,
                            labelStyle: TextStyle(
                              color: isReading ? Colors.blue.shade900 : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('ID: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(q.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 15,
                        children: () {
                          List<String> opts = [];
                          if (q is ReadingTextQuestion) opts = q.textOptions;
                          if (q is ListeningAudioQuestion) opts = q.textOptions;
                          return List.generate(
                            opts.length,
                            (i) => Text('${i + 1}) ${opts[i]}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          );
                        }(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
