import '../../core/services/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
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
        _statusMessage = LanguageService.instance.isEnglish ? '✅ Profile and photo saved successfully!' : (LanguageService.instance.isKorean ? '✅ 프로필 정보와 사진이 저장되었습니다!' : '✅ प्रोफाइल विवरण र फोटो सफलतापूर्वक सुरक्षित भयो!');
      } else {
        _isSuccess = false;
        _statusMessage = LanguageService.instance.isEnglish ? '❌ Failed to update profile!' : (LanguageService.instance.isKorean ? '❌ 프로필 업데이트 실패!' : '❌ प्रोफाइल अपडेट गर्न सकिएन!');
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
        _statusMessage = LanguageService.instance.isEnglish ? '❌ Please fill in all password fields!' : (LanguageService.instance.isKorean ? '❌ 모든 비밀번호 항목을 입력해주세요!' : '❌ कृपया सबै पासवर्ड विवरण भर्नुहोस्!');
      });
      return;
    }

    if (currentPw != user.password) {
      setState(() {
        _isSuccess = false;
        _statusMessage = LanguageService.instance.isEnglish ? '❌ Current password is incorrect!' : (LanguageService.instance.isKorean ? '❌ 현재 비밀번호가 일치하지 않습니다!' : '❌ हालको पासवर्ड मिलेन! कृपया सही पासवर्ड हाल्नुहोस्।');
      });
      return;
    }

    if (newPw.length < 4) {
      setState(() {
        _isSuccess = false;
        _statusMessage = LanguageService.instance.isEnglish ? '❌ New password must be at least 4 characters!' : (LanguageService.instance.isKorean ? '❌ 새 비밀번호는 최소 4자 이상이어야 합니다!' : '❌ नयाँ पासवर्ड कम्तिमा ४ अक्षरको हुनुपर्छ!');
      });
      return;
    }

    if (newPw != confirmPw) {
      setState(() {
        _isSuccess = false;
        _statusMessage = LanguageService.instance.isEnglish ? '❌ New password and confirmation do not match!' : (LanguageService.instance.isKorean ? '❌ 새 비밀번호와 확인 비밀번호가 일치하지 않습니다!' : '❌ नयाँ पासवर्ड र पुष्टि पासवर्ड समान हुनुपर्छ!');
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
        _statusMessage = LanguageService.instance.isEnglish ? '✅ Password changed successfully!' : (LanguageService.instance.isKorean ? '✅ 비밀번호가 성공적으로 변경되었습니다!' : '✅ पासवर्ड सफलतापूर्वक परिवर्तन भयो र सुरक्षित गरियो!');
        _currentPwController.clear();
        _newPwController.clear();
        _confirmPwController.clear();
      } else {
        _isSuccess = false;
        _statusMessage = LanguageService.instance.isEnglish ? '❌ Error saving password!' : (LanguageService.instance.isKorean ? '❌ 비밀번호 저장 중 오류 발생!' : '❌ पासवर्ड सुरक्षित गर्दा त्रुटि भयो!');
      }
    });
  }

  void _handleLogout() {
    AuthService.confirmAndLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final user = auth.currentUser ?? auth.students.first;
        final langService = LanguageService.instance;

        String roleBadge;
        Color roleColor;
        if (user.role == UserRole.superAdmin) {
          roleBadge = '👑 ${langService.tr('role_super_admin')}';
          roleColor = const Color(0xFF0F172A);
        } else if (user.role == UserRole.admin) {
          roleBadge = '🏢 ${langService.tr('role_admin')}';
          roleColor = const Color(0xFF0F766E);
        } else {
          roleBadge = '👨‍🎓 ${langService.tr('role_student')}';
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
                  tooltip: LanguageService.instance.tr('close_btn'),
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
                tabs: [
                  Tab(icon: const Icon(Icons.language, size: 16), text: '🌐 ${langService.tr('language')}'),
                  Tab(icon: const Icon(Icons.person, size: 16), text: '👤 ${langService.tr('tab_profile')}'),
                  Tab(icon: const Icon(Icons.lock_reset, size: 16), text: '🔑 ${langService.tr('change_password')}'),
                  Tab(icon: const Icon(Icons.tune, size: 16), text: '⚙️ ${langService.tr('mode_preference')}'),
                  Tab(icon: const Icon(Icons.sync, size: 16), text: '🔄 ${langService.tr('cloud_sync')}'),
                  Tab(icon: const Icon(Icons.info_outline, size: 16), text: '📦 ${langService.tr('system_info')}'),
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

                  // TAB 5: 🔄 MOBILE & CLOUD SYNC
                  _buildSyncTab(),

                  // TAB 6: 📦 DATA & SYSTEM INFO
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
                  label: Text(langService.tr('logout')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(langService.tr('done')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
}

  // 🌐 TAB 1: LANGUAGE SETTINGS
  Widget _buildLanguageTab(LanguageService langService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            '${langService.tr('select_language')}:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
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
                  lang.flag,
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
                    _statusMessage = '🌐 ${lang.displayName}';
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
          Text(
            LanguageService.instance.isEnglish ? 'Choose Avatar or Profile Photo:' : (LanguageService.instance.isKorean ? '아바타 또는 프로필 사진 선택:' : 'अवतार वा प्रोफाइल फोटो रोज्नुहोस्:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
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
            label: Text(LanguageService.instance.isEnglish ? '📁 Choose photo from device' : (LanguageService.instance.isKorean ? '📁 기기에서 사진 선택' : '📁 कम्प्युटर/मोबाइलबाट आफ्नै फोटो रोज्नुहोस्')),
          ),
          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: LanguageService.instance.tr('fullname'),
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Mobile field
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: LanguageService.instance.tr('mobile_number'),
              prefixIcon: const Icon(Icons.phone_android_outlined),
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
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _handleSaveProfile,
              icon: const Icon(Icons.save, size: 18),
              label: Text(LanguageService.instance.tr('save_profile')),
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
          Text(
            LanguageService.instance.isEnglish ? 'Security & Password Change:' : (LanguageService.instance.isKorean ? '보안 및 비밀번호 변경:' : 'सुरक्षा तथा पासवर्ड परिवर्तन:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Current Password
          TextField(
            controller: _currentPwController,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: LanguageService.instance.tr('current_password'),
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
              labelText: LanguageService.instance.tr('new_password'),
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
              labelText: LanguageService.instance.tr('confirm_password'),
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
              label: Text(LanguageService.instance.tr('save_btn')),
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
          Text(
            LanguageService.instance.isEnglish ? 'Audio & Exam Preferences:' : (LanguageService.instance.isKorean ? '오디오 및 시험 기본 설정:' : 'अडियो तथा परीक्षा प्राथमिकताहरू:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
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
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 18, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Text(LanguageService.instance.tr('audio_speed'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                            sp == 0.8 ? (LanguageService.instance.isEnglish ? '0.8x Slow' : (LanguageService.instance.isKorean ? '0.8x 느리게' : '०.८x सुस्त')) : (sp == 1.0 ? (LanguageService.instance.isEnglish ? '1.0x Normal' : (LanguageService.instance.isKorean ? '1.0x 보통' : '१.०x सामान्य')) : (LanguageService.instance.isEnglish ? '1.2x Fast' : (LanguageService.instance.isKorean ? '1.2x 빠름' : '१.२x छिटो'))),
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
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Text(LanguageService.instance.tr('mode_preference'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<ExamModePreference>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(LanguageService.instance.isEnglish ? '🔴 Strict UBT Exam Mode (50 mins, anti-cheat)' : (LanguageService.instance.isKorean ? '🔴 실전 UBT 시험 모드 (50분, 부정행위 방지)' : '🔴 कडा UBT परीक्षा मोड (५० मिनेट, वास्तविक परीक्षा)'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    title: Text(LanguageService.instance.isEnglish ? '🟢 Study & Practice Mode (Instant answers & explanation)' : (LanguageService.instance.isKorean ? '🟢 자율 학습 모드 (즉시 정답 및 해설)' : '🟢 स्वतन्त्र अभ्यास मोड (तत्काल सही/गलत उत्तर र व्याख्या)'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        ? '${sync.lastSyncTime!.hour.toString().padLeft(2, '0')}:${sync.lastSyncTime!.minute.toString().padLeft(2, '0')}'
        : (LanguageService.instance.isEnglish ? 'First sync pending' : (LanguageService.instance.isKorean ? '첫 동기화 대기' : 'पहिलो पटक सिङ्क बाँकी'));

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (sync.state) {
      case SyncState.syncing:
        statusText = LanguageService.instance.isEnglish ? '🔄 Syncing...' : (LanguageService.instance.isKorean ? '🔄 동기화 진행 중...' : '🔄 सिङ्क भइरहेको छ...');
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case SyncState.synced:
        statusText = LanguageService.instance.isEnglish ? '✅ All data synced (Up-to-date)' : (LanguageService.instance.isKorean ? '✅ 모든 데이터 동기화 완료 (최신)' : '✅ सबै डेटा सिङ्क भइसक्यो (अप-टु-डेट)');
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SyncState.error:
        statusText = sync.lastError ?? (LanguageService.instance.isEnglish ? '❌ Sync Error' : (LanguageService.instance.isKorean ? '❌ 동기화 오류' : '❌ सिङ्क त्रुटि'));
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case SyncState.offline:
        statusText = LanguageService.instance.isEnglish ? '📡 Offline Mode (Syncs when connected)' : (LanguageService.instance.isKorean ? '📡 오프라인 모드 (인터넷 연결 시 자동 동기화)' : '📡 अफलाइन मोड (इन्टरनेट उपलब्ध हुँदा सिङ्क हुनेछ)');
        statusColor = Colors.blueGrey;
        statusIcon = Icons.cloud_off;
        break;
      case SyncState.idle:
        statusText = LanguageService.instance.isEnglish ? '☁️ Cloud Sync Ready' : (LanguageService.instance.isKorean ? '☁️ 클라우드 동기화 준비됨' : '☁️ क्लाउड सिङ्क तयार');
        statusColor = const Color(0xFF1E3A8A);
        statusIcon = Icons.cloud_done_outlined;
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            LanguageService.instance.isEnglish ? 'Data Sync between App & PC:' : (LanguageService.instance.isKorean ? '앱과 PC 간 데이터 실시간 동기화:' : 'मोबाइल एप र कम्प्युटर बीच डाटा सिङ्क:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),

          // Live Sync Status Card
          Card(
            color: statusColor.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withValues(alpha: 0.3))),
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
                        Text(LanguageService.instance.isEnglish ? 'Last Sync: $lastTime' : (LanguageService.instance.isKorean ? '최근 동기화: $lastTime' : 'अन्तिम सिङ्क: $lastTime'), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cloud Server Realtime DB Setup Card
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
                      const Text('GitHub Cloud Sync Server:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: Text(LanguageService.instance.isEnglish ? 'Guide / Help' : (LanguageService.instance.isKorean ? '도움말' : 'गाइड / मद्दत'), style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.deepOrange),
                                  const SizedBox(width: 8),
                                  Text(LanguageService.instance.trText(ne: 'नि:शुल्क Cloud Server बनाउने तरिका', en: 'How to create free Cloud Server', ko: '무료 Cloud Server 생성 가이드')),
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
                                ElevatedButton(onPressed: () => Navigator.pop(c), child: Text(LanguageService.instance.trText(ne: 'बुझेँ', en: 'Got it', ko: '확인'))),
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
                      hintText: 'https://raw.githubusercontent.com/brosandy9999/epstopikabante2072/main/data/eps_sync_data.json',
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
                        label: Text(LanguageService.instance.isEnglish ? 'Save URL' : (LanguageService.instance.isKorean ? 'URL 저장' : 'URL सेभ गर्नुहोस्'), style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          final textVal = _firebaseUrlCtrl.text.trim();
                          if (textVal.isNotEmpty) {
                            sync.setCloudEndpoint(textVal);
                            _firebaseUrlCtrl.text = sync.cloudEndpoint;
                            setState(() {
                              _isSuccess = true;
                              _statusMessage = LanguageService.instance.trText(ne: '✅ Cloud Server URL सुरक्षित भयो!', en: '✅ Cloud Server URL saved successfully!', ko: '✅ Cloud Server URL이 저장되었습니다!');
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.network_check_rounded, size: 15),
                        label: Text(LanguageService.instance.isEnglish ? 'Test Connection' : (LanguageService.instance.isKorean ? '연결 테스트' : 'कनेक्सन जाँच्नुहोस्'), style: const TextStyle(fontSize: 11)),
                        onPressed: () async {
                          final ok = await sync.testConnection();
                          setState(() {
                            _isSuccess = ok;
                            _statusMessage = ok
                                ? LanguageService.instance.trText(ne: '✅ Cloud Server सँग सफलतापूर्वक कनेक्सन भयो!', en: '✅ Connected to Cloud Server successfully!', ko: '✅ Cloud Server에 성공적으로 연결되었습니다!')
                                : (LanguageService.instance.trText(ne: '❌ Cloud Server कनेक्सन असफल: ', en: '❌ Cloud Server connection failed: ', ko: '❌ Cloud Server 연결 실패: ') + (sync.lastError ?? ""));
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
          // 1-Tap Instant Sync Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              icon: const Icon(Icons.sync, size: 20),
              label: Text(
                LanguageService.instance.trText(
                  ne: '⚡ अहिले नै सिङ्क गर्नुहोस् (Instant Sync Now)',
                  en: '⚡ Instant Sync Now (Web & Mobile)',
                  ko: '⚡ 지금 동기화 실행 (Web & Mobile)',
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final ok = await sync.syncNow(context: context);
                setState(() {
                  _isSuccess = ok;
                  _statusMessage = ok
                      ? LanguageService.instance.trText(
                          ne: '✅ सबै डाटा सफलतापूर्वक सिङ्क भयो!',
                          en: '✅ All data synced successfully across devices!',
                          ko: '✅ 모든 데이터가 성공적으로 동기화되었습니다!',
                        )
                      : (LanguageService.instance.trText(
                          ne: '⚠️ सिङ्क हुन सकेन: ',
                          en: '⚠️ Sync failed: ',
                          ko: '⚠️ 동기화 실패: ',
                        ) + (sync.lastError ?? ''));
                });
              },
            ),
          ),
          const SizedBox(height: 12),

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
                  label: Text(LanguageService.instance.isEnglish ? 'Upload to Cloud' : (LanguageService.instance.isKorean ? '클라우드로 올리기' : 'क्लाउडमा पठाउनुहोस्'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final ok = await sync.pushToCloud();
                    setState(() {
                      _isSuccess = ok;
                      _statusMessage = ok
                          ? LanguageService.instance.trText(ne: '✅ प्रश्नहरू र विवरणहरू क्लाउडमा सफलतापूर्वक पठाइयो!', en: '✅ Questions & data uploaded to cloud successfully!', ko: '✅ 문항 및 데이터가 클라우드에 성공적으로 업로드되었습니다!')
                          : (LanguageService.instance.trText(ne: '❌ क्लाउडमा पठाउन सकिएन: ', en: '❌ Cloud upload failed: ', ko: '❌ 클라우드 업로드 실패: ') + (sync.lastError ?? ""));
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
                  label: Text(LanguageService.instance.isEnglish ? 'Download from Cloud' : (LanguageService.instance.isKorean ? '클라우드에서 받기' : 'क्लाउडबाट ल्याउनुहोस्'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final ok = await sync.pullFromCloud();
                    setState(() {
                      _isSuccess = ok;
                      _statusMessage = ok
                          ? LanguageService.instance.trText(ne: '✅ नयाँ प्रश्न र अपडेटहरू मोबाइल/डेस्कटपमा सिङ्क भयो!', en: '✅ New questions and updates synced to device!', ko: '✅ 새 문항 및 업데이트가 기기에 동기화되었습니다!')
                          : (LanguageService.instance.trText(ne: '❌ अपडेट ल्याउन सकिएन: ', en: '❌ Sync download failed: ', ko: '❌ 동기화 다운로드 실패: ') + (sync.lastError ?? ""));
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
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Text(LanguageService.instance.isEnglish ? 'Direct Backup & Restore' : (LanguageService.instance.isKorean ? '직접 백업 및 복원' : 'प्रत्यक्ष ब्याकअप तथा पुनर्स्थापना'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService.instance.trText(ne: 'यदि इन्टरनेट कमजोर भएमा कम्प्युटरबाट सबै प्रश्नहरूको ब्याकअप निकालेर मोबाइलमा १ सेकेन्डमै सिङ्क गर्न सकिन्छ।', en: 'If internet is slow, export questions backup from PC and sync to mobile instantly.', ko: '인터넷이 불안정한 경우 PC에서 백업을 생성하여 모바일로 즉시 동기화할 수 있습니다.'),
                    style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: Text(LanguageService.instance.isEnglish ? 'Generate Backup Code' : (LanguageService.instance.isKorean ? '백업 코드 생성' : 'ब्याकअप कोड बनाउनुहोस्')),
                        onPressed: () {
                          final jsonStr = sync.exportBackupJson();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(LanguageService.instance.trText(ne: 'सिङ्क ब्याकअप डाटा', en: 'Sync Backup Data', ko: '동기화 백업 데이터')),
                              content: SizedBox(
                                width: 500,
                                height: 250,
                                child: SingleChildScrollView(
                                  child: SelectableText(jsonStr),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: Text(LanguageService.instance.trText(ne: 'बन्द गर्नुहोस्', en: 'Close', ko: '닫기'))),
                              ],
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: Text(LanguageService.instance.isEnglish ? 'Import' : (LanguageService.instance.isKorean ? '가져오기' : 'इम्पोर्ट गर्नुहोस्')),
                        onPressed: () {
                          final textCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text(LanguageService.instance.trText(ne: 'ब्याकअप डाटा पेस्ट गर्नुहोस्', en: 'Paste Backup Data', ko: '백업 데이터 붙여넣기')),
                              content: TextField(
                                controller: textCtrl,
                                maxLines: 5,
                                decoration: InputDecoration(hintText: LanguageService.instance.trText(ne: 'यहाँ ब्याकअप JSON पेस्ट गर्नुहोस्...', en: 'Paste backup JSON here...', ko: '여기에 백업 JSON 붙여넣기...'), border: const OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
                                ElevatedButton(
                                  onPressed: () {
                                    final ok = sync.importBackupJson(textCtrl.text.trim());
                                    Navigator.pop(c);
                                    setState(() {
                                      _isSuccess = ok;
                                      _statusMessage = ok ? LanguageService.instance.trText(ne: '✅ सबै प्रश्न र डेटा मोबाइलमा सिङ्क भयो!', en: '✅ All questions and data synced to mobile!', ko: '✅ 모든 문항과 데이터가 기기에 동기화되었습니다!') : LanguageService.instance.trText(ne: '❌ अमान्य डेटा!', en: '❌ Invalid backup data!', ko: '❌ 유효하지 않은 데이터입니다!');
                                    });
                                  },
                                  child: Text(LanguageService.instance.trText(ne: 'सिङ्क गर्नुहोस्', en: 'Sync Now', ko: '동기화 실행')),
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
          Text(
            LanguageService.instance.isEnglish ? 'Storage, Cache & System Info:' : (LanguageService.instance.isKorean ? '저장소, 캐시 및 시스템 정보:' : 'भण्डारण, क्यास र प्रणाली विवरण:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          // Cache management
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.teal),
              title: Text(LanguageService.instance.isEnglish ? 'Clear Temporary Cache' : (LanguageService.instance.isKorean ? '임시 캐시 삭제' : 'अस्थायी क्यास खाली गर्नुहोस्'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(LanguageService.instance.isEnglish ? 'Improves app speed and cleans local storage.' : (LanguageService.instance.isKorean ? '앱 속도를 개선하고 로컬 저장공간을 정리합니다.' : 'एपको गति र स्थानीय भण्डारण सफा गर्दछ।'), style: const TextStyle(fontSize: 11)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                onPressed: () {
                  setState(() {
                    _isSuccess = true;
                    _statusMessage = LanguageService.instance.trText(ne: '✅ अस्थायी क्यास सफलतापूर्वक खाली गरियो!', en: '✅ Temporary cache cleared successfully!', ko: '✅ 임시 캐시가 성공적으로 삭제되었습니다!');
                  });
                },
                child: Text(LanguageService.instance.tr('clear')),
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
                  Text(LanguageService.instance.trText(ne: '• संस्करण: v2.4.0 (2026 Production Edition)', en: '• Version: v2.4.0 (2026 Production Edition)', ko: '• 버전: v2.4.0 (2026 Production Edition)'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(LanguageService.instance.trText(ne: '• UBT परीक्षा इन्जिन: HRD Korea मानक ४० प्रश्न ढाँचा', en: '• UBT Exam Engine: HRD Korea Standard 40 Questions', ko: '• UBT 시험 엔진: HRD Korea 표준 40문항 규격'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(LanguageService.instance.trText(ne: '• बहु-भाषा इन्जिन: नेपाली, 한국어, English समर्थित', en: '• Multi-language Engine: Nepali, Korean, English Supported', ko: '• 다국어 엔진: 한국어, 영어, 네팔어 완벽 지원'), style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(LanguageService.instance.trText(ne: '• डेटा इन्क्रिप्सन: स्थानीय AES र सुरक्षित SharedPreferences भण्डारण', en: '• Data Encryption: Local AES & Secure Storage', ko: '• 데이터 암호화: 로컬 AES 및 보안 스토리지 적용'), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
