import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/weakness_analysis_service.dart';
import 'targeted_practice_screen.dart';

/// Weakness Analysis Screen: Topic-wise diagnostic and launcher for targeted practice
class WeaknessAnalysisScreen extends StatefulWidget {
  final AppUser? student;

  const WeaknessAnalysisScreen({super.key, this.student});

  @override
  State<WeaknessAnalysisScreen> createState() => _WeaknessAnalysisScreenState();
}

class _WeaknessAnalysisScreenState extends State<WeaknessAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final sId = widget.student?.id ?? AuthService.instance.currentUser?.id ?? 'student_01';
    final service = WeaknessAnalysisService.instance;
    final diagnostics = service.analyzeStudent(sId);
    final allWeakQuestions = service.getWeakQuestions(sId);

    // Calculate total questions attempted and total mistakes
    int totalQ = 0;
    int totalMistakes = 0;
    for (final d in diagnostics) {
      totalQ += d.totalQuestions;
      totalMistakes += d.mistakes;
    }
    final overallAccuracy = totalQ > 0 ? ((totalQ - totalMistakes) / totalQ) : 0.70;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'कमजोरी विश्लेषण तथा स्मार्ट अभ्यास',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP MASTERY SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'विद्यार्थी: ' + (widget.student?.name ?? 'राम बहादुर'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'AI स्वचालित परीक्षा कमजोरी विश्लेषण',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'समग्र सफलता: ' + (overallAccuracy * 100).toInt().toString() + '%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Mastery Linear Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallAccuracy,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overallAccuracy > 0.75 ? Colors.greenAccent : (overallAccuracy > 0.5 ? Colors.amberAccent : Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Launch Practice Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TargetedPracticeScreen(
                              title: 'सबै कमजोर प्रश्नहरूको स्मार्ट अभ्यास',
                              questions: allWeakQuestions,
                              studentId: sId,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.flash_on, color: Colors.black87),
                      label: Text(
                        'सबै कमजोर प्रश्नहरू अभ्यास गर्नुहोस् (' + allWeakQuestions.length.toString() + ' वटा)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // 2. TOPIC WISE DIAGNOSTICS SECTION
            const Text(
              'विषयगत दक्षता तथा कमजोरी विश्लेषण (Topic Diagnostics)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'विगतका सबै परीक्षामा भएको गल्तीको आधारमा तयार पारिएको रिपोर्ट:',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diagnostics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = diagnostics[index];
                return _buildDiagnosticCard(context, d, sId, service);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard(BuildContext context, TopicDiagnostic d, String sId, WeaknessAnalysisService service) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (d.proficiency) {
      case TopicProficiency.critical:
        badgeBg = Colors.red.shade100;
        badgeText = Colors.red.shade900;
        badgeLabel = '🔴 गम्भीर कमजोरी';
        break;
      case TopicProficiency.moderate:
        badgeBg = Colors.amber.shade100;
        badgeText = Colors.amber.shade900;
        badgeLabel = '🟡 मध्यम';
        break;
      case TopicProficiency.strong:
        badgeBg = Colors.green.shade100;
        badgeText = Colors.green.shade900;
        badgeLabel = '🟢 बलियो तयारी';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon, Title & Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(d.icon, color: d.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.titleNe, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(d.titleKo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar & Percentage
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.accuracy,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(d.color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  (d.accuracy * 100).toInt().toString() + '%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: d.color, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Advice Row
            Row(
              children: [
                const Icon(Icons.tips_and_updates, size: 15, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    d.adviceNe,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final weakQ = service.getWeakQuestions(sId, topicFilter: d.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TargetedPracticeScreen(
                          title: d.titleNe + ' अभ्यास',
                          questions: weakQ,
                          studentId: sId,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.play_circle_fill, size: 16),
                  label: const Text('अभ्यास गर्नुहोस्', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: d.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
