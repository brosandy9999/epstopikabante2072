import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/exam_service.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/language_service.dart';
import '../question_engine/question_template.dart';

/// Official HRD Korea Style EPS-TOPIK Scorecard & Certificate Screen
/// Allows students and teachers to view, print, and save high-fidelity scorecards.
class OfficialScorecardScreen extends StatelessWidget {
  final AppUser? student;
  final String setTitle;
  final List<QuestionTemplate> questions;
  final Map<int, int> userAnswers;
  final double score;
  final double readingScore;
  final double listeningScore;
  final bool isPassed;
  final DateTime date;
  final int timeSpentSeconds;

  const OfficialScorecardScreen({
    super.key,
    this.student,
    required this.setTitle,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.readingScore,
    required this.listeningScore,
    required this.isPassed,
    required this.date,
    required this.timeSpentSeconds,
  });

  factory OfficialScorecardScreen.fromAttempt(ExamAttemptRecord record, List<QuestionTemplate> questions) {
    return OfficialScorecardScreen(
      student: AppUser(
        id: record.studentId,
        name: record.studentName,
        username: record.studentId,
        registrationNo: record.registrationNo,
        password: 'student_password',
        role: UserRole.student,
      ),
      setTitle: record.setTitle,
      questions: questions,
      userAnswers: record.userAnswers,
      score: record.score,
      readingScore: record.readingScore,
      listeningScore: record.listeningScore,
      isPassed: record.isPassed,
      date: record.completedAt,
      timeSpentSeconds: record.timeSpentSeconds,
    );
  }

  void _triggerPrint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.print, color: Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 10),
            Text(LanguageService.instance.trText(
              ne: '🖨️ आधिकारिक स्कोरकार्ड प्रिन्ट',
              en: '🖨️ Print Official Scorecard',
              ko: '🖨️ 공식 시험 성적표 인쇄',
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageService.instance.trText(
                ne: 'कम्प्युटर वा ब्राउजरमा [ Ctrl + P ] थिचेर A4 साइजमा सिधै PDF सेभ गर्न वा प्रिन्टरबाट छाप्न सकिन्छ।',
                en: 'Press [ Ctrl + P ] in your browser to print or save directly as an A4 PDF.',
                ko: '브라우저에서 [ Ctrl + P ]를 눌러 A4 PDF로 저장하거나 바로 인쇄할 수 있습니다.',
              ),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              LanguageService.instance.trText(
                ne: '📌 सुझाव: Print Setting मा "Layout: Portrait" र "Margins: Minimum" राख्नुहोला।',
                en: '📌 Tip: In print settings, select "Layout: Portrait" and "Margins: Minimum".',
                ko: '📌 안내: 인쇄 설정에서 "레이아웃: 세로", "여백: 최소"로 지정하십시오.',
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.instance.trText(ne: 'बुझें (OK)', en: 'OK', ko: '확인')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answerKeys = QuestionBankService.instance.getAnswerKeys();
    final name = student?.name ?? LanguageService.instance.trText(ne: 'विद्यार्थी', en: 'Student', ko: '수험자');
    final regNo = student?.registrationNo ?? '2026-0812-40';
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final mins = timeSpentSeconds ~/ 60;
    final secs = timeSpentSeconds % 60;

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFE2E8F0),
        appBar: AppBar(
          title: Text(
            LanguageService.instance.trText(
              ne: 'आधिकारिक स्कोरकार्ड',
              en: 'Official Scorecard',
              ko: '성적확인서 (공식 시험 성적표)',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          actions: [
                        const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _triggerPrint(context),
              icon: const Icon(Icons.print, size: 18),
              label: Text(LanguageService.instance.trText(
                ne: '🖨️ प्रिन्ट',
                en: '🖨️ Print',
                ko: '🖨️ 인쇄',
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 4)),
              ],
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. OFFICIAL TOP HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '고용허가제 한국어능력시험',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 1.5),
                        ),
                        const Text(
                          '성 적 확 인 서',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'EPS-TOPIK Score Report / Certificate of Result',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                    // HRD Korea Logo simulation
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          const Text('한국산업인력공단', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                          Text('HRD Korea', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(thickness: 2, color: Color(0xFF0F172A)),
                const SizedBox(height: 16),

                // 2. CANDIDATE PROFILE & PASS/FAIL SEAL ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Photo Avatar
                    Container(
                      width: 100,
                      height: 125,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 50, color: Colors.grey.shade500),
                          const SizedBox(height: 4),
                          Text('수험자 사진', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          Text('Candidate', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Candidate Identity Details Table
                    Expanded(
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.8),
                        },
                        children: [
                          _buildTableRow('수험번호 (Reg No)', regNo, '좌석번호 (Seat)', '12번'),
                          _buildTableRow('성명 (Name)', name, '국적 (Nationality)', 'NEPAL (네팔)'),
                          _buildTableRow('응시업종 (Sector)', '제조업 (Manufacturing)', '시험일자 (Date)', dateStr),
                          _buildTableRow('소요시간 (Time)', '$mins분 $secs초', '시험회차 (Exam)', setTitle),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Official Stamp (합격 / 불합격)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                          width: 3.5,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isPassed ? '합 격' : '불 합 격',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPassed ? 'PASSED' : 'FAILED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              '검인 (VERIFIED)',
                              style: TextStyle(
                                fontSize: 8,
                                color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. SCORE TABLE (성적 상세내역)
                const Text(
                  '1. 성적 상세내역 (Examination Scores Breakdown)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade400, width: 1.2),
                  columnWidths: const {
                    0: FlexColumnWidth(1.8),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.8),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('영역 (Section)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('문항수 (Items)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('배점 (Full Marks)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('취득점수 (Score)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('판정 (Status)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    _buildScoreRow('읽기 (Reading 01~20)', '20', '100점', '${(readingScore * 2).toInt()}점', readingScore >= 25 ? '기준 충족' : '미달'),
                    _buildScoreRow('듣기 (Listening 21~40)', '20', '100점', '${(listeningScore * 2).toInt()}점', listeningScore >= 25 ? '기준 충족' : '미달'),
                    TableRow(
                      decoration: BoxDecoration(color: isPassed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2)),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('총점 (Total Score)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('40', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('200점', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            '${(score * 2).toInt()}점 / 200',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            isPassed ? '합격 (PASSED)' : '불합격 (FAILED)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. ITEM-BY-ITEM QUESTION MATRIX (40문항 답안 현황표)
                const Text(
                  '2. 문항별 답안 현황표 (Item Performance Table 01 - 40)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: List.generate(10, (col) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '${(col * 4 + 1).toString().padLeft(2, '0')}~${(col * 4 + 4).toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      )),
                    ),
                  ],
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 20,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: 40,
                  itemBuilder: (context, i) {
                    final isReading = i < 20;
                    final userChoice = userAnswers[i];
                    final q = i < questions.length ? questions[i] : null;
                    final keyInfo = q != null ? answerKeys[q.questionId] : null;
                    final isCorrect = userChoice != null && keyInfo != null && userChoice == keyInfo.correctIndex;

                    Color bg = Colors.grey.shade100;
                    Color textCol = Colors.black87;
                    if (userChoice != null) {
                      bg = isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                      textCol = isCorrect ? Colors.green.shade900 : Colors.red.shade900;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: isReading ? Colors.blue.shade200 : Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}\n${userChoice != null ? (isCorrect ? 'O' : 'X') : '-'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 5. OFFICIAL WATERMARK, FOOTER & BARCODE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Simulated Barcode
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 35,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '||| | |||| | ||||| || ||| | ||',
                            style: TextStyle(fontSize: 22, letterSpacing: 3, color: Colors.black87, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HRD-KOREA-EPS-TOPIK-VERIFY-2026',
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade600, letterSpacing: 1.2),
                        ),
                      ],
                    ),

                    // Verification statement & HRD Korea Official Issuer
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '위와 같이 고용허가제 한국어능력시험 성적을 증명합니다.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This is to certify the examinee’s test result as above.',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '한국산업인력공단 이사장 [직인생략]',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  TableRow _buildTableRow(String l1, String v1, String l2, String v2) {
    return TableRow(
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(l1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(v1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(l2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(v2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ],
    );
  }

  TableRow _buildScoreRow(String section, String items, String fullScore, String myScore, String status) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(section, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(items, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(fullScore, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(myScore, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: status.contains('충족') ? Colors.green.shade800 : Colors.red.shade800),
          ),
        ),
      ],
    );
  }
}
