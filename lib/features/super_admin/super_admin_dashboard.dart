import 'package:flutter/material.dart';
import '../settings/universal_settings_dialog.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/cloud_sync_service.dart';
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
        return Scaffold(
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
                        ne: 'केन्द्रीय इन्स्टिच्युट, कोटा तथा क्लाउड नियन्त्रण',
                        en: 'Master Platform Management • All Institutes & Resources Control',
                        ko: '전국 학원 인가, 문제 세트 쿼터 및 클라우드 통합 관리',
                      ),
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Language Switcher
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      LanguageService.instance.trText(ne: 'प्लेटफर्म धनी', en: 'Platform Owner', ko: '플랫폼 본부'),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: LanguageService.instance.trText(ne: 'सेटिङ', en: 'Settings', ko: '설정'),
                onPressed: () => showUniversalSettingsDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: LanguageService.instance.trText(ne: 'लगआउट', en: 'Logout', ko: '로그아웃'),
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              indicatorWeight: 3.5,
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
                  icon: const Icon(Icons.quiz),
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
}
