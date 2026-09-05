import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/weakness_analysis_service.dart';
import '../../core/services/language_service.dart';
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
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
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
            title: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang.trText(
                      ne: 'कमजोरी विश्लेषण तथा स्मार्ट अभ्यास',
                      en: 'Weakness Analysis & Smart Practice',
                      ko: '취약점 분석 및 맞춤 학습',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
            elevation: 1,
            actions: [
              const SizedBox(width: 8),
            ],
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
                                '${lang.trText(ne: "विद्यार्थी", en: "Student", ko: "수험생")}: ' + (widget.student?.name ?? 'विद्यार्थी'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang.trText(
                                  ne: 'AI स्वचालित परीक्षा कमजोरी विश्लेषण',
                                  en: 'AI Automatic Exam Weakness Diagnostic',
                                  ko: 'AI 기반 취약점 자동 진단 시스템',
                                ),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                              '${lang.trText(ne: "सफलता दर", en: "Accuracy", ko: "정확도")}: ' + (overallAccuracy * 100).toInt().toString() + '%',
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
                                  title: lang.trText(ne: 'सबै कमजोर प्रश्नहरूको स्मार्ट अभ्यास', en: 'All Weak Questions Smart Practice', ko: '전체 취약 문항 맞춤 학습'),
                                  questions: allWeakQuestions,
                                  studentId: sId,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          icon: const Icon(Icons.flash_on, color: Colors.black87),
                          label: Text(
                            lang.trText(
                              ne: 'सबै कमजोर प्रश्नहरू अभ्यास गर्नुहोस् (' + allWeakQuestions.length.toString() + ' वटा)',
                              en: 'Practice All Weak Questions (' + allWeakQuestions.length.toString() + ')',
                              ko: '전체 취약 문항 학습하기 (' + allWeakQuestions.length.toString() + '개)',
                            ),
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
                Text(
                  lang.trText(
                    ne: 'विषयगत दक्षता तथा कमजोरी विश्लेषण',
                    en: 'Topic-wise Proficiency & Diagnostic',
                    ko: '영역별 진단 및 취약점 분석',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.trText(
                    ne: 'विगतका सबै परीक्षामा भएको गल्तीको आधारमा तयार पारिएको रिपोर्ट:',
                    en: 'Report generated from historical exam attempt mistake patterns:',
                    ko: '역대 시험 오답 기록을 바탕으로 생성된 분석 리포트:',
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: diagnostics.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = diagnostics[index];
                    return _buildDiagnosticCard(context, d, sId, service, lang);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticCard(BuildContext context, TopicDiagnostic d, String sId, WeaknessAnalysisService service, LanguageService lang) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (d.proficiency) {
      case TopicProficiency.critical:
        badgeBg = Colors.red.shade100;
        badgeText = Colors.red.shade900;
        badgeLabel = lang.trText(ne: '🔴 गम्भीर कमजोरी', en: '🔴 Critical Weakness', ko: '🔴 취약 영역');
        break;
      case TopicProficiency.moderate:
        badgeBg = Colors.amber.shade100;
        badgeText = Colors.amber.shade900;
        badgeLabel = lang.trText(ne: '🟡 मध्यम तयारी', en: '🟡 Moderate', ko: '🟡 보통');
        break;
      case TopicProficiency.strong:
        badgeBg = Colors.green.shade100;
        badgeText = Colors.green.shade900;
        badgeLabel = lang.trText(ne: '🟢 बलियो तयारी', en: '🟢 Strong / Mastered', ko: '🟢 우수 영역');
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
                      Text(
                        lang.isEnglish ? d.titleKo : (lang.isKorean ? d.titleKo : d.titleNe),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
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
                          title: (lang.isEnglish ? d.titleKo : d.titleNe) + ' ' + lang.trText(ne: 'अभ्यास', en: 'Practice', ko: '학습'),
                          questions: weakQ,
                          studentId: sId,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.play_circle_fill, size: 16),
                  label: Text(
                    lang.trText(ne: 'अभ्यास गर्नुहोस्', en: 'Practice Now', ko: '맞춤 학습'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
