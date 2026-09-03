import 'package:flutter/material.dart';
import '../settings/universal_settings_dialog.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../admin/admin_question_set_screen.dart';
import '../admin/admin_study_manager_screen.dart';
import '../admin/results_analytics_screen.dart';
import '../authentication/login_screen.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('सुपर एडमिन लगआउट'),
          ],
        ),
        content: const Text('के तपाईं सुपर एडमिन पोर्टलबाट लगआउट गर्न निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
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
            child: const Text('हो, लगआउट'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 3,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.amber,
              child: Icon(Icons.workspace_premium, color: Colors.black87, size: 22),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPS-TOPIK सुपर एडमिन (Super Admin Hub)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Master Platform Management • All Institutes & Resources Control',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('Platform Owner', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
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
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'इन्स्टिच्युटहरू (Institutes)'),
            Tab(icon: Icon(Icons.menu_book), text: 'केन्द्रीय रिसोर्स (Resources)'),
            Tab(icon: Icon(Icons.quiz), text: 'प्रश्न सेटहरू (Mock Sets)'),
            Tab(icon: Icon(Icons.insights), text: 'समग्र नतिजा (Analytics)'),
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
                  _buildStatCard('कुल इन्स्टिच्युटहरू', '${institutes.length} वटा', Icons.apartment, Colors.blue),
                  const SizedBox(width: 14),
                  _buildStatCard('सक्रिय इन्स्टिच्युट', '${institutes.where((i) => i.isActive && !i.isExpired).length} वटा', Icons.check_circle, Colors.green),
                  const SizedBox(width: 14),
                  _buildStatCard('म्याद सकिएका', '${institutes.where((i) => i.isExpired).length} वटा', Icons.timer_off, Colors.red),
                  const SizedBox(width: 14),
                  _buildStatCard('प्ल्याटफर्म कपिराइट', 'सुरक्षित (Protected)', Icons.copyright, Colors.purple),
                ],
              ),
              const SizedBox(height: 20),

              // Action & Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏢 दर्ता भएका इन्स्टिच्युटहरू (Registered Institutes)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'प्रत्येक इन्स्टिच्युटलाई सेट कोटा, समय सीमा (Validity) र पहुँच नियन्त्रण गर्नुहोस्',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
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
                    label: const Text('➕ नयाँ इन्स्टिच्युट दर्ता गर्नुहोस्'),
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
                                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                                                  isExpired ? '🔴 म्याद सकिएको (Expired)' : (inst.isActive ? '🟢 सक्रिय (Active)' : '⏸️ रोक्का (Suspended)'),
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
                                        'कोड: ${inst.code} • फोन: ${inst.phone} • ठेगाना: ${inst.address}',
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
                                      Text('प्रश्न सेट कोटा: ${inst.allowedSetsQuota} वटा सेट', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                            ? 'समय समाप्त भएको छ'
                                            : 'म्याद: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day} (बाँकी ${inst.daysRemaining} दिन)',
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
                                      Text('अधिकतम विद्यार्थी: ${inst.maxStudentsQuota} जना', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Change Quota Button
                                OutlinedButton.icon(
                                  onPressed: () => _showChangeQuotaDialog(inst),
                                  icon: const Icon(Icons.tune, size: 14),
                                  label: const Text('कोटा बदल्नुहोस्'),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                // Extend Validity Button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showExtendValidityDialog(inst),
                                  icon: const Icon(Icons.more_time, size: 14),
                                  label: const Text('⏳ म्याद थप गर्नुहोस्'),
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
              backgroundColor: color.withOpacity(0.12),
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
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text('नयाँ इन्स्टिच्युट दर्ता गर्नुहोस्'),
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
                    decoration: const InputDecoration(labelText: 'इन्स्टिच्युटको पूरा नाम', hintText: 'जस्तै: एभरेष्ट कोरियन इन्स्टिच्युट'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(labelText: 'इन्स्टिच्युट कोड', hintText: 'EVEREST_01'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'सम्पर्क फोन', hintText: '9851000000'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'ठेगाना', hintText: 'जस्तै: पुतलीसडक, काठमाडौं'),
                  ),
                  const SizedBox(height: 14),
                  const Text('👤 इन्स्टिच्युट एडमिन लगइन खाता:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: adminUserCtrl,
                          decoration: const InputDecoration(labelText: 'एडमिन Username', hintText: 'everest_admin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: adminPassCtrl,
                          decoration: const InputDecoration(labelText: 'पासवर्ड', hintText: 'admin123'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('⚙️ कोटा तथा समय सीमा (Quota & Validity):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: quota,
                          decoration: const InputDecoration(labelText: 'प्रश्न सेट कोटा', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('३ वटा सेट')),
                            DropdownMenuItem(value: 5, child: Text('५ वटा सेट')),
                            DropdownMenuItem(value: 10, child: Text('१० वटा सेट')),
                            DropdownMenuItem(value: 20, child: Text('२० वटा सेट')),
                            DropdownMenuItem(value: 999, child: Text('असीमित (Unlimited)')),
                          ],
                          onChanged: (val) => setDialogState(() => quota = val ?? 5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: validityMonths,
                          decoration: const InputDecoration(labelText: 'म्याद अवधि', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('३ महिना (90 दिन)')),
                            DropdownMenuItem(value: 6, child: Text('६ महिना (180 दिन)')),
                            DropdownMenuItem(value: 12, child: Text('१ वर्ष (365 दिन)')),
                            DropdownMenuItem(value: 24, child: Text('२ वर्ष (730 दिन)')),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
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
                    name: '${nameCtrl.text.trim()} एडमिन',
                    mobileNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '9800000000',
                    instituteId: instId,
                    instituteName: nameCtrl.text.trim(),
                  );
                }

                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('नयाँ इन्स्टिच्युट र एडमिन खाता सफलतापूर्वक सिर्जना भयो!')),
                );
              },
              child: const Text('दर्ता गर्नुहोस्'),
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
              Expanded(child: Text('${inst.name} को कोटा तथा समयावधि नियन्त्रण', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('सुपर एडमिनले यस इन्स्टिच्युटको लागि कस्टमाइज सेट र मेन सेट अपलोड तथा एक्सेसको सीमा तोक्न सक्नुहुन्छ:', style: TextStyle(fontSize: 12, color: Colors.black54)),
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
                        const Row(
                          children: [
                            Icon(Icons.upload_file, size: 16, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 6),
                            Text('१. कस्टमाइज प्रश्न सेट अपलोड कोटा (Custom Sets)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [1, 2, 3, 5, 7, 10, 20, 50].contains(customQuota) ? customQuota : 1,
                                decoration: const InputDecoration(labelText: 'अधिकतम सेट संख्या', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('१ वटा सेट')),
                                  DropdownMenuItem(value: 2, child: Text('२ वटा सेट')),
                                  DropdownMenuItem(value: 3, child: Text('३ वटा सेट')),
                                  DropdownMenuItem(value: 5, child: Text('५ वटा सेट')),
                                  DropdownMenuItem(value: 7, child: Text('७ वटा सेट')),
                                  DropdownMenuItem(value: 10, child: Text('१० वटा सेट')),
                                  DropdownMenuItem(value: 20, child: Text('२० वटा सेट')),
                                  DropdownMenuItem(value: 50, child: Text('५० वटा सेट')),
                                ],
                                onChanged: (val) => setDialogState(() => customQuota = val ?? 1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [7, 15, 30, 90, 180, 365].contains(customDays) ? customDays : 30,
                                decoration: const InputDecoration(labelText: 'एक्सेस समयावधि', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 7, child: Text('१ हप्ता (7 दिन)')),
                                  DropdownMenuItem(value: 15, child: Text('१५ दिन')),
                                  DropdownMenuItem(value: 30, child: Text('१ महिना (30 दिन)')),
                                  DropdownMenuItem(value: 90, child: Text('३ महिना (90 दिन)')),
                                  DropdownMenuItem(value: 180, child: Text('६ महिना (180 दिन)')),
                                  DropdownMenuItem(value: 365, child: Text('१ वर्ष (365 दिन)')),
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
                        const Row(
                          children: [
                            Icon(Icons.quiz, size: 16, color: Color(0xFF15803D)),
                            SizedBox(width: 6),
                            Text('२. मुख्य केन्द्रीय प्रश्न सेट पहुँच (Main Sets Access)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [3, 5, 10, 20, 50, 100].contains(mainQuota) ? mainQuota : 5,
                                decoration: const InputDecoration(labelText: 'पहुँच सेट कोटा', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 3, child: Text('३ वटा सेट')),
                                  DropdownMenuItem(value: 5, child: Text('५ वटा सेट')),
                                  DropdownMenuItem(value: 10, child: Text('१० वटा सेट')),
                                  DropdownMenuItem(value: 20, child: Text('२० वटा सेट')),
                                  DropdownMenuItem(value: 50, child: Text('५० वटा सेट')),
                                  DropdownMenuItem(value: 100, child: Text('१०० वटा सेट')),
                                ],
                                onChanged: (val) => setDialogState(() => mainQuota = val ?? 5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: [30, 90, 180, 365].contains(mainDays) ? mainDays : 365,
                                decoration: const InputDecoration(labelText: 'एक्सेस अवधि', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 30, child: Text('१ महिना (30 दिन)')),
                                  DropdownMenuItem(value: 90, child: Text('३ महिना (90 दिन)')),
                                  DropdownMenuItem(value: 180, child: Text('६ महिना (180 दिन)')),
                                  DropdownMenuItem(value: 365, child: Text('१ वर्ष (365 दिन)')),
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
                    value: [50, 100, 200, 500, 1000].contains(maxStudents) ? maxStudents : 100,
                    decoration: const InputDecoration(labelText: 'अधिकतम विद्यार्थी संख्या कोटा (Max Students)', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 50, child: Text('५० जना विद्यार्थी')),
                      DropdownMenuItem(value: 100, child: Text('१०० जना विद्यार्थी')),
                      DropdownMenuItem(value: 200, child: Text('२०० जना विद्यार्थी')),
                      DropdownMenuItem(value: 500, child: Text('५०० जना विद्यार्थी')),
                      DropdownMenuItem(value: 1000, child: Text('१००० जना विद्यार्थी')),
                    ],
                    onChanged: (val) => setDialogState(() => maxStudents = val ?? 100),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
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
              },
              child: const Text('सेभ र लागू गर्नुहोस्'),
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
        title: Text('${inst.name} को म्याद थप'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('हालको म्याद: ${inst.validityExpiry.year}/${inst.validityExpiry.month}/${inst.validityExpiry.day}'),
            const SizedBox(height: 12),
            const Text('कति समयको लागि म्याद थप गर्ने?'),
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
                  child: const Text('+३ महिना'),
                ),
                ElevatedButton(
                  onPressed: () {
                    InstituteService.instance.extendValidity(inst.id, 180);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('+६ महिना'),
                ),
                ElevatedButton(
                  onPressed: () {
                    InstituteService.instance.extendValidity(inst.id, 365);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('+१ वर्ष'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
