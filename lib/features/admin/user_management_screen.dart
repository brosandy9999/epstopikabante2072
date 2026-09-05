import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';

/// Admin Student Batch Management & Credential Screen
/// Allows teachers and administrators to organize students by batch,
/// assign sectors, set passwords, and manage active status.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _adminOldPassController = TextEditingController();
  final _adminNewUsernameController = TextEditingController();
  final _adminNewPassController = TextEditingController();
  final _adminConfirmPassController = TextEditingController();

  String _adminStatusMsg = '';
  bool _isAdminSuccess = false;

  String _selectedBatchFilter = 'सबै ब्याचहरू';
  final TextEditingController _studentSearchController = TextEditingController();

  final List<String> _batchesList = [
    'सबै ब्याचहरू',
    '2026 Batch A (बिहानी सत्र)',
    '2026 Batch B (दिवा सत्र)',
    '2026 Batch C (साँझ सत्र)',
    'विशेष UBT बुटक्याम्प',
  ];

  final List<String> _sectorsList = [
    '제조업 (Manufacturing)',
    '농축산 (Agriculture)',
    '건설업 (Construction)',
    '어업 (Fishery)',
  ];

  @override
  void initState() {
    super.initState();
    _adminNewUsernameController.text = AuthService.instance.admin.username;
  }

  @override
  void dispose() {
    _adminOldPassController.dispose();
    _adminNewUsernameController.dispose();
    _adminNewPassController.dispose();
    _adminConfirmPassController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  void _handleChangeAdminCredentials() {
    final oldPass = _adminOldPassController.text.trim();
    final newUsername = _adminNewUsernameController.text.trim();
    final newPass = _adminNewPassController.text.trim();
    final confirmPass = _adminConfirmPassController.text.trim();

    if (oldPass.isEmpty) {
      setState(() {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'कृपया हालको एडमिन पासवर्ड प्रविष्ट गर्नुहोस्!',
          en: 'Please enter the current admin password!',
          ko: '현재 관리자 비밀번호를 입력해주세요!',
        );
        _isAdminSuccess = false;
      });
      return;
    }

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'नयाँ पासवर्ड र कन्फर्म पासवर्ड मिलेन!',
          en: 'New password and confirmation do not match!',
          ko: '새 비밀번호와 확인 비밀번호가 일치하지 않습니다!',
        );
        _isAdminSuccess = false;
      });
      return;
    }

    final success = AuthService.instance.changeAdminCredentials(
      oldPassword: oldPass,
      newUsername: newUsername.isNotEmpty ? newUsername : AuthService.instance.admin.username,
      newPassword: newPass.isNotEmpty ? newPass : AuthService.instance.admin.password,
    );

    setState(() {
      if (success) {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'सफल भयो! एडमिन लगइन विवरण सफलतापूर्वक परिवर्तन गरियो।',
          en: 'Success! Admin login credentials updated successfully.',
          ko: '성공! 관리자 로그인 정보가 변경되었습니다.',
        );
        _isAdminSuccess = true;
        _adminOldPassController.clear();
        _adminNewPassController.clear();
        _adminConfirmPassController.clear();
      } else {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'हालको पासवर्ड गलत छ! कृपया सही पासवर्ड हाल्नुहोस्।',
          en: 'Current password is incorrect! Please try again.',
          ko: '현재 비밀번호가 올바르지 않습니다. 다시 입력해주세요.',
        );
        _isAdminSuccess = false;
      }
    });
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'student123');
    String selectedBatch = '2026 Batch A (बिहानी सत्र)';
    String selectedSector = '제조업 (Manufacturing)';
    String selectedStatus = 'सक्रिय';
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 10),
              Text(
                LanguageService.instance.trText(
                  ne: 'नयाँ विद्यार्थी थप्नुहोस्',
                  en: 'Add New Student',
                  ko: '새 수험생 등록',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'विद्यार्थीको पूरा नाम*',
                        en: 'Student Full Name*',
                        ko: '수험생 성명*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'दर्ता नम्बर (e.g. 01234575)*',
                        en: 'Registration No (e.g. 01234575)*',
                        ko: '수험번호 (e.g. 01234575)*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: userCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'प्रयोगकर्ता नाम (Username)*',
                              en: 'Username*',
                              ko: '아이디 (Username)*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'पासवर्ड (Password)*',
                              en: 'Password*',
                              ko: '비밀번호*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'ब्याच*',
                        en: 'Batch*',
                        ko: '학습 반*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSector,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'औद्योगिक क्षेत्र',
                              en: 'Industry Sector',
                              ko: '업종 분야',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: _sectorsList.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(LanguageService.instance.sectorText(s), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'स्थिति',
                              en: 'Status',
                              ko: '상태',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'सक्रिय',
                              child: Text(LanguageService.instance.statusText('सक्रिय'), style: const TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'निलम्बित',
                              child: Text(LanguageService.instance.statusText('निलम्बित'), style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) => setDialogState(() => selectedStatus = val!),
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
              child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'कृपया सबै आवश्यक विवरण भर्नुहोस्!',
                    en: 'Please fill in all required fields!',
                    ko: '모든 필수 항목을 입력해주세요!',
                  ));
                  return;
                }
                final ok = AuthService.instance.addStudent(
                  name: nameCtrl.text.trim(),
                  registrationNo: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  batch: selectedBatch,
                  sector: selectedSector,
                  status: selectedStatus,
                );
                if (ok) {
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LanguageService.instance.trText(
                        ne: 'नयाँ विद्यार्थी सफलतापूर्वक थपियो!',
                        en: 'New student added successfully!',
                        ko: '새 수험생이 등록되었습니다!',
                      )),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'यो Username पहिले नै प्रयोगमा छ!',
                    en: 'This username is already taken!',
                    ko: '이미 사용 중인 아이디입니다!',
                  ));
                }
              },
              child: Text(LanguageService.instance.trText(ne: 'विद्यार्थी सेभ गर्नुहोस्', en: 'Save Student', ko: '수험생 저장')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(AppUser student) {
    final nameCtrl = TextEditingController(text: student.name);
    final userCtrl = TextEditingController(text: student.username);
    final passCtrl = TextEditingController(text: student.password);
    String selectedBatch = student.batch;
    String selectedSector = student.sector;
    String selectedStatus = student.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${student.name} - ' + LanguageService.instance.trText(ne: 'विवरण सम्पादन', en: 'Edit Credentials', ko: '정보 수정'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'नाम', en: 'Name', ko: '성명'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: userCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'Username', en: 'Username', ko: '아이디'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'Password', en: 'Password', ko: '비밀번호'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _batchesList.contains(selectedBatch) ? selectedBatch : _batchesList[1],
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'ब्याच', en: 'Batch', ko: '학습 반'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sectorsList.contains(selectedSector) ? selectedSector : _sectorsList.first,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'क्षेत्र', en: 'Sector', ko: '업종'),
                            border: const OutlineInputBorder(),
                          ),
                          items: _sectorsList.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(LanguageService.instance.sectorText(s), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'स्थिति', en: 'Status', ko: '상태'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'सक्रिय',
                              child: Text(LanguageService.instance.statusText('सक्रिय'), style: const TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'निलम्बित',
                              child: Text(LanguageService.instance.statusText('निलम्बित'), style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) => setDialogState(() => selectedStatus = val!),
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
              child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                AuthService.instance.updateStudentCredentials(
                  studentId: student.id,
                  newName: nameCtrl.text.trim(),
                  newUsername: userCtrl.text.trim(),
                  newPassword: passCtrl.text.trim(),
                  newBatch: selectedBatch,
                  newSector: selectedSector,
                  newStatus: selectedStatus,
                );
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'विद्यार्थीको विवरण सफलतापूर्वक अद्यावधिक गरियो!',
                      en: 'Student details updated successfully!',
                      ko: '수험생 정보가 변경되었습니다!',
                    )),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'अपडेट गर्नुहोस्', en: 'Update', ko: '저장')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent(AppUser student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageService.instance.trText(
          ne: 'विद्यार्थी हटाउने पुष्टि गर्नुहोस्',
          en: 'Confirm Delete Student',
          ko: '수험생 삭제 확인',
        )),
        content: Text(LanguageService.instance.trText(
          ne: 'के तपाईं निश्चित रूपमा "${student.name}" लाई हटाउन चाहनुहुन्छ?',
          en: 'Are you sure you want to delete "${student.name}"?',
          ko: '정말로 "${student.name}" 수험생을 삭제하시겠습니까?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              AuthService.instance.deleteStudent(student.id);
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LanguageService.instance.trText(
                    ne: 'विद्यार्थी सफलतापूर्वक हटाइयो।',
                    en: 'Student deleted successfully.',
                    ko: '수험생이 삭제되었습니다.',
                  )),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(LanguageService.instance.trText(ne: 'हटाउनुहोस्', en: 'Delete', ko: '삭제')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        final allStudents = AuthService.instance.students;
        final query = _studentSearchController.text.trim().toLowerCase();

        final filteredStudents = allStudents.where((s) {
          final matchesBatch = _selectedBatchFilter.contains('सबै') || _selectedBatchFilter.contains('All') || s.batch == _selectedBatchFilter;
          final matchesQuery = query.isEmpty ||
              s.name.toLowerCase().contains(query) ||
              s.username.toLowerCase().contains(query) ||
              (s.registrationNo?.toLowerCase().contains(query) ?? false);
          return matchesBatch && matchesQuery;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 1. Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.groups_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: 'विद्यार्थी ब्याच तथा क्रेडिसियल व्यवस्थापन',
                          en: 'Student Batch & Credentials Management',
                          ko: '수험생 반별 및 계정 관리',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'ब्याच अनुसार विद्यार्थीहरूको नामावली, क्षेत्र र लगइन क्रेडिसियल नियन्त्रण',
                          en: 'Manage student rosters, industry sectors, and login credentials by batch',
                          ko: '반별 수험생 명단, 업종 선택 및 로그인 계정 정보 제어',
                        ),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Student List with Batch Filter & Search
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 10),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'दर्ता भएका विद्यार्थीहरू (${filteredStudents.length} जना)',
                              en: 'Registered Students (${filteredStudents.length})',
                              ko: '등록된 수험생 목록 (${filteredStudents.length}명)',
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(LanguageService.instance.trText(
                          ne: 'नयाँ विद्यार्थी थप्नुहोस्',
                          en: 'Add Student',
                          ko: '수험생 추가',
                        )),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Batch Filter Bar & Search
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBatchFilter,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'ब्याच फिल्टर',
                              en: 'Filter by Batch',
                              ko: '반별 필터',
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: _batchesList.map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedBatchFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _studentSearchController,
                          decoration: InputDecoration(
                            hintText: LanguageService.instance.trText(
                              ne: 'विद्यार्थीको नाम, दर्ता नम्बर वा Username खोज्नुहोस्...',
                              en: 'Search by name, reg no, or username...',
                              ko: '이름, 수험번호, 아이디로 검색...',
                            ),
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            suffixIcon: _studentSearchController.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _studentSearchController.clear()))
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Students List
                  if (filteredStudents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Text(
                        LanguageService.instance.trText(
                          ne: 'कुनै विद्यार्थी भेटिएन।',
                          en: 'No students found.',
                          ko: '해당 조건의 수험생이 없습니다.',
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final s = filteredStudents[i];
                        final isActive = s.status.contains('सक्रिय') || s.status.toLowerCase().contains('active');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0] : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(LanguageService.instance.batchText(s.batch), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(LanguageService.instance.sectorText(s.sector), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            LanguageService.instance.trText(
                              ne: 'दर्ता नं: ${s.registrationNo ?? "N/A"}  •  Username: ${s.username}  •  Password: ${s.password}',
                              en: 'Reg: ${s.registrationNo ?? "N/A"}  •  User: ${s.username}  •  Pass: ${s.password}',
                              ko: '수험번호: ${s.registrationNo ?? "N/A"}  •  아이디: ${s.username}  •  비밀번호: ${s.password}',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isActive ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  LanguageService.instance.statusText(s.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A), size: 20),
                                tooltip: LanguageService.instance.trText(ne: 'सम्पादन गर्नुहोस्', en: 'Edit', ko: '수정'),
                                onPressed: () => _showEditStudentDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: LanguageService.instance.trText(ne: 'हटाउनुहोस्', en: 'Delete', ko: '삭제'),
                                onPressed: () => _confirmDeleteStudent(s),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Admin Credentials Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF0F766E)),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'एडमिन क्रेडिसियल तथा पासवर्ड परिवर्तन',
                          en: 'Admin Credentials & Password Management',
                          ko: '학원 관리자 로그인 계정 및 비밀번호 변경',
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_adminStatusMsg.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isAdminSuccess ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isAdminSuccess ? Colors.green : Colors.red),
                      ),
                      child: Text(_adminStatusMsg, style: TextStyle(color: _isAdminSuccess ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adminOldPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'हालको एडमिन पासवर्ड*',
                              en: 'Current Admin Password*',
                              ko: '현재 관리자 비밀번호*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminNewUsernameController,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ प्रयोगकर्ता नाम (Username)',
                              en: 'New Admin Username',
                              ko: '새 관리자 아이디 (Username)',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adminNewPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ पासवर्ड',
                              en: 'New Password',
                              ko: '새 비밀번호',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminConfirmPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ पासवर्ड पुष्टि गर्नुहोस्',
                              en: 'Confirm New Password',
                              ko: '새 비밀번호 확인',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    onPressed: _handleChangeAdminCredentials,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(LanguageService.instance.trText(
                      ne: 'एडमिन विवरण सुरक्षित गर्नुहोस्',
                      en: 'Save Admin Credentials',
                      ko: '관리자 정보 저장',
                    )),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
      },
    );
  }
}
