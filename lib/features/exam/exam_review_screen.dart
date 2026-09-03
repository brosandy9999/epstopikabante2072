import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/services/question_bank_service.dart';

enum ReviewFilter { all, correct, incorrect, unanswered }

/// Comprehensive Question-by-Question Review Screen (???? / Answer Key)
class ExamReviewScreen extends StatefulWidget {
  final List<QuestionTemplate> questions;
  final Map<int, int> userAnswers;
  final String? setId;
  final String? setTitle;
  final Map<String, QuestionAnswerInfo>? customAnswerKeys;

  const ExamReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    this.setId,
    this.setTitle,
    this.customAnswerKeys,
  });

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  ReviewFilter _selectedFilter = ReviewFilter.all;
  late final Map<String, QuestionAnswerInfo> _answerKeys;

  @override
  void initState() {
    super.initState();
    if (widget.customAnswerKeys != null) {
      _answerKeys = widget.customAnswerKeys!;
    } else if (widget.setId != null) {
      _answerKeys = QuestionBankService.instance.getMockSetById(widget.setId!).answerKeys;
    } else {
      _answerKeys = QuestionBankService.instance.getAnswerKeys();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate counts for badges
    int correctCount = 0;
    int incorrectCount = 0;
    int unansweredCount = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final keyInfo = _answerKeys[q.questionId];
      final userChoice = widget.userAnswers[i];

      if (userChoice == null) {
        unansweredCount++;
      } else if (keyInfo != null && userChoice == keyInfo.correctIndex) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    // Filter questions
    final filteredQuestionsWithIndex = <MapEntry<int, QuestionTemplate>>[];
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final keyInfo = _answerKeys[q.questionId];
      final userChoice = widget.userAnswers[i];

      bool matches = false;
      switch (_selectedFilter) {
        case ReviewFilter.all:
          matches = true;
          break;
        case ReviewFilter.correct:
          matches = userChoice != null && keyInfo != null && userChoice == keyInfo.correctIndex;
          break;
        case ReviewFilter.incorrect:
          matches = userChoice != null && keyInfo != null && userChoice != keyInfo.correctIndex;
          break;
        case ReviewFilter.unanswered:
          matches = userChoice == null;
          break;
      }

      if (matches) {
        filteredQuestionsWithIndex.add(MapEntry(i, q));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.setTitle != null
              ? "${widget.setTitle} (Review & Explanations)"
              : "EPS-TOPIK परीक्षा प्रश्न-उत्तर समीक्षा (Review & Explanations)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text("??????: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                _buildFilterChip("??? (All 40)", ReviewFilter.all, widget.questions.length, Colors.blueGrey),
                const SizedBox(width: 8),
                _buildFilterChip("??? ()", ReviewFilter.correct, correctCount, Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip("??? ()", ReviewFilter.incorrect, incorrectCount, Colors.red),
                const SizedBox(width: 8),
                _buildFilterChip("????? ()", ReviewFilter.unanswered, unansweredCount, Colors.orange),
              ],
            ),
          ),
          const Divider(height: 1),

          // Questions List
          Expanded(
            child: filteredQuestionsWithIndex.isEmpty
                ? const Center(
                    child: Text(
                      "?? ???????? ???? ?????? ???? ?????",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    itemCount: filteredQuestionsWithIndex.length,
                    itemBuilder: (context, idx) {
                      final entry = filteredQuestionsWithIndex[idx];
                      final qIndex = entry.key;
                      final q = entry.value;
                      final keyInfo = _answerKeys[q.questionId];
                      final userChoice = widget.userAnswers[qIndex];
                      final isReading = qIndex < 20;

                      final isCorrect = userChoice != null && keyInfo != null && userChoice == keyInfo.correctIndex;
                      final isUnanswered = userChoice == null;

                      final options = (q is ReadingTextQuestion)
                          ? q.textOptions
                          : ((q is ListeningAudioQuestion) ? q.textOptions : <String>[]);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green.shade300
                                : (isUnanswered ? Colors.orange.shade300 : Colors.red.shade300),
                            width: 1.8,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Header & Result Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isReading ? const Color(0xFF1E3A8A) : const Color(0xFFD97706),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isReading ? "?? (Reading)" : "?? (Listening)",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "??  / 40 ()",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14),
                                      ),
                                    ],
                                  ),

                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? Colors.green.shade50
                                          : (isUnanswered ? Colors.orange.shade50 : Colors.red.shade50),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isCorrect
                                            ? Colors.green
                                            : (isUnanswered ? Colors.orange : Colors.red),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCorrect
                                              ? Icons.check_circle
                                              : (isUnanswered ? Icons.help_outline : Icons.cancel),
                                          color: isCorrect
                                              ? Colors.green
                                              : (isUnanswered ? Colors.orange : Colors.red),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isCorrect
                                              ? "정답 (सही) +2.5점"
                                              : (isUnanswered ? "미답 (खाली) 0점" : "오답 (गलत) 0점"),
                                          style: TextStyle(
                                            color: isCorrect
                                                ? Colors.green.shade900
                                                : (isUnanswered ? Colors.orange.shade900 : Colors.red.shade900),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Question Text
                              Text(
                                q.questionText,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                              ),
                              const SizedBox(height: 14),

                              // 4 Options with Correct / User Pick indicators
                              ...List.generate(options.length, (optIdx) {
                                final isCorrectChoice = keyInfo != null && optIdx == keyInfo.correctIndex;
                                final isUserChoice = userChoice == optIdx;
                                final circledNumbers = ["?", "?", "?", "?"];
                                final label = optIdx < circledNumbers.length ? circledNumbers[optIdx] : "";

                                Color optBgColor = Colors.grey.shade50;
                                Color optBorderColor = Colors.grey.shade300;
                                Color textColor = Colors.black87;
                                Widget? badge;

                                if (isCorrectChoice) {
                                  optBgColor = const Color(0xFFDCFCE7); // Light green
                                  optBorderColor = Colors.green;
                                  textColor = Colors.green.shade900;
                                  badge = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("? ?? (??? ?????)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  );
                                } else if (isUserChoice && !isCorrectChoice) {
                                  optBgColor = const Color(0xFFFEE2E2); // Light red
                                  optBorderColor = Colors.red;
                                  textColor = Colors.red.shade900;
                                  badge = Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("? ? ?? (??????? ?????)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: optBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: optBorderColor, width: (isCorrectChoice || isUserChoice) ? 2 : 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          options[optIdx],
                                          style: TextStyle(fontSize: 15, fontWeight: (isCorrectChoice || isUserChoice) ? FontWeight.bold : FontWeight.normal, color: textColor),
                                        ),
                                      ),
                                      if (badge != null) badge,
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 12),

                              // Explanation Box (?????? ? ?????? ????????)
                              if (keyInfo != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.lightbulb, color: Color(0xFF2563EB), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "?? ?? (????????):",
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              keyInfo.explanation,
                                              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
                                            ),
                                          ],
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReviewFilter filter, int count, Color activeColor) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      selectedColor: activeColor.withOpacity(0.2),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? activeColor : Colors.black87,
      ),
    );
  }
}
