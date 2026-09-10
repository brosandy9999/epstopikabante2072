import '../../core/services/exam_service.dart';
import '../../core/services/study_material_service.dart';
import 'package:flutter/material.dart';
import '../settings/universal_settings_dialog.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/widgets/app_exit_dialog.dart';
import '../admin/admin_question_set_screen.dart';
import '../admin/admin_study_manager_screen.dart';
import '../admin/results_analytics_screen.dart';
import '../authentication/login_screen.dart';
import '../../core/services/language_service.dart';

/// Platform Super Admin Master Dashboard
/// Manages Institutes, Sets Quota, Validity Expiration, Central Study Resources, and Oversight
class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CloudSyncService.instance.pullFromCloud(silent: true).catchError((_) => false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    AuthService.confirmAndLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_tabController.index != 0) {
              _tabController.animateTo(0);
              return;
            }
            await showAppExitConfirmationDialog(context);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 3,
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.workspace_premium, color: Colors.black87, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: 'सुपर एडमिन मास्टर पोर्टल',
                          en: 'Super Admin Master Portal',
                          ko: '최고 관리자 마스터 포털',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'केन्द्रीय नियन्त्रण तथा अनुमति व्यवस्थापन',
                          en: 'Central Control & License Management',
                          ko: '중앙 통제 및 권한 관리',
                        ),
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: LanguageService.instance.trText(ne: 'क्लाउड सिङ्क', en: 'Cloud Sync', ko: '클라우드 동기화'),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LanguageService.instance.trText(ne: 'क्लाउड सिङ्क्रोनाइजेसन सुरु भयो...', en: 'Syncing to Cloud...', ko: '클라우드 동기화 중...')),
                        backgroundColor: const Color(0xFF1E3A8A),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    await CloudSyncService.instance.pushToCloud(silent: false);
                    await CloudSyncService.instance.pullFromCloud(silent: false);
                    if (context.mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LanguageService.instance.trText(ne: '✅ क्लाउड सिङ्क्रोनाइजेसन सम्पन्न भयो!', en: '✅ Cloud sync complete!', ko: '✅ 클라우드 동기화 완료!')),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_sync_rounded, color: Colors.amberAccent),
                  tooltip: LanguageService.instance.trText(
                    ne: 'क्लाउड सिङ्क तथा ब्याकअप',
                    en: 'Cloud Sync & Backup',
                    ko: '클라우드 동기화 및 백업',
                  ),
                  onPressed: () => showUniversalSettingsDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.cleaning_services_rounded, color: Colors.orangeAccent),
                  tooltip: LanguageService.instance.trText(
                    ne: 'डाटाबेस तथा नमुना डाटा व्यवस्थापन (Clean Slate)',
                    en: 'Clean Slate & Database Tools',
                    ko: '데이터베이스 정리 및 관리',
                  ),
                  onPressed: _showCleanDatabaseDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: LanguageService.instance.trText(ne: 'सेटिङ', en: 'Settings', ko: '설정'),
                  onPressed: () => showUniversalSettingsDialog(context),
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.apartment),
                    text: LanguageService.instance.trText(ne: 'इन्स्टिच्युटहरू', en: 'Institutes', ko: '학원 관리'),
                  ),
                  Tab(
                    icon: const Icon(Icons.menu_book),
                    text: LanguageService.instance.trText(ne: 'केन्द्रीय पाठ्यपुस्तक', en: 'Textbooks & Hub', ko: '표준교재 허브'),
                  ),
                  Tab(
                    icon: ListenableBuilder(
                      listenable: QuestionBankService.instance,
                      builder: (context, _) {
                        final pendingCount = QuestionBankService.instance.getPendingApprovalSets().length;
                        if (pendingCount > 0) {
                          return Badge(
                            label: Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                            backgroundColor: Colors.amber.shade900,
                            child: const Icon(Icons.quiz),
                          );
                        }
                        return const Icon(Icons.quiz);
                      },
                    ),
                    text: LanguageService.instance.trText(ne: 'प्रश्न सेट बैंक', en: 'Question Bank', ko: '문제 세트 은행'),
                  ),
                  Tab(
                    icon: const Icon(Icons.insights),
                    text: LanguageService.instance.trText(ne: 'समग्र एनालिटिक्स', en: 'Analytics', ko: '전체 통계'),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInstitutesManagerTab(),
                const AdminStudyManagerScreen(),
                const AdminQuestionSetScreen(),
                const ResultsAnalyticsScreen(),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 1: INSTITUTES, QUOTAS & VALIDITY EXPIRATION
  // -------------------------------------------------------------
  Widget _buildInstitutesManagerTab() {
    final institutes = InstituteService.instance.getAllInstitutes();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Metrics Row
              Row(
                children: [
                  _buildStatCard(
                    LanguageService.instance.trText(ne: 'कुल इन्स्टिच्युट', en: 'Total Institutes', ko: '총 인가 학원'),
                    '${institutes.length} ' + LanguageService.instance.trText(ne: 'वटा', en: 'Units', ko: '개'),
                    Icons.apartment,
                    Colors.blue,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    LanguageService.instance.trText(ne: 'सक्रिय इन्स्टिच्युट', en: 'Active Institutes', ko: '정상 운영 학원'),
                    '${institutes.where((i) => i.isActive && !i.isExpired).length} ' + LanguageService.instance.trText(ne: 'वटा', en: 'Units', ko: '개'),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    LanguageService.instance.trText(ne: 'म्याद सकिएका', en: 'Expired Units', ko: '기간 만료 학원'),
                    '${institutes.where((i) => i.isExpired).length} ' + LanguageService.instance.trText(ne: 'वटा', en: 'Units', ko: '개'),
                    Icons.timer_off,
                    Colors.red,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    LanguageService.instance.trText(ne: 'सुरक्षा तथा कपीराइट', en: 'Copyright Protection', ko: '저작권 보호'),
                    LanguageService.instance.trText(ne: 'सुरक्षित (Active)', en: 'Protected', ko: '보호됨'),
                    Icons.copyright,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action & Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏢 ' + LanguageService.instance.trText(
                          ne: 'दर्ता भएका इन्स्टिच्युटहरूको सूची',
                          en: 'Registered Institutes List',
                          ko: '등록 학원 및 라이선스 목록',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'प्रत्येक इन्स्टिच्युटलाई सेट कोटा, समय सीमा र पहुँच नियन्त्रण गर्नुहोस्',
                          en: 'Manage institute quotas, validity period, and access control',
                          ko: '각 학원별 문제 세트 할당, 유효 기간 및 접근 권한 관리',
                        ),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showCreateInstituteDialog,
                    icon: const Icon(Icons.add_business, size: 18),
                    label: Text(LanguageService.instance.trText(
                      ne: 'नयाँ इन्स्टिच्युट थप्नुहोस्',
                      en: 'Add New Institute',
                      ko: '신규 학원 등록',
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Institutes List
              Expanded(
                child: ListView.separated(
                  itemCount: institutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final inst = institutes[i];
                    final isExpired = inst.isExpired;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isExpired ? Colors.red.shade300 : (inst.isActive ? Colors.grey.shade300 : Colors.amber.shade400),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                  child: const Icon(Icons.apartment, color: Color(0xFF1E3A8A), size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            inst.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isExpired ? Colors.red.shade50 : (inst.isActive ? Colors.green.shade50 : Colors.amber.shade50),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: isExpired ? Colors.red : (inst.isActive ? Colors.green : Colors.amber.shade800)),
                                                ),
                                                child: Text(
                                                  isExpired
                                                      ? LanguageService.instance.statusText('म्याद सकिएको')
                                                      : (inst.isActive ? LanguageService.instance.statusText('सक्रिय') : LanguageService.instance.statusText('रोक्का')),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: isExpired ? Colors.red.shade900 : (inst.isActive ? Colors.green.shade900 : Colors.amber.shade900),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Switch(
                                                value: inst.isActive,
                                                activeColor: Colors.green,
                                                onChanged: (_) {
                                                  setState(() {
                                                    InstituteService.instance.toggleInstituteActive(inst.id);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${LanguageService.instance.trText(ne: "कोड", en: "Code", ko: "코드")}: ${inst.code} • ${LanguageService.instance.trText(ne: "फोन", en: "Phone", ko: "전화")}: ${inst.phone} • ${LanguageService.instance.trText(ne: "ठेगाना", en: "Address", ko: "주소")}: ${inst.address}',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        inst.aboutUs,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Subscription & Quotas Control Row
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Sets Quota Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.quiz, size: 14, color: Color(0xFF1E3A8A)),
                                      const SizedBox(width: 6),
                                      Text(
                                        LanguageService.instance.trText(
                                          ne: 'सेट कोटा: ${inst.allowedSetsQuota} वटा',
                                          en: 'Set Quota: ${inst.allowedSetsQuota}',
                                          ko: '세트 할당: ${inst.allowedSetsQuota}개',
                                        ),
                                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                // Validity Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isExpired ? Colors.red.shade50 : Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_month, size: 14, color: isExpired ? Colors.red : const Color(0xFF0F766E)),
                                      const SizedBox(width: 6),
                                      Text(
                                        isExpired
                                            ? LanguageService.instance.trText(ne: 'म्याद समाप्त', en: 'Expired', ko: '기간 만료')
                                            : LanguageService.instance.trText(
                                                ne: 'म्याद: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day} (बाँकी ${inst.daysRemaining} दिन)',
                                                en: 'Valid: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day} (${inst.daysRemaining}d left)',
                                                ko: '유효: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day} (${inst.daysRemaining}일 남음)',
                                              ),
                                        style: TextStyle(color: isExpired ? Colors.red.shade900 : Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                // Students Limit Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.group, size: 14, color: Colors.purple),
                                      const SizedBox(width: 6),
                                      Text(
                                        LanguageService.instance.trText(
                                          ne: 'विद्यार्थी सीमा: ${inst.maxStudentsQuota} जना',
                                          en: 'Student Limit: ${inst.maxStudentsQuota}',
                                          ko: '수험생 정원: ${inst.maxStudentsQuota}명',
                                        ),
                                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Assign Sets Button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showAssignSetsToInstituteDialog(inst),
                                  icon: const Icon(Icons.checklist_rounded, size: 14),
                                  label: Text(LanguageService.instance.trText(
                                    ne: '🎯 सेट तोक्नुहोस् (${inst.assignedSetIds.length})',
                                    en: '🎯 Assign Sets (${inst.assignedSetIds.length})',
                                    ko: '🎯 세트 배정 (${inst.assignedSetIds.length})',
                                  )),
                                ),
                                const SizedBox(width: 6),
                                // Change Quota Button
                                OutlinedButton.icon(
                                  onPressed: () => _showChangeQuotaDialog(inst),
                                  icon: const Icon(Icons.tune, size: 14),
                                  label: Text(LanguageService.instance.trText(ne: 'कोटा बदल्नुहोस्', en: 'Edit Quota', ko: '쿼터 설정')),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                const SizedBox(width: 6),
                                // Extend Validity Button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showExtendValidityDialog(inst),
                                  icon: const Icon(Icons.more_time, size: 14),
                                  label: Text(LanguageService.instance.trText(ne: '⏳ म्याद थप', en: '⏳ Extend Validity', ko: '⏳ 기간 연장')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOGS: CREATE INSTITUTE, EXTEND VALIDITY, CHANGE QUOTA
  // -------------------------------------------------------------
  void _showCreateInstituteDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final adminUserCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController(text: 'admin123');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    int quota = 5;
    int validityMonths = 6;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_business, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(LanguageService.instance.trText(
                ne: 'नयाँ इन्स्टिच्युट दर्ता गर्नुहोस्',
                en: 'Register New Institute',
                ko: '신규 학원 등록',
              )),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'इन्स्टिच्युटको पूरा नाम', en: 'Institute Full Name', ko: '학원 정식 명칭'),
                      hintText: LanguageService.instance.trText(ne: 'जस्तै: एभरेष्ट कोरियन इन्स्टिच्युट', en: 'e.g. Everest Korean Institute', ko: '예: 에베레스트 한국어학원'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'इन्स्टिच्युट कोड', en: 'Institute Code', ko: '학원 코드'),
                            hintText: 'EVEREST_01',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'सम्पर्क फोन', en: 'Contact Phone', ko: '연락처'),
                            hintText: '9851000000',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'ठेगाना', en: 'Address', ko: '주소'),
                      hintText: LanguageService.instance.trText(ne: 'जस्तै: पुतलीसडक, काठमाडौं', en: 'e.g. Putalisadak, Kathmandu', ko: '예: 네팔 카트만두'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '👤 ' + LanguageService.instance.trText(
                      ne: 'इन्स्टिच्युट एडमिन लगइन खाता:',
                      en: 'Institute Admin Login Account:',
                      ko: '학원 관리자 로그인 계정:',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: adminUserCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'एडमिन Username', en: 'Admin Username', ko: '관리자 아이디'),
                            hintText: 'everest_admin',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: adminPassCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'पासवर्ड', en: 'Password', ko: '비밀번호'),
                            hintText: 'admin123',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚙️ ' + LanguageService.instance.trText(
                      ne: 'कोटा तथा समय सीमा:',
                      en: 'Quota & Validity Settings:',
                      ko: '할당 쿼터 및 유효기간 설정:',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: quota,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'प्रश्न सेट कोटा', en: 'Test Sets Quota', ko: '모의고사 세트 쿼터'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: 3, child: Text('3 ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트'))),
                            DropdownMenuItem(value: 5, child: Text('5 ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트'))),
                            DropdownMenuItem(value: 10, child: Text('10 ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트'))),
                            DropdownMenuItem(value: 20, child: Text('20 ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트'))),
                            DropdownMenuItem(value: 999, child: Text(LanguageService.instance.trText(ne: 'असीमित (Unlimited)', en: 'Unlimited', ko: '무제한'))),
                          ],
                          onChanged: (val) => setDialogState(() => quota = val ?? 5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: validityMonths,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'म्याद अवधि', en: 'Validity Duration', ko: '이용 유효기간'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: 3, child: Text('3 ' + LanguageService.instance.trText(ne: 'महिना (90 दिन)', en: 'Months (90d)', ko: '개월 (90일)'))),
                            DropdownMenuItem(value: 6, child: Text('6 ' + LanguageService.instance.trText(ne: 'महिना (180 दिन)', en: 'Months (180d)', ko: '개월 (180일)'))),
                            DropdownMenuItem(value: 12, child: Text('1 ' + LanguageService.instance.trText(ne: 'वर्ष (365 दिन)', en: 'Year (365d)', ko: '년 (365일)'))),
                            DropdownMenuItem(value: 24, child: Text('2 ' + LanguageService.instance.trText(ne: 'वर्ष (730 दिन)', en: 'Years (730d)', ko: '년 (730일)'))),
                          ],
                          onChanged: (val) => setDialogState(() => validityMonths = val ?? 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: 'रद्द', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final expiry = DateTime.now().add(Duration(days: validityMonths * 30));
                final instId = 'inst_${DateTime.now().millisecondsSinceEpoch}';

                InstituteService.instance.createInstitute(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'INST_${DateTime.now().millisecondsSinceEpoch % 1000}',
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  allowedSetsQuota: quota,
                  validityExpiry: expiry,
                );

                // Register Admin User
                if (adminUserCtrl.text.trim().isNotEmpty) {
                  AuthService.instance.registerInstituteAdmin(
                    username: adminUserCtrl.text.trim(),
                    password: adminPassCtrl.text.trim(),
                    name: '${nameCtrl.text.trim()} Admin',
                    mobileNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '9800000000',
                    instituteId: instId,
                    instituteName: nameCtrl.text.trim(),
                  );
                }

                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'नयाँ इन्स्टिच्युट र एडमिन खाता सिर्जना भयो!',
                      en: 'New institute and admin account created successfully!',
                      ko: '신규 학원 및 관리자 계정이 등록되었습니다!',
                    )),
                  ),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'दर्ता गर्नुहोस्', en: 'Register', ko: '등록하기')),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeQuotaDialog(InstituteProfile inst) {
    int customQuota = inst.customSetQuota;
    int customDays = inst.customSetDurationDays;
    int mainQuota = inst.mainSetQuota;
    int mainDays = inst.mainSetDurationDays;
    int maxStudents = inst.maxStudentsQuota;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${inst.name} - ' + LanguageService.instance.trText(
                    ne: 'कोटा तथा समयावधि नियन्त्रण',
                    en: 'Quota & Duration Control',
                    ko: '쿼터 및 유효기간 설정',
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageService.instance.trText(
                      ne: 'सुपर एडमिनले यस इन्स्टिच्युटको लागि कस्टमाइज सेट र मेन सेटको सीमा तोक्न सक्नुहुन्छ:',
                      en: 'Configure custom uploads, main test sets quota and validity for this institute:',
                      ko: '학원별 자체 문제 업로드 쿼터 및 본부 제공 모의고사 이용 범위를 설정합니다:',
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  
                  // Section 1: Custom Set Upload Quota & Duration
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.upload_file, size: 16, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 6),
                            Text(
                              '१. ' + LanguageService.instance.trText(
                                ne: 'कस्टमाइज प्रश्न सेट अपलोड कोटा',
                                en: 'Custom Test Sets Upload Quota',
                                ko: '자체 제작 문제 세트 등록 쿼터',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: [1, 2, 3, 5, 7, 10, 20, 50].contains(customQuota) ? customQuota : 1,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(ne: 'अधिकतम सेट संख्या', en: 'Max Sets', ko: '최대 세트수'),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: [1, 2, 3, 5, 7, 10, 20, 50].map((num) => DropdownMenuItem(
                                  value: num,
                                  child: Text('$num ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트')),
                                )).toList(),
                                onChanged: (val) => setDialogState(() => customQuota = val ?? 1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: [7, 15, 30, 90, 180, 365].contains(customDays) ? customDays : 30,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(ne: 'एक्सेस समयावधि', en: 'Access Duration', ko: '이용 기간'),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(value: 7, child: Text('7 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 15, child: Text('15 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 30, child: Text('30 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 90, child: Text('90 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 180, child: Text('180 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 365, child: Text('365 ' + LanguageService.instance.trText(ne: 'दिन (१ वर्ष)', en: 'Days (1 Year)', ko: '일 (1년)'))),
                                ],
                                onChanged: (val) => setDialogState(() => customDays = val ?? 30),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Main Set Access Quota & Duration
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.quiz, size: 16, color: Color(0xFF15803D)),
                            const SizedBox(width: 6),
                            Text(
                              '२. ' + LanguageService.instance.trText(
                                ne: 'मुख्य केन्द्रीय प्रश्न सेट पहुँच',
                                en: 'Master Test Sets Access Quota',
                                ko: '본부 공통 문제 세트 이용 쿼터',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: [3, 5, 10, 20, 50, 100].contains(mainQuota) ? mainQuota : 5,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(ne: 'पहुँच सेट कोटा', en: 'Access Quota', ko: '이용 쿼터'),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: [3, 5, 10, 20, 50, 100].map((num) => DropdownMenuItem(
                                  value: num,
                                  child: Text('$num ' + LanguageService.instance.trText(ne: 'वटा सेट', en: 'Sets', ko: '세트')),
                                )).toList(),
                                onChanged: (val) => setDialogState(() => mainQuota = val ?? 5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: [30, 90, 180, 365].contains(mainDays) ? mainDays : 365,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(ne: 'एक्सेस अवधि', en: 'Duration', ko: '이용 기간'),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(value: 30, child: Text('30 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 90, child: Text('90 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 180, child: Text('180 ' + LanguageService.instance.trText(ne: 'दिन', en: 'Days', ko: '일'))),
                                  DropdownMenuItem(value: 365, child: Text('365 ' + LanguageService.instance.trText(ne: 'दिन (१ वर्ष)', en: 'Days (1 Year)', ko: '일 (1년)'))),
                                ],
                                onChanged: (val) => setDialogState(() => mainDays = val ?? 365),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Students Quota
                  DropdownButtonFormField<int>(
                    initialValue: [50, 100, 200, 500, 1000].contains(maxStudents) ? maxStudents : 100,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'अधिकतम विद्यार्थी संख्या कोटा', en: 'Student Enrollment Limit', ko: '최대 수험생 등록 인원'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [50, 100, 200, 500, 1000].map((num) => DropdownMenuItem(
                      value: num,
                      child: Text('$num ' + LanguageService.instance.trText(ne: 'जना विद्यार्थी', en: 'Students', ko: '명')),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => maxStudents = val ?? 100),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: 'रद्द', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                InstituteService.instance.updateCustomSetQuota(inst.id, customQuota);
                InstituteService.instance.updateCustomSetDuration(inst.id, customDays);
                InstituteService.instance.updateMainSetQuota(inst.id, mainQuota);
                InstituteService.instance.updateMainSetDuration(inst.id, mainDays);
                InstituteService.instance.updateAllowedSetsQuota(inst.id, mainQuota);
                InstituteService.instance.updateMaxStudentsQuota(inst.id, maxStudents);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(LanguageService.instance.trText(ne: 'सेभ र लागू गर्नुहोस्', en: 'Save & Apply', ko: '저장 및 적용')),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendValidityDialog(InstituteProfile inst) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${inst.name} - ' + LanguageService.instance.trText(ne: 'म्याद थप', en: 'Extend Validity', ko: '이용 기간 연장')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LanguageService.instance.trText(
              ne: 'हालको म्याद: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day}',
              en: 'Current Expiry: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day}',
              ko: '현재 만료일자: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day}',
            )),
            const SizedBox(height: 12),
            Text(LanguageService.instance.trText(
              ne: 'कति समयको लागि म्याद थप गर्ने?',
              en: 'How long to extend?',
              ko: '연장할 기간을 선택하세요:',
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    InstituteService.instance.extendValidity(inst.id, 90);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: Text('+3 ' + LanguageService.instance.trText(ne: 'महिना', en: 'Months', ko: '개월')),
                ),
                ElevatedButton(
                  onPressed: () {
                    InstituteService.instance.extendValidity(inst.id, 180);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: Text('+6 ' + LanguageService.instance.trText(ne: 'महिना', en: 'Months', ko: '개월')),
                ),
                ElevatedButton(
                  onPressed: () {
                    InstituteService.instance.extendValidity(inst.id, 365);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: Text('+1 ' + LanguageService.instance.trText(ne: 'वर्ष', en: 'Year', ko: '년')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignSetsToInstituteDialog(InstituteProfile inst) {
    final allSets = QuestionBankService.instance.getAllMockSets();
    final selectedSetIds = Set<String>.from(inst.assignedSetIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: 'प्रश्न सेट छनोट तथा सक्रियता (Assign Sets)',
                          en: 'Assign & Activate Question Sets',
                          ko: '문제 세트 배정 및 활성화',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        inst.name,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 520,
            height: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner & bulk actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageService.instance.trText(
                            ne: 'यस इन्स्टिच्युटका विद्यार्थीले यहाँ छानिएका सेटहरू मात्र परीक्षा दिन पाउनेछन्। (${selectedSetIds.length} सेट छानियो)',
                            en: 'Students of this institute can only access selected sets. (${selectedSetIds.length} selected)',
                            ko: '해당 학원의 수험생은 선택된 세트만 응시할 수 있습니다. (${selectedSetIds.length}개 선택)',
                          ),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.select_all, size: 16),
                      label: Text(LanguageService.instance.trText(ne: 'सबै छान्नुहोस्', en: 'Select All', ko: '전체 선택'), style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setDialogState(() {
                          selectedSetIds.addAll(allSets.map((s) => s.id));
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.deselect, size: 16, color: Colors.red),
                      label: Text(LanguageService.instance.trText(ne: 'सबै हटाउनुहोस्', en: 'Deselect All', ko: '전체 해제'), style: const TextStyle(fontSize: 12, color: Colors.red)),
                      onPressed: () {
                        setDialogState(() {
                          selectedSetIds.clear();
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 10),
                // Sets list with checkboxes
                Expanded(
                  child: allSets.isEmpty
                      ? Center(
                          child: Text(
                            LanguageService.instance.trText(ne: 'कुनै पनि प्रश्न सेट उपलब्ध छैन', en: 'No question sets available', ko: '등록된 문제 세트가 없습니다'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: allSets.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final set = allSets[idx];
                            final isChecked = selectedSetIds.contains(set.id);

                            return CheckboxListTile(
                              value: isChecked,
                              dense: true,
                              activeColor: const Color(0xFF0F766E),
                              title: Text(
                                set.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isChecked ? const Color(0xFF0F766E) : Colors.black87,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(set.sector, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${set.questions.length} ${LanguageService.instance.trText(ne: "प्रश्नहरू", en: "Questions", ko: "문항")}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              onChanged: (bool? val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedSetIds.add(set.id);
                                  } else {
                                    selectedSetIds.remove(set.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.save, size: 16),
              label: Text(
                LanguageService.instance.trText(
                  ne: 'सेटहरू सुरक्षित गर्नुहोस् (${selectedSetIds.length})',
                  en: 'Save Sets (${selectedSetIds.length})',
                  ko: '세트 저장 (${selectedSetIds.length})',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final list = selectedSetIds.toList();
                InstituteService.instance.assignSetsToInstitute(inst.id, list);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LanguageService.instance.trText(
                        ne: '✅ ${inst.name} का लागि ${list.length} वटा सेटहरू सफलतापूर्वक तोकियो!',
                        en: '✅ Successfully assigned ${list.length} sets to ${inst.name}!',
                        ko: '✅ ${inst.name}에 ${list.length}개 세트가 성공적으로 배정되었습니다!',
                      ),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCleanDatabaseDialog() {
    final lang = LanguageService.instance;
    final isCleanSlate = QuestionBankService.instance.isCleanSlateMode();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cleaning_services_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.trText(ne: 'डाटाबेस तथा नमुना डाटा नियन्त्रण', en: 'Database & Seed Data Tools', ko: '데이터베이스 및 샘플 데이터 관리'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      lang.trText(ne: 'सफा डाटाबेस (Clean Slate) वा नमुना डाटा व्यवस्थापन', en: 'Clean Slate Mode or Sample Data Reset', ko: '클린 슬레이트 모드 또는 샘플 데이터 정리'),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isCleanSlate ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCleanSlate ? Colors.green.shade300 : Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(isCleanSlate ? Icons.check_circle_rounded : Icons.info_outline, color: isCleanSlate ? Colors.green : const Color(0xFF1E3A8A), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCleanSlate
                                ? lang.trText(
                                    ne: '✨ Clean Slate सक्रिय छ: पुराना कुनै पनि नमुना प्रश्न वा विद्यार्थी देखिने छैनन्। तपाईंले Admin Panel बाट थपेको नयाँ डाटा मात्र देखिन्छ।',
                                    en: '✨ Clean Slate Active: No default sample questions or students appear. Only Admin-created data is displayed.',
                                    ko: '✨ 클린 슬레이트 활성화됨: 기본 샘플 문제/학생이 표시되지 않으며, 관리자가 등록한 데이터만 표시됩니다.',
                                  )
                                : lang.trText(
                                    ne: 'ℹ️ हाल डिफल्ट नमुना प्रश्नहरू (Set 1-5) प्रणालीमा समावेश छन्। तपाईंले तलको बटनबाट पुराना नमुना डाटा हटाएर पूर्ण सफा बनाउन सक्नुहुन्छ।',
                                    en: 'ℹ️ Default sample questions (Set 1-5) are currently loaded. You can clear them below for a completely fresh start.',
                                    ko: 'ℹ️ 현재 기본 샘플 문제(1-5회)가 포함되어 있습니다. 아래 버튼을 통해 정리할 수 있습니다.',
                                  ),
                            style: TextStyle(fontSize: 11.5, color: isCleanSlate ? Colors.green.shade900 : const Color(0xFF1E3A8A), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Option 1: Master Clean Slate (Remove All Dummy Data)
                  ListTile(
                    tileColor: const Color(0xFFFEF3C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.amber.shade400)),
                    leading: const Icon(Icons.auto_delete_rounded, color: Colors.orange, size: 28),
                    title: Text(
                      lang.trText(ne: '🧹 पूर्ण Clean Slate (सबै नमुना डाटा हटाउनुहोस्)', en: '🧹 Full Clean Slate (Clear All Sample Data)', ko: '🧹 전체 클린 슬레이트 (모든 샘플 데이터 삭제)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    subtitle: Text(
                      lang.trText(
                        ne: 'डिफल्ट ५ वटा सेट, नमुना विद्यार्थी र नमुना परीक्षा नतिजा सबै हटाई नयाँ डाटा मात्र राख्ने।',
                        en: 'Clears default 5 sets, dummy students, and dummy attempts. Keeps real admin data only.',
                        ko: '기본 5개 세트, 더미 학생, 시험 기록을 정리하고 실제 관리자 데이터만 유지합니다.',
                      ),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                    ),
                    onTap: () {
                      QuestionBankService.instance.clearAllSampleSets();
                      AuthService.instance.clearAllStudents();
                      ExamHistoryService.instance.clearAllExamAttempts();
                      StudyMaterialService.instance.clearAllBooks();
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(lang.trText(ne: '✨ सबै पुराना नमुना डाटाहरू हटाइयो! अब नयाँ थपिएका डाटाहरू मात्र देखिनेछन्।', en: '✨ All sample data cleared! Database is now clean slate.', ko: '✨ 모든 샘플 데이터가 삭제되었습니다! 클린 슬레이트 완료.')),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Option 2: Clear Dummy Students Only
                  ListTile(
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                    leading: const Icon(Icons.people_outline, color: Colors.blueGrey),
                    title: Text(
                      lang.trText(ne: '🗑️ नमुना विद्यार्थीहरू मात्र हटाउनुहोस्', en: '🗑️ Clear Dummy Students Only', ko: '🗑️ 더미 학생만 삭제'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    subtitle: Text(
                      lang.trText(ne: 'नयाँ दर्ता भएका वा एडमिनले थपेका विद्यार्थीहरू बाहेक पुराना नमुना नाम हटाउने।', en: 'Removes dummy sample accounts, keeping newly registered students.', ko: '신규 등록 학생을 제외한 샘플 학생 계정 삭제.'),
                      style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                    onTap: () {
                      AuthService.instance.clearAllStudents();
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.trText(ne: '✅ नमुना विद्यार्थीहरू हटाइयो!', en: '✅ Dummy students cleared!', ko: '✅ 더미 학생 삭제 완료!')), backgroundColor: Colors.teal),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Option 3: Clear Dummy Exam Records
                  ListTile(
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                    leading: const Icon(Icons.history_edu, color: Colors.blueGrey),
                    title: Text(
                      lang.trText(ne: '🗑️ परीक्षा नतिजा इतिहास खाली गर्नुहोस्', en: '🗑️ Reset Exam Results History', ko: '🗑️ 시험 결과 기록 초기화'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    subtitle: Text(
                      lang.trText(ne: 'परीक्षा नतिजा तालिका शून्य बनाउने (नयाँ विद्यार्थीको वास्तविक परीक्षा मात्र रेकर्ड हुनेछ)।', en: 'Resets exam attempt history so only new test attempts are recorded.', ko: '시험 응시 기록을 초기화하여 실제 응시 데이터만 기록.'),
                      style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                    onTap: () {
                      ExamHistoryService.instance.clearAllExamAttempts();
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.trText(ne: '✅ परीक्षा नतिजा इतिहास सफा गरियो!', en: '✅ Exam history reset!', ko: '✅ 시험 결과 기록 초기화 완료!')), backgroundColor: Colors.teal),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Option 4: Restore Sample Data (Optional Fallback)
                  ListTile(
                    tileColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.blue.shade200)),
                    leading: const Icon(Icons.restore, color: Color(0xFF1E3A8A)),
                    title: Text(
                      lang.trText(ne: '🔄 डिफल्ट नमुना प्रश्नहरू पुनः ल्याउनुहोस्', en: '🔄 Restore Default Sample Sets', ko: '🔄 기본 샘플 문제 복원'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E3A8A)),
                    ),
                    subtitle: Text(
                      lang.trText(ne: 'कहिलेकाहीं डेमो देखाउनका लागि डिफल्ट ५ वटा सेटहरू पुनः सक्रिय गर्ने।', en: 'Restores the original 5 sample mock test sets for demonstration.', ko: '데모를 위해 기본 5개 모의고사 세트를 복원합니다.'),
                      style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                    onTap: () {
                      QuestionBankService.instance.restoreSampleSets();
                      StudyMaterialService.instance.restoreSampleBooks();
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.trText(ne: '🔄 नमुना प्रश्न सेटहरू पुनर्स्थापना गरियो!', en: '🔄 Sample sets restored!', ko: '🔄 샘플 세트가 복원되었습니다!')), backgroundColor: const Color(0xFF1E3A8A)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.trText(ne: 'बन्द गर्नुहोस्', en: 'Close', ko: '닫기')),
            ),
          ],
        ),
      ),
    );
  }

}
