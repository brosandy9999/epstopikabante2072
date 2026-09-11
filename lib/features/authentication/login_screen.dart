import '../../core/models/institute_model.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/language_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/services/download_helper.dart';
import '../../core/widgets/device_download_modal.dart';
import '../../core/services/platform_detector.dart';
import '../security/android_web_gatekeeper_screen.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart'; // To access StudentDashboard and AdminDashboard
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/firebase_google_auth_service.dart';
import '../../core/services/whatsapp_otp_service.dart';
import '../super_admin/super_admin_dashboard.dart';
import 'approval_pending_screen.dart';

/// Unified Authentication Screen with Auto Role Detection (Admin & Student)
/// Supports 1-Click Google Sign-In, Mobile Number OTP Login,
/// Standard Username/Password, Registration, and Password Reset.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _activeInstituteId = 'inst_abante_ktm';

  @override
  void initState() {
    super.initState();
    _loadSavedInstitute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isAndroidWeb) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AndroidWebGatekeeperScreen()),
          );
        }
        return;
      }
      CloudSyncService.instance.pullFromCloud(silent: true).catchError((_) => false);
    });
  }

  void _loadSavedInstitute() {
    try {
      final savedId = StorageService.instance.getString('eps_last_active_institute_id') ??
                      StorageService.instance.getString('eps_selected_institute_id');
      if (savedId != null && savedId.isNotEmpty) {
        final institutes = InstituteService.instance.getAllInstitutes();
        if (institutes.any((i) => i.id == savedId)) {
          setState(() {
            _activeInstituteId = savedId;
          });
        }
      }
    } catch (_) {}
  }

  void _selectInstitute(String instituteId) {
    setState(() {
      _activeInstituteId = instituteId;
    });
    try {
      StorageService.instance.setString('eps_last_active_institute_id', instituteId);
      StorageService.instance.setString('eps_selected_institute_id', instituteId);
    } catch (_) {}
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
      } else if (user.isPendingApproval) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ApprovalPendingScreen(student: user)),
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

  /// Official Firebase Google Sign-In Flow
  Future<void> _handleGoogleSignIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                LanguageService.instance.trText(
                  ne: 'Google लगइन विन्डो खुल्दैछ...',
                  en: 'Connecting to Google Sign-In...',
                  ko: 'Google 로그인 연결 중...',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                LanguageService.instance.trText(
                  ne: 'कृपया पपअप विन्डोमा आफ्नो Google खाता छान्नुहोस्',
                  en: 'Please choose your Google account in popup',
                  ko: '팝업 창에서 구글 계정을 선택해 주세요',
                ),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final res = await FirebaseGoogleAuthService.instance.signInWithGoogle();
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

      if (res['success'] == true) {
        final email = (res['email'] as String?) ?? '';
        final displayName = (res['displayName'] as String?) ?? '';
        final photoUrl = res['photoUrl'] as String?;
        final uid = res['uid'] as String?;

        if (email.isNotEmpty) {
          _processGoogleAuthResult(
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            googleUid: uid,
          );
        }
      } else {
        final errMsg = (res['message'] as String?) ?? 'Google Sign-In हुन सकेन।';
        if (mounted) {
          _showGoogleFallbackDialog(errMsg);
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        _showGoogleFallbackDialog(e.toString());
      }
    }
  }

  /// Process Google Auth: Checks if student already exists or needs Institute selection registration
  void _processGoogleAuthResult({
    required String email,
    required String displayName,
    String? photoUrl,
    String? googleUid,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUser = cleanEmail.split('@')[0];

    // Check existing student in local list
    final existingUser = AuthService.instance.students.cast<AppUser?>().firstWhere(
      (s) => s != null && (
        s.username.toLowerCase() == cleanUser ||
        (s.registrationNo != null && s.registrationNo!.toLowerCase() == cleanEmail) ||
        (googleUid != null && s.id == googleUid)
      ),
      orElse: () => null,
    );

    if (existingUser != null) {
      // Existing user: direct login
      final user = AuthService.instance.loginWithGoogle(
        email: cleanEmail,
        displayName: displayName,
        photoUrl: photoUrl,
        googleUid: googleUid,
      );

      if (user.isPendingApproval) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ApprovalPendingScreen(student: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: user)),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.instance.trText(
              ne: '🎉 Google मार्फत स्वागत छ, ${user.name}!',
              en: '🎉 Welcome back via Google, ${user.name}!',
              ko: '🎉 Google 로그인 환영합니다, ${user.name}님!',
            ),
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } else {
      // New Google User: Show Institute Selection & Registration Modal
      _showGoogleInstituteRegistrationDialog(
        email: cleanEmail,
        name: displayName.isNotEmpty ? displayName : cleanUser,
        photoUrl: photoUrl,
        googleUid: googleUid,
      );
    }
  }

  /// Google New Registration Dialog with Institute Selection
  void _showGoogleInstituteRegistrationDialog({
    required String email,
    required String name,
    String? photoUrl,
    String? googleUid,
  }) {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController();
    
    final institutes = InstituteService.instance.getAllInstitutes();
    String selectedInstituteId = institutes.isNotEmpty ? institutes.first.id : 'inst_abante_ktm';
    String selectedBatch = _batchesList.first;
    String selectedSector = _sectorsList.first;
    String regError = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentInst = institutes.firstWhere(
            (i) => i.id == selectedInstituteId,
            orElse: () => institutes.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.instance.trText(
                            ne: 'Google दर्ता तथा इन्स्टिच्युट छनोट',
                            en: 'Google Registration & Institute Choice',
                            ko: '구글 신규 회원가입 및 학원 선택',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        Text(
                          LanguageService.instance.trText(
                            ne: 'कृपया आफ्नो इन्स्टिच्युट छानेर दर्ता पूरा गर्नुहोस्',
                            en: 'Select your institute to complete registration',
                            ko: '소속 학원을 선택하여 회원가입을 완료하세요',
                          ),
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Google Account Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageService.instance.trText(ne: 'प्रमाणित Google खाता:', en: 'Verified Google Account:', ko: '인증된 구글 계정:'),
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (regError.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(regError, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),

                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: LanguageService.instance.trText(ne: 'पूरा नाम (Full Name)*', en: 'Full Name*', ko: '성명*'),
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mobile Number (WhatsApp)
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: LanguageService.instance.trText(ne: 'मोबाइल नम्बर (Mobile / WhatsApp)', en: 'Mobile / WhatsApp (Optional)', ko: '휴대폰 번호 (선택)'),
                        hintText: 'e.g. 9841234567',
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF1E3A8A)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Institute Selector
                    Text(
                      LanguageService.instance.trText(ne: 'आफ्नो इन्स्टिच्युट छान्नुहोस्:*', en: 'Select Your Institute:*', ko: '소속 학원 선택:*'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedInstituteId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF0F766E)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: institutes.map((inst) {
                        return DropdownMenuItem<String>(
                          value: inst.id,
                          child: Text(inst.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedInstituteId = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Job Sector & Batch
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LanguageService.instance.trText(ne: 'क्षेत्र (Sector):', en: 'Sector:', ko: '직종:'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedSector,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (v) => setDialogState(() => selectedSector = v ?? selectedSector),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(LanguageService.instance.trText(ne: 'सत्र (Batch):', en: 'Batch:', ko: '반/기수:'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedBatch,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: _batchesList.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 11)))).toList(),
                                onChanged: (v) => setDialogState(() => selectedBatch = v ?? selectedBatch),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Institute Admin Approval Notice Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LanguageService.instance.trText(
                                ne: 'दर्ता पूरा गरेपछि तपाईंको ID ${currentInst.name} का इन्स्टिच्युट एडमिनले सक्रिय (Active) गरिदिनुहुनेछ।',
                                en: 'After registration, ${currentInst.name} admin will activate your student ID.',
                                ko: '가입 후 ${currentInst.name} 관리자가 학생 계정을 승인/활성화합니다.',
                              ),
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.35),
                            ),
                          ),
                        ],
                      ),
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                label: Text(
                  LanguageService.instance.trText(
                    ne: 'दर्ता पूरा गरी स्वीकृति अनुरोध पठाउनुहोस्',
                    en: 'Submit Registration & Request Approval',
                    ko: '가입 신청 및 승인 요청',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  final finalName = nameCtrl.text.trim();
                  if (finalName.isEmpty) {
                    setDialogState(() {
                      regError = LanguageService.instance.trText(
                        ne: 'कृपया आफ्नो पूरा नाम भर्नुहोस्!',
                        en: 'Please enter your full name!',
                        ko: '성명을 입력해 주세요!',
                      );
                    });
                    return;
                  }

                  Navigator.pop(ctx);

                  final user = AuthService.instance.loginWithGoogle(
                    email: email,
                    displayName: finalName,
                    photoUrl: photoUrl,
                    googleUid: googleUid,
                    instituteId: currentInst.id,
                    instituteName: currentInst.name,
                    mobileNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                    batch: selectedBatch,
                    sector: selectedSector,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ApprovalPendingScreen(student: user)),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LanguageService.instance.trText(
                          ne: '🎉 Google दर्ता सफल भयो! तपाईंको आईडी ${currentInst.name} मा स्वीकृतिको लागि पठाइयो।',
                          en: '🎉 Registration submitted! Pending approval from ${currentInst.name}.',
                          ko: '🎉 가입 신청 완료! ${currentInst.name} 승인 대기 중입니다.',
                        ),
                      ),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Gmail Fallback Dialog when Firebase Console Google Provider is not enabled
  void _showGoogleFallbackDialog(String? reason) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LanguageService.instance.trText(
                  ne: 'Google / Gmail मार्फत लगइन',
                  en: 'Sign in with Google / Gmail',
                  ko: 'Google / Gmail 로그인',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageService.instance.trText(
                            ne: 'आफ्नो वास्तविक Gmail ठेगाना हालेर EPS-TOPIK परीक्षा प्रणालीमा सुरक्षित लगइन वा दर्ता गर्नुहोस्:',
                            en: 'Enter your Gmail address to securely sign into EPS-TOPIK system:',
                            ko: 'Gmail 계정을 입력하여 EPS-TOPIK 시스템에 안전하게 로그인하세요:',
                          ),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'Gmail ठेगाना (Email)*', en: 'Gmail Address*', ko: 'Gmail 이메일*'),
                    hintText: 'e.g. sujan123@gmail.com',
                    prefixIcon: const Icon(Icons.mail_outline, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'विद्यार्थीको नाम (ऐच्छिक)', en: 'Candidate Name (Optional)', ko: '성명 (선택)'),
                    hintText: 'e.g. सुजन श्रेष्ठ (Sujan Shrestha)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(
                      LanguageService.instance.tr('sign_in'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      final email = emailCtrl.text.trim().toLowerCase();
                      if (!email.contains('@') || !email.contains('.')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(LanguageService.instance.trText(
                              ne: 'कृपया सही Gmail ठेगाना भर्नुहोस्!',
                              en: 'Please enter a valid Gmail address!',
                              ko: '올바른 Gmail 주소를 입력해 주세요!',
                            )),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : email.split('@')[0];
                      _processGoogleAuthResult(email: email, displayName: name);
                    },
                  ),
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
        ],
      ),
    );
  }

  /// Direct WhatsApp OTP Login Flow
  void _showMobileOtpDialog() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final institutes = InstituteService.instance.getAllInstitutes();
    String selectedInstituteId = institutes.isNotEmpty ? institutes.first.id : 'inst_abante_ktm';

    String generatedOtp = '';
    bool otpSent = false;
    bool isSending = false;
    String error = '';
    String infoMessage = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentInst = institutes.firstWhere(
            (i) => i.id == selectedInstituteId,
            orElse: () => institutes.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.instance.trText(
                            ne: 'WhatsApp OTP लगइन / दर्ता',
                            en: 'WhatsApp OTP Login / Register',
                            ko: 'WhatsApp OTP 로그인 / 가입',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        Text(
                          LanguageService.instance.trText(
                            ne: 'मोबाइल नम्बरमा आधिकारिक ६ अङ्कको OTP कोड',
                            en: 'Official 6-digit OTP code to mobile number',
                            ko: '휴대폰으로 발송되는 6자리 공식 인증코드',
                          ),
                          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
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

                    if (!otpSent) ...[
                      Text(
                        LanguageService.instance.trText(
                          ne: 'आफ्नो १० अङ्कको WhatsApp भएको मोबाइल नम्बर हाल्नुहोस्:',
                          en: 'Enter your 10-digit WhatsApp mobile number:',
                          ko: 'WhatsApp이 등록된 휴대폰 번호를 입력하세요:',
                        ),
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(ne: 'मोबाइल नम्बर (Mobile Number)*', en: 'Mobile Number*', ko: '휴대폰 번호*'),
                          hintText: 'e.g. 9851234567',
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF25D366)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Optional Name (for new candidates)
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(ne: 'विद्यार्थीको नाम (नयाँ भएमा ऐच्छिक)', en: 'Candidate Name (Optional if new)', ko: '성명 (신규 등록 시)'),
                          hintText: 'e.g. सुजन श्रेष्ठ (Sujan Shrestha)',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Institute Selection
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LanguageService.instance.trText(ne: 'सोसिएसन इन्स्टिच्युट (Institute):', en: 'Institute Association:', ko: '소속 학원:'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F766E)),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedInstituteId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              items: institutes.map((inst) => DropdownMenuItem(
                                value: inst.id,
                                child: Text(
                                  '${inst.name} (${inst.address})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedInstituteId = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isSending
                              ? null
                              : () async {
                                  final phone = phoneCtrl.text.trim();
                                  if (phone.length < 8) {
                                    setDialogState(() => error = LanguageService.instance.trText(
                                      ne: 'कृपया सही मोबाइल नम्बर भर्नुहोस्!',
                                      en: 'Please enter a valid mobile number!',
                                      ko: '올바른 휴대폰 번호를 입력해 주세요!',
                                    ));
                                    return;
                                  }

                                  setDialogState(() {
                                    isSending = true;
                                    error = '';
                                  });

                                  final result = await WhatsAppOtpService.instance.sendOtp(phone);
                                  setDialogState(() {
                                    isSending = false;
                                    if (result['success'] == true) {
                                      otpSent = true;
                                      generatedOtp = result['otp'] ?? '';
                                      infoMessage = result['message'] ?? 'WhatsApp मा OTP पठाइयो!';
                                      if (result['isSimulated'] == true && generatedOtp.isNotEmpty) {
                                        otpCtrl.text = generatedOtp; // Auto-fill in demo mode
                                      }
                                    } else {
                                      error = result['message'] ?? 'OTP पठाउन सकिएन';
                                    }
                                  });
                                },
                          icon: isSending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            isSending
                                ? LanguageService.instance.trText(ne: 'पठाउँदैछ...', en: 'Sending...', ko: '발송 중...')
                                : LanguageService.instance.trText(
                                    ne: '💬 WhatsApp OTP कोड पठाउनुहोस्',
                                    en: '💬 Send WhatsApp OTP Code',
                                    ko: '💬 WhatsApp OTP 발송',
                                  ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ] else ...[
                      // STEP 2: OTP VERIFICATION
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF16A34A), size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                infoMessage.isNotEmpty
                                    ? infoMessage
                                    : LanguageService.instance.trText(
                                        ne: 'मोबाइल ${phoneCtrl.text} मा ६ अङ्कको OTP पठाइयो!',
                                        en: '6-digit OTP sent to ${phoneCtrl.text}!',
                                        ko: '${phoneCtrl.text}로 6자리 OTP가 발송되었습니다!',
                                      ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(
                            ne: '६ अङ्कको OTP कोड प्रविष्ट गर्नुहोस्',
                            en: 'Enter 6-digit OTP code',
                            ko: '6자리 인증번호 입력',
                          ),
                          hintText: '------',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFF25D366)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Resend option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 14),
                            label: Text(
                              LanguageService.instance.trText(ne: 'पुनः कोड पठाउनुहोस्', en: 'Resend Code', ko: '재발송'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final res = await WhatsAppOtpService.instance.sendOtp(phoneCtrl.text.trim());
                              setDialogState(() {
                                if (res['success'] == true) {
                                  generatedOtp = res['otp'] ?? '';
                                  infoMessage = res['message'] ?? 'नयाँ कोड पठाइयो';
                                  if (res['isSimulated'] == true && generatedOtp.isNotEmpty) {
                                    otpCtrl.text = generatedOtp;
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final entered = otpCtrl.text.trim();
                            final isValid = WhatsAppOtpService.instance.verifyOtp(phoneCtrl.text.trim(), entered);

                            if (!isValid) {
                              setDialogState(() => error = LanguageService.instance.trText(
                                ne: '❌ गलत वा म्याद सकिएको OTP कोड! कृपया फेरि प्रयास गर्नुहोस्।',
                                en: '❌ Invalid or expired OTP code! Please try again.',
                                ko: '❌ 잘못되었거나 만료된 인증번호입니다. 다시 시도해 주세요.',
                              ));
                              return;
                            }

                            final student = AuthService.instance.loginWithMobileOtp(
                              mobileNumber: phoneCtrl.text.trim(),
                              name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                              instituteId: currentInst.id,
                              instituteName: currentInst.name,
                            );

                            if (student != null) {
                              Navigator.pop(ctx);
                              if (student.isPendingApproval) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => ApprovalPendingScreen(student: student)),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: student)),
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LanguageService.instance.trText(
                                      ne: '🎉 WhatsApp OTP प्रमाणीकरण सफल भयो! स्वागत छ ${student.name}',
                                      en: '🎉 WhatsApp OTP verified successfully! Welcome ${student.name}',
                                      ko: '🎉 WhatsApp OTP 인증 완료! 환영합니다 ${student.name}님',
                                    ),
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            LanguageService.instance.trText(
                              ne: 'सत्यापन गरी लगइन गर्नुहोस्',
                              en: 'Verify & Login',
                              ko: '인증 완료 및 로그인',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LanguageService.instance.tr('cancel')),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Registration Dialog (नयाँ खाता दर्ता - इन्स्टिच्युट छनोट सहित)
  void _showRegisterDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    final institutes = InstituteService.instance.getAllInstitutes();
    String selectedInstituteId = institutes.isNotEmpty ? institutes.first.id : 'inst_abante_ktm';
    String selectedBatch = _batchesList.first;
    String selectedSector = _sectorsList.first;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentInst = institutes.firstWhere(
            (i) => i.id == selectedInstituteId,
            orElse: () => institutes.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: 'नयाँ विद्यार्थी दर्ता (इन्स्टिच्युट छनोट)',
                      en: 'New Student Registration',
                      ko: '새 수험생 등록 (학원 선택)',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 460,
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

                    // Institute Selection Field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, size: 18, color: Color(0xFF0F766E)),
                              const SizedBox(width: 6),
                              Text(
                                LanguageService.instance.trText(
                                  ne: 'आफ्नो इन्स्टिच्युट छनोट गर्नुहोस्*',
                                  en: 'Select Your Institute*',
                                  ko: '소속 학원 선택*',
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedInstituteId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            items: institutes.map((inst) => DropdownMenuItem(
                              value: inst.id,
                              child: Text(
                                '${inst.name} (${inst.address})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedInstituteId = val);
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.instance.trText(
                              ne: '📌 दर्ता भएपछि ${currentInst.name} को एडमिनले स्वीकृत गरेपछि मात्र खाता सक्रिय हुनेछ।',
                              en: '📌 Account will be activated after approval from ${currentInst.name} admin.',
                              ko: '📌 등록 후 ${currentInst.name} 관리자의 승인 후에 정식 활성화됩니다.',
                            ),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), height: 1.3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
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
                  final newStudent = AuthService.instance.registerStudentWithInstitute(
                    name: nameCtrl.text.trim(),
                    username: userCtrl.text.trim(),
                    mobileNumber: phoneCtrl.text.trim(),
                    registrationNo: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    instituteId: currentInst.id,
                    instituteName: currentInst.name,
                    batch: selectedBatch,
                    sector: selectedSector,
                  );
                  if (newStudent != null) {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ApprovalPendingScreen(student: newStudent)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LanguageService.instance.trText(
                            ne: '🎉 दर्ता सफलतापूर्वक सम्पन्न भयो! तपाईंको खाता स्वीकृतिको प्रतीक्षामा छ।',
                            en: '🎉 Registered successfully! Account is pending institute approval.',
                            ko: '🎉 등록이 완료되었습니다! 학원 관리자의 승인을 기다려 주세요.',
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
          );
        },
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
              _buildFeatureBullet(Icons.wifi_off_rounded, LanguageService.instance.trText(ne: 'इन्टरनेट बिना पनि चल्ने १००% अफलाइन परीक्षा प्रणाली', en: '100% Offline Exam Hall without Internet', ko: '인터넷 없이 작동하는 오프라인 시험 시스템')),
              _buildFeatureBullet(Icons.headset_rounded, LanguageService.instance.trText(ne: '६० वटै पाठ्यपुस्तकका अडियो ट्र्याकहरू उच्च गुणस्तरमा उपलब्ध', en: 'All 60 textbook audio tracks in high fidelity', ko: '60과 표준교재 전 트랙 고음질 오디오')),
              _buildFeatureBullet(Icons.quiz_rounded, LanguageService.instance.trText(ne: 'HRD Korea आधिकारिक ढाँचाको ४० प्रश्न (२० R + २० L) UBT हल', en: 'HRD Korea Standard 40-Question UBT Hall', ko: '한국산업인력공단 표준 40문항 UBT 시험장')),
              _buildFeatureBullet(Icons.insights_rounded, LanguageService.instance.trText(ne: 'कमजोरी विश्लेषण, तत्काल नतिजा र रिभ्यु नोट', en: 'Weakness Analysis, Instant Score & Review Note', ko: '취약점 분석, 즉시 성적표 및 오답노트')),
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
                      ne: 'APK सिधै डाउनलोड गर्नुहोस् (१९.५ MB)',
                      en: 'Download APK Directly (19.5 MB)',
                      ko: 'APK 직접 다운로드 (19.5 MB)',
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
              const SizedBox(height: 10),
              if (!kIsWeb)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    LanguageService.instance.trText(
                      ne: '✨ एपका सबै विशेषताहरू हेर्नुहोस्',
                      en: '✨ Explore All App Features',
                      ko: '✨ 앱 전체 기능 상세 보기',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AndroidWebGatekeeperScreen(showBackButton: true)),
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
                ne: 'बन्द गर्नुहोस् (Close)',
                en: 'Close',
                ko: '닫기',
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

                if (!kIsWeb)  // Android app banner — mobile only
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
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AndroidWebGatekeeperScreen(showBackButton: true)),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        LanguageService.instance.trText(
                                          ne: '📱 Android मोबाइल एप उपलब्ध छ!',
                                          en: '📱 Android App Available!',
                                          ko: '📱 Android 앱 다운로드 가능!',
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF1E3A8A)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LanguageService.instance.trText(
                                    ne: 'अफलाइन परीक्षा र ६० च्याप्टर अब मोबाइलमै (विवरण हेर्नुहोस्)',
                                    en: 'Offline exam & 60 chapters on mobile (View details)',
                                    ko: '오프라인 시험과 60과 학습을 모바일에서 (상세보기)',
                                  ),
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                ),
                              ],
                            ),
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
                  // Dynamic Institute Emblem & Branding Header
                  Builder(
                    builder: (context) {
                      final institutes = InstituteService.instance.getAllInstitutes();
                      final activeInst = institutes.firstWhere(
                        (i) => i.id == _activeInstituteId,
                        orElse: () => institutes.isNotEmpty
                            ? institutes.first
                            : InstituteProfile(
                                id: 'inst_abante_ktm',
                                name: 'Abante Korean Language (Abante Academy)',
                                code: 'ABANTE_KTM',
                                logoUrl: '',
                                phone: '014168102',
                                email: 'info@abante.edu.np',
                                address: 'बागबजार, काठमाडौं',
                                aboutUs: '',
                                allowedSetsQuota: 5,
                                validityExpiry: DateTime.now().add(const Duration(days: 365)),
                                maxStudentsQuota: 200,
                                isActive: true,
                              ),
                      );

                      return Column(
                        children: [
                          // Institute Logo Avatar with Glow Effect
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: ClipOval(
                              child: activeInst.logoUrl.isNotEmpty
                                  ? Image.asset(
                                      activeInst.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Center(
                                        child: Text(
                                          activeInst.name.isNotEmpty ? activeInst.name[0] : '🏢',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        activeInst.name.isNotEmpty ? activeInst.name[0] : '🏢',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Institute Name
                          Text(
                            activeInst.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.2,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Institute Address & Phone
                          Text(
                            activeInst.address + (activeInst.phone.isNotEmpty ? ' • 📞 ${activeInst.phone}' : ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),

                          // Official UBT Training Partner Badge & Switcher Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 14, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  LanguageService.instance.trText(
                                    ne: 'आधिकारिक UBT परीक्षा केन्द्र',
                                    en: 'Official UBT Exam Center',
                                    ko: '공식 UBT 시험 센터',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                if (institutes.length > 1) ...[
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    tooltip: LanguageService.instance.trText(
                                      ne: 'इन्स्टिच्युट छान्नुहोस्',
                                      en: 'Switch Institute',
                                      ko: '학원 변경',
                                    ),
                                    onSelected: (instId) => _selectInstitute(instId),
                                    itemBuilder: (ctx) => institutes.map((inst) {
                                      final isSelected = inst.id == activeInst.id;
                                      return PopupMenuItem<String>(
                                        value: inst.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.check_circle_rounded : Icons.apartment_rounded,
                                              size: 16,
                                              color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                inst.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            LanguageService.instance.trText(ne: 'फेर्नुहोस्', en: 'Switch', ko: '변경'),
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                                          ),
                                          const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF2563EB)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),

                  // 1-Click Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
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

                  const SizedBox(height: 14),

                  // Explore App Features Link
                  if (!kIsWeb)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AndroidWebGatekeeperScreen(showBackButton: true)),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              LanguageService.instance.trText(
                                ne: 'एपका ६ मुख्य विशेषता तथा सुविधाहरू हेर्नुहोस् ➜',
                                en: 'Explore 6 Key Features of the App ➜',
                                ko: '앱의 6가지 핵심 기능 상세 보기 ➜',
                              ),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
