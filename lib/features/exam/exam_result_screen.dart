import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
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

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            LanguageService.instance.trText(
              ne: 'परीक्षा नतिजा तथा स्कोरकार्ड',
              en: 'Exam Results & Scorecard',
              ko: '시험 결과 및 성적표',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            LanguageService.instance.buildLanguageSwitcherWidget(),
            const SizedBox(width: 10),
          ],
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
                                      isPassed
                                          ? LanguageService.instance.trText(
                                              ne: 'उत्तीर्ण (PASSED) - बधाई छ!',
                                              en: 'PASS - Congratulations!',
                                              ko: '합격 (PASSED) - 축하합니다!',
                                            )
                                          : LanguageService.instance.trText(
                                              ne: 'अनुत्तीर्ण (FAILED) - अझै अभ्यास गर्नुहोस्',
                                              en: 'FAIL - Needs Improvement',
                                              ko: '불합격 (FAILED) - 재도전 필요',
                                            ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isPassed
                                          ? LanguageService.instance.trText(
                                              ne: 'तपाईंले न्यूनतम उत्तीर्णांक (५० अंक) प्राप्त गर्नुभएको छ।',
                                              en: 'You have achieved the required passing score (50+ points).',
                                              ko: '합격 기준 점수(50점 이상)를 달성하셨습니다.',
                                            )
                                          : LanguageService.instance.trText(
                                              ne: 'उत्तीर्ण हुन कम्तिमा ५० अंक आवश्यक पर्दछ। पुनः प्रयास गर्नुहोस्।',
                                              en: 'Minimum 50 points required to pass. Keep practicing!',
                                              ko: '합격을 위해서는 50점 이상이 필요합니다. 다시 도전해 보세요.',
                                            ),
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
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
                                LanguageService.instance.trText(
                                  ne: 'कुल ${formatScore(totalScore)} / १००',
                                  en: 'Score ${formatScore(totalScore)} / 100',
                                  ko: '총점 ${formatScore(totalScore)} / 100',
                                ),
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
                                  _buildInfoColumn(
                                    LanguageService.instance.trText(ne: 'विद्यार्थीको नाम', en: 'Candidate Name', ko: '성명'),
                                    student?.name ?? 'राम बहादुर',
                                  ),
                                  _buildInfoColumn(
                                    LanguageService.instance.trText(ne: 'दर्ता नम्बर', en: 'Reg Number', ko: '수험번호'),
                                    student?.registrationNo ?? '01234567',
                                  ),
                                  _buildInfoColumn(
                                    LanguageService.instance.trText(ne: 'परीक्षा प्रकार', en: 'Exam Type', ko: '시험 유형'),
                                    LanguageService.instance.trText(ne: 'EPS-TOPIK UBT ४० प्रश्न', en: 'EPS-TOPIK UBT 40 Items', ko: 'EPS-TOPIK UBT 40문항'),
                                  ),
                                  _buildInfoColumn(
                                    LanguageService.instance.trText(ne: 'परीक्षा मिति', en: 'Exam Date', ko: '시험 일자'),
                                    '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
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
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: LanguageService.instance.trText(ne: 'कुल प्राप्ताङ्क', en: 'Total Score', ko: '총점'),
                        value: formatScore(totalScore),
                        subValue: LanguageService.instance.trText(ne: '/ १०० पूर्णाङ्क', en: '/ 100 Full Marks', ko: '/ 100 만점'),
                        color: const Color(0xFF1E3A8A),
                        icon: Icons.stars,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: LanguageService.instance.readingSectionText(),
                        value: formatScore(readingScore),
                        subValue: '/ 50 ($readingCorrect/20 ' + LanguageService.instance.trText(ne: 'सहि', en: 'Correct', ko: '정답') + ')',
                        color: const Color(0xFF2563EB),
                        icon: Icons.menu_book,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: LanguageService.instance.listeningSectionText(),
                        value: formatScore(listeningScore),
                        subValue: '/ 50 ($listeningCorrect/20 ' + LanguageService.instance.trText(ne: 'सहि', en: 'Correct', ko: '정답') + ')',
                        color: const Color(0xFFD97706),
                        icon: Icons.headphones,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        title: LanguageService.instance.trText(ne: 'शुद्धता दर', en: 'Accuracy Rate', ko: '정답률'),
                        value: '${accuracy.toStringAsFixed(1)}%',
                        subValue: '$minutes ' + LanguageService.instance.trText(ne: 'मिनेट', en: 'm', ko: '분') + ' $seconds ' + LanguageService.instance.trText(ne: 'सेकेन्ड', en: 's', ko: '초'),
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
                      Text(
                        LanguageService.instance.trText(ne: 'उत्तर विश्लेषण तथा विवरण', en: 'Answer Breakdown', ko: '문항별 정답 현황'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBreakdownItem(LanguageService.instance.trText(ne: 'सहि उत्तर', en: 'Correct', ko: '정답'), totalCorrect, Colors.green),
                          _buildBreakdownItem(LanguageService.instance.trText(ne: 'गलत उत्तर', en: 'Incorrect', ko: '오답'), totalAttempted - totalCorrect, Colors.red),
                          _buildBreakdownItem(LanguageService.instance.trText(ne: 'नछोएका प्रश्न', en: 'Unanswered', ko: '미풀이'), 40 - totalAttempted, Colors.orange),
                          _buildBreakdownItem(LanguageService.instance.trText(ne: 'कुल हल गरेका', en: 'Attempted', ko: '풀이 문항'), totalAttempted, const Color(0xFF1E3A8A)),
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
                            label: Text(
                              '📄 ' + LanguageService.instance.trText(
                                ne: 'आधिकारिक स्कोरकार्ड प्रिन्ट',
                                en: 'Official Scorecard',
                                ko: '공식 성적확인서 발급',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            label: Text(
                              LanguageService.instance.trText(
                                ne: 'सबै प्रश्न तथा व्याख्या समीक्षा',
                                en: 'Review All Answers',
                                ko: '전체 문항 해설 복습',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            label: Text(
                              LanguageService.instance.trText(
                                ne: 'गृहपृष्ठ / ड्यासबोर्डमा फर्कनुहोस्',
                                en: 'Back to Dashboard',
                                ko: '대시보드로 돌아가기',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
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
          '$count ' + LanguageService.instance.trText(ne: 'वटा', en: 'items', ko: '문항'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
      ],
    );
  }
}
