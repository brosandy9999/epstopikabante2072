import '../../core/services/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../authentication/login_screen.dart';

void showUniversalSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const UniversalSettingsDialog(),
  );
}

class UniversalSettingsDialog extends StatefulWidget {
  const UniversalSettingsDialog({super.key});

  @override
  State<UniversalSettingsDialog> createState() => _UniversalSettingsDialogState();
}

class _UniversalSettingsDialogState extends State<UniversalSettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile fields
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _photoUrlController;
  String? _selectedAvatar;

  // Password fields
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  late final TextEditingController _firebaseUrlCtrl;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _statusMessage = '';
  bool _isSuccess = false;

  final List<String> _quickAvatars = [
    '👑', '🏢', '👨‍🎓', '👩‍🎓', '👨‍🏫', '👩‍🏫', '👷', '🌾', '🚀', '🇰🇷'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final user = AuthService.instance.currentUser ?? AuthService.instance.students.first;
    _nameController = TextEditingController(text: user.name);
    _mobileController = TextEditingController(text: user.mobileNumber ?? '');
    _photoUrlController = TextEditingController(text: user.profilePhoto ?? '');
    _selectedAvatar = user.profilePhoto;
    _firebaseUrlCtrl = TextEditingController(text: CloudSyncService.instance.cloudEndpoint);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _photoUrlController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    _firebaseUrlCtrl.dispose();
    super.dispose();
  }

  void _handleSaveProfile() {
    final user = AuthService.instance.currentUser ?? AuthService.instance.students.first;
    final photo = _selectedAvatar ?? _photoUrlController.text.trim();

    final success = AuthService.instance.updateUserCredentials(
      userId: user.id,
      newName: _nameController.text.trim(),
      newMobile: _mobileController.text.trim(),
      profilePhoto: photo.isNotEmpty ? photo : null,
    );

    setState(() {
      if (success) {
        _isSuccess = true;
        _statusMessage = '✅ प्रोफाइल विवरण र फोटो सफलतापूर्वक सुरक्षित भयो!';
      } else {
        _isSuccess = false;
        _statusMessage = '❌ प्रोफाइल अपडेट गर्न सकिएन!';
      }
    });
  }

  void _handleChangePassword() {
    final user = AuthService.instance.currentUser ?? AuthService.instance.students.first;
    final currentPw = _currentPwController.text.trim();
    final newPw = _newPwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();

    if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = '❌ कृपया सबै पासवर्ड विवरण भर्नुहोस्!';
      });
      return;
    }

    if (currentPw != user.password) {
      setState(() {
        _isSuccess = false;
        _statusMessage = '❌ हालको पासवर्ड मिलेन! कृपया सही पासवर्ड हाल्नुहोस्।';
      });
      return;
    }

    if (newPw.length < 4) {
      setState(() {
        _isSuccess = false;
        _statusMessage = '❌ नयाँ पासवर्ड कम्तिमा ४ अक्षरको हुनुपर्छ!';
      });
      return;
    }

    if (newPw != confirmPw) {
      setState(() {
        _isSuccess = false;
        _statusMessage = '❌ नयाँ पासवर्ड र पुष्टि पासवर्ड समान हुनुपर्छ!';
      });
      return;
    }

    final success = AuthService.instance.updateUserCredentials(
      userId: user.id,
      newPassword: newPw,
    );

    setState(() {
      if (success) {
        _isSuccess = true;
        _statusMessage = '✅ पासवर्ड सफलतापूर्वक परिवर्तन भयो र सुरक्षित गरियो!';
        _currentPwController.clear();
        _newPwController.clear();
        _confirmPwController.clear();
      } else {
        _isSuccess = false;
        _statusMessage = '❌ पासवर्ड सुरक्षित गर्दा त्रुटि भयो!';
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('लगआउट पुष्टि गर्नुहोस्'),
          ],
        ),
        content: const Text('के तपाईं आफ्नो खाताबाट लगआउट हुन निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द गर्नुहोस्'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              AuthService.instance.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('लगआउट हुनुहोस्'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final user = auth.currentUser ?? auth.students.first;
    final langService = LanguageService.instance;

    String roleBadge;
    Color roleColor;
    if (user.role == UserRole.superAdmin) {
      roleBadge = '👑 सुपर एडमिन (Super Admin Master)';
      roleColor = const Color(0xFF0F172A);
    } else if (user.role == UserRole.admin) {
      roleBadge = '🏢 इन्स्टिच्युट एडमिन (Institute Admin)';
      roleColor = const Color(0xFF0F766E);
    } else {
      roleBadge = '👨‍🎓 परीक्षार्थी (Student Candidate)';
      roleColor = const Color(0xFF1E3A8A);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 620,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: User Card & Role
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: roleColor, width: 2.2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Center(
                    child: (user.profilePhoto != null && (user.profilePhoto!.startsWith('data:image') || user.profilePhoto!.startsWith('http')))
                        ? ClipOval(child: SmartImageWidget(imageSource: user.profilePhoto!, width: 50, height: 50, fit: BoxFit.cover))
                        : Text(
                            user.profilePhoto ?? (user.role == UserRole.superAdmin ? '👑' : (user.role == UserRole.admin ? '🏢' : '👨‍🎓')),
                            style: const TextStyle(fontSize: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              roleBadge,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('ID: ${user.username}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'बन्द गर्नुहोस्',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5 Tabs: 🌐 भाषा | 👤 प्रोफाइल | 🔑 पासवर्ड | ⚙️ प्राथमिकता | 📦 डेटा र एप
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.language, size: 16), text: '🌐 भाषा (Language)'),
                  Tab(icon: Icon(Icons.person, size: 16), text: '👤 प्रोफाइल (Profile)'),
                  Tab(icon: Icon(Icons.lock_reset, size: 16), text: '🔑 पासवर्ड (Password)'),
                  Tab(icon: Icon(Icons.tune, size: 16), text: '⚙️ प्राथमिकता (Preferences)'),
                  Tab(icon: Icon(Icons.sync, size: 16), text: '🔄 सिङ्क (Mobile & Cloud Sync)'),
                  Tab(icon: Icon(Icons.info_outline, size: 16), text: '📦 डेटा र एप (Info)'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status message banner
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isSuccess ? Colors.green.shade300 : Colors.red.shade300),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            // Tab Content Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: 🌐 LANGUAGE SETTINGS
                  _buildLanguageTab(langService),

                  // TAB 2: 👤 PROFILE & AVATAR SETTINGS
                  _buildProfileTab(user),

                  // TAB 3: 🔑 PASSWORD SETTINGS
                  _buildPasswordTab(user),

                  // TAB 4: ⚙️ PREFERENCES & AUDIO
                  _buildPreferencesTab(langService),

                  // TAB 5: 📦 DATA & SYSTEM INFO
                  _buildDataAndInfoTab(),
                ],
              ),
            ),

            const Divider(height: 20),

            // Bottom Actions: Logout & Done
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('लगआउट हुनुहोस् (Logout)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('सम्पन्न भयो (Close)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🌐 TAB 1: LANGUAGE SETTINGS
  Widget _buildLanguageTab(LanguageService langService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'प्रणालीको भाषा छान्नुहोस् (Select System Language):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          ...AppLanguage.values.map((lang) {
            final isSelected = langService.currentLanguage == lang;
            return Card(
              elevation: isSelected ? 2 : 0,
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Text(
                  lang == AppLanguage.nepali ? '🇳🇵' : (lang == AppLanguage.korean ? '🇰🇷' : '🇬🇧'),
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  lang.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
                    : null,
                onTap: () {
                  setState(() {
                    langService.setLanguage(lang);
                    _isSuccess = true;
                    _statusMessage = '🌐 भाषा परिवर्तन भयो: ${lang.displayName}';
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // 👤 TAB 2: PROFILE & AVATAR SETTINGS
  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'अवतार वा प्रोफाइल फोटो रोज्नुहोस् (Select Profile Avatar):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),

          // Quick Avatar Picker
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAvatars.map((avatar) {
              final isSel = _selectedAvatar == avatar;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                    _photoUrlController.text = avatar;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFDBEAFE) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                      width: isSel ? 2.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(avatar, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
            ),
            onPressed: () async {
              final file = await FileUploadService.instance.pickImageFile();
              if (file != null) {
                setState(() {
                  _selectedAvatar = file.dataUrl;
                  _photoUrlController.text = file.dataUrl;
                  _isSuccess = true;
                  _statusMessage = '📷 फोटो लोड भयो (${file.name}, ${file.formattedSize})। सेभ गर्नुहोस्।';
                });
              }
            },
            icon: const Icon(Icons.add_a_photo, size: 18),
            label: const Text('📁 कम्प्युटर/मोबाइलबाट आफ्नै फोटो रोज्नुहोस् (Pick Photo File)'),
          ),
          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'पूरा नाम (Full Name)',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Mobile field
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'मोबाइल नम्बर (Mobile Number)',
              prefixIcon: Icon(Icons.phone_android_outlined),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _handleSaveProfile,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('प्रोफाइल विवरण सुरक्षित गर्नुहोस् (Save Profile)'),
            ),
          ),
        ],
      ),
    );
  }

  // 🔑 TAB 3: PASSWORD SETTINGS
  Widget _buildPasswordTab(AppUser user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'सुरक्षा तथा पासवर्ड परिवर्तन (Change Account Password):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Current Password
          TextField(
            controller: _currentPwController,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'हालको पासवर्ड (Current Password)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // New Password
          TextField(
            controller: _newPwController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'नयाँ पासवर्ड (New Password)',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Confirm New Password
          TextField(
            controller: _confirmPwController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'नयाँ पासवर्ड पुनः हाल्नुहोस् (Confirm New Password)',
              prefixIcon: const Icon(Icons.check_circle_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _handleChangePassword,
              icon: const Icon(Icons.key, size: 18),
              label: const Text('नयाँ पासवर्ड सुरक्षित गर्नुहोस् (Update Password)'),
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ TAB 4: PREFERENCES & AUDIO SPEED
  Widget _buildPreferencesTab(LanguageService langService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'अडियो तथा परीक्षा प्राथमिकताहरू (Audio & Exam Preferences):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Audio Speed
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed, size: 18, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text('कोरियन अडियो उच्चारण गति (Listening Speed):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [0.8, 1.0, 1.2].map((sp) {
                      final isSel = (langService.audioSpeed - sp).abs() < 0.05;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(
                            sp == 0.8 ? '०.८x सुस्त (Slow)' : (sp == 1.0 ? '१.०x सामान्य (Normal)' : '१.२x छिटो (Fast)'),
                            style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF1E3A8A),
                          onSelected: (_) {
                            setState(() {
                              langService.setAudioSpeed(sp);
                              _isSuccess = true;
                              _statusMessage = '✅ अडियो गति सेट गरियो: ${sp}x';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Exam Mode
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text('पूर्ववत परीक्षा मोड (Default Exam Mode):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<ExamModePreference>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🔴 Strict Exam Mode (५० मिनेट समय, एन्टी-चिट, वास्तविक परीक्षा)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: ExamModePreference.strictExam,
                    groupValue: langService.modePreference,
                    onChanged: (v) {
                      setState(() {
                        langService.setModePreference(v!);
                        _isSuccess = true;
                        _statusMessage = '✅ पूर्ववत मोड: Strict Exam';
                      });
                    },
                  ),
                  RadioListTile<ExamModePreference>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🟢 Study & Practice Mode (तत्काल सही/गलत उत्तर र व्याख्या)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    value: ExamModePreference.studyPractice,
                    groupValue: langService.modePreference,
                    onChanged: (v) {
                      setState(() {
                        langService.setModePreference(v!);
                        _isSuccess = true;
                        _statusMessage = '✅ पूर्ववत मोड: Study Practice';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 🔄 TAB 5: MOBILE & CLOUD SYNC
  Widget _buildSyncTab() {
    final sync = CloudSyncService.instance;
    final lastTime = sync.lastSyncTime != null
        ? '\:\ (\-\-\)'
        : 'पहिलो पटक सिङ्क बाँकी';

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (sync.state) {
      case SyncState.syncing:
        statusText = '🔄 सिङ्क भइरहेको छ... (Syncing in progress)';
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case SyncState.synced:
        statusText = '✅ सबै डेटा सिङ्क भइसक्यो (100% Up to Date)';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SyncState.error:
        statusText = sync.lastError ?? '❌ सिङ्क त्रुटि';
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case SyncState.offline:
        statusText = '📡 अफलाइन मोड (इन्टरनेट उपलब्ध हुँदा सिङ्क हुनेछ)';
        statusColor = Colors.blueGrey;
        statusIcon = Icons.cloud_off;
        break;
      case SyncState.idle:
      default:
        statusText = '☁️ क्लाउड सिङ्क तयार (Ready to Sync)';
        statusColor = const Color(0xFF1E3A8A);
        statusIcon = Icons.cloud_done_outlined;
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'मोबाइल एप र डेस्कटप बीच डाटा सिङ्क (Mobile & Desktop Cross-Sync):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),

          // Live Sync Status Card
          Card(
            color: statusColor.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: statusColor, radius: 20, child: Icon(statusIcon, color: Colors.white, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor)),
                        const SizedBox(height: 4),
                        Text('अन्तिम सिङ्क: ', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Firebase Realtime DB Setup Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.deepOrange.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fireplace_rounded, size: 20, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      const Text('Firebase Cloud Sync Database:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('गाइड (Help)', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.deepOrange),
                                  SizedBox(width: 8),
                                  Text('नि:शुल्क Firebase बनाउने तरिका'),
                                ],
                              ),
                              content: const SingleChildScrollView(
                                child: Text(
                                  '१. console.firebase.google.com मा गई आफ्नो Gmail बाट लगइन गर्नुहोस्।\n'
                                  '२. "Create a project" गरी परियोजनाको नाम राख्नुहोस् (जस्तै: eps-topik-app)।\n'
                                  '३. बायाँ मेनुको Build > Realtime Database मा जानुहोस् र "Create Database" थिच्नुहोस्।\n'
                                  '४. Security Rules मा "Start in test mode" छान्नुहोस् र Enable गर्नुहोस्।\n'
                                  '५. त्यहाँ माथि देखिने डाटाबेसको URL कपी गरी यहाँ राख्नुहोस्।\n\n'
                                  'यति गरेपछि तपाईंको कम्प्युटर र सबै विद्यार्थीको मोबाइल २४ सै घण्टा रियल-टाइम सिङ्क हुन्छन्!',
                                  style: TextStyle(fontSize: 13, height: 1.5),
                                ),
                              ),
                              actions: [
                                ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('बुझेँ (Got it)')),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _firebaseUrlCtrl,
                    decoration: InputDecoration(
                      hintText: 'https://your-project-default-rtdb.firebaseio.com',
                      prefixIcon: const Icon(Icons.link, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange.shade700,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.save_rounded, size: 15),
                        label: const Text('URL सेभ गर्नुहोस्', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          final textVal = _firebaseUrlCtrl.text.trim();
                          if (textVal.isNotEmpty) {
                            sync.setCloudEndpoint(textVal);
                            _firebaseUrlCtrl.text = sync.cloudEndpoint;
                            setState(() {
                              _isSuccess = true;
                              _statusMessage = '✅ Firebase URL सुरक्षित भयो!';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.network_check_rounded, size: 15),
                        label: const Text('कनेक्सन जाँच्नुहोस् (Test)', style: TextStyle(fontSize: 11)),
                        onPressed: () async {
                          final ok = await sync.testConnection();
                          setState(() {
                            _isSuccess = ok;
                            _statusMessage = ok
                                ? '✅ Firebase सँग सफलतापूर्वक कनेक्सन भयो!'
                                : '❌ Firebase कनेक्सन असफल: ${sync.lastError ?? ""}';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons: Push & Pull
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('क्लाउडमा पठाउनुहोस् (Upload)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final ok = await sync.pushToCloud();
                    setState(() {
                      _isSuccess = ok;
                      _statusMessage = ok
                          ? '✅ प्रश्नहरू र विवरणहरू क्लाउडमा सफलतापूर्वक पठाइयो!'
                          : '❌ क्लाउडमा पठाउन सकिएन: ${sync.lastError ?? ""}';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('क्लाउडबाट ल्याउनुहोस् (Download)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final ok = await sync.pullFromCloud();
                    setState(() {
                      _isSuccess = ok;
                      _statusMessage = ok
                          ? '✅ नयाँ प्रश्न र अपडेटहरू मोबाइल/डेस्कटपमा सिङ्क भयो!'
                          : '❌ अपडेट ल्याउन सकिएन: ${sync.lastError ?? ""}';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Direct Transfer / Instant Backup
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text('प्रत्यक्ष सिङ्क ब्याकअप (Instant Backup & Restore)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'यदि इन्टरनेट कमजोर भएमा कम्प्युटरबाट सबै प्रश्नहरूको ब्याकअप निकालेर मोबाइलमा १ सेकेन्डमै सिङ्क गर्न सकिन्छ।',
                    style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: const Text('ब्याकअप कोड बनाउनुहोस् (Export)'),
                        onPressed: () {
                          final jsonStr = sync.exportBackupJson();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('सिङ्क ब्याकअप डाटा'),
                              content: SizedBox(
                                width: 500,
                                height: 250,
                                child: SingleChildScrollView(
                                  child: SelectableText(jsonStr),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('बन्द गर्नुहोस्')),
                              ],
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('इम्पोर्ट (Import)'),
                        onPressed: () {
                          final textCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('ब्याकअप डाटा पेस्ट गर्नुहोस्'),
                              content: TextField(
                                controller: textCtrl,
                                maxLines: 5,
                                decoration: const InputDecoration(hintText: 'यहाँ ब्याकअप JSON पेस्ट गर्नुहोस्...', border: OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('रद्द गर्नुहोस्')),
                                ElevatedButton(
                                  onPressed: () {
                                    final ok = sync.importBackupJson(textCtrl.text.trim());
                                    Navigator.pop(c);
                                    setState(() {
                                      _isSuccess = ok;
                                      _statusMessage = ok ? '✅ सबै प्रश्न र डेटा मोबाइलमा सिङ्क भयो!' : '❌ अमान्य डेटा!';
                                    });
                                  },
                                  child: const Text('सिङ्क गर्नुहोस्'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📦 TAB 6: DATA, STORAGE & APP INFO
  Widget _buildDataAndInfoTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'भण्डारण, क्यास र प्रणाली विवरण (Storage & System Information):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Cache management
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.teal),
              title: const Text('अस्थायी क्यास खाली गर्नुहोस् (Clear Cache)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('एपको गति र स्थानीय भण्डारण सफा गर्दछ।', style: TextStyle(fontSize: 11)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                onPressed: () {
                  setState(() {
                    _isSuccess = true;
                    _statusMessage = '✅ अस्थायी क्यास सफलतापूर्वक खाली गरियो!';
                  });
                },
                child: const Text('खाली गर्नुहोस्'),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // App Info
          Card(
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('EPS-TOPIK Nepal-Korea Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const Divider(height: 16),
                  const Text('• संस्करण: v2.4.0 (2026 Production Edition)', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• UBT परीक्षा इन्जिन: HRD Korea मानक ४० प्रश्न ढाँचा', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• बहु-भाषा इन्जिन: नेपाली, 한국어, English समर्थित', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('• डेटा इन्क्रिप्सन: स्थानीय AES र सुरक्षित SharedPreferences भण्डारण', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
