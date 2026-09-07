import 'package:flutter/material.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../question_engine/question_template.dart';
import 'paper_exam_html_builder.dart';
import 'paper_exam_print_helper.dart';

/// Official HRD Korea Style EPS-TOPIK Paper-Based Test (PBT) Booklet — 8 Pages
///
/// Page 1 : Institute Cover + Candidate Fill-Up Boxes
/// Pages 2–5 : Reading Section (Single column, HRD style, ~5 Qs/page)
/// Pages 6–8 : Listening Section (Single column, HRD style, ~6-7 Qs/page)
///              - Question title BOLD
///              - Passage/word/material in ROUNDED BORDER BOX
///              - Options ①②③④ listed below
///              - Listening script NOT displayed
class PaperExamPrintScreen extends StatefulWidget {
  final MockTestSet testSet;
  const PaperExamPrintScreen({super.key, required this.testSet});

  @override
  State<PaperExamPrintScreen> createState() => _PaperExamPrintScreenState();
}

class _PaperExamPrintScreenState extends State<PaperExamPrintScreen> {
  double _zoomLevel = 1.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerPrint() {
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    if (!isSuperAdmin && !widget.testSet.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 सुपर एडमिनको स्वीकृति बिना यो प्रश्नपत्र डाउनलोड गर्न मिल्दैन।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final htmlContent = PaperExamHtmlBuilder.buildExamHtml(widget.testSet);
    printExamHtml(htmlContent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ प्रिन्ट / PDF विन्डो खुल्दैछ... Destination मा "Save as PDF" छान्नुहोस्।'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _openInNewTab() {
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    if (!isSuperAdmin && !widget.testSet.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 सुपर एडमिनको स्वीकृति बिना यो प्रश्नपत्र खोल्न मिल्दैन।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final htmlContent = PaperExamHtmlBuilder.buildExamHtml(widget.testSet);
    openExamInNewTab(htmlContent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌐 नयाँ ट्याबमा ८ पृष्ठको PBT प्रश्नपत्र खुल्यो। त्यहाँ माथिको Print बटनबाट PDF save गर्न सक्नुहुन्छ।'),
        backgroundColor: Color(0xFF1E3A8A),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    final isAllowed = isSuperAdmin || widget.testSet.isApproved;

    if (!isAllowed) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: Text(widget.testSet.title),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300, width: 2),
                  ),
                  child: Icon(Icons.lock_outline, size: 52, color: Colors.amber.shade900),
                ),
                const SizedBox(height: 20),
                const Text(
                  'सुपर एडमिनको अनुमति आवश्यक',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Super Admin Permission Required',
                  style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    'यो PBT प्रश्नपत्र (८ पृष्ठ) प्रिन्ट वा PDF डाउनलोड गर्नका लागि पहिले सुपर एडमिन (Super Admin) को स्वीकृति (Approval) हुनुपर्छ।\n\nहाल यो सेट स्वीकृत भइसकेको छैन। कृपया सुपर एडमिनसँग सम्पर्क गरी यो सेट स्वीकृत गराउनुहोस्।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5, color: Colors.amber.shade900),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('फर्कनुहोस् (Go Back)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allQs = widget.testSet.questions; // up to 40 questions
    final reading  = allQs.take(20).toList();
    final listening = allQs.skip(20).take(20).toList();

    // Dynamic pagination: Distribute Reading across 4 Pages (Pages 2, 3, 4, 5)
    // and Listening across 3 Pages (Pages 6, 7, 8) by calculating content heights
    final readingPages = _partitionInto4Pages(reading, hasBanner: true);
    final listeningPages = _partitionInto3Pages(listening, hasBanner: true, hasEndBanner: true);

    final r1 = readingPages[0];
    final r2 = readingPages[1];
    final r3 = readingPages[2];
    final r4 = readingPages[3];

    final l1 = listeningPages[0];
    final l2 = listeningPages[1];
    final l3 = listeningPages[2];

    final int r1Start = 1;
    final int r2Start = r1Start + r1.length;
    final int r3Start = r2Start + r2.length;
    final int r4Start = r3Start + r3.length;

    final int l1Start = r4Start + r4.length;
    final int l2Start = l1Start + l1.length;
    final int l3Start = l2Start + l2.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 3,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.testSet.title}  —  PBT Paper Exam (८ पृष्ठ)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Text('Page 1: Cover  •  Pages 2–8: Questions (Single Column, HRD Style)',
                style: TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.zoom_out), tooltip: 'Zoom Out',
              onPressed: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 1.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(child: Text('${(_zoomLevel * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          IconButton(icon: const Icon(Icons.zoom_in), tooltip: 'Zoom In',
              onPressed: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 1.4))),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('🖨️ PDF डाउनलोड / Print',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              onPressed: _triggerPrint,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white60),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('🌐 नयाँ ट्याब',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              onPressed: _openInNewTab,
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
                // ── PAGE 1: INSTITUTE COVER ──────────────────────────────
                _page(1, _buildPage1Cover()),
                _gap,

                // ── PAGE 2: READING PART 1 ───────────────────────────────
                _page(2, _buildQPage(
                  questions: r1,
                  startNumber: r1Start,
                  isReadingStart: true,
                )),
                _gap,

                // ── PAGE 3: READING PART 2 ───────────────────────────────
                _page(3, _buildQPage(
                  questions: r2,
                  startNumber: r2Start,
                )),
                _gap,

                // ── PAGE 4: READING PART 3 ───────────────────────────────
                _page(4, _buildQPage(
                  questions: r3,
                  startNumber: r3Start,
                )),
                _gap,

                // ── PAGE 5: READING PART 4 ───────────────────────────────
                _page(5, _buildQPage(
                  questions: r4,
                  startNumber: r4Start,
                )),
                _gap,

                // ── PAGE 6: LISTENING PART 1 ─────────────────────────────
                _page(6, _buildQPage(
                  questions: l1,
                  startNumber: l1Start,
                  isListeningStart: true,
                )),
                _gap,

                // ── PAGE 7: LISTENING PART 2 ─────────────────────────────
                _page(7, _buildQPage(
                  questions: l2,
                  startNumber: l2Start,
                )),
                _gap,

                // ── PAGE 8: LISTENING PART 3 (last) ──────────────────────
                _page(8, _buildQPage(
                  questions: l3,
                  startNumber: l3Start,
                  isLastPage: true,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const Widget _gap = SizedBox(height: 32);

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // DYNAMIC PAGINATION ALGORITHM (4 Reading + 3 Listening = 7 question pages + 1 Cover = 8 total)
  // ─────────────────────────────────────────────────────────────────────────
  List<List<QuestionTemplate>> _partitionInto4Pages(List<QuestionTemplate> questions, {required bool hasBanner}) {
    if (questions.isEmpty) return [[], [], [], []];
    if (questions.length <= 4) {
      final res = <List<QuestionTemplate>>[];
      for (var q in questions) {
        res.add([q]);
      }
      while (res.length < 4) {
        res.add([]);
      }
      return res;
    }

    final n = questions.length;
    final heights = questions.map((q) => _estimateQuestionHeight(q)).toList();

    // A4 height budget (px)
    final double b1 = hasBanner ? 770.0 : 860.0;
    const double b2 = 860.0;
    const double b3 = 860.0;
    const double b4 = 860.0;

    int bestI = (n / 4).round().clamp(1, n - 3);
    int bestJ = (2 * n / 4).round().clamp(bestI + 1, n - 2);
    int bestK = (3 * n / 4).round().clamp(bestJ + 1, n - 1);
    double bestScore = double.infinity;

    for (int i = 1; i < n - 2; i++) {
      for (int j = i + 1; j < n - 1; j++) {
        for (int k = j + 1; k < n; k++) {
          double h1 = 0;
          for (int m = 0; m < i; m++) { h1 += heights[m]; }
          double h2 = 0;
          for (int m = i; m < j; m++) { h2 += heights[m]; }
          double h3 = 0;
          for (int m = j; m < k; m++) { h3 += heights[m]; }
          double h4 = 0;
          for (int m = k; m < n; m++) { h4 += heights[m]; }

          final r1 = h1 / b1;
          final r2 = h2 / b2;
          final r3 = h3 / b3;
          final r4 = h4 / b4;

          final maxRatio = [r1, r2, r3, r4].reduce((a, b) => a > b ? a : b);
          final variance = (r1 - r2).abs() + (r2 - r3).abs() + (r3 - r4).abs() +
                           (r1 - r3).abs() + (r1 - r4).abs() + (r2 - r4).abs();
          final score = maxRatio * 100.0 + variance * 10.0;

          if (score < bestScore) {
            bestScore = score;
            bestI = i;
            bestJ = j;
            bestK = k;
          }
        }
      }
    }

    return [
      questions.sublist(0, bestI),
      questions.sublist(bestI, bestJ),
      questions.sublist(bestJ, bestK),
      questions.sublist(bestK),
    ];
  }

  List<List<QuestionTemplate>> _partitionInto3Pages(
    List<QuestionTemplate> questions, {
    required bool hasBanner,
    bool hasEndBanner = false,
  }) {
    if (questions.isEmpty) return [[], [], []];
    if (questions.length <= 3) {
      final res = <List<QuestionTemplate>>[];
      for (var q in questions) {
        res.add([q]);
      }
      while (res.length < 3) {
        res.add([]);
      }
      return res;
    }

    final n = questions.length;
    final heights = questions.map((q) => _estimateQuestionHeight(q)).toList();

    // A4 height budget (px)
    final double b1 = hasBanner ? 770.0 : 860.0;
    const double b2 = 860.0;
    final double b3 = hasEndBanner ? 800.0 : 860.0;

    int bestI = (n / 3).round().clamp(1, n - 2);
    int bestJ = (2 * n / 3).round().clamp(bestI + 1, n - 1);
    double bestScore = double.infinity;

    for (int i = 1; i < n - 1; i++) {
      for (int j = i + 1; j < n; j++) {
        double h1 = 0;
        for (int k = 0; k < i; k++) { h1 += heights[k]; }
        double h2 = 0;
        for (int k = i; k < j; k++) { h2 += heights[k]; }
        double h3 = 0;
        for (int k = j; k < n; k++) { h3 += heights[k]; }

        final r1 = h1 / b1;
        final r2 = h2 / b2;
        final r3 = h3 / b3;
        final maxRatio = [r1, r2, r3].reduce((a, b) => a > b ? a : b);
        final variance = (r1 - r2).abs() + (r2 - r3).abs() + (r1 - r3).abs();
        final score = maxRatio * 100.0 + variance * 10.0;

        if (score < bestScore) {
          bestScore = score;
          bestI = i;
          bestJ = j;
        }
      }
    }

    return [
      questions.sublist(0, bestI),
      questions.sublist(bestI, bestJ),
      questions.sublist(bestJ),
    ];
  }

  double _estimateQuestionHeight(QuestionTemplate q) {
    double h = 30.0; // Badge & Title
    final rawText = q.questionText.trim();
    final (_, passage) = _splitQuestionPrompt(rawText);

    final imgUrl = (q is UniversalQuestion) ? q.questionImageUrl
        : (q is ReadingImageQuestion) ? q.imageAssetPath : null;

    final bool hasMaterial = (passage != null && passage.isNotEmpty) ||
        (imgUrl != null && imgUrl.isNotEmpty);

    if (hasMaterial) {
      h += 18.0;
      if (passage != null && passage.isNotEmpty) {
        final lines = (passage.length / 45.0).ceil();
        h += lines * 18.0;
      }
      if (imgUrl != null && imgUrl.isNotEmpty) {
        h += 110.0;
      }
    }

    List<String> textOpts = [];
    List<String?> imgOpts = [];
    if (q is UniversalQuestion) { textOpts = q.textOptions; imgOpts = q.imageOptions; }
    else if (q is ReadingTextQuestion) { textOpts = q.textOptions; }
    else if (q is ReadingImageQuestion) { textOpts = q.textOptions; }
    else if (q is ListeningAudioQuestion) { textOpts = q.textOptions; }
    else if (q is ListeningImageOptionsQuestion) { imgOpts = q.imageOptionPaths; }

    final bool hasImageOpts = imgOpts.isNotEmpty && imgOpts.any((x) => x != null && x.isNotEmpty);
    if (hasImageOpts) {
      h += 110.0;
    } else {
      final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');
      final hasNewlines = cleaned.any((o) => o.contains('\n'));
      final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
      if (!hasNewlines && maxLen <= 11) {
        h += 24.0;
      } else if (!hasNewlines && maxLen <= 26) {
        h += 48.0;
      } else {
        h += 92.0;
      }
    }

    h += 14.0; // padding
    return h;
  }

  (String, String?) _splitQuestionPrompt(String rawText) {
    var text = rawText.trim();
    // Strip leading question numbers like [1], [01], 1., 1)
    text = text.replaceFirst(RegExp(r'^\[?\d{1,2}\]?[.\s-]*'), '').trim();

    if (text.contains('\n')) {
      final firstLine = text.split('\n').first.trim();
      final rest = text.split('\n').skip(1).join('\n').trim();
      return (firstLine, rest.isNotEmpty ? rest : null);
    }

    // Check for inline bracketed / quoted word like:
    // "다음 단어와 관계있는 것은 무엇입니까? [ 밥, 찌개, 김치 ]"
    // "다음 질문에 맞는 표지를 고르십시오. '주차금지'"
    // "다음 단어의 반대말은 무엇입니까? <들어가다>"
    final bracketOrQuoteMatch = RegExp(r'''^(.*?)(\s*(\[[^\]]+\]|<[^>]+>|['"][^'"]+['"])\s*)$''').firstMatch(text);
    if (bracketOrQuoteMatch != null && bracketOrQuoteMatch.group(1)!.trim().isNotEmpty) {
      return (bracketOrQuoteMatch.group(1)!.trim(), bracketOrQuoteMatch.group(2)!.trim());
    }

    // Check for standard question endings followed by content/passage/word
    final promptEndMatch = RegExp(r'^(.*?(?:고르십시오\.|무엇입니까\?|답하십시오\.|맞는\s*것은\?|알맞은\s*것은\?|알맞은\s*것을\?))\s+(.+)$').firstMatch(text);
    if (promptEndMatch != null) {
      return (promptEndMatch.group(1)!.trim(), promptEndMatch.group(2)!.trim());
    }

    return (text, null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE WRAPPER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _page(int pageNum, Widget content) {
    return Container(
      width: 794,   // A4-ish width in screen pixels
      constraints: const BoxConstraints(minHeight: 1122),
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(fit: FlexFit.loose, child: content),
          // ── Footer ──
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EPS-TOPIK  PBT  |  한국산업인력공단',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('- $pageNum -',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Text(widget.testSet.instituteName ?? 'Official Test Center',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
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
        Container(height: 6, color: const Color(0xFF1E3A8A)),
        const SizedBox(height: 3),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.school, color: Colors.white, size: 26),
              Text('HRD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ])),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('고용허가제 한국어능력시험 (EPS-TOPIK)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const Text('Employment Permit System — Test of Proficiency in Korean',
                style: TextStyle(fontSize: 10, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(instituteName.toUpperCase(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.8)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E3A8A), width: 2), borderRadius: BorderRadius.circular(4)),
            child: const Text('PBT\n문제지', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E3A8A))),
          ),
        ]),

        const SizedBox(height: 22),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 14),

        Center(child: Text(widget.testSet.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF0F172A)))),
        const SizedBox(height: 10),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(4)),
          child: const Text('읽기 20문항 + 듣기 20문항  |  시험시간: 50분  |  100점 만점  |  합격: 50점',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3)),
        )),

        const SizedBox(height: 28),

        // Candidate fill-up
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: Colors.black87,
          child: const Text('■  수험자 정보 기재란  (Candidate Information — Please Fill In)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(flex: 4, child: _fillBox('수험번호 (Registration No.)', 'e.g. NP-2025-000001')),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: _fillBox('성명 / Name (नाम)', 'e.g. Ram Bahadur Thapa')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(flex: 3, child: _fillBox('국적 (Nationality)', 'Nepal')),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: _fillBox('생년월일 (Date of Birth)', 'YYYY / MM / DD')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(flex: 3, child: _fillBox('시험실 (Exam Room)', '____호실')),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _fillBox('좌석번호 (Seat No.)', '____번')),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: _fillBox('시험일 (Exam Date)', '____ 년  ____ 월  ____ 일')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(flex: 5, child: _fillBox('서명 (Candidate Signature)', '______________________________')),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: _fillBox('감독관 서명 (Invigilator Signature)', '______________________________')),
        ]),

        const SizedBox(height: 26),

        // Rules
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: const Color(0xFF1E3A8A),
          child: const Text('■  수험자 유의사항  (Exam Rules / परीक्षा नियमहरू)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            _RuleRow('1', '시험 시작 전까지 문제지를 열어보지 마십시오. / परीक्षा सुरु नभएसम्म प्रश्नपत्र नखोल्नुहोस्।'),
            SizedBox(height: 5),
            _RuleRow('2', '답안은 컴퓨터용 사인펜(흑색/청색)으로 작성하십시오. / उत्तर OMR पानामा कलमले भर्नुहोस्।'),
            SizedBox(height: 5),
            _RuleRow('3', '총 40문항 (읽기 20문항 + 듣기 20문항), 시험시간 50분 / कुल ४० प्रश्न, ५० मिनेट।'),
            SizedBox(height: 5),
            _RuleRow('4', '부정행위 적발 시 즉시 퇴실 조치됩니다. / नक्कल गरेमा तत्काल निष्काशन गरिनेछ।'),
            SizedBox(height: 5),
            _RuleRow('5', '듣기 문제는 음성 방송 후 바로 풀어야 합니다. / अडियो सकिनासाथ उत्तर भर्नुहोस्।'),
            SizedBox(height: 5),
            _RuleRow('6', '시험 종료 후 문제지와 답안지를 모두 제출하십시오. / प्रश्नपत्र र OMR दुवै बुझाउनुहोस्।'),
          ]),
        ),

        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '분야 (Sector): ${widget.testSet.sector}   •   ${widget.testSet.description}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
            )),
          ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          height: 26, width: double.infinity,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black54, width: 1))),
          child: Text(hint, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGES 2–7 — SINGLE COLUMN HRD-STYLE QUESTION PAGES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQPage({
    required List<QuestionTemplate> questions,
    required int startNumber,
    bool isReadingStart = false,
    bool isListeningStart = false,
    bool isLastPage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Running header
        _runningHeader(isListeningStart || (!isReadingStart && startNumber > 20) ? '듣기 (Listening)' : '읽기 (Reading)'),
        const SizedBox(height: 12),

        // Section start banner
        if (isReadingStart) ...[
          _sectionBanner('읽기 영역 (Reading)  :  1번 ~ 20번  /  50점',
              '아래 내용을 읽고 물음에 맞는 가장 알맞은 것을 ①②③④ 중에서 고르십시오. / Q1–Q20 सम्म पढेर सही उत्तर ①②③④ मा छान्नुहोस्।'),
          const SizedBox(height: 14),
        ] else if (isListeningStart) ...[
          _sectionBanner('듣기 영역 (Listening)  :  21번 ~ 40번  /  50점',
              '다음을 듣고 알맞은 것을 ①②③④ 중에서 고르십시오. / Q21–Q40 सम्म सुनेर सही उत्तर ①②③④ मा छान्नुहोस्।'),
          const SizedBox(height: 14),
        ],

        // Questions — single column, HRD style
        ...questions.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _hrdQuestion(startNumber + e.key, e.value),
        )),

        // End of exam banner on last page
        if (isLastPage) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '★ 이상으로 문제가 끝났습니다.  •  परीक्षाका सबै प्रश्नहरू यहाँ समाप्त हुन्छन्।  ★',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _runningHeader(String sectionTitle) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black87, width: 1.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${widget.testSet.title}  •  $sectionTitle',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const Text('EPS-TOPIK  PBT  지필 모의고사',
            style: TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    );
  }

  Widget _sectionBanner(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HRD-STYLE SINGLE QUESTION WIDGET
  // Bold question title + rounded-border material box + options ①②③④
  // ─────────────────────────────────────────────────────────────────────────
  Widget _hrdQuestion(int no, QuestionTemplate q) {
    const nums = ['①', '②', '③', '④'];

    // Extract fields with smart prompt / passage / word splitting
    final rawText = q.questionText.trim();
    final (qText, passage) = _splitQuestionPrompt(rawText);

    final imgUrl = (q is UniversalQuestion) ? q.questionImageUrl
        : (q is ReadingImageQuestion) ? q.imageAssetPath : null;

    List<String> textOpts = [];
    List<String?> imgOpts = [];
    if (q is UniversalQuestion) { textOpts = q.textOptions; imgOpts = q.imageOptions; }
    else if (q is ReadingTextQuestion) { textOpts = q.textOptions; }
    else if (q is ReadingImageQuestion) { textOpts = q.textOptions; }
    else if (q is ListeningAudioQuestion) { textOpts = q.textOptions; }
    else if (q is ListeningImageOptionsQuestion) { imgOpts = q.imageOptionPaths; }

    final bool hasImageOpts = imgOpts.isNotEmpty && imgOpts.any((x) => x != null && x.isNotEmpty);
    final bool hasMaterial = (passage != null && passage.isNotEmpty) ||
        (imgUrl != null && imgUrl.isNotEmpty);

    // Identify if the passage is a single word or short vocabulary item
    final bool isSingleWord = passage != null &&
        !passage.contains('\n') &&
        !passage.contains('가:') &&
        !passage.contains('나:') &&
        passage.length <= 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Question Number Badge + Bold Title ─────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Number badge
          Container(
            width: 26, height: 26,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$no',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          Expanded(
            child: Text(qText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.35,
                )),
          ),
        ]),

        // ── Rounded Corner Rectangular Border Box ─────────────────────
        // Houses Paragraphs, Dialogues, Single Word Questions, or Images
        if (hasMaterial) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6, bottom: 4),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isSingleWord ? 11 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: Colors.black87, width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: isSingleWord ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                // Paragraph / Passage / Words
                if (passage != null && passage.isNotEmpty)
                  isSingleWord
                      ? Center(
                          child: Text(
                            passage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : Text(
                          passage,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.55,
                            color: Colors.black87,
                          ),
                        ),

                // Image inside rounded border box
                if (imgUrl != null && imgUrl.isNotEmpty) ...[
                  if (passage != null && passage.isNotEmpty) const SizedBox(height: 6),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 110, maxWidth: 280),
                      child: SmartImageWidget(imageSource: imgUrl, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // ── Options ──────────────────────────────────────────────────
        const SizedBox(height: 4),

        if (hasImageOpts)
          // Image options: 2×2 grid inside a border box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6),
              itemCount: 4,
              itemBuilder: (ctx, i) {
                final img = i < imgOpts.length ? imgOpts[i] : null;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(nums[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (img != null && img.isNotEmpty)
                      Expanded(child: SmartImageWidget(imageSource: img, fit: BoxFit.contain)),
                  ]),
                );
              },
            ),
          )
        else
          // Dynamic text options: 1 column / 2 columns / 4 columns based on option length
          _buildDynamicTextOptions(textOpts),
      ],
    );
  }

  Widget _buildDynamicTextOptions(List<String> textOpts) {
    const nums = ['①', '②', '③', '④'];
    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');

    // Check if options have newlines
    final hasNewlines = cleaned.any((o) => o.contains('\n'));

    // Find the max length among all options
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
    final count = cleaned.where((o) => o.isNotEmpty).length;

    // Determine layout columns:
    // 4 columns: very short options (e.g. single words / vocabulary, maxLen <= 11) -> 1 row (① ② ③ ④)
    // 2 columns: medium options (e.g. short sentences / phrases, maxLen <= 26) -> 2 rows × 2 cols (① ② / ③ ④)
    // 1 column: long options / long sentences / newlines -> 4 rows × 1 col
    int colCount = 1;
    if (!hasNewlines && count > 0) {
      if (count == 4 && maxLen <= 11) {
        colCount = 4;
      } else if (maxLen <= 26) {
        colCount = 2;
      } else {
        colCount = 1;
      }
    }

    Widget buildOptionItem(int i) {
      final txt = cleaned[i];
      if (txt.isEmpty) return const SizedBox.shrink();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${nums[i]}  ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              txt,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }

    if (colCount == 4) {
      return Padding(
        padding: const EdgeInsets.only(left: 36, top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildOptionItem(0)),
            const SizedBox(width: 8),
            Expanded(child: buildOptionItem(1)),
            const SizedBox(width: 8),
            Expanded(child: buildOptionItem(2)),
            const SizedBox(width: 8),
            Expanded(child: buildOptionItem(3)),
          ],
        ),
      );
    } else if (colCount == 2) {
      return Padding(
        padding: const EdgeInsets.only(left: 36, top: 4),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildOptionItem(0)),
                const SizedBox(width: 16),
                Expanded(child: buildOptionItem(1)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildOptionItem(2)),
                const SizedBox(width: 16),
                Expanded(child: buildOptionItem(3)),
              ],
            ),
          ],
        ),
      );
    } else {
      // 1 column (vertical list)
      return Padding(
        padding: const EdgeInsets.only(left: 36, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (i) {
            if (cleaned[i].isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: buildOptionItem(i),
            );
          }),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _RuleRow extends StatelessWidget {
  final String number;
  final String text;
  const _RuleRow(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 18, height: 18,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
        child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.35))),
    ]);
  }
}
