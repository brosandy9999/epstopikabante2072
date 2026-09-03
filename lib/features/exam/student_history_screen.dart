import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/exam_service.dart';
import '../../core/services/question_bank_service.dart';
import 'exam_review_screen.dart';
import '../../main.dart'; // For UbtExamScreen

class StudentHistoryScreen extends StatefulWidget {
  final AppUser student;
  const StudentHistoryScreen({super.key, required this.student});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _filter = 'all'; // all, passed, failed

  @override
  Widget build(BuildContext context) {
    final allAttempts = ExamHistoryService.instance.getAttemptsForStudent(widget.student.username);

    // Apply Filter
    final filteredAttempts = allAttempts.where((a) {
      if (_filter == 'passed') return a.isPassed;
      if (_filter == 'failed') return !a.isPassed;
      return true;
    }).toList();

    // Stats
    final totalTaken = allAttempts.length;
    final totalPassed = allAttempts.where((a) => a.isPassed).length;
    final avgScore = totalTaken > 0
        ? allAttempts.map((a) => a.score).reduce((a, b) => a + b) / totalTaken
        : 0.0;
    final bestScore = totalTaken > 0
        ? allAttempts.map((a) => a.score).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "मेरो परीक्षा इतिहास तथा कमजोरी समीक्षा (My Exam History)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.student.name.isNotEmpty ? widget.student.name[0] : 'S',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.student.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          "दर्ता नम्बर: ${widget.student.registrationNo ?? '2026-001'}  •  ID: ${widget.student.username}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "EPS-TOPIK परीक्षार्थी",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Performance Metric Counters
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildStatPill("कुल परीक्षाहरू", "$totalTaken पटक", Icons.assignment_turned_in, Colors.blue),
                _buildStatPill("उत्तीर्ण परीक्षाहरू", "$totalPassed पटक", Icons.verified, Colors.green),
                _buildStatPill("औसत प्राप्ताङ्क", "${avgScore.toStringAsFixed(1)} / १००", Icons.analytics, Colors.purple),
                _buildStatPill("उत्कृष्ट नतिजा", "${bestScore.toStringAsFixed(1)} / १००", Icons.emoji_events, Colors.amber.shade800),
              ],
            ),

            const SizedBox(height: 24),

            // Filter Tabs
            Row(
              children: [
                ChoiceChip(
                  label: Text("सबै परीक्षाहरू ($totalTaken)"),
                  selected: _filter == 'all',
                  selectedColor: const Color(0xFF1E3A8A),
                  labelStyle: TextStyle(
                    color: _filter == 'all' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text("उत्तीर्ण ($totalPassed)"),
                  selected: _filter == 'passed',
                  selectedColor: Colors.green.shade700,
                  labelStyle: TextStyle(
                    color: _filter == 'passed' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _filter = 'passed'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text("सुधार आवश्यक (${totalTaken - totalPassed})"),
                  selected: _filter == 'failed',
                  selectedColor: Colors.red.shade700,
                  labelStyle: TextStyle(
                    color: _filter == 'failed' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _filter = 'failed'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Attempts List
            if (filteredAttempts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 14),
                    const Text("कुनै परीक्षा रेकर्ड फेला परेन",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      "तपाईंले अहिलेसम्म परीक्षा दिनुभएको छैन। ड्यासबोर्डमा गएर कुनै पनि सेटबाट परीक्षा सुरु गर्नुहोस्!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAttempts.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final attempt = filteredAttempts[index];
                  final mockSet = QuestionBankService.instance.getMockSetById(attempt.setId);

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: attempt.isPassed ? Colors.green.shade200 : Colors.red.shade200,
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Set and Status Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    attempt.setId.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    mockSet.sector,
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: attempt.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: attempt.isPassed ? Colors.green : Colors.red),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    attempt.isPassed ? Icons.check_circle : Icons.cancel,
                                    size: 14,
                                    color: attempt.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    attempt.isPassed ? "합격 (Pass)" : "불합격 (Fail)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: attempt.isPassed ? Colors.green.shade900 : Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          attempt.setTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "परीक्षा मिति: ${attempt.completedAt.year}/${attempt.completedAt.month.toString().padLeft(2, '0')}/${attempt.completedAt.day.toString().padLeft(2, '0')} ${attempt.completedAt.hour.toString().padLeft(2, '0')}:${attempt.completedAt.minute.toString().padLeft(2, '0')}  •  समय: ${attempt.timeSpentSeconds ~/ 60} मिनेट",
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),

                        const Divider(height: 22),

                        // Scores breakdown
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text("읽기 (Reading)", style: TextStyle(fontSize: 11, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text("${attempt.readingScore.toStringAsFixed(1)} / ५०",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text("듣기 (Listening)", style: TextStyle(fontSize: 11, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text("${attempt.listeningScore.toStringAsFixed(1)} / ५०",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: attempt.isPassed ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text("कुल प्राप्ताङ्क", style: TextStyle(fontSize: 11, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${attempt.score.toStringAsFixed(1)} / १००",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: attempt.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action buttons (Review Mistakes vs Retake)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExamReviewScreen(
                                        questions: mockSet.questions,
                                        userAnswers: attempt.userAnswers,
                                        setId: attempt.setId,
                                        setTitle: attempt.setTitle,
                                        customAnswerKeys: mockSet.answerKeys,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.fact_check, size: 16),
                                label: const Text("🔍 कमजोरी समीक्षा (Review Mistakes)",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UbtExamScreen(
                                      student: widget.student,
                                      mockSet: mockSet,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text("पुनः परीक्षा (Retake)"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
