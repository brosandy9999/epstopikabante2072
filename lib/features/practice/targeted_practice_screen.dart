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
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(LanguageService.instance.trText(ne: 'यस विधामा कुनै कमजोर प्रश्नहरू भेटिएन। तपाईंको तयारी राम्रो छ! 🎉', en: 'No weak questions found in this category. Excellent preparation! 🎉', ko: '이 영역에 취약 문항이 없습니다. 준비가 완벽합니다! 🎉')),
        ),
      );
    }

    final q = widget.questions[_currentIndex];
    final answerKeys = QuestionBankService.instance.getAnswerKeys();
    final keyInfo = answerKeys[q.questionId] ?? const QuestionAnswerInfo(correctIndex: 1, explanation: 'Official EPS-TOPIK Key');
    final isCorrect = _submitted && _selectedOption == keyInfo.correctIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              LanguageService.instance.trText(ne: 'प्रश्न ' + (_currentIndex + 1).toString() + ' / ' + widget.questions.length.toString() + ' • सुधारिएका: ' + _masteredCount.toString(), en: 'Question ' + (_currentIndex + 1).toString() + ' / ' + widget.questions.length.toString() + ' • Mastered: ' + _masteredCount.toString(), ko: '문항 ' + (_currentIndex + 1).toString() + ' / ' + widget.questions.length.toString() + ' • 오답해결: ' + _masteredCount.toString()),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
                    const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 5,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      LanguageService.instance.trText(ne: '🎯 लक्षित कमजोरी निवारण अभ्यास', en: '🎯 Targeted Weakness Practice', ko: '🎯 맞춤형 취약 문항 연습'),
                      style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final isListening = (q is ListeningAudioQuestion) ||
                          (q is UniversalQuestion && q.isListening);
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
                  if (_submitted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCorrect
                                      ? LanguageService.instance.trText(
                                          ne: '🎉 सहि उत्तर! यो प्रश्न सफलतापूर्वक सुधारियो!',
                                          en: '🎉 Correct Answer! Weakness resolved!',
                                          ko: '🎉 정답입니다! 취약점이 해결되었습니다!',
                                        )
                                      : LanguageService.instance.trText(
                                          ne: '❌ गल्ती भयो! सही उत्तर तल हेर्नुहोस्:',
                                          en: '❌ Incorrect! Check the correct answer below:',
                                          ko: '❌ 오답입니다! 아래 해설을 확인하세요:',
                                        ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'सहि उत्तर: विकल्प (${keyInfo.correctIndex + 1})',
                              en: 'Correct Answer: Option (${keyInfo.correctIndex + 1})',
                              ko: '정답: 보기 (${keyInfo.correctIndex + 1})',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'व्याख्या: ${keyInfo.explanation}',
                              en: 'Explanation: ${keyInfo.explanation}',
                              ko: '해설: ${keyInfo.explanation}',
                            ),
                            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _submitted
                      ? (isCorrect ? LanguageService.instance.trText(ne: 'सुधार भयो ✅', en: 'Mastered ✅', ko: '정답 확인 ✅') : LanguageService.instance.trText(ne: 'पुनः प्रयास आवश्यक ⚠️', en: 'Review Needed ⚠️', ko: '다시 풀기 필요 ⚠️'))
                      : LanguageService.instance.trText(ne: 'उत्तर छान्नुहोस्', en: 'Select an option', ko: '답안을 선택하세요'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _submitted ? (isCorrect ? Colors.green : Colors.red) : Colors.grey.shade700,
                  ),
                ),
                if (!_submitted)
                  ElevatedButton.icon(
                    onPressed: _selectedOption != null ? _submitAnswer : null,
                    icon: const Icon(Icons.check),
                    label: Text(LanguageService.instance.trText(ne: 'उत्तर जाँच्नुहोस्', en: 'Check Answer', ko: '정답 확인')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_currentIndex < widget.questions.length - 1 ? LanguageService.instance.tr('next_btn') : LanguageService.instance.tr('done')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
