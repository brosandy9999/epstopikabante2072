import 'package:flutter/material.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/exam_service.dart';
import '../../core/services/language_service.dart';
import 'real_ubt_exam_hall_screen.dart';
import '../../main.dart';

class MockTestListScreen extends StatefulWidget {
  final String? initialFilter;

  const MockTestListScreen({super.key, this.initialFilter});

  @override
  State<MockTestListScreen> createState() => _MockTestListScreenState();
}

class _MockTestListScreenState extends State<MockTestListScreen> {
  String _selectedSector = 'all';

  @override
  Widget build(BuildContext context) {
    final allSets = QuestionBankService.instance.getAllMockSets();
    final completedCount = ExamHistoryService.instance.completedSetsCount;

    final filteredSets = _selectedSector == 'all'
        ? allSets
        : allSets.where((s) => s.sector.contains(_selectedSector)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EPS-TOPIK Mock Test Portal (모의고사)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "५० मिनेट • ४० प्रश्न • १०० पूर्णांक (पूर्णांक १००, उत्तीर्णांक ५०)",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 36.0 : 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Summary Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.assignment, size: 34, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "실전 모의고사 세트 선택 (Mock Test Sets)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "कुल ${allSets.length} वटा आधिकारिक सेटहरू उपलब्ध छन्। तपाईंले $completedCount वटा सेट पूरा गर्नुभएको छ।",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Sector Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSectorChip("전체 (सबै सेट)", 'all'),
                      const SizedBox(width: 8),
                      _buildSectorChip("제조업 (Manufacturing)", '제조업'),
                      const SizedBox(width: 8),
                      _buildSectorChip("농축산업 (Agriculture)", '농축산'),
                      const SizedBox(width: 8),
                      _buildSectorChip("건설/안전 (Construction)", '건설'),
                      const SizedBox(width: 8),
                      _buildSectorChip("실전 종합 (Simulation)", '실전'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Random Exam Banner Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF92400E), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.casino, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎲 अनन्त र्‍यान्डम परीक्षा (Random Blueprint Exam)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'हरेक पटक नयाँ-नयाँ ४० प्रश्नहरू स्वतः छानिने असीमित परीक्षा',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final randomSet = QuestionBankService.instance.generateRandomBlueprintExam();
                          final mode = LanguageService.instance.modePreference;
                          if (mode == ExamModePreference.strictExam) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RealUbtExamHallScreen(mockSet: randomSet)),
                            ).then((_) => setState(() {}));
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => StudyModeScreen(mockSet: randomSet)),
                            ).then((_) => setState(() {}));
                          }
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('स्टार्ट Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Mock Test Cards Grid
                if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: filteredSets.length,
                    itemBuilder: (context, index) {
                      return _buildSetCard(filteredSets[index]);
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredSets.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildSetCard(filteredSets[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectorChip(String label, String sectorKey) {
    final isSelected = _selectedSector == sectorKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) {
        setState(() {
          _selectedSector = sectorKey;
        });
      },
    );
  }

  Widget _buildSetCard(MockTestSet set) {
    final bestAttempt = ExamHistoryService.instance.getBestAttempt(set.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sector Badge and Best Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Text(
                  set.sector,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (bestAttempt != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bestAttempt.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bestAttempt.isPassed ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: bestAttempt.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "최고: ${bestAttempt.score.toStringAsFixed(1)} / 100",
                        style: TextStyle(
                          color: bestAttempt.isPassed ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "미응시 (नयाँ)",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            set.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            set.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),

          const Spacer(),

          // Details Row: Questions, Time, Marks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.help_outline, "४० प्रश्नहरू (२० R + २० L)"),
                _buildInfoItem(Icons.timer_outlined, "५० मिनेट"),
                _buildInfoItem(Icons.military_tech_outlined, "१०० पूर्णांक"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Single Action Button: Start Exam (मोड सेटिङबाट स्वतः निर्धारित हुन्छ)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final isStrict = LanguageService.instance.modePreference == ExamModePreference.strictExam;
                if (isStrict) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RealUbtExamHallScreen(mockSet: set),
                    ),
                  ).then((_) => setState(() {}));
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudyModeScreen(mockSet: set),
                    ),
                  ).then((_) => setState(() {}));
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                LanguageService.instance.modePreference == ExamModePreference.strictExam
                    ? "स्टार्ट Exam (Start Exam)"
                    : "स्टार्ट Exam (Study Mode)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      ],
    );
  }
}
