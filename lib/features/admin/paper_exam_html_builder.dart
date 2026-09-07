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
    final reading = allQs.take(20).toList();
    final listening = allQs.skip(20).take(20).toList();

    // Partition Reading across 4 Pages (Pages 2, 3, 4, 5)
    final rPages = _partitionInto4(reading, hasBanner: true);
    // Partition Listening across 3 Pages (Pages 6, 7, 8)
    final lPages = _partitionInto3(listening, hasBanner: true, hasEndBanner: true);

    final r1 = rPages[0];
    final r2 = rPages[1];
    final r3 = rPages[2];
    final r4 = rPages[3];

    final l1 = lPages[0];
    final l2 = lPages[1];
    final l3 = lPages[2];

    final int r1Start = 1;
    final int r2Start = r1Start + r1.length;
    final int r3Start = r2Start + r2.length;
    final int r4Start = r3Start + r3.length;

    final int l1Start = r4Start + r4.length;
    final int l2Start = l1Start + l1.length;
    final int l3Start = l2Start + l2.length;

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

    <!-- PAGE 2: READING 1 -->
    ${_buildQPageHtml(testSet, r1, r1Start, 2, institute, isReadingStart: true)}

    <!-- PAGE 3: READING 2 -->
    ${_buildQPageHtml(testSet, r2, r2Start, 3, institute)}

    <!-- PAGE 4: READING 3 -->
    ${_buildQPageHtml(testSet, r3, r3Start, 4, institute)}

    <!-- PAGE 5: READING 4 -->
    ${_buildQPageHtml(testSet, r4, r4Start, 5, institute)}

    <!-- PAGE 6: LISTENING 1 -->
    ${_buildQPageHtml(testSet, l1, l1Start, 6, institute, isListeningStart: true, qrCodes: customQrCodes, sectionQrUrl: customSectionQr)}

    <!-- PAGE 7: LISTENING 2 -->
    ${_buildQPageHtml(testSet, l2, l2Start, 7, institute, qrCodes: customQrCodes)}

    <!-- PAGE 8: LISTENING 3 (LAST) -->
    ${_buildQPageHtml(testSet, l3, l3Start, 8, institute, isLastPage: true, qrCodes: customQrCodes)}
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

  static String _buildQPageHtml(
    MockTestSet testSet,
    List<QuestionTemplate> questions,
    int startNumber,
    int pageNum,
    String institute, {
    bool isReadingStart = false,
    bool isListeningStart = false,
    bool isLastPage = false,
    Map<String, String>? qrCodes,
    String? sectionQrUrl,
  }) {
    final sectionTitle = (isListeningStart || (!isReadingStart && startNumber > 20))
        ? '듣기 (Listening)'
        : '읽기 (Reading)';

    final effectiveSectionQr = sectionQrUrl ?? testSet.listeningSectionQrUrl;

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

    // Section Banner
    if (isReadingStart) {
      sb.writeln('''
        <div class="section-banner">
          <div class="section-banner-content">
            <div class="section-banner-title">읽기 영역 (Reading) : 1번 ~ 20번 / 50점</div>
            <div class="section-banner-desc">아래 내용을 읽고 물음에 맞는 가장 알맞은 것을 ①②③④ 중에서 고르십시오.</div>
          </div>
        </div>
      ''');
    } else if (isListeningStart) {
      sb.writeln('''
        <div class="section-banner">
          <div class="section-banner-content">
            <div class="section-banner-title">듣기 영역 (Listening) : 21번 ~ 40번 / 50점</div>
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

    // Questions List
    sb.writeln('<div class="questions-list">');
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final no = startNumber + i;

      String? qQr;
      if (qrCodes != null) {
        qQr = qrCodes[q.questionId] ?? qrCodes['$no'];
      }
      if (qQr == null && testSet.listeningQrCodes != null) {
        qQr = testSet.listeningQrCodes![q.questionId] ?? testSet.listeningQrCodes!['$no'];
      }
      if (qQr == null && q is UniversalQuestion && q.questionQrCodeUrl != null && q.questionQrCodeUrl!.isNotEmpty) {
        qQr = q.questionQrCodeUrl;
      }

      sb.writeln(_buildSingleQuestionHtml(no, q, qrCodeUrl: qQr));
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

    // Material Box
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
      sb.writeln(_buildTextOptionsHtml(textOpts));
    }

    sb.writeln('</div>'); // q-item
    return sb.toString();
  }

  static String _buildTextOptionsHtml(List<String> textOpts) {
    const nums = ['①', '②', '③', '④'];
    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');

    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
    final count = cleaned.where((o) => o.isNotEmpty).length;

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

  static List<List<QuestionTemplate>> _partitionInto4(
    List<QuestionTemplate> questions, {
    bool hasBanner = false,
  }) {
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
    final heights = questions.map((q) => _estimateHeight(q)).toList();

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

  static List<List<QuestionTemplate>> _partitionInto3(
    List<QuestionTemplate> questions, {
    bool hasBanner = false,
    bool hasEndBanner = false,
  }) {
    if (questions.isEmpty) return [[], [], []];
    if (questions.length <= 3) {
      final res = <List<QuestionTemplate>>[];
      for (var q in questions) { res.add([q]); }
      while (res.length < 3) { res.add([]); }
      return res;
    }

    final n = questions.length;
    final heights = questions.map((q) => _estimateHeight(q)).toList();

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

  static double _estimateHeight(QuestionTemplate q) {
    double h = 26.0;
    final rawText = q.questionText.trim();
    final (_, passage) = _splitQuestionPrompt(rawText);

    final imgUrl = (q is UniversalQuestion) ? q.questionImageUrl
        : (q is ReadingImageQuestion) ? q.imageAssetPath : null;

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

    List<String> textOpts = [];
    if (q is UniversalQuestion) { textOpts = q.textOptions; }
    else if (q is ReadingTextQuestion) { textOpts = q.textOptions; }
    else if (q is ReadingImageQuestion) { textOpts = q.textOptions; }
    else if (q is ListeningAudioQuestion) { textOpts = q.textOptions; }

    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');
    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);

    if (!hasNewlines && maxLen <= 11) {
      h += 20.0;
    } else if (!hasNewlines && maxLen <= 26) {
      h += 40.0;
    } else {
      h += 75.0;
    }

    h += 12.0;
    return h;
  }

  static String _esc(String? text) {
    if (text == null || text.isEmpty) return '';
    return const HtmlEscape().convert(text);
  }
}
