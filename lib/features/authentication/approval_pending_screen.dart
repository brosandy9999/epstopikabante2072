import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/language_service.dart';
import '../../main.dart'; // For StudentDashboardScreen and LoginScreen

/// Screen shown to students whose registration is pending approval by their Institute Admin.
class ApprovalPendingScreen extends StatefulWidget {
  final AppUser student;

  const ApprovalPendingScreen({super.key, required this.student});

  @override
  State<ApprovalPendingScreen> createState() => _ApprovalPendingScreenState();
}

class _ApprovalPendingScreenState extends State<ApprovalPendingScreen> {
  bool _isChecking = false;
  late AppUser _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.student;
  }

  Future<void> _checkApprovalStatus() async {
    setState(() => _isChecking = true);
    try {
      await CloudSyncService.instance.pullFromCloud(silent: false);
      final refreshed = AuthService.instance.getStudentById(_currentUser.id);
      if (refreshed != null) {
        _currentUser = refreshed;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!_currentUser.isPendingApproval) {
      // Successfully approved!
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text(
                LanguageService.instance.trText(
                  ne: 'बधाई छ! खाता स्वीकृत भयो',
                  en: 'Congratulations! Account Approved',
                  ko: '축하합니다! 계정 승인 완료',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            LanguageService.instance.trText(
              ne: 'तपाईंको इन्स्टिच्युटले खाता स्वीकृत गरिसकेको छ। अब तपाईं सबै परीक्षा सेटहरू अभ्यास गर्न सक्नुहुन्छ।',
              en: 'Your Institute has approved your account. You can now access all your test sets.',
              ko: '학원에서 계정 승인을 완료했습니다. 이제 모든 모의고사를 응시하실 수 있습니다.',
            ),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboardScreen(student: _currentUser),
                  ),
                );
              },
              child: Text(
                LanguageService.instance.trText(
                  ne: 'ड्यासबोर्डमा जानुहोस्',
                  en: 'Go to Dashboard',
                  ko: '대시보드로 이동',
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.instance.trText(
              ne: 'खाता अझै इन्स्टिच्युटको स्वीकृतिको पर्खाइमा छ। केही समयपछि फेरि जाँच्नुहोस्।',
              en: 'Account is still pending institute approval. Please check again shortly.',
              ko: '아직 학원 승인 대기 중입니다. 잠시 후 다시 확인해 주세요.',
            ),
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final inst = InstituteService.instance.getInstituteById(_currentUser.instituteId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.trText(
            ne: 'खाता स्वीकृति पर्खाइ',
            en: 'Pending Institute Approval',
            ko: '학원 승인 대기 중',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: lang.trText(ne: 'लगआउट', en: 'Logout', ko: '로그아웃'),
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Status Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.amber.shade200, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Pending Badge Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.shade300, width: 2),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFD97706),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.trText(
                          ne: 'इन्स्टिच्युटको स्वीकृति पर्खिँदै',
                          en: 'Pending Institute Approval',
                          ko: '학원 승인 대기 중',
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lang.trText(
                            ne: '⏳ स्थिति: प्रतीक्षामा (Pending)',
                            en: '⏳ Status: Pending Approval',
                            ko: '⏳ 상태: 승인 대기 중',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.trText(
                          ne: 'नमस्ते ${_currentUser.name}! तपाईंको नयाँ दर्ता आवेदन तपाईंले छनोट गर्नुभएको इन्स्टिच्युटको प्रशासनमा पठाइएको छ। इन्स्टिच्युट एडमिनले स्वीकृत गरेपछि तपाईंले सीधै मोक टेस्ट र UBT सेटहरू हल गर्न पाउनुहुनेछ।',
                          en: 'Hello ${_currentUser.name}! Your registration application has been submitted to your chosen Institute. Once approved by the Institute Admin, you will be able to access all mock tests and study materials.',
                          ko: '안녕하세요 ${_currentUser.name}님! 등록 신청이 선택하신 학원 관리자에게 전달되었습니다. 학원 승인 완료 후 즉시 모의고사 및 CBT 시험을 응시하실 수 있습니다.',
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF475569)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Institute Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            lang.trText(
                              ne: 'तपाईंले छनोट गर्नुभएको इन्स्टिच्युट:',
                              en: 'Your Selected Institute:',
                              ko: '선택하신 소속 학원:',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        _currentUser.instituteName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      if (inst != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                inst.address,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              '${lang.trText(ne: "सम्पर्क फोन:", en: "Contact Phone:", ko: "연락처:")} ${inst.phone}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Student Details Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(lang.trText(ne: 'विद्यार्थीको नाम', en: 'Candidate Name', ko: '성명'), _currentUser.name),
                      const SizedBox(height: 6),
                      _buildInfoRow(lang.trText(ne: 'प्रयोगकर्ता नाम (Username)', en: 'Username', ko: '아이디'), _currentUser.username),
                      const SizedBox(height: 6),
                      _buildInfoRow(lang.trText(ne: 'मोबाइल नम्बर', en: 'Mobile Number', ko: '휴대폰 번호'), _currentUser.mobileNumber ?? '-'),
                      const SizedBox(height: 6),
                      _buildInfoRow(lang.trText(ne: 'दर्ता / सिम्बोल नम्बर', en: 'Registration No', ko: '수험번호'), _currentUser.registrationNo ?? '-'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _isChecking ? null : _checkApprovalStatus,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isChecking
                          ? lang.trText(ne: 'जाँच्दैछ...', en: 'Checking Status...', ko: '확인 중...')
                          : lang.trText(ne: '🔄 स्वीकृति स्थिति जाँच्नुहोस्', en: '🔄 Check Approval Status', ko: '🔄 승인 상태 확인'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () {
                    AuthService.instance.logout();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(
                    lang.trText(
                      ne: 'लगइन पृष्ठमा फर्कनुहोस्',
                      en: 'Back to Login',
                      ko: '로그인 화면으로 돌아가기',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }
}
