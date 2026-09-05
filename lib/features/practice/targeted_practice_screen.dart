import '../../core/services/language_service.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/weakness_analysis_service.dart';
import '../question_engine/question_template.dart';
import '../reading/reading_widget.dart';
import '../listening/listening_widget.dart';

/// Targeted Practice Screen: Interactive session for resolving weak/mistake questions
class TargetedPracticeScreen extends StatefulWidget {
  final String title;
  final List<QuestionTemplate> questions;
  final String? studentId;

  const TargetedPracticeScreen({
    super.key,
    required this.title,
    required this.questions,
    this.studentId,
  });

  @override
  State<TargetedPracticeScreen> createState() => _TargetedPracticeScreenState();
}

class _TargetedPracticeScreenState extends State<TargetedPracticeScreen> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _submitted = false;
  int _masteredCount = 0;

  void _submitAnswer() {
    if (_selectedOption == null) return;

    final q = widget.questions[_currentIndex];
    final answerKeys = QuestionBankService.instance.getAnswerKeys();
    final keyInfo = answerKeys[q.questionId] ?? const QuestionAnswerInfo(correctIndex: 1, explanation: 'Official EPS-TOPIK Key');
    final isCorrect = _selectedOption == keyInfo.correctIndex;

    setState(() {
      _submitted = true;
      if (isCorrect) {
        _masteredCount++;
        final sId = widget.studentId ?? AuthService.instance.currentUser?.id ?? 'student_01';
        WeaknessAnalysisService.instance.markQuestionResolved(sId, q.questionId);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _submitted = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            const SizedBox(width: 10),
            Text(LanguageService.instance.trText(ne: 'अभ्यास सम्पन्न!', en: 'Practice Complete!', ko: '연습 완료!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.instance.trText(
                ne: 'तपाईंले कुल ' + widget.questions.length.toString() + ' वटा कमजोर प्रश्नहरूमध्ये ' + _masteredCount.toString() + ' वटा प्रश्न सफलतापूर्वक सुधार गर्नुभयो!',
                en: 'You successfully solved ' + _masteredCount.toString() + ' out of ' + widget.questions.length.toString() + ' weak questions!',
                ko: '총 ' + widget.questions.length.toString() + '개의 취약 문항 중 ' + _masteredCount.toString() + '문항을 완료했습니다!',
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    LanguageService.instance.trText(ne: 'सुधार दर: ', en: 'Improvement Rate: ', ko: '개선율: ') + ((_masteredCount / (widget.questions.isEmpty ? 1 : widget.questions.length)) * 100).toInt().toString() + '%',
                    style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(LanguageService.instance.trText(ne: 'ड्यासबोर्डमा फर्कनुहोस्', en: 'Back to Dashboard', ko: '대시보드로 돌아가기')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(LanguageService.instance.trText(ne: 'फर्कनुहोस्', en: 'Back', ko: '돌아가기'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: 'यस विधामा कुनै कमजोर प्रश्नहरू भेटिएन। तपाईंको तयारी राम्रो छ! 🎉',
                      en: 'No weak questions found in this category. Excellent preparation! 🎉',
                      ko: '이 영역에 취약 문항이 없습니다. 준비가 완벽합니다! 🎉',
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final q = widget.questions[_currentIndex];
    final answerKeys = QuestionBankService.instance.getAnswerKeys();
    final keyInfo = answerKeys[q.questionId] ?? const QuestionAnswerInfo(correctIndex: 1, explanation: 'Official EPS-TOPIK Key');
    final isCorrect = _submitted && _selectedOption == keyInfo.correctIndex;
    final isListening = (q is ListeningAudioQuestion) || (q is UniversalQuestion && q.isListening);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. SLEEK FLOATING HEADER (No solid blue bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    // Exit Button (Red Accent)
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              LanguageService.instance.trText(ne: 'बाहिरिनुहोस्', en: 'Exit', ko: '나가기'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Topic / Practice Title Badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology, size: 16, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Section Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isListening ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isListening ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        isListening ? LanguageService.instance.trText(ne: '🎧 लिसनिङ', en: '🎧 Listening', ko: '🎧 듣기') : LanguageService.instance.trText(ne: '📖 रिडिङ', en: '📖 Reading', ko: '📖 읽기'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isListening ? const Color(0xFFB45309) : const Color(0xFF1E3A8A)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Question Counter Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text(
                        LanguageService.instance.trText(
                          ne: 'प्रश्न ${_currentIndex + 1} / ${widget.questions.length}',
                          en: 'Q ${_currentIndex + 1} / ${widget.questions.length}',
                          ko: '문항 ${_currentIndex + 1} / ${widget.questions.length}',
                        ),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Mastered Count Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'सुधार: $_masteredCount',
                              en: 'Resolved: $_masteredCount',
                              ko: '오답해결: $_masteredCount',
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtle Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 2. MAIN INTERACTIVE QUESTION CANVAS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3.5,
                  clipBehavior: Clip.none,
                  child: Builder(
                    builder: (context) {
                      if (isListening) {
                        return ListeningQuestionWidget(
                          key: ValueKey(q.questionId),
                          question: q,
                          selectedOptionIndex: _selectedOption,
                          onOptionSelected: _submitted ? (_) {} : (idx) => setState(() => _selectedOption = idx),
                        );
                      } else {
                        return ReadingQuestionWidget(
                          key: ValueKey(q.questionId),
                          question: q,
                          selectedOptionIndex: _selectedOption,
                          onOptionSelected: _submitted ? (_) {} : (idx) => setState(() => _selectedOption = idx),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            // 3. EXPLANATION & INSTANT FEEDBACK BANNER (If Submitted)
            if (_submitted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCorrect ? Colors.green.shade400 : Colors.red.shade400, width: 1.2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCorrect
                                  ? LanguageService.instance.trText(
                                      ne: '🎉 सहि उत्तर! यो प्रश्नको कमजोरी सफलतापूर्वक सुधार गरियो!',
                                      en: '🎉 Correct Answer! Weakness successfully resolved!',
                                      ko: '🎉 정답입니다! 취약점이 해결되었습니다!',
                                    )
                                  : LanguageService.instance.trText(
                                      ne: '❌ गल्ती भयो! सही उत्तर: विकल्प (${keyInfo.correctIndex + 1})',
                                      en: '❌ Incorrect! Correct: Option (${keyInfo.correctIndex + 1})',
                                      ko: '❌ 오답입니다! 정답: 보기 (${keyInfo.correctIndex + 1})',
                                    ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                            if (keyInfo.explanation.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${LanguageService.instance.trText(ne: "व्याख्या", en: "Explanation", ko: "해설")}: ${keyInfo.explanation}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. FLOATING ACTION CONTROLS (No heavy solid bottom bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _submitted ? (isCorrect ? Icons.check_circle : Icons.error_outline) : Icons.touch_app,
                          size: 16,
                          color: _submitted ? (isCorrect ? Colors.green : Colors.red) : Colors.blueGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _submitted
                              ? (isCorrect ? LanguageService.instance.trText(ne: 'सुधार भयो ✅', en: 'Mastered ✅', ko: '정답 확인 ✅') : LanguageService.instance.trText(ne: 'पुनः प्रयास आवश्यक ⚠️', en: 'Review Needed ⚠️', ko: '다시 풀기 필요 ⚠️'))
                              : (_selectedOption != null
                                  ? LanguageService.instance.trText(ne: 'विकल्प ${_selectedOption! + 1} छनोट भयो', en: 'Option ${_selectedOption! + 1} selected', ko: '보기 ${_selectedOption! + 1} 선택됨')
                                  : LanguageService.instance.trText(ne: 'उत्तर छान्नुहोस्', en: 'Select an option', ko: '답안을 선택하세요')),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _submitted ? (isCorrect ? Colors.green.shade800 : Colors.red.shade800) : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button (Check Answer / Next)
                  if (!_submitted)
                    ElevatedButton.icon(
                      onPressed: _selectedOption != null ? _submitAnswer : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(LanguageService.instance.trText(ne: 'उत्तर जाँच्नुहोस्', en: 'Check Answer', ko: '정답 확인'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        _currentIndex < widget.questions.length - 1 ? LanguageService.instance.tr('next_btn') : LanguageService.instance.tr('done'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCorrect ? const Color(0xFF16A34A) : Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
