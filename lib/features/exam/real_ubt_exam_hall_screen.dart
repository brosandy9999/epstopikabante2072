import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  int _remainingSeconds = 3000;
  Timer? _timer;
  bool _fiveMinuteWarningShown = false;

  double _fontScale = 1.0;

  // Anti-Cheat
  int _cheatWarnings = 0;
  static const int _maxCheatWarnings = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questions = widget.mockSet?.questions ?? QuestionBankService.instance.getFull40ExamQuestions();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
              '🚨 부정행위 방지 경고 (' + _cheatWarnings.toString() + '/' + _maxCheatWarnings.toString() + ')',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시험 중 브라우저 창이나 탭을 벗어나는 행위는 엄격히 금지됩니다!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'परीक्षा हलबाट बाहिर अन्य विन्डो वा ट्याबमा जान सख्त निषेध गरिएको छ। ३ पटक उल्लंघन भएमा परीक्षा स्वतः सबमिट हुनेछ।',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'बाँकी मौका: ' + (_maxCheatWarnings - _cheatWarnings).toString() + ' पटक',
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('परीक्षामा फर्कनुहोस् (Continue Exam)'),
          ),
        ],
      ),
    );
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);

        if (_remainingSeconds == 300 && !_fiveMinuteWarningShown) {
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
        content: const Row(
          children: [
            Icon(Icons.timer, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '⏰ 시험 종료 5분 전입니다! (५ मिनेट बाँकी छ, कृपया उत्तरहरू रुजु गर्नुहोस्!)',
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
        title: const Text('시험 중단 및 퇴실 확인 (Exit Confirmation)'),
        content: const Text(
          '지금 퇴실하시면 현재까지 작성한 답안만 채점되거나 시험이 무효 처리될 수 있습니다. 정말 퇴실하시겠습니까?\n\n'
          '(के तपाईं परीक्षा समाप्त नगरी बाहिरिन निश्चित हुनुहुन्छ?)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소 (रद्द)')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('퇴실 (Exit Exam)'),
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
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF1E3A8A), size: 28),
            SizedBox(width: 10),
            Text('최종 답안 제출 (Submit Exam)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수험자: ' + (widget.student?.name ?? 'विद्यार्थी'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('수험번호: ' + (widget.student?.registrationNo ?? '2026-001')),
            const Divider(height: 20),
            _buildStatRow('총 문항수 (Total Questions):', total.toString(), Colors.black87),
            _buildStatRow('답안 작성 (Answered):', answered.toString(), Colors.green),
            _buildStatRow('미작성 문항 (Unanswered):', unanswered.toString(), unanswered > 0 ? Colors.red : Colors.grey),
            _buildStatRow('검토 요청 (Marked for Review):', flagged.toString(), Colors.amber.shade900),
            const SizedBox(height: 14),
            const Text(
              '제출 후에는 답안을 수정할 수 없습니다. 답안을 최종 제출하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('계속 풀기 (रद्द)')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _submitExamDirectly();
            },
            child: const Text('제출하기 (Submit)'),
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
                      const Row(
                        children: [
                          Icon(Icons.grid_view, color: Color(0xFF1E3A8A), size: 24),
                          SizedBox(width: 10),
                          Text(
                            '전체문항 (४० प्रश्नहरूको दुई खण्ड ग्रिड)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'कुल हल: ' + _selectedAnswers.length.toString() + '/40',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'बन्द गर्नुहोस्',
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
                              title: '📖 읽기 (Reading 01 - 20)',
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
                              title: '🎧 듣기 (Listening 21 - 40)',
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
                      _buildLegend(const Color(0xFF1E3A8A), 'हल भएको (' + _selectedAnswers.length.toString() + ')'),
                      _buildLegend(Colors.white, 'नछोएको (' + (40 - _selectedAnswers.length).toString() + ')', border: true),
                      _buildLegend(Colors.amber, 'हालको प्रश्न', border: true),
                      _buildLegend(Colors.red, 'समीक्षा (' + _flaggedQuestions.length.toString() + ')', isFlag: true),
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
                  'हल: ' + answeredCount.toString() + '/20',
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
    final currentQ = _questions[_currentQuestionIndex];
    final isReading = _currentQuestionIndex < 20;

    return Scaffold(
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
                      label: const Text('퇴실 (Exit)', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                          '수험번호: ' + (widget.student?.registrationNo ?? '2026-001') + '  |  좌석: 12번',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          '성명: ' + (widget.student?.name ?? 'विद्यार्थी'),
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
                        isReading ? '📖 읽기 (Reading 1-20)' : '🎧 듣기 (Listening 21-40)',
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
                        '문항 ' + (_currentQuestionIndex + 1).toString() + ' / ' + _questions.length.toString(),
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

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 300 ? Colors.red.shade700 : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _remainingSeconds < 300 ? Colors.redAccent : Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: _remainingSeconds < 300 ? Colors.yellowAccent : Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimer(_remainingSeconds),
                            style: TextStyle(
                              color: _remainingSeconds < 300 ? Colors.yellowAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
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
    );
  }

  Widget _buildCurrentQuestion(QuestionTemplate currentQ) {
    if (currentQ is ReadingTextQuestion) {
      return ReadingQuestionWidget(
        key: ValueKey(currentQ.questionId),
        question: currentQ,
        selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
        onOptionSelected: (idx) {
          setState(() => _selectedAnswers[_currentQuestionIndex] = idx);
        },
      );
    } else if (currentQ is ListeningAudioQuestion) {
      return ListeningQuestionWidget(
        key: ValueKey(currentQ.questionId),
        question: currentQ,
        selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
        onOptionSelected: (idx) {
          setState(() => _selectedAnswers[_currentQuestionIndex] = idx);
        },
      );
    }
    return const SizedBox.shrink();
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
            label: const Text('이전 (Previous)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text(
                          '전체문항 (दुई खण्ड ग्रिड)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'हल: ' + _selectedAnswers.length.toString() + '/40',
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
                            '문항 ' + (_currentQuestionIndex + 1).toString() + ' / 40',
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
                        '검토 (Review 🚩)',
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
                  label: const Text('다음 (Next)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                label: const Text('최종 제출 (Submit)', style: TextStyle(fontWeight: FontWeight.bold)),
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
