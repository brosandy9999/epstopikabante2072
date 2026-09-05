import '../../core/services/platform_detector.dart';
import '../security/android_web_gatekeeper_screen.dart';
import 'package:flutter/material.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/exam_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/cloud_sync_service.dart';
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
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // स्क्रिन खुल्नासाथ ब्याकग्राउन्डमा स्वतः क्लाउडबाट नयाँ प्रश्नहरू सिङ्क गर्ने (Silent Auto-Sync)
    _autoSyncQuestions();
  }

  Future<void> _autoSyncQuestions({bool showSnackbar = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final success = await CloudSyncService.instance.pullFromCloud();
    if (mounted) {
      setState(() => _isSyncing = false);
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? LanguageService.instance.trText(
                    ne: '✅ क्लाउडबाट नयाँ प्रश्न सेटहरू सफलतापूर्वक सिङ्क भए!',
                    en: '✅ Successfully synced new mock tests from cloud!',
                    ko: '✅ 클라우드에서 새 모의고사 세트를 동기화했습니다!',
                  )
                : LanguageService.instance.trText(
                    ne: '⚠️ नयाँ प्रश्न सिङ्क हुन सकेन। इन्टरनेट जाँच गर्नुहोस्।',
                    en: '⚠️ Could not sync new questions. Please check internet connection.',
                    ko: '⚠️ 모의고사 세트를 동기화할 수 없습니다. 인터넷을 확인하세요.',
                  )),
            backgroundColor: success ? Colors.teal : Colors.orange.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([QuestionBankService.instance, LanguageService.instance]),
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Student side: isApproved भएका sets मात्र देखाउने
    final allSets = QuestionBankService.instance
        .getAllMockSets()
        .where((s) => s.isApproved)
        .toList();
    final completedCount = ExamHistoryService.instance.completedSetsCount;
    final lang = LanguageService.instance;

    final filteredSets = _selectedSector == 'all'
        ? allSets
        : allSets.where((s) => s.sector.contains(_selectedSector)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.trText(
                ne: "EPS-TOPIK मोडल टेस्ट पोर्टल (Mock Tests)",
                en: "EPS-TOPIK Mock Test Portal",
                ko: "EPS-TOPIK 실전 모의고사 포털",
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              lang.trText(
                ne: "५० मिनेट • ४० प्रश्न • १०० पूर्णाङ्क (उत्तीर्णाङ्क ५०)",
                en: "50 Mins • 40 Questions • 100 Marks (Pass: 50)",
                ko: "50분 • 40문항 • 100점 만점 (합격선 50점)",
              ),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
      body: RefreshIndicator(
        onRefresh: () => CloudSyncService.instance.syncNow(context: context),
        child: LayoutBuilder(
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
                            Text(
                              lang.trText(
                                ne: "आधिकारिक मोडल परीक्षा सेटहरू छान्नुहोस्",
                                en: "Select Official Mock Test Sets",
                                ko: "실전 모의고사 세트 선택",
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.trText(
                                ne: "कुल ${allSets.length} वटा आधिकारिक सेटहरू उपलब्ध छन्। तपाईंले $completedCount वटा पूरा गर्नुभयो।",
                                en: "Total ${allSets.length} official sets available. You have completed $completedCount.",
                                ko: "총 ${allSets.length}개 공식 모의고사 제공. 응시 완료: $completedCount개.",
                              ),
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
                      _buildSectorChip(lang.trText(ne: "सबै (${allSets.length})", en: "All (${allSets.length})", ko: "전체 (${allSets.length})"), 'all'),
                      const SizedBox(width: 8),
                      _buildSectorChip(lang.trText(ne: "उत्पादन (Manufacturing)", en: "Manufacturing", ko: "제조업"), '제조업'),
                      const SizedBox(width: 8),
                      _buildSectorChip(lang.trText(ne: "कृषि (Agriculture)", en: "Agriculture", ko: "농축산"), '농축산'),
                      const SizedBox(width: 8),
                      _buildSectorChip(lang.trText(ne: "निर्माण (Construction)", en: "Construction", ko: "건설"), '건설'),
                      const SizedBox(width: 8),
                      _buildSectorChip(lang.trText(ne: "सिमुलेसन (Simulation)", en: "Simulation", ko: "실전"), '실전'),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.trText(ne: '🎲 अनन्त र्‍यान्डम परीक्षा', en: '🎲 Infinite Random Exam', ko: '🎲 무작위 실전 모의고사'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang.trText(
                                ne: 'हरेक पटक नयाँ-नयाँ ४० प्रश्नहरू स्वतः छानिने असीमित परीक्षा',
                                en: 'Unlimited 40-question randomized blueprint exam generated on the fly',
                                ko: '매번 새로운 40문항이 무작위로 출제되는 무제한 실전 시험',
                              ),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final randomSet = QuestionBankService.instance.generateRandomBlueprintExam();
                          if (isAndroidWeb) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AndroidWebGatekeeperScreen()));
                            return;
                          }
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
                        label: Text(
                          lang.trText(ne: 'परीक्षा सुरु', en: 'Start Exam', ko: '시험 시작'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
    final lang = LanguageService.instance;

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
                        "${lang.trText(ne: 'उत्कृष्ट:', en: 'Best:', ko: '최고:')} ${bestAttempt.score.toStringAsFixed(1)} / 100",
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
                    lang.trText(ne: "नयाँ (नदिएको)", en: "New (Not Attempted)", ko: "미응시 (신규)"),
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
                _buildInfoItem(Icons.help_outline, lang.trText(ne: "४० प्रश्नहरू", en: "40 Questions", ko: "40문항")),
                _buildInfoItem(Icons.timer_outlined, lang.trText(ne: "५० मिनेट", en: "50 Mins", ko: "50분")),
                _buildInfoItem(Icons.military_tech_outlined, lang.trText(ne: "१०० पूर्णाङ्क", en: "100 Marks", ko: "100점 만점")),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Single Action Button: Start Exam (मोड सेटिङबाट स्वतः निर्धारित हुन्छ)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final isStrict = lang.modePreference == ExamModePreference.strictExam;
                if (isAndroidWeb) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AndroidWebGatekeeperScreen()));
                  return;
                }
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
                lang.modePreference == ExamModePreference.strictExam
                    ? lang.trText(ne: "परीक्षा सुरु गर्नुहोस्", en: "Start Official Exam", ko: "실전 시험 시작")
                    : lang.trText(ne: "अभ्यास सुरु गर्नुहोस्", en: "Start Practice", ko: "연습 시작하기"),
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
