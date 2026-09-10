import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/language_service.dart';
import '../../main.dart';

/// Dynamic Institute-Branded Splash Screen
/// Displayed upon app open on all devices when a student's ID has been activated by an Institute.
/// Features the activating Institute's Logo, Name, Verification badge, and student status.
class InstituteSplashScreen extends StatefulWidget {
  final AppUser student;

  const InstituteSplashScreen({super.key, required this.student});

  @override
  State<InstituteSplashScreen> createState() => _InstituteSplashScreenState();
}

class _InstituteSplashScreenState extends State<InstituteSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // Auto navigate after 2.5 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      _navigateToDashboard();
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    _navigationTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentDashboardScreen(student: widget.student)),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final inst = InstituteService.instance.getInstituteById(widget.student.instituteId);
    final instName = inst?.name ?? widget.student.instituteName;
    final instAddress = inst?.address ?? 'Authorized EPS-TOPIK Training Center';
    final instPhone = inst?.phone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: InkWell(
        onTap: _navigateToDashboard, // Instant tap to proceed
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF042F2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Official Center Activation Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  lang.trText(
                                    ne: 'आधिकारिक सक्रिय परीक्षा तथा अध्ययन केन्द्र',
                                    en: 'Official Active Examination & Training Center',
                                    ko: '공식 활성 모의고사 및 교육 센터',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Institute Logo Avatar with glow
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 56,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Institute Name
                          Text(
                            instName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Institute Location & Contact
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  instAddress + (instPhone.isNotEmpty ? ' • Tel: $instPhone' : ''),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Activated Student Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF334155), width: 1.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF0F766E),
                                      child: Text(
                                        widget.student.name.isNotEmpty ? widget.student.name[0] : 'S',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.student.name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            'ID: ${widget.student.username}  •  ${widget.student.registrationNo ?? "REG"}',
                                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF059669)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF34D399)),
                                          const SizedBox(width: 4),
                                          Text(
                                            lang.trText(ne: 'सक्रिय ID', en: 'Active ID', ko: '승인 완료'),
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: Color(0xFF334155)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '📚 ${widget.student.batch}',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '🎯 ${widget.student.quotaSummaryText}',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Loading Bar & Tap Hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                lang.trText(
                                  ne: 'अध्ययन तथा परीक्षा पोर्टल खुल्दैछ...',
                                  en: 'Loading Study & Exam Portal...',
                                  ko: '학습 및 시험 포털 연결 중...',
                                ),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Direct enter button
                          TextButton.icon(
                            onPressed: _navigateToDashboard,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF38BDF8)),
                            label: Text(
                              lang.trText(ne: 'सिधै प्रवेश गर्नुहोस् ➜', en: 'Enter Directly ➜', ko: '바로 시작하기 ➜'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // HRD Korea Engine Footer
                          Text(
                            'HRD Korea • EPS-TOPIK UBT Online Engine v2.4.0',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
