import '../../core/services/platform_detector.dart';
import '../security/android_web_gatekeeper_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/services/language_service.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/question_bank_service.dart';
import '../question_engine/question_template.dart';
import '../reading/reading_widget.dart';
import '../listening/listening_widget.dart';
import 'exam_result_screen.dart';

/// Authentic HRD Korea EPS-TOPIK UBT Real Exam Hall Screen
/// - Full-width question display
/// - Center '전체문항 (Total Questions)' Button opens TWO SEPARATE GRIDS:
///   1. Reading Grid (1 to 20 questions)
///   2. Listening Grid (21 to 40 questions)
class RealUbtExamHallScreen extends StatefulWidget {
  final AppUser? student;
  final MockTestSet? mockSet;

  const RealUbtExamHallScreen({
    super.key,
    this.student,
    this.mockSet,
  });

  @override
  State<RealUbtExamHallScreen> createState() => _RealUbtExamHallScreenState();
}

class _RealUbtExamHallScreenState extends State<RealUbtExamHallScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  late final List<QuestionTemplate> _questions;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _flaggedQuestions = {};

  // Timer: 50 minutes = 3000 seconds
  late final ValueNotifier<int> _remainingSecondsNotifier;
  int get _remainingSeconds => _remainingSecondsNotifier.value;
  Timer? _timer;
  bool _fiveMinuteWarningShown = false;

  double _fontScale = 1.0;

  // Anti-Cheat
  int _cheatWarnings = 0;
  static const int _maxCheatWarnings = 3;

  @override
  void initState() {
    super.initState();
    _remainingSecondsNotifier = ValueNotifier<int>(3000);
    WidgetsBinding.instance.addObserver(this);
    _questions = widget.mockSet?.questions ?? QuestionBankService.instance.getFull40ExamQuestions();
    _startCountdownTimer();

    // 🔒 Force Landscape Orientation for Authentic UBT Exam Hall Terminal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _remainingSecondsNotifier.dispose();

    // 🔓 Restore all screen orientations upon exiting the exam hall
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _triggerAntiCheatWarning();
    }
  }

  void _triggerAntiCheatWarning() {
    setState(() => _cheatWarnings++);

    if (_cheatWarnings >= _maxCheatWarnings) {
      _submitExamDirectly(reason: '부정행위 감지로 인한 자동 제출 (Automatic Submission: Anti-Cheat Policy)');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Text(
              LanguageService.instance.trText(ne: '🚨 परीक्षा नियम उल्लंघन चेतावनी (${_cheatWarnings}/${_maxCheatWarnings})', en: '🚨 Anti-Cheat Warning (${_cheatWarnings}/${_maxCheatWarnings})', ko: '🚨 부정행위 방지 경고 (${_cheatWarnings}/${_maxCheatWarnings})'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.instance.trText(
                ne: 'परीक्षा हल विन्डो छाड्न सख्त निषेध गरिएको छ!',
                en: 'Leaving the exam window is strictly prohibited!',
                ko: '시험 중 창이나 탭을 벗어나는 행위는 엄격히 금지됩니다!',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              LanguageService.instance.trText(
                ne: 'परीक्षा हलबाट बाहिर अन्य विन्डो वा ट्याबमा जान सख्त निषेध छ। ३ पटक उल्लंघन भएमा परीक्षा स्वतः सबमिट हुनेछ।',
                en: 'Leaving the exam window is strictly prohibited. If violated 3 times, your exam will be automatically submitted.',
                ko: '시험 중 다른 창이나 탭으로 전환하면 안 됩니다. 3회 위반 시 자동 제출됩니다.',
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                LanguageService.instance.trText(ne: 'बाँकी मौका: ${(_maxCheatWarnings - _cheatWarnings)} पटक', en: 'Remaining chances: ${(_maxCheatWarnings - _cheatWarnings)}', ko: '남은 기회: ${(_maxCheatWarnings - _cheatWarnings)}회'),
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.instance.trText(ne: 'परीक्षामा फर्कनुहोस्', en: 'Return to Exam', ko: '시험으로 돌아가기')),
          ),
        ],
      ),
    );
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSecondsNotifier.value > 0) {
        _remainingSecondsNotifier.value--;
        if (_remainingSecondsNotifier.value == 300 && !_fiveMinuteWarningShown) {
          _fiveMinuteWarningShown = true;
          _showFiveMinuteWarning();
        }
      } else {
        t.cancel();
        _submitExamDirectly(reason: '시간 종료 (Time Over)');
      }
    });
  }

  void _showFiveMinuteWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                LanguageService.instance.trText(ne: '⏰ परीक्षा समाप्त हुन ५ मिनेट बाँकी छ, कृपया उत्तरहरू रुजु गर्नुहोस्!', en: '⏰ 5 minutes remaining! Please review your answers.', ko: '⏰ 시험 종료 5분 전입니다! 답안을 검토해 주세요.'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return mins + ':' + secs;
  }

  void _jumpToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() => _currentQuestionIndex = index);
    }
  }

  void _toggleFlagQuestion(int index) {
    setState(() {
      if (_flaggedQuestions.contains(index)) {
        _flaggedQuestions.remove(index);
      } else {
        _flaggedQuestions.add(index);
      }
    });
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageService.instance.trText(ne: 'परीक्षाबाट बाहिरिन चाहनुहुन्छ?', en: 'Exit Exam Confirmation', ko: '시험 중단 및 퇴실 확인')),
        content: Text(
          LanguageService.instance.trText(
            ne: 'यदि तपाईं अहिले बाहिरिनुभयो भने परीक्षा बीचमै रोकिनेछ। के तपाईं निश्चित हुनुहुन्छ?',
            en: 'Leaving now will terminate your ongoing exam progress. Are you sure you want to exit?',
            ko: '지금 퇴실하시면 시험이 중단됩니다. 정말 퇴실하시겠습니까?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(LanguageService.instance.tr('exit_exam')),
          ),
        ],
      ),
    );
  }

  void _confirmSubmit() {
    final total = _questions.length;
    final answered = _selectedAnswers.length;
    final unanswered = total - answered;
    final flagged = _flaggedQuestions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 10),
            Text(LanguageService.instance.trText(ne: 'अन्तिम उत्तर सबमिट', en: 'Submit Final Answers', ko: '최종 답안 제출'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LanguageService.instance.trText(ne: 'विद्यार्थी: ${widget.student?.name ?? "परीक्षार्थी"}', en: 'Candidate: ${widget.student?.name ?? "Student"}', ko: '수험자: ${widget.student?.name ?? "수험생"}'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(LanguageService.instance.trText(ne: 'दर्ता नं: ${widget.student?.registrationNo ?? "2026-001"}', en: 'Reg No: ${widget.student?.registrationNo ?? "2026-001"}', ko: '수험번호: ${widget.student?.registrationNo ?? "2026-001"}')),
            const Divider(height: 20),
            _buildStatRow(LanguageService.instance.trText(ne: 'कुल प्रश्न:', en: 'Total Questions:', ko: '총 문항수:'), total.toString(), Colors.black87),
            _buildStatRow(LanguageService.instance.trText(ne: 'हल गरिएका प्रश्न:', en: 'Answered:', ko: '답안 작성:'), answered.toString(), Colors.green),
            _buildStatRow(LanguageService.instance.trText(ne: 'नछोएका प्रश्न:', en: 'Unanswered:', ko: '미작성 문항:'), unanswered.toString(), unanswered > 0 ? Colors.red : Colors.grey),
            _buildStatRow(LanguageService.instance.trText(ne: 'समीक्षाका लागि चिन्हित:', en: 'Marked for Review:', ko: '검토 요청:'), flagged.toString(), Colors.amber.shade900),
            const SizedBox(height: 14),
            Text(
              LanguageService.instance.trText(
                ne: 'सबमिट गरेपछि उत्तर परिवर्तन गर्न सकिने छैन। के तपाईं सबमिट गर्न निश्चित हुनुहुन्छ?',
                en: 'You cannot modify answers after submission. Are you sure you want to submit?',
                ko: '제출 후에는 답안을 수정할 수 없습니다. 답안을 최종 제출하시겠습니까?',
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'परीक्षा जारी राख्नुहोस्', en: 'Continue Exam', ko: '계속 풀기'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _submitExamDirectly();
            },
            child: Text(LanguageService.instance.tr('submit_exam')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }

  void _submitExamDirectly({String? reason}) {
    _timer?.cancel();

    final timeSpent = 3000 - _remainingSeconds;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          student: widget.student,
          setId: widget.mockSet?.id ?? 'set_01',
          setTitle: widget.mockSet?.title ?? '제1회 EPS-TOPIK 실전 모의고사',
          questions: _questions,
          userAnswers: _selectedAnswers,
          timeSpentSeconds: timeSpent > 0 ? timeSpent : 1500,
        ),
      ),
    );
  }

  /// Open Center Modal Sheet with TWO SEPARATE GRIDS:
  /// 1. Reading (1 to 20)
  /// 2. Listening (21 to 40)
  void _openAllQuestionsSheet() {
    int readingAnswered = 0;
    int listeningAnswered = 0;
    for (int i = 0; i < 20; i++) {
      if (_selectedAnswers.containsKey(i)) readingAnswered++;
    }
    for (int i = 20; i < 40; i++) {
      if (_selectedAnswers.containsKey(i)) listeningAnswered++;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 520,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -6))],
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grid_view, color: Color(0xFF1E3A8A), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'सबै प्रश्नहरूको स्थिति (४० प्रश्न ग्रिड)',
                              en: 'All Questions Overview (40 Questions Grid)',
                              ko: '전체문항 (40문항 현황표)',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              LanguageService.instance.trText(
                                ne: 'कुल हल: ${_selectedAnswers.length}/40',
                                en: 'Answered: ${_selectedAnswers.length}/40',
                                ko: '작성 완료: ${_selectedAnswers.length}/40',
                              ),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: LanguageService.instance.trText(ne: 'बन्द गर्नुहोस्', en: 'Close', ko: '닫기'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8),

                // TWO SEPARATE GRIDS: Reading (01-20) on LEFT & Listening (21-40) on RIGHT (FITS 100% IN ONE SCREEN, ZERO SIDEWAYS SCROLL)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT SIDE: READING (01 - 20)
                          Expanded(
                            child: _buildSectionGridCard(
                              title: LanguageService.instance.trText(ne: '📖 रिडिङ (०१ - २०)', en: '📖 Reading (01 - 20)', ko: '📖 읽기 (01 - 20)'),
                              color: const Color(0xFF1E3A8A),
                              answeredCount: readingAnswered,
                              startIdx: 0,
                              endIdx: 20,
                              ctx: ctx,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // RIGHT SIDE: LISTENING (21 - 40)
                          Expanded(
                            child: _buildSectionGridCard(
                              title: LanguageService.instance.trText(ne: '🎧 लिसनिङ (२१ - ४०)', en: '🎧 Listening (21 - 40)', ko: '🎧 듣기 (21 - 40)'),
                              color: const Color(0xFFEA580C),
                              answeredCount: listeningAnswered,
                              startIdx: 20,
                              endIdx: 40,
                              ctx: ctx,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegend(const Color(0xFF1E3A8A), LanguageService.instance.trText(ne: 'हल भएको (${_selectedAnswers.length})', en: 'Answered (${_selectedAnswers.length})', ko: '답안 작성 (${_selectedAnswers.length})')),
                      _buildLegend(Colors.white, LanguageService.instance.trText(ne: 'नछोएको (${40 - _selectedAnswers.length})', en: 'Unanswered (${40 - _selectedAnswers.length})', ko: '미작성 (${40 - _selectedAnswers.length})'), border: true),
                      _buildLegend(Colors.amber, LanguageService.instance.trText(ne: 'हालको प्रश्न', en: 'Current Question', ko: '현재 문항'), border: true),
                      _buildLegend(Colors.red, LanguageService.instance.trText(ne: 'समीक्षा (${_flaggedQuestions.length})', en: 'Review (${_flaggedQuestions.length})', ko: '검토 (${_flaggedQuestions.length})'), isFlag: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a self-contained 20-question grid card
  Widget _buildSectionGridCard({
    required String title,
    required Color color,
    required int answeredCount,
    required int startIdx,
    required int endIdx,
    required BuildContext ctx,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  LanguageService.instance.trText(
                    ne: 'हल: $answeredCount/20',
                    en: 'Done: $answeredCount/20',
                    ko: '완료: $answeredCount/20',
                  ),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Columns x 4 Rows Grid for 20 questions (Compact fit)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.5,
            ),
            itemCount: endIdx - startIdx,
            itemBuilder: (context, i) {
              final qIndex = startIdx + i;
              final isAnswered = _selectedAnswers.containsKey(qIndex);
              final isCurrent = qIndex == _currentQuestionIndex;
              final isFlagged = _flaggedQuestions.contains(qIndex);

              Color bg = Colors.white;
              Color textColor = Colors.black87;
              Border border = Border.all(color: Colors.grey.shade300);

              if (isAnswered) {
                bg = color;
                textColor = Colors.white;
                border = Border.all(color: color);
              }

              if (isCurrent) {
                border = Border.all(color: Colors.amber, width: 2.5);
              }

              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _jumpToQuestion(qIndex);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                    boxShadow: isCurrent ? [const BoxShadow(color: Colors.amber, blurRadius: 4)] : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          (qIndex + 1).toString().padLeft(2, '0'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        ),
                      ),
                      if (isFlagged)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(Icons.flag, size: 12, color: Colors.red),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label, {bool border = false, bool isFlag = false}) {
    return Row(
      children: [
        if (isFlag)
          const Icon(Icons.flag, size: 14, color: Colors.red)
        else
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: border ? Border.all(color: Colors.grey.shade400) : null,
            ),
          ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }


  Widget _buildRotateToLandscapePrompt(BuildContext context) {
    final lang = LanguageService.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // HRD Korea Official UBT Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇰🇷', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        lang.trText(
                          ne: 'आधिकारिक HRD Korea UBT परीक्षा मोड',
                          en: 'Official HRD Korea UBT Mode',
                          ko: '한국산업인력공단 공식 UBT 모드',
                        ),
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Animated/Glow Rotating Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.screen_rotation_rounded, size: 48, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Instruction
                Text(
                  lang.trText(
                    ne: 'कृपया आफ्नो मोबाइललाई तेर्सो (Landscape) मोडमा घुमाउनुहोस्',
                    en: 'Please Rotate Your Device to Landscape',
                    ko: '기기를 가로(Landscape) 모드로 회전해 주세요',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Explanation
                Text(
                  lang.trText(
                    ne: 'EPS-TOPIK UBT परीक्षा वास्तविक परीक्षा हलमा झैँ कम्प्युटर/ट्याबलेट स्क्रिन (Landscape) मा दिनुपर्ने गरी तयार पारिएको छ। मोबाइल तेर्सो बनाउनासाथ परीक्षा स्वतः सुरु हुनेछ।',
                    en: 'The EPS-TOPIK UBT exam layout requires landscape orientation for the authentic split-screen reading and listening experience.',
                    ko: '실제 UBT 시험장 환경과 동일한 40문항 2분할 화면 구성을 위해 가로(Landscape) 화면이 필수입니다.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Force Landscape & Exit Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      },
                      icon: const Icon(Icons.screen_lock_landscape, size: 18),
                      label: Text(
                        lang.trText(
                          ne: 'Landscape Mode सक्रिय गर्नुहोस्',
                          en: 'Enable Landscape',
                          ko: '가로 모드 적용',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirmExit,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        lang.trText(ne: 'बाहिरिनुहोस्', en: 'Exit Exam', ko: '시험 나가기'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ STRICT SECURITY: Block exam hall on Android Web browsers (Must use official APK)
    if (isAndroidWeb) {
      return const AndroidWebGatekeeperScreen();
    }
    // In mobile portrait, enforce authentic landscape rotation prompt
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait && mediaQuery.size.width < 600;
    if (isPortrait) {
      return _buildRotateToLandscapePrompt(context);
    }

    final currentQ = _questions[_currentQuestionIndex];
    final isReading = _currentQuestionIndex < 20;

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // 1. TOP OFFICIAL HEADER BAR
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Candidate Badge
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _confirmExit,
                      icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.white),
                      label: Text(LanguageService.instance.trText(ne: 'बाहिरिनुहोस्', en: 'Exit', ko: '퇴실'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        (widget.student?.name.isNotEmpty == true) ? widget.student!.name[0] : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          LanguageService.instance.trText(ne: 'दर्ता नं: ${widget.student?.registrationNo ?? "2026-001"} | सिट: १२', en: 'Reg No: ${widget.student?.registrationNo ?? "2026-001"} | Seat: 12', ko: '수험번호: ${widget.student?.registrationNo ?? "2026-001"} | 좌석: 12번'),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          LanguageService.instance.trText(ne: 'नाम: ${widget.student?.name ?? "परीक्षार्थी"}', en: 'Name: ${widget.student?.name ?? "Candidate"}', ko: '성명: ${widget.student?.name ?? "수험생"}'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center: Section & Question Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReading ? const Color(0xFF2563EB) : const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isReading ? LanguageService.instance.trText(ne: '📖 रिडिङ (१-२०)', en: '📖 Reading (1-20)', ko: '📖 읽기 (1-20)') : LanguageService.instance.trText(ne: '🎧 लिसनिङ (२१-४०)', en: '🎧 Listening (21-40)', ko: '🎧 듣기 (21-40)'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        LanguageService.instance.trText(ne: 'प्रश्न ${_currentQuestionIndex + 1} / ${_questions.length}', en: 'Question ${_currentQuestionIndex + 1} / ${_questions.length}', ko: '문항 ${_currentQuestionIndex + 1} / ${_questions.length}'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                // Right: Zoom & Timer
                Row(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 20),
                          tooltip: 'Font Smaller',
                          onPressed: () {
                            if (_fontScale > 0.85) setState(() => _fontScale -= 0.1);
                          },
                        ),
                        Text(
                          (_fontScale * 100).toInt().toString() + '%',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                          tooltip: 'Font Bigger',
                          onPressed: () {
                            if (_fontScale < 1.4) setState(() => _fontScale += 0.1);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    ValueListenableBuilder<int>(
                      valueListenable: _remainingSecondsNotifier,
                      builder: (context, remainingSecs, _) {
                        final isLowTime = remainingSecs < 300;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLowTime ? Colors.red.shade700 : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLowTime ? Colors.redAccent : Colors.white30,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, color: isLowTime ? Colors.yellowAccent : Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimer(remainingSecs),
                                style: TextStyle(
                                  color: isLowTime ? Colors.yellowAccent : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
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
      ),

      // 2. MAIN BODY: Clean full-width Question View with Pinch-to-Zoom
      body: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  if (pointerSignal.scrollDelta.dy < 0) {
                    setState(() => _fontScale = (_fontScale + 0.08).clamp(0.8, 2.0));
                  } else if (pointerSignal.scrollDelta.dy > 0) {
                    setState(() => _fontScale = (_fontScale - 0.08).clamp(0.8, 2.0));
                  }
                }
              },
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: _buildCurrentQuestion(currentQ),
                ),
              ),
            ),
          ),

          // 3. BOTTOM CONTROL BAR with CENTER '전체문항' BUTTON
          _buildBottomControlBar(),
        ],
      ),
    ),
  );
}

  Widget _buildCurrentQuestion(QuestionTemplate currentQ) {
    final bool isListening = (currentQ is ListeningAudioQuestion) ||
        (currentQ is UniversalQuestion && currentQ.isListening) ||
        (_currentQuestionIndex >= 20);

    if (isListening) {
      return ListeningQuestionWidget(
        key: ValueKey(currentQ.questionId),
        question: currentQ,
        selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
        onOptionSelected: (idx) {
          setState(() => _selectedAnswers[_currentQuestionIndex] = idx);
        },
      );
    } else {
      return ReadingQuestionWidget(
        key: ValueKey(currentQ.questionId),
        question: currentQ,
        selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
        onOptionSelected: (idx) {
          setState(() => _selectedAnswers[_currentQuestionIndex] = idx);
        },
      );
    }
  }

  // 4. BOTTOM NAVIGATION CONTROLS
  Widget _buildBottomControlBar() {
    final isFlagged = _flaggedQuestions.contains(_currentQuestionIndex);
    final isLast = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton.icon(
            onPressed: _currentQuestionIndex > 0 ? () => _jumpToQuestion(_currentQuestionIndex - 1) : null,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(LanguageService.instance.tr('prev_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),

          // -------------------------------------------------------------
          // CENTER: '전체문항 (Total 40 Questions)' BUTTON & REVIEW
          // -------------------------------------------------------------
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _openAllQuestionsSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_arrow_up, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          LanguageService.instance.trText(ne: 'सबै प्रश्नहरू (दुई खण्ड)', en: 'All Questions', ko: '전체문항'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            LanguageService.instance.trText(ne: 'हल: ${_selectedAnswers.length}/४०', en: 'Answered: ${_selectedAnswers.length}/40', ko: '작성: ${_selectedAnswers.length}/40'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            LanguageService.instance.trText(ne: 'प्रश्न ${_currentQuestionIndex + 1} / ४०', en: 'Question ${_currentQuestionIndex + 1} / 40', ko: '문항 ${_currentQuestionIndex + 1} / 40'),
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              InkWell(
                onTap: () => _toggleFlagQuestion(_currentQuestionIndex),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFlagged ? Colors.red.shade700 : Colors.white12,
                    border: Border.all(color: isFlagged ? Colors.redAccent : Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFlagged ? Icons.flag : Icons.outlined_flag,
                        color: isFlagged ? Colors.white : Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LanguageService.instance.trText(ne: 'समीक्षा 🚩', en: 'Review 🚩', ko: '검토 🚩'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFlagged ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Next / Submit Button
          Row(
            children: [
              if (!isLast)
                ElevatedButton.icon(
                  onPressed: () => _jumpToQuestion(_currentQuestionIndex + 1),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(LanguageService.instance.tr('next_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _confirmSubmit,
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text(LanguageService.instance.tr('submit_exam'), style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
