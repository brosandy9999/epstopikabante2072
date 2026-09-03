import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

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

  String _selectedBatchFilter = 'सबै ब्याचहरू (All Batches)';
  final TextEditingController _studentSearchController = TextEditingController();

  final List<String> _batchesList = [
    'सबै ब्याचहरू (All Batches)',
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
        _adminStatusMsg = 'कृपया हालको एडमिन पासवर्ड प्रविष्ट गर्नुहोस्!';
        _isAdminSuccess = false;
      });
      return;
    }

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() {
        _adminStatusMsg = 'नयाँ पासवर्ड र कन्फर्म पासवर्ड मिलेन!';
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
        _adminStatusMsg = 'सफल भयो! एडमिन लगइन विवरण सफलतापूर्वक परिवर्तन गरियो।';
        _isAdminSuccess = true;
        _adminOldPassController.clear();
        _adminNewPassController.clear();
        _adminConfirmPassController.clear();
      } else {
        _adminStatusMsg = 'हालको पासवर्ड गलत छ! कृपया सही पासवर्ड हाल्नुहोस्।';
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
    String selectedStatus = 'सक्रिय (Active)';
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1E3A8A)),
              SizedBox(width: 10),
              Text('नयाँ विद्यार्थी थप्नुहोस् (Add Student)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    decoration: const InputDecoration(labelText: 'विद्यार्थीको पूरा नाम (Full Name)*', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    decoration: const InputDecoration(labelText: 'दर्ता नम्बर (Registration No. e.g. 01234575)*', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: userCtrl,
                          decoration: const InputDecoration(labelText: 'Username (लगइन आईडी)*', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: const InputDecoration(labelText: 'Password*', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(labelText: 'ब्याच (Batch)*', border: OutlineInputBorder()),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSector,
                          decoration: const InputDecoration(labelText: 'क्षेत्र (Sector)', border: OutlineInputBorder()),
                          items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s.split(' ')[0], style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(labelText: 'स्थिति (Status)', border: OutlineInputBorder()),
                          items: ['सक्रिय (Active)', 'निलम्बित (Suspended)'].map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)))).toList(),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = 'कृपया सबै आवश्यक विवरण भर्नुहोस्!');
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
                    const SnackBar(content: Text('नयाँ विद्यार्थी सफलतापूर्वक थपियो!'), backgroundColor: Colors.teal),
                  );
                } else {
                  setDialogState(() => error = 'यो Username पहिले नै प्रयोगमा छ!');
                }
              },
              child: const Text('विद्यार्थी सेभ गर्नुहोस्'),
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
          title: Text('${student.name} - विवरण सम्पादन', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'नाम (Name)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _batchesList.contains(selectedBatch) ? selectedBatch : _batchesList[1],
                    decoration: const InputDecoration(labelText: 'ब्याच (Batch)', border: OutlineInputBorder()),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sectorsList.contains(selectedSector) ? selectedSector : _sectorsList.first,
                          decoration: const InputDecoration(labelText: 'क्षेत्र', border: OutlineInputBorder()),
                          items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s.split(' ')[0], style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(labelText: 'स्थिति', border: OutlineInputBorder()),
                          items: ['सक्रिय (Active)', 'निलम्बित (Suspended)'].map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)))).toList(),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
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
                  const SnackBar(content: Text('विद्यार्थीको विवरण सफलतापूर्वक अद्यावधिक गरियो!'), backgroundColor: Colors.teal),
                );
              },
              child: const Text('अपडेट गर्नुहोस्'),
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
        title: const Text('विद्यार्थी हटाउने पुष्टि गर्नुहोस्'),
        content: Text('के तपाईं निश्चित रूपमा "${student.name}" लाई हटाउन चाहनुहुन्छ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              AuthService.instance.deleteStudent(student.id);
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('विद्यार्थी सफलतापूर्वक हटाइयो।'), backgroundColor: Colors.red),
              );
            },
            child: const Text('हटाउनुहोस्'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allStudents = AuthService.instance.students;
    final query = _studentSearchController.text.trim().toLowerCase();

    final filteredStudents = allStudents.where((s) {
      final matchesBatch = _selectedBatchFilter.contains('सबै') || s.batch == _selectedBatchFilter;
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
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.groups_rounded, color: Colors.white, size: 34),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'विद्यार्थी ब्याच व्यवस्थापन (Student Batch Hub)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ब्याच अनुसार विद्यार्थीहरूको नामावली, क्षेत्र (Sector) र लगइन क्रेडिसियल नियन्त्रण',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
                            'दर्ता भएका विद्यार्थीहरू (${filteredStudents.length} जना)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('नयाँ विद्यार्थी थप्नुहोस्'),
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
                          decoration: const InputDecoration(
                            labelText: 'ब्याच फिल्टर (Filter by Batch)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: _batchesList.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedBatchFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _studentSearchController,
                          decoration: InputDecoration(
                            hintText: 'विद्यार्थीको नाम, दर्ता नम्बर वा Username खोज्नुहोस्...',
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
                      child: const Text('कुनै विद्यार्थी भेटिएन।', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final s = filteredStudents[i];
                        final isActive = s.status.contains('सक्रिय');

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
                                child: Text(s.batch.split(' ')[0] + ' ' + s.batch.split(' ')[1], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(s.sector.split(' ')[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                              ),
                            ],
                          ),
                          subtitle: Text('दर्ता नं: ${s.registrationNo ?? "N/A"}  •  Username: ${s.username}  •  Password: ${s.password}'),
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
                                child: Text(isActive ? 'सक्रिय' : 'निलम्बित', style: TextStyle(fontSize: 10, color: isActive ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A), size: 20),
                                tooltip: 'सम्पादन गर्नुहोस्',
                                onPressed: () => _showEditStudentDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'हटाउनुहोस्',
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
                  const Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFF0F766E)),
                      SizedBox(width: 10),
                      Text('एडमिन क्रेडिसियल परिवर्तन (Admin Login Settings)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text(_adminStatusMsg, style: TextStyle(color: _isAdminSuccess ? Colors.green.shade900 : Colors.red.shade900)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adminOldPassController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'हालको एडमिन पासवर्ड (Current Password)*', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminNewUsernameController,
                          decoration: const InputDecoration(labelText: 'नयाँ Username (वैकल्पिक)', border: OutlineInputBorder()),
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
                          decoration: const InputDecoration(labelText: 'नयाँ पासवर्ड (New Password)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminConfirmPassController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'नयाँ पासवर्ड पुष्टि गर्नुहोस् (Confirm)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    onPressed: _handleChangeAdminCredentials,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('एडमिन पासवर्ड सुरक्षित गर्नुहोस्'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
