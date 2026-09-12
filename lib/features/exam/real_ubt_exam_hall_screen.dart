import 'package:flutter/services.dart';
import '../../core/services/orientation_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
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

  // Anti-Cheat
  int _cheatWarnings = 0;
  static const int _maxCheatWarnings = 3;
  String? _activeCheatWarning;
  Timer? _cheatWarningDismissTimer;

  @override
  void initState() {
    super.initState();
    _remainingSecondsNotifier = ValueNotifier<int>(3000);
    WidgetsBinding.instance.addObserver(this);
    _questions = widget.mockSet?.questions ?? QuestionBankService.instance.getFull40ExamQuestions();
    _startCountdownTimer();

    // 🔄 Force immersive fullscreen mode for authentic exam terminal security
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    OrientationService.forceLandscape();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _cheatWarningDismissTimer?.cancel();
    _remainingSecondsNotifier.dispose();

    // 🔓 Restore standard system UI and orientations upon exiting the exam hall
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    OrientationService.unlockOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _triggerAntiCheatWarning();
    }
  }

    void _triggerAntiCheatWarning({String? customReason}) {
    setState(() => _cheatWarnings++);

    if (_cheatWarnings >= _maxCheatWarnings) {
      _submitExamDirectly(reason: 'Automatic Submission: Anti-Cheat Policy (${_cheatWarnings} Warnings)');
      return;
    }

    final reasonText = customReason ??
        LanguageService.instance.trText(
          ne: 'कृपया टाउको नहल्लाउनुहोस् र स्क्रिनतर्फ मात्र हेर्नुहोस्। परीक्षा विन्डो छोड्न निषेध छ!',
          en: 'Please keep your head steady and face the screen. Leaving the exam window is strictly prohibited!',
          ko: '머리를 움직이지 마시고 화면만 응시하십시오. 시험 창을 벗어나는 것은 금지됩니다!',
        );

    _cheatWarningDismissTimer?.cancel();
    _cheatWarningDismissTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _activeCheatWarning = null;
        });
      }
    });

    setState(() {
      _activeCheatWarning = reasonText;
    });
  }

  /// Bottom-Left Floating Anti-Cheat Toast Warning Card (स्क्रीनको बायाँपट्टि तल साइडमा)
  Widget _buildBottomLeftAntiCheatCard() {
    final remaining = _maxCheatWarnings - _cheatWarnings;

    return Material(
      color: Colors.transparent,
      elevation: 10,
      child: Container(
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF991B1B), // Deep warning crimson
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Warning icon + Badge + Close Button
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFDE047), size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: 'एन्टी-चिट चेतावनी (${_cheatWarnings}/${_maxCheatWarnings})',
                      en: 'Anti-Cheat Warning (${_cheatWarnings}/${_maxCheatWarnings})',
                      ko: '부정행위 경고 (${_cheatWarnings}/${_maxCheatWarnings})',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _cheatWarningDismissTimer?.cancel();
                    setState(() => _activeCheatWarning = null);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, color: Colors.white70, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Warning Reason Body (e.g. "कृपया टाउको नहल्लाउनुहोस्...")
            Text(
              _activeCheatWarning ?? '',
              style: const TextStyle(
                color: Color(0xFFFEF2F2),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),

            // Footer Row: Remaining chances + Dismiss Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    LanguageService.instance.trText(
                      ne: 'बाँकी मौका: $remaining पटक',
                      en: 'Remaining: $remaining',
                      ko: '남은 기회: $remaining회',
                    ),
                    style: TextStyle(
                      color: remaining <= 1 ? const Color(0xFFFDE047) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _cheatWarningDismissTimer?.cancel();
                    setState(() => _activeCheatWarning = null);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      LanguageService.instance.trText(ne: '✓ बुझें', en: '✓ Got It', ko: '✓ 확인'),
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final bool isNarrow = gridConstraints.maxWidth < 600;
                          final readingCard = _buildSectionGridCard(
                            title: LanguageService.instance.trText(ne: '📖 रिडिङ (०१ - २०)', en: '📖 Reading (01 - 20)', ko: '📖 읽기 (01 - 20)'),
                            color: const Color(0xFF1E3A8A),
                            answeredCount: readingAnswered,
                            startIdx: 0,
                            endIdx: 20,
                            ctx: ctx,
                          );
                          final listeningCard = _buildSectionGridCard(
                            title: LanguageService.instance.trText(ne: '🎧 लिसनिङ (२१ - ४०)', en: '🎧 Listening (21 - 40)', ko: '🎧 듣기 (21 - 40)'),
                            color: const Color(0xFFEA580C),
                            answeredCount: listeningAnswered,
                            startIdx: 20,
                            endIdx: 40,
                            ctx: ctx,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                readingCard,
                                const SizedBox(height: 12),
                                listeningCard,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: readingCard),
                              const SizedBox(width: 12),
                              Expanded(child: listeningCard),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
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




  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait || mediaQuery.size.width < 600;
    final currentQ = _questions[_currentQuestionIndex];
    final isReading = _currentQuestionIndex < 20;

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(LanguageService.instance.textScale),
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _confirmExit();
          },
          child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // 1. ULTRA-RESPONSIVE FLOATING HEADER (Adapts to Portrait & Landscape)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                  child: isPortrait
                      // 📱 PORTRAIT HEADER (2 COMPACT ROWS: Zero Horizontal Overflow)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                // Exit Button
                                OutlinedButton.icon(
                                  onPressed: _confirmExit,
                                  icon: const Icon(Icons.exit_to_app, size: 12, color: Colors.red),
                                  label: Text(
                                    LanguageService.instance.trText(ne: 'बाहिरिने', en: 'Exit', ko: '퇴실'),
                                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: Colors.red.shade300, width: 1.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    elevation: 1,
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Candidate Tag (Compact Name Only)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 7,
                                          backgroundColor: const Color(0xFF1E3A8A),
                                          child: Text(
                                            (widget.student?.name.isNotEmpty == true) ? widget.student!.name[0] : 'S',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            widget.student?.name ?? "수험생",
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Countdown Timer
                                ValueListenableBuilder<int>(
                                  valueListenable: _remainingSecondsNotifier,
                                  builder: (context, remainingSecs, _) {
                                    final isLowTime = remainingSecs < 300;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isLowTime ? Colors.red.shade50 : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isLowTime ? Colors.red : Colors.grey.shade300,
                                          width: 1.0,
                                        ),
                                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer_outlined, color: isLowTime ? Colors.red : const Color(0xFF1E3A8A), size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTimer(remainingSecs),
                                            style: TextStyle(
                                              color: isLowTime ? Colors.red.shade900 : const Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),

                                // Screen Rotation Switch Button
                                InkWell(
                                  onTap: () => OrientationService.toggleOrientation(mediaQuery.orientation),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                    ),
                                    child: const Icon(Icons.screen_rotation, size: 14, color: Color(0xFF1E3A8A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isReading ? const Color(0xFF2563EB) : const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    isReading
                                        ? '📖 읽기 (Reading) #${_currentQuestionIndex + 1}/40'
                                        : '🎧 듣기 (Listening) #${_currentQuestionIndex + 1}/40',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${LanguageService.instance.trText(ne: "उत्तर:", en: "Answered:", ko: "풀이:")} ${_selectedAnswers.length}/40',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      // 🖥️ LANDSCAPE HEADER (1 SLEEK ROW)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Exit Button & Compact Candidate Tag
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _confirmExit,
                                  icon: const Icon(Icons.exit_to_app, size: 13, color: Colors.red),
                                  label: Text(
                                    LanguageService.instance.trText(ne: 'बाहिरिनुहोस्', en: 'Exit', ko: '퇴실'),
                                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: Colors.red.shade300, width: 1.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    elevation: 1,
                                    shadowColor: Colors.black12,
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: const Color(0xFF1E3A8A),
                                        child: Text(
                                          (widget.student?.name.isNotEmpty == true) ? widget.student!.name[0] : 'S',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.student?.name ?? "수험생"} | ${widget.student?.registrationNo ?? "2026-001"}',
                                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Center: Compact Section Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReading ? const Color(0xFF2563EB) : const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: Text(
                                isReading
                                    ? '📖 읽기 (문항 ${_currentQuestionIndex + 1}/40)'
                                    : '🎧 듣기 (문항 ${_currentQuestionIndex + 1}/40)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),

                            // Right: Countdown Timer & Screen Rotation Button
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: _remainingSecondsNotifier,
                                  builder: (context, remainingSecs, _) {
                                    final isLowTime = remainingSecs < 300;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isLowTime ? Colors.red.shade50 : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isLowTime ? Colors.red : Colors.grey.shade300,
                                          width: 1.1,
                                        ),
                                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer_outlined, color: isLowTime ? Colors.red : const Color(0xFF1E3A8A), size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                            _formatTimer(remainingSecs),
                                            style: TextStyle(
                                              color: isLowTime ? Colors.red.shade900 : const Color(0xFF0F172A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => OrientationService.toggleOrientation(mediaQuery.orientation),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                    ),
                                    child: const Icon(Icons.screen_rotation, size: 15, color: Color(0xFF1E3A8A)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // 2. MAIN BODY: Full-height, unclipped Question View
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                    child: _buildCurrentQuestion(currentQ),
                  ),
                ),

                // 3. ULTRA-SLEEK FLOATING BOTTOM CONTROLS
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                  child: _buildBottomControlBar(),
                ),
              ],
            ),
          ),
        ),
      ),
              if (_activeCheatWarning != null)
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: _buildBottomLeftAntiCheatCard(),
                ),
            ],
          ),
        ),
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

  // 4. ULTRA-SLEEK FLOATING BOTTOM NAVIGATION CONTROLS (Zero bulky bar)
  Widget _buildBottomControlBar() {
    final isFlagged = _flaggedQuestions.contains(_currentQuestionIndex);
    final isLast = _currentQuestionIndex == _questions.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        final hPad = isCompact ? 6.0 : 10.0;
        final btnFontSize = isCompact ? 10.5 : 12.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            OutlinedButton.icon(
              onPressed: _currentQuestionIndex > 0 ? () => _jumpToQuestion(_currentQuestionIndex - 1) : null,
              icon: Icon(Icons.arrow_back, size: isCompact ? 12 : 14),
              label: Text(
                LanguageService.instance.tr('prev_btn'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: btnFontSize),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
                disabledForegroundColor: Colors.grey.shade400,
                disabledBackgroundColor: Colors.white70,
                side: BorderSide(color: Colors.grey.shade300, width: 1.0),
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: isCompact ? 4 : 5),
                elevation: 1,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            // CENTER: '전체문항 (Total 40 Questions)' & REVIEW FLAG
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    onTap: _openAllQuestionsSheet,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: isCompact ? 3 : 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view, color: const Color(0xFF1E3A8A), size: isCompact ? 13 : 15),
                          SizedBox(width: isCompact ? 2 : 4),
                          Text(
                            isCompact
                                ? LanguageService.instance.trText(ne: 'सबै', en: 'All', ko: '전체')
                                : LanguageService.instance.trText(ne: 'सबै प्रश्नहरू', en: 'All Qs', ko: '전체문항'),
                            style: TextStyle(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: isCompact ? 9.5 : 11),
                          ),
                          SizedBox(width: isCompact ? 3 : 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_selectedAnswers.length}/40',
                              style: TextStyle(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: isCompact ? 9 : 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 4 : 8),

                Material(
                  color: isFlagged ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    onTap: () => _toggleFlagQuestion(_currentQuestionIndex),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: isCompact ? 3 : 4),
                      decoration: BoxDecoration(
                        color: isFlagged ? Colors.red.shade50 : Colors.white,
                        border: Border.all(color: isFlagged ? Colors.red : Colors.grey.shade300, width: 1.0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFlagged ? Icons.flag : Icons.outlined_flag,
                            color: isFlagged ? Colors.red : Colors.grey.shade700,
                            size: isCompact ? 12 : 14,
                          ),
                          SizedBox(width: isCompact ? 2 : 3),
                          Text(
                            isCompact
                                ? (isFlagged ? '🚩' : '🚩')
                                : LanguageService.instance.trText(ne: 'समीक्षा 🚩', en: 'Review 🚩', ko: '검토 🚩'),
                            style: TextStyle(
                              fontSize: isCompact ? 9.5 : 10,
                              fontWeight: FontWeight.bold,
                              color: isFlagged ? Colors.red.shade900 : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Next / Submit Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLast)
                  ElevatedButton.icon(
                    onPressed: () => _jumpToQuestion(_currentQuestionIndex + 1),
                    icon: Icon(Icons.arrow_forward, size: isCompact ? 12 : 14),
                    label: Text(
                      LanguageService.instance.tr('next_btn'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: btnFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: isCompact ? 4 : 5),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (isLast)
                  ElevatedButton.icon(
                    onPressed: _confirmSubmit,
                    icon: Icon(Icons.check_circle, size: isCompact ? 12 : 14),
                    label: Text(
                      LanguageService.instance.tr('submit_exam'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: btnFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: isCompact ? 4 : 5),
                      elevation: 1,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}


