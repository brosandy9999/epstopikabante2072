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
        _errorMessage = "कृपया आफ्नो Username, मोबाइल नम्बर वा पासवर्ड भर्नुहोस्!";
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
        _errorMessage = "लगइन विवरण गलत छ! कृपया सहि Username/मोबाइल नम्बर र पासवर्ड हाल्नुहोस्।";
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
        title: const Row(
          children: [
            Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text('Google खाता छान्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('EPS-TOPIK प्रणालीमा लगइन गर्न आफ्नो Google खाता रोज्नुहोस्:', style: TextStyle(fontSize: 13, color: Colors.black54)),
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
              const Text('वा अन्य Gmail खाता प्रयोग गर्नुहोस्:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 6),
              TextField(
                controller: customEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'तपाईंको_gmail@gmail.com',
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
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
      SnackBar(content: Text('🎉 Google मार्फत स्वागत छ, ${user.name}!'), backgroundColor: Colors.teal),
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
          title: const Row(
            children: [
              Icon(Icons.phone_android_rounded, color: Color(0xFF0F766E), size: 24),
              SizedBox(width: 8),
              Text('मोबाइल नम्बरबाट लगइन', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text('तपाईंको १० अङ्कको मोबाइल नम्बर हाल्नुहोस्:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'मोबाइल नम्बर (Mobile Number)', hintText: 'e.g. 9812345678', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
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
                          setDialogState(() => error = 'कृपया सही मोबाइल नम्बर भर्नुहोस्!');
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
                      label: const Text('OTP कोड पठाउनुहोस्'),
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
                        Expanded(child: Text('मोबाइल ${phoneCtrl.text} मा OTP पठाइयो! (परीक्षण कोड: $generatedOtp)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '४ अङ्कको OTP कोड प्रविष्ट गर्नुहोस्', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock)),
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
                          setDialogState(() => error = 'गलत OTP कोड! कृपया फेरि प्रयास गर्नुहोस्।');
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
                            SnackBar(content: Text('📱 मोबाइल लगइन सफल भयो! स्वागत छ ${student.name}'), backgroundColor: Colors.teal),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('सत्यापन गरी लगइन गर्नुहोस्'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बन्द गर्नुहोस्')),
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
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1E3A8A), size: 24),
              SizedBox(width: 10),
              Text('नयाँ विद्यार्थी दर्ता (Register Account)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    decoration: const InputDecoration(labelText: 'पूरा नाम (Full Name)*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'मोबाइल नम्बर (Mobile Number)*', hintText: 'e.g. 9812345678', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    decoration: const InputDecoration(labelText: 'दर्ता / सिम्बोल नम्बर (Registration No)', hintText: 'वैकल्पिक (e.g. 01234575)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.pin_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'Username (लगइन आईडी)*', hintText: 'e.g. ram123', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_circle_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'पासवर्ड (Password)*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: confirmPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'कन्फर्म पासवर्ड*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset_outlined)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(labelText: 'ब्याच (Batch)*', border: OutlineInputBorder()),
                    items: _batchesList.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSector,
                    decoration: const InputDecoration(labelText: 'औद्योगिक क्षेत्र (Sector)', border: OutlineInputBorder()),
                    items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setDialogState(() => selectedSector = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = 'कृपया सबै आवश्यक (*) विवरणहरू भर्नुहोस्!');
                  return;
                }
                if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                  setDialogState(() => error = 'पासवर्ड र कन्फर्म पासवर्ड मिलेन!');
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
                    const SnackBar(content: Text('✅ खाता सफलतापूर्वक सिर्जना भयो! स्वागत छ!'), backgroundColor: Colors.teal),
                  );
                } else {
                  setDialogState(() => error = 'यो Username वा मोबाइल नम्बर पहिले नै दर्ता भइसकेको छ!');
                }
              },
              child: const Text('दर्ता गर्नुहोस् (Register)'),
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
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFF0F766E), size: 24),
              SizedBox(width: 10),
              Text('पासवर्ड रिसेट (Forgot Password)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                const Text(
                  'तपाईंको दर्ता गरिएको मोबाइल नम्बर वा Username हाल्नुहोस् र नयाँ पासवर्ड सेट गर्नुहोस्:',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneOrUserCtrl,
                  decoration: const InputDecoration(labelText: 'मोबाइल नम्बर वा Username*', hintText: 'e.g. 9841234567', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_android)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'नयाँ पासवर्ड (New Password)*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'नयाँ पासवर्ड पुष्टि (Confirm)*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                final id = phoneOrUserCtrl.text.trim();
                final p1 = newPassCtrl.text.trim();
                final p2 = confirmPassCtrl.text.trim();

                if (id.isEmpty || p1.isEmpty) {
                  setDialogState(() => error = 'कृपया मोबाइल नम्बर र नयाँ पासवर्ड भर्नुहोस्!');
                  return;
                }
                if (p1 != p2) {
                  setDialogState(() => error = 'पासवर्ड र कन्फर्म पासवर्ड मिलेन!');
                  return;
                }

                final ok = AuthService.instance.resetPassword(mobileOrUsername: id, newPassword: p1);
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ पासवर्ड सफलतापूर्वक परिवर्तन भयो! अब नयाँ पासवर्डले लगइन गर्नुहोस्।'), backgroundColor: Colors.green),
                  );
                } else {
                  setDialogState(() => error = 'यो मोबाइल नम्बर वा Username भेटिएन!');
                }
              },
              child: const Text('पासवर्ड सेभ गर्नुहोस्'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Container(
              width: 440,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                  const Text(
                    "नेपाल-कोरिया भाषा तथा UBT अनलाइन परीक्षा पोर्टल",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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
                      label: const Text(
                        "Google मार्फत सिधै लगइन (Google Sign-In)",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                      label: const Text(
                        "📱 मोबाइल नम्बरबाट सिधै लगइन (OTP)",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("वा Password ले लगइन", style: TextStyle(color: Colors.black45, fontSize: 11)),
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
                      labelText: "Username, मोबाइल वा दर्ता नम्बर",
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
                      labelText: "पासवर्ड (Password)",
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
                      child: const Text(
                        "पासवर्ड बिर्सनुभयो? (Forgot Password?)",
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
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
                      label: const Text("लगइन गर्नुहोस् (Sign In)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                      label: const Text("नयाँ खाता खोल्नुहोस् (Register Account)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
          ),
        ),
      ),
    );
  }
}
