import '../../core/services/cloud_sync_service.dart';
import '../../core/services/language_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/services/download_helper.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart'; // To access StudentDashboard and AdminDashboard
import '../../core/services/auth_service.dart';
import '../super_admin/super_admin_dashboard.dart';

/// Unified Authentication Screen with Auto Role Detection (Admin & Student)
/// Supports 1-Click Google Sign-In, Mobile Number OTP Login,
/// Standard Username/Password, Registration, and Password Reset.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CloudSyncService.instance.pullFromCloud(silent: true).catchError((_) => false);
      if (kIsWeb) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) _showAppDownloadPopup();
        });
      }
    });
  }


  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = "";

  final List<String> _batchesList = [
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
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final identifier = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = LanguageService.instance.trText(ne: "कृपया आफ्नो Username, मोबाइल नम्बर वा पासवर्ड भर्नुहोस्!", en: "Please enter your Username/Mobile and password!", ko: "아이디/휴대폰 번호 및 비밀번호를 입력해 주세요!");
      });
      return;
    }

    // Unified login: Auto-detects admin or student
    final user = AuthService.instance.login(identifier, password);

    if (user != null) {
      setState(() {
        _errorMessage = "";
      });

      if (user.role == UserRole.superAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuperAdminDashboardScreen()),
        );
      } else if (user.role == UserRole.admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: user)),
        );
      }
    } else {
      setState(() {
        _errorMessage = LanguageService.instance.trText(ne: "लगइन विवरण मिलेन! कृपया सही Username/मोबाइल नम्बर र पासवर्ड हाल्नुहोस्।", en: "Invalid credentials! Please check your details.", ko: "로그인 정보가 올바르지 않습니다.");
      });
    }
  }

  /// 1-Click Google Sign-In Flow
  void _showGoogleSignInDialog() {
    final customEmailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
            const SizedBox(width: 8),
            Text(
              LanguageService.instance.trText(
                ne: 'Google खाता छान्नुहोस्',
                en: 'Select Google Account',
                ko: 'Google 계정 선택',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService.instance.trText(
                  ne: 'EPS-TOPIK प्रणालीमा लगइन गर्न आफ्नो Google खाता रोज्नुहोस्:',
                  en: 'Choose your Google account to log into EPS-TOPIK system:',
                  ko: 'EPS-TOPIK 시스템 로그인을 위한 구글 계정을 선택해 주세요:',
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              
              // Google Account Option 1
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                title: const Text('राम बहादुर (Ram Bahadur)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('ram.bahadur@gmail.com', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeGoogleLogin('ram.bahadur@gmail.com', 'राम बहादुर');
                },
              ),
              const SizedBox(height: 10),

              // Google Account Option 2
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                title: const Text('सीता शर्मा (Sita Sharma)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('sita.sharma@gmail.com', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeGoogleLogin('sita.sharma@gmail.com', 'सीता शर्मा');
                },
              ),
              const SizedBox(height: 16),

              // Custom Gmail Input
              Text(
                LanguageService.instance.trText(
                  ne: 'वा अन्य Gmail खाता प्रयोग गर्नुहोस्:',
                  en: 'Or enter another Gmail account:',
                  ko: '또는 다른 Gmail 계정 직접 입력:',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: customEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your_email@gmail.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Color(0xFF1E3A8A)),
                    onPressed: () {
                      final email = customEmailCtrl.text.trim();
                      if (email.isNotEmpty && email.contains('@')) {
                        Navigator.pop(ctx);
                        _executeGoogleLogin(email, email.split('@')[0]);
                      }
                    },
                  ),
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
        ],
      ),
    );
  }

  void _executeGoogleLogin(String email, String name) {
    final user = AuthService.instance.loginWithGoogle(email: email, displayName: name);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: user)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.instance.trText(
            ne: '🎉 Google मार्फत स्वागत छ, ${user.name}!',
            en: '🎉 Welcome via Google, ${user.name}!',
            ko: '🎉 Google 로그인 환영합니다, ${user.name}님!',
          ),
        ),
        backgroundColor: Colors.teal,
      ),
    );
  }

  /// Direct Mobile OTP Login Flow
  void _showMobileOtpDialog() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    String generatedOtp = '';
    bool otpSent = false;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.phone_android_rounded, color: Color(0xFF0F766E), size: 24),
              const SizedBox(width: 8),
              Text(
                LanguageService.instance.trText(
                  ne: 'मोबाइल नम्बरबाट लगइन',
                  en: 'Login with Mobile OTP',
                  ko: '휴대폰 번호 OTP 로그인',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (!otpSent) ...[
                  Text(
                    LanguageService.instance.trText(
                      ne: 'तपाईंको १० अङ्कको मोबाइल नम्बर हाल्नुहोस्:',
                      en: 'Enter your 10-digit mobile number:',
                      ko: '휴대폰 번호를 입력해 주세요:',
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'मोबाइल नम्बर', en: 'Mobile Number', ko: '휴대폰 번호'),
                      hintText: 'e.g. 9812345678',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                      onPressed: () {
                        final phone = phoneCtrl.text.trim();
                        if (phone.length < 8) {
                          setDialogState(() => error = LanguageService.instance.trText(
                            ne: 'कृपया सही मोबाइल नम्बर भर्नुहोस्!',
                            en: 'Please enter a valid mobile number!',
                            ko: '올바른 휴대폰 번호를 입력해 주세요!',
                          ));
                          return;
                        }
                        // Generate mock 4-digit OTP
                        final rng = Random();
                        generatedOtp = (1000 + rng.nextInt(9000)).toString();
                        otpCtrl.text = generatedOtp; // Auto-fill for seamless user experience
                        setDialogState(() {
                          otpSent = true;
                          error = '';
                        });
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(
                        LanguageService.instance.trText(
                          ne: 'OTP कोड पठाउनुहोस्',
                          en: 'Send OTP Code',
                          ko: '인증번호 발송',
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LanguageService.instance.trText(
                              ne: 'मोबाइल ${phoneCtrl.text} मा OTP पठाइयो! (परीक्षण कोड: $generatedOtp)',
                              en: 'OTP sent to ${phoneCtrl.text}! (Demo Code: $generatedOtp)',
                              ko: '${phoneCtrl.text}로 OTP 발송 완료! (테스트 코드: $generatedOtp)',
                            ),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: '४ अङ्कको OTP कोड प्रविष्ट गर्नुहोस्',
                        en: 'Enter 4-digit OTP code',
                        ko: '4자리 인증번호 입력',
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_clock),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      onPressed: () {
                        final entered = otpCtrl.text.trim();
                        if (entered != generatedOtp) {
                          setDialogState(() => error = LanguageService.instance.trText(
                            ne: 'गलत OTP कोड! कृपया फेरि प्रयास गर्नुहोस्।',
                            en: 'Invalid OTP code! Please try again.',
                            ko: '잘못된 인증번호입니다. 다시 시도해 주세요.',
                          ));
                          return;
                        }
                        final student = AuthService.instance.loginWithMobileOtp(mobileNumber: phoneCtrl.text.trim());
                        if (student != null) {
                          Navigator.pop(ctx);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: student)),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LanguageService.instance.trText(
                                  ne: '📱 मोबाइल लगइन सफल भयो! स्वागत छ ${student.name}',
                                  en: '📱 Mobile login successful! Welcome ${student.name}',
                                  ko: '📱 모바일 로그인 완료! 환영합니다 ${student.name}님',
                                ),
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        LanguageService.instance.trText(
                          ne: 'सत्यापन गरी लगइन गर्नुहोस्',
                          en: 'Verify & Login',
                          ko: '인증 완료 및 로그인',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  /// Registration Dialog (नयाँ खाता दर्ता)
  void _showRegisterDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String selectedBatch = _batchesList.first;
    String selectedSector = _sectorsList.first;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1E3A8A), size: 24),
              const SizedBox(width: 10),
              Text(
                LanguageService.instance.trText(
                  ne: 'नयाँ विद्यार्थी दर्ता',
                  en: 'New Student Registration',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'पूरा नाम*', en: 'Full Name*', ko: '성명*'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'मोबाइल नम्बर*', en: 'Mobile Number*', ko: '휴대폰 번호*'),
                      hintText: 'e.g. 9812345678',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'दर्ता / सिम्बोल नम्बर', en: 'Registration / Symbol No', ko: '수험번호 / 등록번호'),
                      hintText: LanguageService.instance.trText(ne: 'वैकल्पिक (e.g. 01234575)', en: 'Optional (e.g. 01234575)', ko: '선택 사항'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'प्रयोगकर्ता नाम (Username)*', en: 'Username*', ko: '아이디(Username)*'),
                      hintText: 'e.g. ram123',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'पासवर्ड*', en: 'Password*', ko: '비밀번호*'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: confirmPassCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'कन्फर्म पासवर्ड*', en: 'Confirm Password*', ko: '비밀번호 확인*'),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'ब्याच*', en: 'Batch*', ko: '반/기수*'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _batchesList.map((b) => DropdownMenuItem(value: b, child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSector,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'औद्योगिक क्षेत्र', en: 'Industry Sector', ko: '업종 분야'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(LanguageService.instance.sectorText(s), style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedSector = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'कृपया सबै आवश्यक (*) विवरणहरू भर्नुहोस्!',
                    en: 'Please fill in all required (*) fields!',
                    ko: '모든 필수(*) 항목을 입력해 주세요!',
                  ));
                  return;
                }
                if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'पासवर्ड र कन्फर्म पासवर्ड मिलेन!',
                    en: 'Passwords do not match!',
                    ko: '비밀번호가 일치하지 않습니다!',
                  ));
                  return;
                }
                final ok = AuthService.instance.registerStudent(
                  name: nameCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  mobileNumber: phoneCtrl.text.trim(),
                  registrationNo: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  batch: selectedBatch,
                  sector: selectedSector,
                );
                if (ok) {
                  Navigator.pop(ctx);
                  final newUser = AuthService.instance.currentUser;
                  if (newUser != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: newUser)),
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageService.instance.trText(
                          ne: '✅ खाता सफलतापूर्वक सिर्जना भयो! स्वागत छ!',
                          en: '✅ Account successfully created! Welcome!',
                          ko: '✅ 계정이 성공적으로 등록되었습니다! 환영합니다!',
                        ),
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'यो Username वा मोबाइल नम्बर पहिले नै दर्ता भइसकेको छ!',
                    en: 'Username or Mobile Number is already registered!',
                    ko: '이미 등록된 아이디 또는 휴대폰 번호입니다!',
                  ));
                }
              },
              child: Text(LanguageService.instance.trText(ne: 'दर्ता गर्नुहोस्', en: 'Register', ko: '회원가입')),
            ),
          ],
        ),
      ),
    );
  }

  /// Forgot Password Dialog (मोबाइल नम्बरबाट पासवर्ड रिसेट)
  void _showForgotPasswordDialog() {
    final phoneOrUserCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFF0F766E), size: 24),
              const SizedBox(width: 10),
              Text(
                LanguageService.instance.trText(
                  ne: 'पासवर्ड रिसेट',
                  en: 'Reset Password',
                  ko: '비밀번호 재설정',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                Text(
                  LanguageService.instance.trText(
                    ne: 'तपाईंको दर्ता गरिएको मोबाइल नम्बर वा Username हाल्नुहोस् र नयाँ पासवर्ड सेट गर्नुहोस्:',
                    en: 'Enter your registered mobile or username and set a new password:',
                    ko: '등록된 휴대폰 번호 또는 아이디를 입력하고 새 비밀번호를 설정하세요:',
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneOrUserCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'मोबाइल नम्बर वा Username*', en: 'Mobile or Username*', ko: '휴대폰 또는 아이디*'),
                    hintText: 'e.g. 9841234567',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'नयाँ पासवर्ड*', en: 'New Password*', ko: '새 비밀번호*'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'नयाँ पासवर्ड पुष्टि*', en: 'Confirm New Password*', ko: '새 비밀번호 확인*'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.check_circle_outline),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                final id = phoneOrUserCtrl.text.trim();
                final p1 = newPassCtrl.text.trim();
                final p2 = confirmPassCtrl.text.trim();

                if (id.isEmpty || p1.isEmpty) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'कृपया मोबाइल नम्बर र नयाँ पासवर्ड भर्नुहोस्!',
                    en: 'Please enter mobile/username and new password!',
                    ko: '휴대폰 번호/아이디와 새 비밀번호를 입력하세요!',
                  ));
                  return;
                }
                if (p1 != p2) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'पासवर्ड र कन्फर्म पासवर्ड मिलेन!',
                    en: 'Passwords do not match!',
                    ko: '비밀번호가 일치하지 않습니다!',
                  ));
                  return;
                }

                final ok = AuthService.instance.resetPassword(mobileOrUsername: id, newPassword: p1);
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageService.instance.trText(
                          ne: '✅ पासवर्ड सफलतापूर्वक परिवर्तन भयो! अब नयाँ पासवर्डले लगइन गर्नुहोस्।',
                          en: '✅ Password changed successfully! Please login with new password.',
                          ko: '✅ 비밀번호가 변경되었습니다! 새 비밀번호로 로그인해 주세요.',
                        ),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'यो मोबाइल नम्बर वा Username भेटिएन!',
                    en: 'Mobile number or Username not found!',
                    ko: '등록된 정보가 일치하지 않습니다!',
                  ));
                }
              },
              child: Text(LanguageService.instance.trText(ne: 'पासवर्ड सेभ गर्नुहोस्', en: 'Save Password', ko: '비밀번호 저장')),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Show "Install Mobile App" Download Popup on Web
  void _showAppDownloadPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.android_rounded, color: Colors.green, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.instance.trText(
                        ne: 'EPS-TOPIK Android एप',
                        en: 'EPS-TOPIK Android App',
                        ko: 'EPS-TOPIK 안드로이드 앱',
                      ),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      LanguageService.instance.trText(
                        ne: 'अहिले नै मोबाइलमा इन्स्टल गर्नुहोस्',
                        en: 'Install directly on your phone now',
                        ko: '지금 모바일에 설치하세요',
                      ),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                LanguageService.instance.trText(
                  ne: 'कहिले पनि इन्टरनेट वा सर्भर नरोकियोस्! अब सम्पूर्ण परीक्षा र अध्ययन सिधै आफ्नो मोबाइलमा:',
                  en: 'Never be stopped by internet issues! Full exams and study directly on your phone:',
                  ko: '인터넷 연결 없이도 끊김 없는 100% 오프라인 UBT 시험과 학습 지원:',
                ),
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildFeatureBullet(Icons.wifi_off_rounded, LanguageService.instance.trText(ne: 'इन्टरनेट बिना पनि चल्ने अफलाइन परीक्षा प्रणाली', en: '100% Offline Exam Hall without Internet', ko: '인터넷 없이 작동하는 오프라인 시험 시스템')),
              _buildFeatureBullet(Icons.headset_rounded, LanguageService.instance.trText(ne: 'किताबका सबै अडियो ट्र्याकहरू उच्च गुणस्तरमा उपलब्ध', en: 'All 60 textbook audio tracks in high fidelity', ko: '60과 표준교재 전 트랙 고음질 오디오')),
              _buildFeatureBullet(Icons.quiz_rounded, LanguageService.instance.trText(ne: 'HRD Korea आधिकारिक ढाँचाको ४० प्रश्न UBT हल', en: 'HRD Korea Standard 40-Question UBT Hall', ko: '한국산업인력공단 표준 40문항 UBT 시험장')),
              _buildFeatureBullet(Icons.cloud_sync_rounded, LanguageService.instance.trText(ne: 'कम्प्युटरसँग Firebase बाट सधैँ सिङ्क हुने', en: 'Instant Cloud Sync with Web & Institute Portal', ko: '웹 및 학원 서버와의 자동 클라우드 동기화')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.download_for_offline_rounded, size: 22),
                  label: Text(
                    LanguageService.instance.trText(
                      ne: 'APK सिधै डाउनलोड गर्नुहोस् (५४.९ MB)',
                      en: 'Download APK Directly (54.9 MB)',
                      ko: 'APK 직접 다운로드 (54.9 MB)',
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    triggerApkDownload();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageService.instance.trText(
                            ne: '📥 Android APK डाउनलोड सुरु भयो! डाउनलोड फोल्डर हेर्नुहोस्।',
                            en: '📥 Android APK download started! Check your downloads folder.',
                            ko: '📥 안드로이드 APK 다운로드가 시작되었습니다!',
                          ),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
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
            child: Text(
              LanguageService.instance.trText(
                ne: 'अहिले वेबसाइटमै चलाउँछु (Later)',
                en: 'Continue on Web (Later)',
                ko: '웹에서 계속하기 (나중에)',
              ),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Modern Dark Slate EPS Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Language Switcher Bar
                Container(
                  width: 440,
                  margin: const EdgeInsets.only(top: 16, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            LanguageService.instance.tr('language') + ':',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      CloudSyncService.instance.buildSyncAction(context, iconColor: Colors.amber),
                      ...AppLanguage.values.map((lang) {
                        final isSel = LanguageService.instance.currentLanguage == lang;
                        return InkWell(
                          onTap: () => LanguageService.instance.setLanguage(lang),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.amber : Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${lang.flag} ${lang.displayName}',
                              style: TextStyle(
                                color: isSel ? Colors.black87 : Colors.white,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                if (kIsWeb)
                  Container(
                    width: 440,
                    margin: const EdgeInsets.only(top: 6, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.android_rounded, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageService.instance.trText(
                                  ne: '📱 Android मोबाइल एप उपलब्ध छ!',
                                  en: '📱 Android App Available!',
                                  ko: '📱 Android 앱 다운로드 가능!',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                LanguageService.instance.trText(
                                  ne: 'अफलाइन परीक्षा र ६० च्याप्टर अब मोबाइलमै।',
                                  en: 'Offline exam & 60 chapters on your mobile.',
                                  ko: '오프라인 시험과 60과 학습을 모바일에서.',
                                ),
                                style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            LanguageService.instance.trText(ne: 'APK डाउनलोड', en: 'APK Download', ko: 'APK 다운'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            triggerApkDownload();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(LanguageService.instance.trText(
                                  ne: '📥 Android APK डाउनलोड सुरु भयो!',
                                  en: '📥 Android APK download started!',
                                  ko: '📥 Android APK 다운로드가 시작되었습니다!',
                                )),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: 440,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(34),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  // Institute Emblem & Branding
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.school_rounded, size: 44, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "EPS-TOPIK KOREA",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    LanguageService.instance.tr('app_subtitle'),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 1-Click Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _showGoogleSignInDialog,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                      label: Text(
                        LanguageService.instance.tr('google_sign_in'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Direct Mobile Number OTP Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _showMobileOtpDialog,
                      icon: const Icon(Icons.phone_android, size: 18, color: Color(0xFF0F766E)),
                      label: Text(
                        LanguageService.instance.tr('mobile_otp_login'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDFA),
                        side: const BorderSide(color: Color(0xFF99F6E4), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider (OR)
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(LanguageService.instance.trText(ne: "वा Password ले लगइन", en: "OR Login with Password", ko: "또는 비밀번호로 로그인"), style: const TextStyle(color: Colors.black45, fontSize: 11)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error Message Banner
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Unified Identifier Field (Username / Mobile / Reg No)
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: "Username, मोबाइल वा दर्ता नम्बर", en: "Username, Mobile or Reg No", ko: "아이디, 휴대폰 또는 수험번호"),
                      hintText: "e.g. 9841234567 वा student वा admin",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E3A8A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 14),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.tr("password"),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 6),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 26)),
                      child: Text(
                        LanguageService.instance.tr('forgot_password'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Login Button (Auto-detects Admin / Student)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(LanguageService.instance.tr("sign_in"), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register New Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _showRegisterDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(LanguageService.instance.tr("register_account"), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
    ),
    );
  }
}
