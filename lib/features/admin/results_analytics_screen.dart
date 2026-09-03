import 'package:flutter/material.dart';
import '../../core/services/exam_service.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/csv_export_service.dart';

class ResultsAnalyticsScreen extends StatefulWidget {
  const ResultsAnalyticsScreen({super.key});

  @override
  State<ResultsAnalyticsScreen> createState() => _ResultsAnalyticsScreenState();
}

class _ResultsAnalyticsScreenState extends State<ResultsAnalyticsScreen> {
  void _openExportDialog(List<ExamAttemptRecord> records) {
    final csvData = CsvExportService.instance.generateExamResultsCsv(records);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Color(0xFF15803D), size: 26),
            SizedBox(width: 10),
            Text('Excel / CSV नतिजा डाउनलोड', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'कुल ${records.length} जना विद्यार्थीका परीक्षा नतिजा निर्यातका लागि तयार छन्।',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('स्तम्भहरू (Columns in Excel):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              const Text('क्र.सं. • नाम • दर्ता नं • ब्याच • क्षेत्र • परीक्षा सेट • रिडिङ अङ्क • लिसनिङ अङ्क • कुल प्राप्ताङ्क • नतिजा (PASS/FAIL) • समय • मिति', style: TextStyle(fontSize: 11, color: Colors.black87)),
              const SizedBox(height: 14),
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: SingleChildScrollView(
                  child: Text(csvData, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बन्द गर्नुहोस्')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
            onPressed: () async {
              await CsvExportService.instance.copyToClipboard(csvData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ CSV डाटा क्लिपबोर्डमा कपी भयो! Excel वा Google Sheets मा Ctrl+V गरी पेस्ट गर्न सक्नुहुन्छ।'), backgroundColor: Colors.green),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('📋 क्लिपबोर्डमा कपी गर्नुहोस्'),
          ),
        ],
      ),
    );
  }

  String _selectedSetFilter = 'all';
  String _selectedStatusFilter = 'all';
  String _selectedBatchFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showScorecardModal(ExamAttemptRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified, color: Color(0xFF1E3A8A), size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "आधिकारिक स्कोरकार्ड (Scorecard)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const Divider(height: 24),

              // Student Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF1E3A8A),
                      child: Text(
                        record.studentName.isNotEmpty ? record.studentName[0] : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("दर्ता नम्बर (Reg No): ${record.registrationNo}  •  ID: ${record.studentId}",
                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: record.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: record.isPassed ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        record.isPassed ? "합격 (Pass)" : "불합격 (Fail)",
                        style: TextStyle(
                          color: record.isPassed ? Colors.green.shade900 : Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Exam Set info
              Text("परीक्षा सेट: ${record.setTitle}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                "सबमिट समय: ${record.completedAt.year}/${record.completedAt.month.toString().padLeft(2, '0')}/${record.completedAt.day.toString().padLeft(2, '0')} ${record.completedAt.hour.toString().padLeft(2, '0')}:${record.completedAt.minute.toString().padLeft(2, '0')} (${record.timeSpentSeconds ~/ 60} मिनेट)",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),

              const SizedBox(height: 18),

              // Scores breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildScoreRow("읽기 (Reading) अङ्क", "${record.readingScore.toStringAsFixed(1)} / ५०.०", Colors.blue),
                    const Divider(height: 16),
                    _buildScoreRow("듣기 (Listening) अङ्क", "${record.listeningScore.toStringAsFixed(1)} / ५०.०", Colors.orange),
                    const Divider(height: 16),
                    _buildScoreRow("कुल प्राप्ताङ्क (Total Marks)", "${record.score.toStringAsFixed(1)} / १००.०",
                        record.isPassed ? Colors.green : Colors.red, isBold: true),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("उत्तीर्णाङ्क मापदण्ड (Pass Standard)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("५०.० अङ्क (५०%)", style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("📄 स्कोरकार्ड प्रिन्टरमा पठाइयो (Sent to Printer).")),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text("प्रिन्ट रिपोर्ट"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("बन्द गर्नुहोस् (Close)"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 14 : 13)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 16 : 14, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAttempts = ExamHistoryService.instance.getAllAttempts();
    final allMockSets = QuestionBankService.instance.getAllMockSets();

    // Filter logic including Batch
    final filteredAttempts = allAttempts.where((attempt) {
      final matchesSet = _selectedSetFilter == 'all' || attempt.setId == _selectedSetFilter;
      final matchesStatus = _selectedStatusFilter == 'all' ||
          (_selectedStatusFilter == 'pass' && attempt.isPassed) ||
          (_selectedStatusFilter == 'fail' && !attempt.isPassed);
      final student = AuthService.instance.getStudentById(attempt.studentId);
      final studentBatch = student?.batch ?? '2026 Batch A (बिहानी सत्र)';
      final matchesBatch = _selectedBatchFilter == 'all' || studentBatch == _selectedBatchFilter;
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          attempt.studentName.toLowerCase().contains(query) ||
          attempt.registrationNo.toLowerCase().contains(query) ||
          attempt.studentId.toLowerCase().contains(query);
      return matchesSet && matchesStatus && matchesBatch && matchesQuery;
    }).toList();

    // Analytics calculations
    final totalAttempts = allAttempts.length;
    final totalPassed = allAttempts.where((a) => a.isPassed).length;
    final passRate = totalAttempts > 0 ? (totalPassed / totalAttempts * 100) : 0.0;
    final avgScore = totalAttempts > 0
        ? allAttempts.map((a) => a.score).reduce((a, b) => a + b) / totalAttempts
        : 0.0;
    final highestScore = totalAttempts > 0
        ? allAttempts.map((a) => a.score).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(22),
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
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.analytics, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "विद्यार्थी परीक्षा नतिजा तथा एनालिटिक्स (Results & Analytics)",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "सबै विद्यार्थीहरूले दिएका UBT परीक्षाहरूको वास्तविक नतिजा, स्कोरकार्ड र समग्र प्रगति विवरण।",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("रिफ्रेस (Refresh)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4 KPI Summary Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildKpiCard(
                "कुल परीक्षार्थी (Total Submissions)",
                "$totalAttempts पटक",
                "प्रणालीमा रेकर्ड भएका परीक्षाहरू",
                Icons.how_to_reg,
                Colors.blue,
              ),
              _buildKpiCard(
                "उत्तीर्ण दर (Pass Rate %)",
                "${passRate.toStringAsFixed(1)}%",
                "$totalPassed जना विद्यार्थी सफल",
                Icons.emoji_events,
                Colors.green,
              ),
              _buildKpiCard(
                "औसत प्राप्ताङ्क (Average Score)",
                "${avgScore.toStringAsFixed(1)} / १००",
                "सबै परीक्षार्थीको औसत अङ्क",
                Icons.trending_up,
                Colors.purple,
              ),
              _buildKpiCard(
                "उच्चतम अङ्क (Highest Score)",
                "${highestScore.toStringAsFixed(1)} / १००",
                "हालसम्मको सर्वाधिक प्राप्ताङ्क",
                Icons.military_tech,
                Colors.amber.shade800,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Set Performance Breakdown Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text(
                        "सेट अनुसारको परीक्षा सहभागिता र उत्तीर्ण अवस्था (Set Breakdown)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: allMockSets.map((set) {
                      final setAttempts = allAttempts.where((a) => a.setId == set.id).toList();
                      final setPassed = setAttempts.where((a) => a.isPassed).length;
                      final setAvg = setAttempts.isNotEmpty
                          ? setAttempts.map((a) => a.score).reduce((a, b) => a + b) / setAttempts.length
                          : 0.0;
                      return Container(
                        width: 260,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(set.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(set.sector, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("सहभागी: ${setAttempts.length} जना", style: const TextStyle(fontSize: 12)),
                                Text("उत्तीर्ण: $setPassed जना",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("औसत अङ्क:", style: TextStyle(fontSize: 12)),
                                Text("${setAvg.toStringAsFixed(1)} / १००",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Filters and Search Bar
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Batch Filter Dropdown
                  DropdownButton<String>(
                    value: _selectedBatchFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text("सबै ब्याचहरू (All Batches)")),
                      DropdownMenuItem(value: '2026 Batch A (बिहानी सत्र)', child: Text("2026 Batch A (बिहानी)")),
                      DropdownMenuItem(value: '2026 Batch B (दिवा सत्र)', child: Text("2026 Batch B (दिवा)")),
                      DropdownMenuItem(value: '2026 Batch C (साँझ सत्र)', child: Text("2026 Batch C (साँझ)")),
                      DropdownMenuItem(value: 'विशेष UBT बुटक्याम्प', child: Text("विशेष UBT बुटक्याम्प")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBatchFilter = val);
                    },
                  ),

                  // Set Filter Dropdown
                  DropdownButton<String>(
                    value: _selectedSetFilter,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text("सबै सेटहरू (All Sets)")),
                      ...allMockSets.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSetFilter = val);
                    },
                  ),

                  // Status Filter Dropdown
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text("सबै नतिजा (All Status)")),
                      DropdownMenuItem(value: 'pass', child: Text("उत्तीर्ण मात्र (Pass >= 50)")),
                      DropdownMenuItem(value: 'fail', child: Text("अनुत्तीर्ण मात्र (Fail < 50)")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),

                  // Search Field
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "विद्यार्थीको नाम वा दर्ता नं...",
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Export Excel / CSV Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: filteredAttempts.isEmpty ? null : () => _openExportDialog(filteredAttempts),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: Text("Excel / CSV डाउनलोड (${filteredAttempts.length})"),
                  ),

                  // Reset Filters
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedSetFilter = 'all';
                        _selectedStatusFilter = 'all';
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text("फिल्टर रिसेट"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submissions Table / Cards Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "विद्यार्थी परीक्षा विवरण तालिका (${filteredAttempts.length} वटा रेकर्ड):",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Results List
          if (filteredAttempts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text("कुनै नतिजा फेला परेन (No results found)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text("फिल्टर परिवर्तन गर्नुहोस् वा विद्यार्थीहरूले परीक्षा दिएपछि यहाँ देखा पर्नेछ।", style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAttempts.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final a = filteredAttempts[index];

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: a.isPassed ? Colors.green.shade100 : Colors.red.shade100,
                        child: Text(
                          a.studentName.isNotEmpty ? a.studentName[0] : 'S',
                          style: TextStyle(
                            color: a.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Student info & Set
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text("दर्ता नं: ${a.registrationNo}  •  ID: ${a.studentId}",
                                style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.setTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Score Breakdown
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${a.score.toStringAsFixed(1)} / १००.०",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: a.isPassed ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "읽기 ${a.readingScore.toStringAsFixed(1)}  •  듣기 ${a.listeningScore.toStringAsFixed(1)}",
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Date & Duration
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${a.completedAt.year}/${a.completedAt.month.toString().padLeft(2, '0')}/${a.completedAt.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${a.completedAt.hour.toString().padLeft(2, '0')}:${a.completedAt.minute.toString().padLeft(2, '0')} (${a.timeSpentSeconds ~/ 60} मिनेट)",
                              style: const TextStyle(color: Colors.black54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: a.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: a.isPassed ? Colors.green : Colors.red),
                        ),
                        child: Text(
                          a.isPassed ? "합격 (Pass)" : "불합격 (Fail)",
                          style: TextStyle(
                            color: a.isPassed ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // View Scorecard Action Button
                      OutlinedButton.icon(
                        onPressed: () => _showScorecardModal(a),
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text("स्कोरकार्ड"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String mainValue, String sub, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 6),
          Text(mainValue, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
