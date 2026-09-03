import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _pwFormKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    if (!_pwFormKey.currentState!.validate()) return;

    final auth = AuthService.instance;
    final currentUser = auth.currentUser ?? auth.students.first;

    if (_currentPwController.text.trim() != currentUser.password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ हालको पासवर्ड मिलेन! कृपया सही पासवर्ड हाल्नुहोस्।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPwController.text.trim() != _confirmPwController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ नयाँ पासवर्ड र पुष्टि पासवर्ड समान हुनुपर्छ!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = auth.updateStudentCredentials(
      studentId: currentUser.id,
      newPassword: _newPwController.text.trim(),
    );

    if (success) {
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ पासवर्ड सफलतापूर्वक परिवर्तन गरियो र सुरक्षित भयो!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = LanguageService.instance;
    final currentLang = langService.currentLanguage;
    final currentMode = langService.modePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              langService.tr('settings'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------
            // 1. LANGUAGE SELECTION (भाषा छनौट)
            // -----------------------------------------------------------
            _buildSectionHeader(Icons.language, langService.tr('language')),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildLanguageTile(
                      lang: AppLanguage.nepali,
                      title: '🇳🇵 नेपाली (Nepali)',
                      subtitle: 'सबै निर्देशन, बटन र व्याख्या नेपाली भाषामा',
                      isSelected: currentLang == AppLanguage.nepali,
                      onTap: () {
                        setState(() {
                          langService.setLanguage(AppLanguage.nepali);
                        });
                      },
                    ),
                    const Divider(height: 1),
                    _buildLanguageTile(
                      lang: AppLanguage.english,
                      title: '🇬🇧 English',
                      subtitle: 'All interface elements and explanations in English',
                      isSelected: currentLang == AppLanguage.english,
                      onTap: () {
                        setState(() {
                          langService.setLanguage(AppLanguage.english);
                        });
                      },
                    ),
                    const Divider(height: 1),
                    _buildLanguageTile(
                      lang: AppLanguage.korean,
                      title: '🇰🇷 한국어 (Korean)',
                      subtitle: '한국어 원문 및 공식 UBT 시험 인터페이스',
                      isSelected: currentLang == AppLanguage.korean,
                      onTap: () {
                        setState(() {
                          langService.setLanguage(AppLanguage.korean);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------
            // 2. EXAM VS STUDY MODE PREFERENCE (मोड सेलेक्ट)
            // -----------------------------------------------------------
            _buildSectionHeader(Icons.tune, langService.tr('mode_preference')),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildModeTile(
                      icon: Icons.timer,
                      iconColor: const Color(0xFF1E3A8A),
                      title: langService.tr('strict_exam_mode'),
                      subtitle: langService.tr('strict_exam_desc'),
                      isSelected: currentMode == ExamModePreference.strictExam,
                      onTap: () {
                        setState(() {
                          langService.setModePreference(ExamModePreference.strictExam);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎯 कडा परीक्षा मोड (Strict Real Exam Mode) चयन गरियो।')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildModeTile(
                      icon: Icons.auto_stories,
                      iconColor: const Color(0xFF0F766E),
                      title: langService.tr('study_practice_mode'),
                      subtitle: langService.tr('study_practice_desc'),
                      isSelected: currentMode == ExamModePreference.studyPractice,
                      onTap: () {
                        setState(() {
                          langService.setModePreference(ExamModePreference.studyPractice);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📖 अध्ययन तथा अभ्यास मोड (Study & Practice Mode) चयन गरियो।')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------
            // 3. CHANGE PASSWORD (पासवर्ड चेन्ज)
            // -----------------------------------------------------------
            _buildSectionHeader(Icons.lock_reset, langService.tr('change_password')),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _pwFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _currentPwController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: langService.tr('current_password'),
                          prefixIcon: const Icon(Icons.key, color: Color(0xFF1E3A8A)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'हालको पासवर्ड हाल्नुहोस्' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newPwController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: langService.tr('new_password'),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E3A8A)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().length < 4) ? 'कम्तिमा ४ अक्षरको नयाँ पासवर्ड हाल्नुहोस्' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPwController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: langService.tr('confirm_password'),
                          prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF1E3A8A)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'नयाँ पासवर्ड पुनः पुष्टि गर्नुहोस्' : null,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleChangePassword,
                          icon: const Icon(Icons.save),
                          label: Text(langService.tr('update_password_btn')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------
            // 4. AUDIO PLAYBACK SPEED (अडियो गति)
            // -----------------------------------------------------------
            _buildSectionHeader(Icons.speed, langService.tr('audio_speed')),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '듣기 (Listening) प्रश्नहरूको अडियो उच्चारण गति:',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildSpeedChip(0.85, '🐢 0.85x'),
                        const SizedBox(width: 8),
                        _buildSpeedChip(1.0, '🚶 1.0x'),
                        const SizedBox(width: 8),
                        _buildSpeedChip(1.15, '⚡ 1.15x'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // -----------------------------------------------------------
            // 5. CACHE & RESET (डाटा व्यवस्थापन)
            // -----------------------------------------------------------
            _buildSectionHeader(Icons.storage, 'अफलाइन भण्डारण तथा क्यास (Offline Storage & Data)'),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'स्थानीय मेमोरीमा सुरक्षित परीक्षा नतिजा वा क्यास हटाउन:',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _confirmClearData(context),
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text('सबै परीक्षा इतिहास रिसेट गर्नुहोस् (Reset All Attempts)',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. ACCOUNT LOGOUT (लगआउट)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
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
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          },
                          child: const Text('हो, लगआउट गर्नुहोस्'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('खाता लगआउट गर्नुहोस् (Logout)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 30),

            // 7. APP VERSION & INFO
            Center(
              child: Column(
                children: [
                  const Text('EPS-TOPIK UBT Examination System',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0 • Offline Ready ✅',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
        ),
      ],
    );
  }

  Widget _buildLanguageTile({
    required AppLanguage lang,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A), size: 24)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.06) : Colors.transparent,
    );
  }

  Widget _buildModeTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? iconColor : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: iconColor, size: 24)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? iconColor.withOpacity(0.06) : Colors.transparent,
    );
  }

  Widget _buildSpeedChip(double speed, String label) {
    final langService = LanguageService.instance;
    final isSelected = (langService.audioSpeed - speed).abs() < 0.01;

    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              langService.setAudioSpeed(speed);
            });
          }
        },
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('डाटा रिसेट पुष्टि (Confirm Reset)'),
        content: const Text('के तपाईं सबै पुराना परीक्षा नतिजाहरू हटाउन चाहनुहुन्छ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await StorageService.instance.clearAll();
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ सबै डाटा सफलतापूर्वक रिसेट गरियो।'), backgroundColor: Colors.green),
              );
            },
            child: const Text('हटाउनुहोस् (Clear)'),
          ),
        ],
      ),
    );
  }
}
