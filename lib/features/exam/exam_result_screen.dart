import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/question_bank_service.dart';
import 'exam_review_screen.dart';
import 'official_scorecard_screen.dart';

import '../../core/services/exam_service.dart';

/// Official EPS-TOPIK UBT Scorecard and Grade Analytics Screen
class ExamResultScreen extends StatelessWidget {
  final AppUser? student;
  final String? setId;
  final String? setTitle;
  final List<QuestionTemplate> questions;
  final Map<int, int> userAnswers;
  final int timeSpentSeconds;

  const ExamResultScreen({
    super.key,
    this.student,
    this.setId,
    this.setTitle,
    required this.questions,
    required this.userAnswers,
    required this.timeSpentSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final activeSet = QuestionBankService.instance.getMockSetById(setId ?? 'set_01');
    final answerKeys = activeSet.answerKeys;

    int readingCorrect = 0;
    int listeningCorrect = 0;
    int totalAttempted = userAnswers.length;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final keyInfo = answerKeys[q.questionId];
      final userChoice = userAnswers[i];

      if (userChoice != null && keyInfo != null && userChoice == keyInfo.correctIndex) {
        if (i < 20) {
          readingCorrect++;
        } else {
          listeningCorrect++;
        }
      }
    }

    final totalCorrect = readingCorrect + listeningCorrect;
    final double readingScore = readingCorrect * 2.5; // 20 questions * 2.5 = 50 marks
    final double listeningScore = listeningCorrect * 2.5; // 20 questions * 2.5 = 50 marks
    final double totalScore = readingScore + listeningScore; // 100 full marks
    final bool isPassed = totalScore >= 50; // Pass mark: 50/100 (50%)

    // Automatically record exam attempt for history tracking
    ExamHistoryService.instance.saveAttempt(
      ExamAttemptRecord(
        setId: setId ?? 'set_01',
        setTitle: setTitle ?? activeSet.title,
        studentId: student?.username ?? 'student',
        studentName: student?.name ?? 'विद्यार्थी',
        registrationNo: student?.registrationNo ?? '01234567',
        score: totalScore,
        readingScore: readingScore,
        listeningScore: listeningScore,
        isPassed: isPassed,
        completedAt: DateTime.now(),
        timeSpentSeconds: timeSpentSeconds,
        userAnswers: Map<int, int>.from(userAnswers),
      ),
    );

    String formatScore(double score) => (score % 1 == 0) ? score.toInt().toString() : score.toStringAsFixed(1);

    final int minutes = timeSpentSeconds ~/ 60;
    final int seconds = timeSpentSeconds % 60;
    final double accuracy = (totalCorrect / 40.0) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'EPS-TOPIK UBT परीक्षा नतिजा (Scorecard)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPassed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                                color: Colors.white,
                                size: 36,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPassed ? '합격 (PASS) - बधाई छ!' : '불합격 (FAIL) - अनुत्तीर्ण',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPassed
                                        ? 'तपाईंले न्यूनतम उत्तीर्णांक (५० अंक) प्राप्त गर्नुभएको छ।'
                                        : 'उत्तीर्ण हुन कम्तिमा ५० अंक आवश्यक पर्दछ। पुनः प्रयास गर्नुहोस्।',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '총점 ${formatScore(totalScore)} / 100',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.person, size: 36, color: Colors.blue.shade900),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoColumn('विद्यार्थीको नाम (성명)', student?.name ?? 'राम बहादुर'),
                                _buildInfoColumn('दर्ता नम्बर (수험번호)', student?.registrationNo ?? '01234567'),
                                _buildInfoColumn('परीक्षा प्रकार', 'EPS-TOPIK UBT 40문항'),
                                _buildInfoColumn('परीक्षा मिति', '2026. 09. 03'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'कुल प्राप्तांक (Total Score)',
                      value: formatScore(totalScore),
                      subValue: '/ 100 अंक',
                      color: const Color(0xFF1E3A8A),
                      icon: Icons.stars,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: '읽기 영역 (Reading)',
                      value: formatScore(readingScore),
                      subValue: '/ 50 ($readingCorrect/20 सहि)',
                      color: const Color(0xFF2563EB),
                      icon: Icons.menu_book,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: '듣기 영역 (Listening)',
                      value: formatScore(listeningScore),
                      subValue: '/ 50 ($listeningCorrect/20 सहि)',
                      color: const Color(0xFFD97706),
                      icon: Icons.headphones,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'समय र शुद्धता (Accuracy)',
                      value: '${accuracy.toStringAsFixed(1)}%',
                      subValue: '$minutes मिनेट $seconds सेकेन्ड',
                      color: const Color(0xFF0D9488),
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'प्रश्न उत्तर विश्लेषण (Answer Breakdown)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBreakdownItem('सहि उत्तर (Correct)', totalCorrect, Colors.green),
                        _buildBreakdownItem('गलत उत्तर (Incorrect)', totalAttempted - totalCorrect, Colors.red),
                        _buildBreakdownItem('छोडेका प्रश्न (Unanswered)', 40 - totalAttempted, Colors.orange),
                        _buildBreakdownItem('हल गरिएका (Attempted)', totalAttempted, const Color(0xFF1E3A8A)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OfficialScorecardScreen(
                                  student: student,
                                  setTitle: setTitle ?? activeSet.title,
                                  questions: questions,
                                  userAnswers: userAnswers,
                                  score: totalScore,
                                  readingScore: readingScore,
                                  listeningScore: listeningScore,
                                  isPassed: isPassed,
                                  date: DateTime.now(),
                                  timeSpentSeconds: timeSpentSeconds,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.workspace_premium, size: 22),
                          label: const Text(
                            '📄 आधिकारिक स्कोरकार्ड (Scorecard / PDF Print)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExamReviewScreen(
                                  questions: questions,
                                  userAnswers: userAnswers,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_turned_in, size: 22),
                          label: const Text(
                            'विस्तृत उत्तर समीक्षा हेर्नुहोस् (Review All Answers / 오답노트)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home, size: 22),
                          label: const Text(
                            'होम पोर्टलमा फर्कनुहोस् (Student Portal)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.8),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: color)),
          const SizedBox(height: 4),
          Text(subValue, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label + ': ', style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Text(
          ' वटा',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
      ],
    );
  }
}
