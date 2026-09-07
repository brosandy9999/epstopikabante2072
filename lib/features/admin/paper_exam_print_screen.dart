import 'package:flutter/material.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/language_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../question_engine/question_template.dart';

/// Official HRD Korea Style EPS-TOPIK Paper-Based Test (PBT) Booklet — 8 Pages
///
/// Page 1 : Institute Cover + Candidate Fill-Up Boxes
/// Page 2 : Reading  Q1  – Q6
/// Page 3 : Reading  Q7  – Q13
/// Page 4 : Reading  Q14 – Q20
/// Page 5 : Listening Q21 – Q28
/// Page 6 : Listening Q29 – Q36
/// Page 7 : Listening Q37 – Q40 (last questions)
/// Page 7 : Listening Q37 – Q40 (last questions)
class PaperExamPrintScreen extends StatefulWidget {
  final MockTestSet testSet;
  const PaperExamPrintScreen({super.key, required this.testSet});

  @override
  State<PaperExamPrintScreen> createState() => _PaperExamPrintScreenState();
}

class _PaperExamPrintScreenState extends State<PaperExamPrintScreen> {
  double _zoomLevel = 1.0;
  final ScrollController _scrollController = ScrollController();

  static const int _totalPages = 7;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPrintGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print, color: Color(0xFF1E3A8A), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('🖨️ PDF / Print — ८ पृष्ठ बुकलेट',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Text(
                '• ब्राउजरमा  [ Ctrl + P ]  थिच्नुहोस्\n'
                '• Paper Size: Letter वा A4\n'
                '• Layout: Portrait (ठाडो)\n'
                '• Margins: Minimum वा None\n'
                '• ☑ Background graphics सक्रिय राख्नुहोस्\n'
                '• कुल ७ पृष्ठ प्रिन्ट हुनेछन्',
                style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print),
            label: const Text('बुझें, प्रिन्ट गर्छु'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('💡 Ctrl + P थिचेर PDF Save As / Print गर्नुहोस्।'),
                backgroundColor: Color(0xFF1E3A8A),
                duration: Duration(seconds: 4),
              ));
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final qs = widget.testSet.questions;
    final reading = qs.take(20).toList();
    final listening = qs.skip(20).take(20).toList();

    // Question slices for each page
    final rQ1_6   = reading.sublist(0,  reading.length >= 6  ? 6  : reading.length);
    final rQ7_13  = reading.sublist(reading.length >= 6  ? 6  : reading.length, reading.length >= 13 ? 13 : reading.length);
    final rQ14_20 = reading.sublist(reading.length >= 13 ? 13 : reading.length, reading.length >= 20 ? 20 : reading.length);
    final lQ21_28 = listening.sublist(0,  listening.length >= 8  ? 8  : listening.length);
    final lQ29_36 = listening.sublist(listening.length >= 8  ? 8  : listening.length, listening.length >= 16 ? 16 : listening.length);
    final lQ37_40 = listening.sublist(listening.length >= 16 ? 16 : listening.length, listening.length >= 20 ? 20 : listening.length);

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 3,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.testSet.title}  —  PBT Paper Exam (७ पृष्ठ)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              'Page 1: Cover  •  Pages 2–6: Questions  •  Page 7: Last Questions',
              style: TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Zoom
          IconButton(icon: const Icon(Icons.zoom_out), tooltip: 'Zoom Out',
              onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 1.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: Text('${(_zoomLevel * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          IconButton(icon: const Icon(Icons.zoom_in), tooltip: 'Zoom In',
              onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 1.4))),
          const SizedBox(width: 6),
          // Print button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 3,
              ),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('🖨️ PDF / Print  (Ctrl+P)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _showPrintGuide,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Transform.scale(
            scale: _zoomLevel,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                // ─── PAGE 1: INSTITUTE COVER + CANDIDATE FILL-UP ─────────────
                _page(1, _buildPage1Cover()),
                _gap,

                // ─── PAGE 2: READING Q1 – Q6 ─────────────────────────────────
                _page(2, _buildQPage(
                  sectionLabel: '읽기 (Reading)',
                  isFirstPage: true,
                  sectionTitle: '읽기 영역 (Reading Test) : 1번 ~ 20번 / 50점',
                  sectionInstruction: 'Q1 देखि Q20 सम्म — पढेर सही उत्तर छान्नुहोस् ①②③④',
                  questions: rQ1_6,
                  startNumber: 1,
                )),
                _gap,

                // ─── PAGE 3: READING Q7 – Q13 ────────────────────────────────
                _page(3, _buildQPage(
                  sectionLabel: '읽기 (Reading)',
                  questions: rQ7_13,
                  startNumber: 7,
                )),
                _gap,

                // ─── PAGE 4: READING Q14 – Q20 ───────────────────────────────
                _page(4, _buildQPage(
                  sectionLabel: '읽기 (Reading)',
                  questions: rQ14_20,
                  startNumber: 14,
                )),
                _gap,

                // ─── PAGE 5: LISTENING Q21 – Q28 ─────────────────────────────
                _page(5, _buildQPage(
                  sectionLabel: '듣기 (Listening)',
                  isFirstPage: true,
                  sectionTitle: '듣기 영역 (Listening Test) : 21번 ~ 40번 / 50점',
                  sectionInstruction: 'Q21 देखि Q40 सम्म — सुनेर सही उत्तर छान्नुहोस् ①②③④',
                  questions: lQ21_28,
                  startNumber: 21,
                )),
                _gap,

                // ─── PAGE 6: LISTENING Q29 – Q36 ─────────────────────────────
                _page(6, _buildQPage(
                  sectionLabel: '듣기 (Listening)',
                  questions: lQ29_36,
                  startNumber: 29,
                )),
                _gap,

                // ─── PAGE 7: LISTENING Q37 – Q40 (last questions) ────────────
                _page(7, _buildQPage(
                  sectionLabel: '듣기 (Listening)  —  अन्तिम प्रश्नहरू (Last Questions)',
                  questions: lQ37_40,
                  startNumber: 37,
                  isLastQuestionPage: true,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE WRAPPER
  // ─────────────────────────────────────────────────────────────────────────
  static const Widget _gap = SizedBox(height: 32);

  Widget _page(int pageNum, Widget content) {
    return Container(
      width: 840,
      constraints: const BoxConstraints(minHeight: 1090),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(fit: FlexFit.loose, child: content),
          // ─── Footer ───
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '한국산업인력공단 (HRD Korea)  •  EPS-TOPIK',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$pageNum / $_totalPages',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Text(
                  widget.testSet.instituteName ?? 'Official Test Center',
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1 — INSTITUTE COVER + CANDIDATE FILL-UP BOXES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage1Cover() {
    final user = AuthService.instance.currentUser;
    final instituteName = widget.testSet.instituteName ?? user?.instituteName ?? 'INSTITUTE NAME';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── TOP DOUBLE-BORDER STRIPE ──────────────────────────────
        Container(height: 6, color: const Color(0xFF1E3A8A)),
        const SizedBox(height: 3),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 18),

        // ── HRD KOREA + INSTITUTE NAME ────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Korean govt logo placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 26),
                    Text('HRD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '고용허가제 한국어능력시험 (EPS-TOPIK)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 0.4),
                  ),
                  const Text(
                    'Employment Permit System — Test of Proficiency in Korean',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    instituteName.toUpperCase(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('PBT\n문제지', textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E3A8A))),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 12),

        // ── EXAM TITLE ────────────────────────────────────────────
        Center(
          child: Text(
            widget.testSet.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '읽기 20문항 + 듣기 20문항  |  시험시간: 50분  |  100점 만점  |  합격: 50점',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── CANDIDATE FILL-UP SECTION TITLE ──────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black87,
          child: const Text(
            '■  수험자 정보 기재란  (Candidate Information — Please Fill In)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.2),
          ),
        ),
        const SizedBox(height: 12),

        // ── ROW 1: Registration No + Candidate Name ───────────────
        Row(
          children: [
            Expanded(flex: 4, child: _fillBox('수험번호 (Registration No.)', 'e.g. NP-2025-000001')),
            const SizedBox(width: 14),
            Expanded(flex: 6, child: _fillBox('성명 / Name (नाम)', 'e.g. Ram Bahadur Thapa / 라암 바하두르 타파')),
          ],
        ),
        const SizedBox(height: 12),

        // ── ROW 2: Nationality + Date of Birth ────────────────────
        Row(
          children: [
            Expanded(flex: 3, child: _fillBox('국적 (Nationality)', 'Nepal / नेपाल')),
            const SizedBox(width: 14),
            Expanded(flex: 5, child: _fillBox('생년월일 (Date of Birth)', 'YYYY / MM / DD')),
          ],
        ),
        const SizedBox(height: 12),

        // ── ROW 3: Exam Room + Seat No + Date ─────────────────────
        Row(
          children: [
            Expanded(flex: 3, child: _fillBox('시험실 (Exam Room)', '____호실')),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: _fillBox('좌석번호 (Seat No.)', '____번')),
            const SizedBox(width: 10),
            Expanded(flex: 4, child: _fillBox('시험일 (Exam Date)', '____ 년  ____ 월  ____ 일')),
          ],
        ),
        const SizedBox(height: 12),

        // ── ROW 4: Signature ──────────────────────────────────────
        Row(
          children: [
            Expanded(flex: 5, child: _fillBox('서명 (Candidate Signature / परिक्षार्थीको हस्ताक्षर)', '______________________________')),
            const SizedBox(width: 14),
            Expanded(flex: 5, child: _fillBox('감독관 서명 (Invigilator Signature / निरिक्षकको हस्ताक्षर)', '______________________________')),
          ],
        ),

        const SizedBox(height: 28),

        // ── EXAM RULES / INSTRUCTIONS ─────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1E3A8A),
          child: const Text(
            '■  수험자 유의사항  (Exam Rules / परीक्षा नियमहरू)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _RuleRow('1', '시험 시작 전까지 문제지를 열어보지 마십시오. / परीक्षा सुरु नभएसम्म प्रश्नपत्र नखोल्नुहोस्।'),
              SizedBox(height: 5),
              _RuleRow('2', '답안은 컴퓨터용 사인펜(흑색/청색)으로 작성하십시오. / उत्तर OMR पानामा सक्कली कलमले भर्नुहोस्।'),
              SizedBox(height: 5),
              _RuleRow('3', '총 40문항 (읽기 20문항 + 듣기 20문항), 시험시간 50분 / कुल ४० प्रश्न, ५० मिनेट।'),
              SizedBox(height: 5),
              _RuleRow('4', '부정행위 적발 시 즉시 퇴실 조치됩니다. / नक्कल गरेमा तत्काल निष्काशन गरिनेछ।'),
              SizedBox(height: 5),
              _RuleRow('5', '듣기 문제는 음성 방송 후 바로 풀어야 합니다. / लिसनिङ प्रश्न अडियो सकिनासाथ हल गर्नुहोस्।'),
              SizedBox(height: 5),
              _RuleRow('6', '시험 종료 후 문제지와 답안지를 모두 제출하십시오. / परीक्षा सकिएपछि प्रश्नपत्र र OMR दुवै बुझाउनुहोस्।'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── SECTOR + SET INFO ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '분야 (Sector): ${widget.testSet.sector}   •   ${widget.testSet.description}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fillBox(String label, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 1.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            height: 28,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black54, width: 1)),
            ),
            child: Text(hint, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGES 2–7 — QUESTION PAGES (2-column layout)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQPage({
    required String sectionLabel,
    required List<QuestionTemplate> questions,
    required int startNumber,
    bool isFirstPage = false,
    String? sectionTitle,
    String? sectionInstruction,
    bool isLastQuestionPage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Running header
        _pageRunningHeader(sectionLabel),
        const SizedBox(height: 10),

        // Section banner (only on section-start pages)
        if (isFirstPage && sectionTitle != null) ...[
          _sectionBanner(sectionTitle, sectionInstruction ?? ''),
          const SizedBox(height: 14),
        ],

        // 2-column questions
        _twoColumnQuestions(questions, startNumber),

        if (isLastQuestionPage) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '★ 이상으로 문제가 끝났습니다.  答え終わり.  परीक्षाका सबै प्रश्नहरू यहाँ समाप्त हुन्छन्। ★',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pageRunningHeader(String sectionTitle) {
    return Container(
      padding: const EdgeInsets.only(bottom: 7),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black87, width: 1.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.testSet.title}  •  $sectionTitle',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const Text('EPS-TOPIK  PBT  지필 모의고사', style: TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _sectionBanner(String title, String instruction) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 2),
          Text(instruction, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _twoColumnQuestions(List<QuestionTemplate> qList, int startNumber) {
    if (qList.isEmpty) return const SizedBox.shrink();
    final half = (qList.length / 2).ceil();
    final left = qList.take(half).toList();
    final right = qList.skip(half).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: left.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _question(startNumber + e.key, e.value),
            )).toList(),
          ),
        ),
        Container(
          width: 1, margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Colors.grey.shade300,
          constraints: const BoxConstraints(minHeight: 300),
        ),
        Expanded(
          child: Column(
            children: right.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _question(startNumber + half + e.key, e.value),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _question(int no, QuestionTemplate q) {
    final imgUrl = (q is UniversalQuestion) ? q.questionImageUrl
        : (q is ReadingImageQuestion) ? q.imageAssetPath : null;
    final script = (q is UniversalQuestion) ? q.audioScript
        : (q is ListeningAudioQuestion) ? q.audioScript : null;

    List<String> textOpts = [];
    List<String?> imgOpts = [];
    if (q is UniversalQuestion) { textOpts = q.textOptions; imgOpts = q.imageOptions; }
    else if (q is ReadingTextQuestion)      { textOpts = q.textOptions; }
    else if (q is ReadingImageQuestion)     { textOpts = q.textOptions; }
    else if (q is ListeningAudioQuestion)   { textOpts = q.textOptions; }
    else if (q is ListeningImageOptionsQuestion) { imgOpts = q.imageOptionPaths; }

    const nums = ['①', '②', '③', '④'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number + text
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('[$no] ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
          Expanded(child: Text(q.questionText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.35))),
        ]),

        // Optional image
        if (imgUrl != null && imgUrl.isNotEmpty) ...[
          const SizedBox(height: 5),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 110, maxWidth: 240),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              child: SmartImageWidget(imageSource: imgUrl, fit: BoxFit.contain),
            ),
          ),
        ],

        // Audio script reference box
        if (script != null && script.isNotEmpty) ...[
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('[ 듣기 대본 / Audio Script ]',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 2),
              Text(script, style: const TextStyle(fontSize: 11, height: 1.3)),
            ]),
          ),
        ],

        const SizedBox(height: 6),

        // Image option grid (2×2)
        if (imgOpts.isNotEmpty && imgOpts.any((x) => x != null && x.isNotEmpty))
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 5, mainAxisSpacing: 5, childAspectRatio: 1.5),
            itemCount: 4,
            itemBuilder: (ctx, i) {
              final img = i < imgOpts.length ? imgOpts[i] : null;
              return Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(3)),
                child: Column(children: [
                  Text(nums[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  if (img != null && img.isNotEmpty)
                    Expanded(child: SmartImageWidget(imageSource: img, fit: BoxFit.contain)),
                ]),
              );
            },
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (i) {
              final txt = i < textOpts.length ? textOpts[i] : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${nums[i]}  ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Expanded(child: Text(txt, style: const TextStyle(fontSize: 11.5, height: 1.25))),
                ]),
              );
            }),
          ),
      ],
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _RuleRow extends StatelessWidget {
  final String number;
  final String text;
  const _RuleRow(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18, height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
          child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.35))),
      ],
    );
  }
}
