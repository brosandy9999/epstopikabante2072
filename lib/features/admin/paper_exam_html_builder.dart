import 'dart:convert';
import '../../core/models/mock_test_model.dart';
import '../question_engine/question_template.dart';

class PaperExamHtmlBuilder {
  static String buildExamHtml(
    MockTestSet testSet, {
    Map<String, String>? customQrCodes,
    String? customSectionQr,
  }) {
    final allQs = testSet.questions;

    // Detect where listening begins (e.g. index 20 for Q21)
    int listeningStartIndex = -1;
    for (int i = 0; i < allQs.length; i++) {
      final q = allQs[i];
      final isL = (q is UniversalQuestion && q.isListening) ||
                  (q is ListeningAudioQuestion) ||
                  (q is ListeningImageOptionsQuestion) ||
                  (i >= 20);
      if (isL && listeningStartIndex == -1) {
        listeningStartIndex = i;
        break;
      }
    }
    if (listeningStartIndex == -1) listeningStartIndex = 20;

    final effectiveSectionQr = customSectionQr ?? testSet.listeningSectionQrUrl;
    final pages = partitionAcross7Pages(
      allQs,
      listeningStartIndex,
      hasSectionQr: effectiveSectionQr != null && effectiveSectionQr.isNotEmpty,
    );

    final institute = testSet.instituteName ?? 'Official Test Center';

    return '''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>${_esc(testSet.title)} — EPS-TOPIK PBT Exam (8 Pages)</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;900&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Noto Sans KR', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #334155;
      color: #0f172a;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    .print-bar {
      position: fixed;
      top: 12px;
      right: 16px;
      z-index: 99999;
      display: flex;
      gap: 10px;
    }
    .btn {
      background: #16a34a;
      color: #ffffff;
      border: none;
      padding: 10px 18px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    }
    .btn:hover { background: #15803d; }
    .btn-secondary {
      background: #1e3a8a;
    }
    .btn-secondary:hover { background: #172554; }

    .page-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 24px 0;
      gap: 28px;
    }
    .pbt-page {
      width: 210mm;
      min-height: 297mm;
      max-height: 297mm;
      padding: 14mm 16mm 12mm 16mm;
      background: #ffffff;
      box-shadow: 0 8px 24px rgba(0,0,0,0.25);
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      position: relative;
      overflow: hidden;
    }

    /* Running Header */
    .running-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1.5px solid #000;
      padding-bottom: 4px;
      margin-bottom: 8px;
    }
    .running-header-title {
      font-size: 11px;
      font-weight: 700;
      color: #1e3a8a;
    }
    .running-header-sub {
      font-size: 10px;
      color: #64748b;
    }

    /* Section Banner */
    .section-banner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #1e3a8a;
      color: #ffffff;
      padding: 6px 12px;
      border-radius: 4px;
      margin-bottom: 10px;
      gap: 12px;
    }
    .section-banner-content {
      flex: 1;
    }
    .section-banner-title {
      font-size: 12px;
      font-weight: 900;
    }
    .section-banner-desc {
      font-size: 9.5px;
      opacity: 0.85;
      margin-top: 1px;
    }
    .section-banner-qr {
      display: flex;
      flex-direction: column;
      align-items: center;
      background: #ffffff;
      border: 1px solid #cbd5e1;
      padding: 3px 6px;
      border-radius: 4px;
      flex-shrink: 0;
    }
    .section-banner-qr img {
      width: 46px;
      height: 46px;
      object-fit: contain;
    }
    .banner-qr-label {
      font-size: 7.5px;
      font-weight: 700;
      color: #1e3a8a;
      margin-top: 2px;
      white-space: nowrap;
    }

    /* Questions container */
    .questions-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
      flex: 1;
    }

    /* Question Item */
    .q-item {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .q-title-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 6px;
    }
    .q-title-left {
      display: flex;
      align-items: flex-start;
      gap: 6px;
      flex: 1;
    }
    .q-badge {
      background: #1e3a8a;
      color: #ffffff;
      font-size: 11.5px;
      font-weight: 900;
      min-width: 22px;
      height: 22px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 3px;
      flex-shrink: 0;
      margin-top: 1px;
    }
    .q-text {
      font-size: 12.5px;
      font-weight: 700;
      line-height: 1.35;
      color: #0f172a;
    }
    .q-qr-box {
      display: flex;
      flex-direction: column;
      align-items: center;
      background: #ffffff;
      border: 1px solid #cbd5e1;
      padding: 2px 4px;
      border-radius: 4px;
      flex-shrink: 0;
      margin-left: 6px;
    }
    .q-qr-box img {
      width: 44px;
      height: 44px;
      object-fit: contain;
    }
    .q-qr-label {
      font-size: 7px;
      font-weight: 700;
      color: #1e3a8a;
      margin-top: 1px;
      white-space: nowrap;
    }

    /* Rounded corner rectangular border box */
    .material-box {
      border: 1.2px solid #0f172a;
      border-radius: 6px;
      background: #fafafa;
      padding: 7px 12px;
      margin: 2px 0 2px 28px;
    }
    .material-box.single-word {
      text-align: center;
      font-size: 13.5px;
      font-weight: 700;
      letter-spacing: 0.5px;
      padding: 8px 12px;
    }
    .material-box.paragraph {
      text-align: left;
      font-size: 11.5px;
      line-height: 1.5;
      color: #1e293b;
      white-space: pre-line;
    }
    .material-box img {
      max-height: 95px;
      max-width: 240px;
      display: block;
      margin: 4px auto;
      object-fit: contain;
    }

    /* Side-by-side layout for picture questions (Picture Left, Options Right) */
    .q-side-row {
      display: flex;
      align-items: center;
      gap: 18px;
      margin-left: 28px;
      margin-top: 4px;
    }
    .q-side-media {
      flex: 0 0 250px;
      max-width: 250px;
    }
    .q-side-media .material-box {
      margin: 0 !important;
      padding: 6px 8px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 85px;
      background: #fafafa;
    }
    .q-side-media img {
      max-height: 105px;
      max-width: 235px;
      object-fit: contain;
      margin: 2px auto;
      display: block;
    }
    .q-side-options {
      flex: 1;
    }
    .q-side-options .options-container {
      margin-left: 0 !important;
      margin-top: 0 !important;
    }

    /* Options */
    .options-container {
      margin-left: 28px;
      margin-top: 3px;
    }
    .opt-col-4 {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 6px;
    }
    .opt-col-2 {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      row-gap: 4px;
      column-gap: 12px;
    }
    .opt-col-1 {
      display: flex;
      flex-direction: column;
      gap: 3px;
    }
    .opt-item {
      display: flex;
      align-items: flex-start;
      gap: 4px;
      font-size: 11.5px;
      line-height: 1.35;
      color: #1e293b;
    }
    .opt-num {
      font-weight: 700;
      flex-shrink: 0;
    }
    .opt-text {
      flex: 1;
    }

    /* Image options */
    .img-opts-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 6px;
      border: 1px solid #cbd5e1;
      padding: 6px;
      border-radius: 4px;
      margin-left: 28px;
      margin-top: 3px;
    }
    .img-opt-box {
      border: 1px solid #e2e8f0;
      border-radius: 4px;
      padding: 4px;
      display: flex;
      flex-direction: column;
      align-items: center;
      height: 70px;
    }
    .img-opt-box img {
      max-height: 48px;
      max-width: 100%;
      object-fit: contain;
    }

    /* Page Footer */
    .pbt-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-top: 1px solid #e2e8f0;
      padding-top: 6px;
      font-size: 8.5px;
      color: #64748b;
      margin-top: 8px;
    }
    .page-pill {
      font-size: 10px;
      font-weight: 700;
      border: 1px solid #cbd5e1;
      padding: 1px 8px;
      border-radius: 3px;
      color: #0f172a;
    }

    /* End exam banner */
    .exam-end-banner {
      background: #0f172a;
      color: #ffffff;
      text-align: center;
      font-size: 11px;
      font-weight: 700;
      padding: 6px;
      border-radius: 4px;
      margin-top: 8px;
    }

    /* Cover Page 1 */
    .cover-top {
      text-align: center;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 12px;
      margin-bottom: 14px;
    }
    .cover-badge {
      display: inline-block;
      background: #0f172a;
      color: #ffffff;
      font-size: 10px;
      font-weight: 700;
      padding: 2px 10px;
      border-radius: 3px;
      margin-bottom: 6px;
    }
    .cover-title {
      font-size: 22px;
      font-weight: 900;
      color: #0f172a;
      letter-spacing: 0.5px;
    }
    .cover-subtitle {
      font-size: 12px;
      color: #475569;
      margin-top: 4px;
    }
    .cover-specs {
      display: inline-block;
      background: #1e3a8a;
      color: #ffffff;
      font-size: 11px;
      font-weight: 700;
      padding: 5px 14px;
      border-radius: 4px;
      margin-top: 8px;
    }

    /* Candidate Box Table */
    .candidate-header {
      background: #0f172a;
      color: #ffffff;
      font-size: 11px;
      font-weight: 700;
      padding: 5px 10px;
      margin-top: 14px;
      margin-bottom: 8px;
    }
    .candidate-grid {
      display: grid;
      grid-template-columns: repeat(12, 1fr);
      gap: 8px;
      margin-bottom: 12px;
    }
    .form-box {
      border: 1.2px solid #0f172a;
      border-radius: 3px;
      padding: 6px 8px;
    }
    .form-label {
      font-size: 9px;
      font-weight: 700;
      color: #0f172a;
      margin-bottom: 4px;
    }
    .form-line {
      border-bottom: 1px solid #94a3b8;
      height: 18px;
      font-size: 9px;
      color: #94a3b8;
      font-style: italic;
    }

    /* Rules */
    .rules-header {
      background: #1e3a8a;
      color: #ffffff;
      font-size: 11px;
      font-weight: 700;
      padding: 5px 10px;
      margin-top: 10px;
    }
    .rules-box {
      background: #f8fafc;
      border: 1px solid #cbd5e1;
      border-top: none;
      padding: 10px 14px;
      font-size: 10px;
      line-height: 1.6;
    }
    .rule-item {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      margin-bottom: 4px;
    }
    .rule-num {
      background: #1e3a8a;
      color: #fff;
      font-size: 8.5px;
      font-weight: 700;
      width: 14px;
      height: 14px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      margin-top: 2px;
    }

    /* Sector pill */
    .sector-info {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 4px;
      padding: 8px 12px;
      font-size: 10px;
      color: #1e3a8a;
      font-weight: 600;
      margin-top: 12px;
    }

    /* Print media rules */
    @media print {
      body { background: transparent; }
      .print-bar { display: none !important; }
      .page-container { padding: 0 !important; gap: 0 !important; }
      .pbt-page {
        width: 100% !important;
        min-height: 100vh !important;
        max-height: 100vh !important;
        box-shadow: none !important;
        margin: 0 !important;
        padding: 12mm 14mm 10mm 14mm !important;
        page-break-after: always !important;
        break-after: page !important;
      }
      .pbt-page:last-child {
        page-break-after: avoid !important;
        break-after: avoid !important;
      }
    }
  </style>
</head>
<body>
  <div class="print-bar">
    <button class="btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
  </div>

  <div class="page-container">
    <!-- PAGE 1: COVER -->
    ${_buildCoverPageHtml(testSet, institute)}

    <!-- PAGES 2–8: 7 CONTINUOUS QUESTION PAGES -->
    ${() {
      final sb = StringBuffer();
      int currentQIndex = 0;
      for (int p = 0; p < 7; p++) {
        final pageQs = pages[p];
        final pageNum = p + 2;
        sb.writeln(_buildContinuousQPageHtml(
          testSet: testSet,
          pageQuestions: pageQs,
          startQuestionIndex: currentQIndex,
          listeningStartIndex: listeningStartIndex,
          pageNum: pageNum,
          institute: institute,
          isLastPage: (p == 6),
          qrCodes: customQrCodes,
          sectionQrUrl: customSectionQr,
        ));
        currentQIndex += pageQs.length;
      }
      return sb.toString();
    }()}
  </div>

  <script>
    window.addEventListener('load', function() {
      setTimeout(function() {
        window.print();
      }, 400);
    });
  </script>
</body>
</html>''';
  }

  static String _buildCoverPageHtml(MockTestSet testSet, String institute) {
    return '''
    <div class="pbt-page">
      <div>
        <div class="cover-top">
          <div class="cover-badge">EPS-TOPIK PBT  지필 모의고사</div>
          <div class="cover-title">${_esc(testSet.title)}</div>
          <div class="cover-subtitle">${_esc(testSet.sector)}  •  공식 지필시험 형태 문제지</div>
          <div class="cover-specs">읽기 20문항 + 듣기 20문항  |  시험시간: 50분  |  100점 만점</div>
        </div>

        <div class="candidate-header">■ 수험자 정보 기재란 (Candidate Information)</div>
        <div class="candidate-grid">
          <div class="form-box" style="grid-column: span 5;">
            <div class="form-label">수험번호 (Registration No.)</div>
            <div class="form-line">e.g. NP-2026-000001</div>
          </div>
          <div class="form-box" style="grid-column: span 7;">
            <div class="form-label">성명 / Name (नाम)</div>
            <div class="form-line">e.g. Ram Bahadur Thapa</div>
          </div>
          <div class="form-box" style="grid-column: span 4;">
            <div class="form-label">국적 (Nationality)</div>
            <div class="form-line">Nepal</div>
          </div>
          <div class="form-box" style="grid-column: span 8;">
            <div class="form-label">생년월일 (Date of Birth)</div>
            <div class="form-line">YYYY / MM / DD</div>
          </div>
          <div class="form-box" style="grid-column: span 4;">
            <div class="form-label">시험실 (Room)</div>
            <div class="form-line">____ 호실</div>
          </div>
          <div class="form-box" style="grid-column: span 4;">
            <div class="form-label">좌석번호 (Seat No.)</div>
            <div class="form-line">____ 번</div>
          </div>
          <div class="form-box" style="grid-column: span 4;">
            <div class="form-label">시험일 (Date)</div>
            <div class="form-line">2026. __. __</div>
          </div>
          <div class="form-box" style="grid-column: span 6;">
            <div class="form-label">수험자 서명 (Candidate Signature)</div>
            <div class="form-line"></div>
          </div>
          <div class="form-box" style="grid-column: span 6;">
            <div class="form-label">감독관 확인 (Invigilator Signature)</div>
            <div class="form-line"></div>
          </div>
        </div>

        <div class="rules-header">■ 수험자 유의사항 (Exam Rules / परीक्षा नियमहरू)</div>
        <div class="rules-box">
          <div class="rule-item"><div class="rule-num">1</div><div>시험 시작 전까지 문제지를 열어보지 마십시오. / परीक्षा सुरु नभएसम्म प्रश्नपत्र नखोल्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">2</div><div>답안은 컴퓨터용 사인펜(흑색/청색)으로 작성하십시오. / उत्तर OMR पानामा कलमले भर्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">3</div><div>총 40문항 (읽기 20문항 + 듣기 20문항), 시험시간 50분 / कुल ४० प्रश्न, ५० मिनेट।</div></div>
          <div class="rule-item"><div class="rule-num">4</div><div>부정행위 적발 시 즉시 퇴실 조치됩니다. / नक्कल गरेमा तत्काल निष्काशन गरिनेछ।</div></div>
          <div class="rule-item"><div class="rule-num">5</div><div>듣기 문제는 방송을 잘 듣고 바로 답을 표기하십시오. / अडियो सकिनासाथ उत्तर भर्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">6</div><div>시험 종료 후 문제지와 답안지를 모두 제출하십시오. / प्रश्नपत्र र OMR दुवै बुझाउनुहोस्।</div></div>
        </div>

        <div class="sector-info">
          ℹ️ 분야 (Sector): ${_esc(testSet.sector)}  •  ${_esc(testSet.description)}
        </div>
      </div>

      <div class="pbt-footer">
        <div>EPS-TOPIK PBT  |  한국산업인력공단</div>
        <div class="page-pill">- 1 -</div>
        <div>${_esc(institute)}</div>
      </div>
    </div>
    ''';
  }

  static String _buildContinuousQPageHtml({
    required MockTestSet testSet,
    required List<QuestionTemplate> pageQuestions,
    required int startQuestionIndex,
    required int listeningStartIndex,
    required int pageNum,
    required String institute,
    bool isLastPage = false,
    Map<String, String>? qrCodes,
    String? sectionQrUrl,
  }) {
    final effectiveSectionQr = sectionQrUrl ?? testSet.listeningSectionQrUrl;

    // Check which sections are represented on this page
    final bool hasReading = pageQuestions.asMap().entries.any((e) => (startQuestionIndex + e.key) < listeningStartIndex);
    final bool hasListening = pageQuestions.asMap().entries.any((e) => (startQuestionIndex + e.key) >= listeningStartIndex);

    final String sectionTitle;
    if (hasReading && hasListening) {
      sectionTitle = '읽기 & 듣기 (Reading & Listening)';
    } else if (hasListening) {
      sectionTitle = '듣기 (Listening)';
    } else {
      sectionTitle = '읽기 (Reading)';
    }

    final sb = StringBuffer();
    sb.writeln('<div class="pbt-page">');
    sb.writeln('<div>');

    // Running Header
    sb.writeln('''
      <div class="running-header">
        <div class="running-header-title">${_esc(testSet.title)}  •  $sectionTitle</div>
        <div class="running-header-sub">EPS-TOPIK PBT 지필 모의고사</div>
      </div>
    ''');

    // Questions List
    sb.writeln('<div class="questions-list">');
    for (int i = 0; i < pageQuestions.length; i++) {
      final q = pageQuestions[i];
      final globalIdx = startQuestionIndex + i;
      final qNo = globalIdx + 1;

      // 1. Reading Section Start Banner (at Q1)
      if (globalIdx == 0 && listeningStartIndex > 0) {
        sb.writeln('''
          <div class="section-banner">
            <div class="section-banner-content">
              <div class="section-banner-title">읽기 영역 (Reading) : 1번 ~ $listeningStartIndex번 / 50점</div>
              <div class="section-banner-desc">아래 내용을 읽고 물음에 맞는 가장 알맞은 것을 ①②③④ 중에서 고르십시오.</div>
            </div>
          </div>
        ''');
      }

      // 2. Listening Section Start Banner (right after reading ends and listening starts)
      if (globalIdx == listeningStartIndex) {
        sb.writeln('''
          <div class="section-banner" style="margin-top: ${i == 0 ? 0 : 10}px; margin-bottom: 10px;">
            <div class="section-banner-content">
              <div class="section-banner-title">듣기 영역 (Listening) : ${listeningStartIndex + 1}번 ~ ${testSet.questions.length}번 / 50점</div>
              <div class="section-banner-desc">다음을 듣고 알맞은 것을 ①②③④ 중에서 고르십시오. (듣기 대본은 시험지에 제공되지 않습니다.)</div>
            </div>
            ${effectiveSectionQr != null && effectiveSectionQr.isNotEmpty ? '''
            <div class="section-banner-qr">
              <img src="${_esc(effectiveSectionQr)}" alt="Full Audio QR" />
              <span class="banner-qr-label">🎧 전체 듣기 (Full Audio)</span>
            </div>
            ''' : ''}
          </div>
        ''');
      }

      // 3. Single Question
      String? qQr;
      if (qrCodes != null) {
        qQr = qrCodes[q.questionId] ?? qrCodes['$qNo'];
      }
      if (qQr == null && testSet.listeningQrCodes != null) {
        qQr = testSet.listeningQrCodes![q.questionId] ?? testSet.listeningQrCodes!['$qNo'];
      }
      if (qQr == null && q is UniversalQuestion && q.questionQrCodeUrl != null && q.questionQrCodeUrl!.isNotEmpty) {
        qQr = q.questionQrCodeUrl;
      }

      sb.writeln(_buildSingleQuestionHtml(qNo, q, qrCodeUrl: qQr));
    }
    sb.writeln('</div>'); // questions-list

    if (isLastPage) {
      sb.writeln('''
        <div class="exam-end-banner">
          ★ 이상으로 문제가 끝났습니다.  •  परीक्षाका सबै प्रश्नहरू यहाँ समाप्त हुन्छन्। ★
        </div>
      ''');
    }

    sb.writeln('</div>'); // top wrapper

    // Footer
    sb.writeln('''
      <div class="pbt-footer">
        <div>EPS-TOPIK PBT  |  한국산업인력공단</div>
        <div class="page-pill">- $pageNum -</div>
        <div>${_esc(institute)}</div>
      </div>
    ''');

    sb.writeln('</div>'); // pbt-page
    return sb.toString();
  }

  static String _buildSingleQuestionHtml(int no, QuestionTemplate q, {String? qrCodeUrl}) {
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
    final bool isSideBySide = (imgUrl != null && imgUrl.isNotEmpty && !hasImageOpts && (passage == null || passage.length <= 80));
    final bool hasMaterial = (passage != null && passage.isNotEmpty) || (imgUrl != null && imgUrl.isNotEmpty);

    final bool isSingleWord = passage != null &&
        !passage.contains('\n') &&
        !passage.contains('가:') &&
        !passage.contains('나:') &&
        passage.length <= 40;

    final sb = StringBuffer();
    sb.writeln('<div class="q-item">');

    // Title Row with badge and optional listening QR code
    sb.writeln('''
      <div class="q-title-row">
        <div class="q-title-left">
          <div class="q-badge">$no</div>
          <div class="q-text">${_esc(qText)}</div>
        </div>
        ${qrCodeUrl != null && qrCodeUrl.isNotEmpty ? '''
        <div class="q-qr-box">
          <img src="${_esc(qrCodeUrl)}" alt="QR $no" />
          <span class="q-qr-label">🎧 듣기 QR</span>
        </div>
        ''' : ''}
      </div>
    ''');

    if (isSideBySide) {
      // ── Side-by-Side: Picture on Left, Options on Right ──
      sb.writeln('<div class="q-side-row">');
      sb.writeln('<div class="q-side-media">');
      sb.writeln('<div class="material-box">');
      if (passage != null && passage.isNotEmpty) {
        sb.writeln('<div style="font-weight: 700; font-size: 11.5px; margin-bottom: 3px; text-align: center; color: #0f172a;">${_esc(passage)}</div>');
      }
      sb.writeln('<img src="${_esc(imgUrl)}" alt="Question Image" />');
      sb.writeln('</div>');
      sb.writeln('</div>'); // q-side-media

      sb.writeln('<div class="q-side-options">');
      sb.writeln(_buildTextOptionsHtml(textOpts, isSideBySide: true));
      sb.writeln('</div>'); // q-side-options
      sb.writeln('</div>'); // q-side-row
    } else {
      // ── Standard Stacked Layout: Material on Top, Options Below ──
      if (hasMaterial) {
        final boxClass = isSingleWord ? 'material-box single-word' : 'material-box paragraph';
        sb.writeln('<div class="$boxClass">');
        if (passage != null && passage.isNotEmpty) {
          sb.writeln(_esc(passage));
        }
        if (imgUrl != null && imgUrl.isNotEmpty) {
          sb.writeln('<img src="${_esc(imgUrl)}" alt="Question Image" />');
        }
        sb.writeln('</div>');
      }

      // Options
      if (hasImageOpts) {
        sb.writeln('<div class="img-opts-grid">');
        const nums = ['①', '②', '③', '④'];
        for (int i = 0; i < 4; i++) {
          final img = i < imgOpts.length ? imgOpts[i] : null;
          sb.writeln('''
            <div class="img-opt-box">
              <span class="opt-num">${nums[i]}</span>
              ${img != null && img.isNotEmpty ? '<img src="${_esc(img)}" alt="Option $i" />' : ''}
            </div>
          ''');
        }
        sb.writeln('</div>');
      } else {
        sb.writeln(_buildTextOptionsHtml(textOpts, isSideBySide: false));
      }
    }

    sb.writeln('</div>'); // q-item
    return sb.toString();
  }

  static String _buildTextOptionsHtml(List<String> textOpts, {bool isSideBySide = false}) {
    const nums = ['①', '②', '③', '④'];
    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');

    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
    final count = cleaned.where((o) => o.isNotEmpty).length;

    int colCount = 1;
    if (isSideBySide) {
      // In side-by-side right column:
      // If options are short (maxLen <= 8, e.g. single vocabulary words), 2 columns (① ② / ③ ④)
      // Otherwise (sentences or longer), 1 column (① \n ② \n ③ \n ④)
      if (!hasNewlines && count == 4 && maxLen <= 8) {
        colCount = 2;
      } else {
        colCount = 1;
      }
    } else {
      if (!hasNewlines && count > 0) {
        if (count == 4 && maxLen <= 11) {
          colCount = 4;
        } else if (maxLen <= 26) {
          colCount = 2;
        } else {
          colCount = 1;
        }
      }
    }

    final colClass = colCount == 4 ? 'opt-col-4' : colCount == 2 ? 'opt-col-2' : 'opt-col-1';
    final sb = StringBuffer();
    sb.writeln('<div class="options-container $colClass">');
    for (int i = 0; i < 4; i++) {
      if (cleaned[i].isEmpty) continue;
      sb.writeln('''
        <div class="opt-item">
          <span class="opt-num">${nums[i]}</span>
          <span class="opt-text">${_esc(cleaned[i])}</span>
        </div>
      ''');
    }
    sb.writeln('</div>');
    return sb.toString();
  }

  static (String, String?) _splitQuestionPrompt(String rawText) {
    var text = rawText.trim();
    text = text.replaceFirst(RegExp(r'^\[?\d{1,2}\]?[.\s-]*'), '').trim();

    if (text.contains('\n')) {
      final firstLine = text.split('\n').first.trim();
      final rest = text.split('\n').skip(1).join('\n').trim();
      return (firstLine, rest.isNotEmpty ? rest : null);
    }

    final bracketOrQuoteMatch = RegExp(r'''^(.*?)(\s*(\[[^\]]+\]|<[^>]+>|['"][^'"]+['"])\s*)$''').firstMatch(text);
    if (bracketOrQuoteMatch != null && bracketOrQuoteMatch.group(1)!.trim().isNotEmpty) {
      return (bracketOrQuoteMatch.group(1)!.trim(), bracketOrQuoteMatch.group(2)!.trim());
    }

    final promptEndMatch = RegExp(r'^(.*?(?:고르십시오\.|무엇입니까\?|답하십시오\.|맞는\s*것은\?|알맞은\s*것은\?|알맞은\s*것을\?))\s+(.+)$').firstMatch(text);
    if (promptEndMatch != null) {
      return (promptEndMatch.group(1)!.trim(), promptEndMatch.group(2)!.trim());
    }

    return (text, null);
  }

  static List<List<QuestionTemplate>> partitionAcross7Pages(
    List<QuestionTemplate> questions,
    int listeningStartIndex, {
    bool hasSectionQr = false,
  }) {
    if (questions.isEmpty) {
      return List.generate(7, (_) => <QuestionTemplate>[]);
    }
    if (questions.length <= 7) {
      final res = <List<QuestionTemplate>>[];
      for (var q in questions) {
        res.add([q]);
      }
      while (res.length < 7) {
        res.add([]);
      }
      return res;
    }

    final n = questions.length;
    final heights = questions.map((q) => _estimateHeight(q)).toList();

    double pageCost(int i, int j, int p) {
      if (j <= i) return 1e9;
      double h = 0;
      for (int k = i; k < j; k++) {
        h += heights[k];
      }
      if (p == 0 && listeningStartIndex > 0) {
        h += 65.0; // Reading banner
      }
      if (i <= listeningStartIndex && listeningStartIndex < j && listeningStartIndex > 0) {
        h += (hasSectionQr ? 85.0 : 65.0);
      }
      if (p == 6) {
        h += 45.0; // Exam end banner
      }

      const budget = 860.0;
      final ratio = h / budget;
      final diff = ratio - 0.82;
      double penalty = diff * diff * 100.0;
      if (ratio > 1.0) {
        penalty += (ratio - 1.0) * 10000.0;
      }
      return penalty;
    }

    final dp = List.generate(7, (_) => List.filled(n + 1, 1e12));
    final parent = List.generate(7, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= n - 6; i++) {
      dp[0][i] = pageCost(0, i, 0);
    }

    for (int p = 1; p < 7; p++) {
      final minI = p + 1;
      final maxI = (p == 6) ? n : (n - (6 - p));
      for (int i = minI; i <= maxI; i++) {
        for (int k = p; k < i; k++) {
          if (dp[p - 1][k] >= 1e11) continue;
          final c = pageCost(k, i, p);
          final total = dp[p - 1][k] + c;
          if (total < dp[p][i]) {
            dp[p][i] = total;
            parent[p][i] = k;
          }
        }
      }
    }

    final splitPoints = List.filled(8, 0);
    splitPoints[7] = n;
    int curr = n;
    for (int p = 6; p >= 1; p--) {
      curr = parent[p][curr];
      splitPoints[p] = curr;
    }
    splitPoints[0] = 0;

    final result = <List<QuestionTemplate>>[];
    for (int p = 0; p < 7; p++) {
      final start = splitPoints[p];
      final end = splitPoints[p + 1];
      result.add(questions.sublist(start, end));
    }
    return result;
  }

  static double _estimateHeight(QuestionTemplate q) {
    double h = 26.0;
    final rawText = q.questionText.trim();
    final (_, passage) = _splitQuestionPrompt(rawText);

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
    final bool isSideBySide = (imgUrl != null && imgUrl.isNotEmpty && !hasImageOpts && (passage == null || passage.length <= 80));

    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');
    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);

    if (isSideBySide) {
      double optionsH = (!hasNewlines && maxLen <= 8) ? 44.0 : 88.0;
      h += (optionsH > 105.0 ? optionsH : 105.0) + 6.0;
    } else {
      final bool hasMaterial = (passage != null && passage.isNotEmpty) || (imgUrl != null && imgUrl.isNotEmpty);
      if (hasMaterial) {
        h += 16.0;
        if (passage != null && passage.isNotEmpty) {
          final lines = (passage.length / 45.0).ceil();
          h += lines * 16.0;
        }
        if (imgUrl != null && imgUrl.isNotEmpty) {
          h += 95.0;
        }
      }

      if (hasImageOpts) {
        h += 110.0;
      } else {
        if (!hasNewlines && maxLen <= 11) {
          h += 20.0;
        } else if (!hasNewlines && maxLen <= 26) {
          h += 40.0;
        } else {
          h += 75.0;
        }
      }
    }

    h += 12.0;
    return h;
  }

  static String _esc(String? text) {
    if (text == null || text.isEmpty) return '';
    return const HtmlEscape().convert(text);
  }
}
