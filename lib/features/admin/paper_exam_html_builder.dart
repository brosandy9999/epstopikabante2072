import 'dart:convert';
import '../../core/models/mock_test_model.dart';
import '../question_engine/question_template.dart';

class PaperExamHtmlBuilder {
  static bool isChartOrNoticeQuestion(int qNo, QuestionTemplate q) {
    final rawImg = (q is UniversalQuestion)
        ? q.questionImageUrl
        : (q is ReadingImageQuestion)
            ? q.imageAssetPath
            : null;

    final imgUrl = cleanImageUrl(rawImg);
    if (imgUrl == null || imgUrl.isEmpty) {
      return false;
    }

    final text = q.questionText.toLowerCase();
    const chartKeywords = [
      '그래프', // graph
      '도표', // chart / pie chart / diagram
      '표', // chart / table / ticket
      '표지판', // signboard / notice
      '안내문', // notice board / announcement
      '영수증', // receipt
      '광고', // advertisement
      '신분증', // badge / ID
      '기차표', // train ticket
      '비행기표', // air ticket
      '시간표', // timetable
      '통계', // statistics
      '비율', // percentage/ratio
      '퍼센트', // percent
      '%',
    ];

    for (final kw in chartKeywords) {
      if (text.contains(kw)) return true;
    }

    if (qNo >= 9 && qNo <= 12) {
      return true;
    }

    return false;
  }

  static String? cleanImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty ||
        trimmed == 'null' ||
        trimmed == 'undefined' ||
        trimmed.endsWith('/null') ||
        trimmed.endsWith('/undefined')) {
      return null;
    }
    return trimmed;
  }

  static String buildExamHtml(
    MockTestSet testSet, {
    Map<String, String>? customQrCodes,
    String? customSectionQr,
    double imageScale = 1.0,
    double qrScale = 1.35,
    bool autoEnlargeCharts = true,
    Map<int, bool>? customChartOverrides,
    String? customInstituteName,
    String? customInstituteLogo,
    String? customInstituteInfo,
    String? customExamSubtitle,
  }) {
    final allQs = testSet.questions;

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
      imageScale: imageScale,
      qrScale: qrScale,
      autoEnlargeCharts: autoEnlargeCharts,
      customChartOverrides: customChartOverrides,
    );

    final institute = (customInstituteName != null && customInstituteName.trim().isNotEmpty)
        ? customInstituteName.trim()
        : (testSet.instituteName ?? 'Official Test Center');

    final returnHeader = '''<!DOCTYPE html>
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
      font-size: 13.5px;
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
      padding: 10mm 14mm 8mm 14mm;
      background: #ffffff;
      box-shadow: 0 8px 24px rgba(0,0,0,0.25);
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      position: relative;
      overflow: hidden;
    }
    .page-body {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
    }

    /* Running Header with Logo */
    .running-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1.5px solid #0f172a;
      padding-bottom: 4px;
      margin-bottom: 6px;
    }
    .running-header-left {
      display: flex;
      align-items: center;
      gap: 8px;
      flex: 1;
      overflow: hidden;
    }
    .header-mini-logo {
      height: 22px;
      width: auto;
      max-width: 38px;
      object-fit: contain;
      border-radius: 3px;
    }
    .running-header-title {
      font-size: 11px;
      font-weight: 700;
      color: #1e3a8a;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .running-header-sub {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 10px;
      color: #475569;
      font-weight: 600;
      flex-shrink: 0;
    }
    .header-inst-name {
      color: #0f172a;
      font-weight: 700;
    }

    /* Section Banner */
    .section-banner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #1e3a8a;
      color: #ffffff;
      padding: 5px 10px;
      border-radius: 4px;
      margin-bottom: 6px;
      gap: 10px;
    }
    .section-banner-content {
      flex: 1;
    }
    .section-banner-title {
      font-size: 12.5px;
      font-weight: 900;
    }
    .section-banner-desc {
      font-size: 10px;
      opacity: 0.9;
      margin-top: 1px;
    }
    .section-banner-qr {
      display: flex;
      flex-direction: column;
      align-items: center;
      background: #ffffff;
      border: 1.2px solid #cbd5e1;
      padding: 3px 5px;
      border-radius: 5px;
      flex-shrink: 0;
      box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    }
    .section-banner-qr img {
      width: ${(50 * qrScale).round()}px;
      height: ${(50 * qrScale).round()}px;
      object-fit: contain;
    }
    .banner-qr-label {
      font-size: ${(7.5 * qrScale.clamp(0.9, 1.25)).toStringAsFixed(1)}px;
      font-weight: 800;
      color: #1e3a8a;
      margin-top: 2px;
      white-space: nowrap;
    }

    /* Questions container - Continuous Flow, Uniform clean spacing */
    .questions-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
      flex: 1;
      justify-content: flex-start;
    }

    /* Question Item */
    .q-item {
      display: flex;
      flex-direction: column;
      gap: 3px;
      width: 100%;
    }
    .q-title-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 6px;
      width: 100%;
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
      font-size: 12px;
      font-weight: 900;
      min-width: 22px;
      height: 22px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 4px;
      flex-shrink: 0;
      margin-top: 1px;
    }
    .q-text {
      font-size: 13.5px;
      font-weight: 700;
      line-height: 1.45;
      color: #0f172a;
    }
    .q-qr-box {
      display: flex;
      flex-direction: column;
      align-items: center;
      background: #ffffff;
      border: 1.2px solid #cbd5e1;
      padding: 2px 4px;
      border-radius: 4px;
      flex-shrink: 0;
      margin-left: 6px;
      box-shadow: 0 1px 2px rgba(0,0,0,0.06);
    }
    .q-qr-box img {
      width: ${(44 * qrScale).round()}px;
      height: ${(44 * qrScale).round()}px;
      object-fit: contain;
    }
    .q-qr-label {
      font-size: ${(7.0 * qrScale.clamp(0.9, 1.25)).toStringAsFixed(1)}px;
      font-weight: 800;
      color: #1e3a8a;
      margin-top: 1px;
      white-space: nowrap;
    }

    /* Rounded corner rectangular border box - NO LEFT GAP */
    .material-box {
      border: 1.2px solid #0f172a;
      border-radius: 4px;
      background: #fafafa;
      padding: 5px 8px;
      margin: 2px 0;
      width: 100%;
    }
    .material-box.single-word {
      text-align: center;
      font-size: 13.5px;
      font-weight: 700;
      letter-spacing: 0.5px;
      padding: 5px 8px;
    }
    .material-box.paragraph {
      text-align: left;
      font-size: 13.5px;
      line-height: 1.5;
      color: #1e293b;
      white-space: pre-line;
      padding: 6px 8px;
      font-weight: 500;
    }
    .material-box.chart-box {
      margin: 2px 0;
      padding: 2px;
      text-align: center;
      background: #ffffff;
      border: 1.5px solid #1e3a8a;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 100%;
    }
    .material-box img {
      max-height: ${(195 * imageScale).round()}px;
      width: 100%;
      max-width: 100%;
      display: block;
      margin: 0 auto;
      object-fit: contain;
      border-radius: 3px;
    }
    .material-box.chart-box img {
      max-height: ${(220 * imageScale).round()}px;
      width: 100%;
      max-width: 100%;
      display: block;
      margin: 0 auto;
      object-fit: contain;
      border-radius: 3px;
    }

    /* Side-by-side layout for picture questions (Large Picture Left, Options Right, NO Left Gap) */
    .q-side-row {
      display: flex;
      align-items: center;
      gap: 14px;
      margin: 3px 0 0 0;
      width: 100%;
    }
    .q-side-media {
      flex: 0 0 ${(290 * imageScale).clamp(240, 360).round()}px;
      max-width: ${(310 * imageScale).clamp(260, 380).round()}px;
    }
    .q-side-media .material-box {
      margin: 0 !important;
      padding: 2px 4px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      background: #ffffff;
      border: 1.2px solid #0f172a;
    }
    .q-side-media img {
      max-height: ${(155 * imageScale).round()}px;
      max-width: 100%;
      width: 100%;
      object-fit: contain;
      margin: 0 auto;
      display: block;
      border-radius: 3px;
    }
    .q-side-options {
      flex: 1;
    }
    .q-side-options .options-container {
      margin-left: 0 !important;
      margin-top: 0 !important;
    }

    /* Options - Size 13.50 pt, Clean Alignment */
    .options-container {
      margin: 3px 0 0 0;
      width: 100%;
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
      font-size: 13.5px;
      line-height: 1.45;
      color: #1e293b;
    }
    .opt-num {
      font-size: 13.5px;
      font-weight: 800;
      color: #0f172a;
      flex-shrink: 0;
    }
    .opt-text {
      font-size: 13.5px;
      font-weight: 500;
      flex: 1;
    }

    /* Image options - Large, Crisp 4 Columns filling full width */
    .img-opts-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
      border: 1.2px solid #cbd5e1;
      padding: 6px;
      border-radius: 5px;
      margin: 3px 0 0 0;
      background: #f8fafc;
      width: 100%;
    }
    .img-opt-box {
      border: 1.2px solid #cbd5e1;
      border-radius: 4px;
      padding: 4px 2px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: space-between;
      height: ${(125 * imageScale).clamp(100, 155).round()}px;
      background: #ffffff;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .img-opt-box .opt-num {
      font-size: 13px;
      font-weight: 800;
      color: #1e3a8a;
      margin-bottom: 2px;
    }
    .img-opt-box img {
      max-height: ${(98 * imageScale).clamp(78, 125).round()}px;
      max-width: 100%;
      object-fit: contain;
    }

    /* Page Footer with Logo & Info */
    .pbt-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-top: 1px solid #cbd5e1;
      padding-top: 4px;
      font-size: 9.5px;
      color: #475569;
      margin-top: 4px;
    }
    .footer-left {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .footer-mini-logo {
      height: 18px;
      width: auto;
      max-width: 32px;
      object-fit: contain;
      border-radius: 2px;
    }
    .page-pill {
      font-size: 10px;
      font-weight: 700;
      border: 1px solid #cbd5e1;
      padding: 1px 8px;
      border-radius: 3px;
      color: #0f172a;
    }
    .footer-right {
      font-weight: 700;
      color: #0f172a;
    }

    /* End exam banner */
    .exam-end-banner {
      background: #0f172a;
      color: #ffffff;
      text-align: center;
      font-size: 11px;
      font-weight: 700;
      padding: 5px;
      border-radius: 4px;
      margin-top: 6px;
    }

    /* Cover Page 1 */
    .cover-inst-header {
      display: flex;
      align-items: center;
      gap: 18px;
      margin-bottom: 12px;
    }
    .inst-logo-box {
      width: 90px;
      height: 90px;
      border-radius: 8px;
      border: 2px solid #1e3a8a;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      background: #ffffff;
      flex-shrink: 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      padding: 4px;
    }
    .inst-logo-img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }
    .inst-logo-fallback {
      background: #1e3a8a;
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #ffffff;
    }
    .inst-logo-fallback .logo-icon {
      font-size: 32px;
      line-height: 1;
    }
    .inst-logo-fallback .logo-txt {
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 0.5px;
      margin-top: 2px;
    }
    .inst-meta {
      flex: 1;
    }
    .inst-kor-top {
      font-size: 11.5px;
      font-weight: 800;
      color: #1e3a8a;
      letter-spacing: 0.3px;
    }
    .inst-eng-sub {
      font-size: 9.5px;
      color: #64748b;
      margin-bottom: 3px;
    }
    .inst-name {
      font-size: 18px;
      font-weight: 900;
      color: #0f172a;
      letter-spacing: 0.5px;
      text-transform: uppercase;
      line-height: 1.25;
    }
    .inst-info {
      font-size: 10px;
      color: #475569;
      margin-top: 4px;
      line-height: 1.35;
      font-weight: 500;
    }
    .inst-pbt-badge {
      border: 2px solid #1e3a8a;
      border-radius: 6px;
      padding: 6px 12px;
      text-align: center;
      color: #1e3a8a;
      flex-shrink: 0;
      background: #eff6ff;
    }
    .inst-pbt-badge .pbt-b1 {
      font-size: 15px;
      font-weight: 900;
      line-height: 1.1;
    }
    .inst-pbt-badge .pbt-b2 {
      font-size: 11px;
      font-weight: 800;
      line-height: 1.1;
    }
    .cover-divider {
      height: 3px;
      background: #1e3a8a;
      border-bottom: 1.5px solid #0f172a;
      margin-bottom: 12px;
    }

    .cover-top {
      text-align: center;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 10px;
      margin-bottom: 12px;
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
      margin-top: 12px;
      margin-bottom: 8px;
    }
    .candidate-grid {
      display: grid;
      grid-template-columns: repeat(12, 1fr);
      gap: 8px;
      margin-bottom: 10px;
    }
    .form-box {
      border: 1.2px solid #0f172a;
      border-radius: 3px;
      padding: 6px 8px;
    }
    .form-label {
      font-size: 9px;
      font-weight: 700;
      color: #64748b;
      margin-bottom: 2px;
    }
    .form-line {
      height: 16px;
      font-size: 11px;
      font-weight: 700;
      color: #0f172a;
    }

    /* Rules */
    .rules-header {
      background: #1e3a8a;
      color: #ffffff;
      font-size: 11px;
      font-weight: 700;
      padding: 4px 10px;
      margin-top: 6px;
      margin-bottom: 6px;
    }
    .rules-box {
      border: 1.2px solid #cbd5e1;
      border-radius: 4px;
      padding: 8px 10px;
      background: #f8fafc;
      display: flex;
      flex-direction: column;
      gap: 5px;
    }
    .rule-item {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      font-size: 9.5px;
      color: #334155;
      line-height: 1.35;
    }
    .rule-num {
      background: #1e3a8a;
      color: #ffffff;
      border-radius: 50%;
      width: 14px;
      height: 14px;
      font-size: 8px;
      font-weight: 800;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      margin-top: 1px;
    }
    .sector-info {
      margin-top: 8px;
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 4px;
      padding: 6px 10px;
      font-size: 10px;
      font-weight: 700;
      color: #1e3a8a;
      text-align: center;
    }

    @media print {
      body {
        background: none !important;
        color: #000000 !important;
      }
      .print-bar { display: none !important; }
      .page-container {
        padding: 0 !important;
        gap: 0 !important;
      }
      .pbt-page {
        box-shadow: none !important;
        margin: 0 !important;
        page-break-after: always !important;
        break-after: page !important;
        padding: 8mm 12mm 6mm 12mm !important;
      }
    }
  </style>
</head>
<body>
  <div class="print-bar">
    <button class="btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
    <button class="btn btn-secondary" onclick="window.close()">✕ Close</button>
  </div>
  <div class="page-container">
    ${_buildCoverPageHtml(
      testSet,
      institute: institute,
      logoUrl: customInstituteLogo,
      instituteInfo: customInstituteInfo,
      examSubtitle: customExamSubtitle,
    )}
''';

    final sb = StringBuffer(returnHeader);
    int currentQIndex = 0;

    for (int p = 0; p < pages.length; p++) {
      final pageQuestions = pages[p];
      final pageNum = p + 2; // Cover is page 1
      final isLast = (p == pages.length - 1);

      sb.writeln(_buildContinuousQPageHtml(
        testSet: testSet,
        pageQuestions: pageQuestions,
        startQuestionIndex: currentQIndex,
        listeningStartIndex: listeningStartIndex,
        pageNum: pageNum,
        institute: institute,
        logoUrl: customInstituteLogo,
        isLastPage: isLast,
        qrCodes: customQrCodes,
        sectionQrUrl: effectiveSectionQr,
        imageScale: imageScale,
        autoEnlargeCharts: autoEnlargeCharts,
        customChartOverrides: customChartOverrides,
      ));

      currentQIndex += pageQuestions.length;
    }

    sb.writeln('''
  </div>
</body>
</html>
''');
    return sb.toString();
  }

  static String _buildCoverPageHtml(
    MockTestSet testSet, {
    required String institute,
    String? logoUrl,
    String? instituteInfo,
    String? examSubtitle,
  }) {
    final sub = (examSubtitle != null && examSubtitle.trim().isNotEmpty)
        ? examSubtitle.trim()
        : '${testSet.sector} • 일반 수험자용 문제지';

    return '''
    <div class="pbt-page">
      <div>
        <div class="cover-inst-header">
          <div class="inst-logo-box">
            ${(logoUrl != null && logoUrl.trim().isNotEmpty)
                ? '<img src="$logoUrl" class="inst-logo-img" alt="Logo" />'
                : '<div class="inst-logo-fallback"><div class="logo-icon">🏢</div><div class="logo-txt">HRD</div></div>'}
          </div>
          <div class="inst-meta">
            <div class="inst-kor-top">한국산업인력공단 (EPS-TOPIK)</div>
            <div class="inst-eng-sub">Employment Permit System — Test of Proficiency in Korean</div>
            <div class="inst-name">${_esc(institute.toUpperCase())}</div>
            ${(instituteInfo != null && instituteInfo.trim().isNotEmpty)
                ? '<div class="inst-info">${_esc(instituteInfo.trim())}</div>'
                : ''}
          </div>
          <div class="inst-pbt-badge">
            <div class="pbt-b1">PBT</div>
            <div class="pbt-b2">문제지</div>
          </div>
        </div>

        <div class="cover-divider"></div>

        <div class="cover-top">
          <div class="cover-badge">EPS-TOPIK PBT 시험 문제지</div>
          <div class="cover-title">${_esc(testSet.title)}</div>
          <div class="cover-subtitle">${_esc(sub)}</div>
          <div class="cover-specs">읽기 20문항 + 듣기 20문항  |  시험시간: 50분  |  100점 만점</div>
        </div>

        <div class="candidate-header">수험자 인적 사항 (Candidate Information)</div>
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

        <div class="rules-header">수험자 유의사항 (Exam Rules / परीक्षार्थीका लागि नियमहरू)</div>
        <div class="rules-box">
          <div class="rule-item"><div class="rule-num">1</div><div>시험 시작 전에는 문제지를 펼치지 마십시오. / परीक्षा सुरु हुनुभन्दा अघि प्रश्नपत्र नखोल्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">2</div><div>답안은 반드시 컴퓨터용 사인펜(검정색)으로 작성하십시오. / उत्तरहरू OMR पानामा कालो मसीले भर्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">3</div><div>총 40문항 (읽기 20문항 + 듣기 20문항), 시험시간 50분 / कुल ४० प्रश्न, ५० मिनेट समय।</div></div>
          <div class="rule-item"><div class="rule-num">4</div><div>부정행위자는 퇴실 조치되며 시험이 무효 처리됩니다. / चिट चोर्ने वा नियम उल्लंघन गर्नेको परीक्षा रद्द हुनेछ।</div></div>
          <div class="rule-item"><div class="rule-num">5</div><div>듣기 문제는 방송을 잘 듣고 답을 작성하십시오. / सुनाइ खण्डको अडियो ध्यान दिएर सुन्नुहोस्।</div></div>
          <div class="rule-item"><div class="rule-num">6</div><div>시험 종료 후 문제지와 답안지를 모두 제출하십시오. / परीक्षा सकिएपछि प्रश्नपत्र र OMR दुवै बुझाउनुहोस्।</div></div>
        </div>

        <div class="sector-info">
          선택 직종 (Sector): ${_esc(testSet.sector)}  •  ${_esc(testSet.description)}
        </div>
      </div>

      <div class="pbt-footer">
        <div class="footer-left">
          ${(logoUrl != null && logoUrl.trim().isNotEmpty)
              ? '<img src="$logoUrl" class="footer-mini-logo" alt="Logo" />'
              : ''}
          <span>EPS-TOPIK PBT  |  한국산업인력공단</span>
        </div>
        <div class="page-pill">- 1 -</div>
        <div class="footer-right">${_esc(institute)}</div>
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
    String? logoUrl,
    bool isLastPage = false,
    Map<String, String>? qrCodes,
    String? sectionQrUrl,
    double imageScale = 1.0,
    bool autoEnlargeCharts = true,
    Map<int, bool>? customChartOverrides,
  }) {
    final effectiveSectionQr = sectionQrUrl ?? testSet.listeningSectionQrUrl;

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
    sb.writeln('<div class="page-body">');

    sb.writeln('''
      <div class="running-header">
        <div class="running-header-left">
          ${(logoUrl != null && logoUrl.trim().isNotEmpty)
              ? '<img src="$logoUrl" class="header-mini-logo" alt="Logo" />'
              : ''}
          <span class="running-header-title">${_esc(testSet.title)}</span>
        </div>
        <div class="running-header-sub">
          <span>$sectionTitle</span>
          <span>•</span>
          <span class="header-inst-name">${_esc(institute)}</span>
        </div>
      </div>
    ''');

    sb.writeln('<div class="questions-list">');
    for (int i = 0; i < pageQuestions.length; i++) {
      final q = pageQuestions[i];
      final globalIdx = startQuestionIndex + i;
      final qNo = globalIdx + 1;

      // 1. Reading Section Start Banner
      if (globalIdx == 0) {
        sb.writeln('''
          <div class="section-banner">
            <div class="section-banner-content">
              <div class="section-banner-title">읽기 영역 (Reading) : 1번 ~ $listeningStartIndex번 / 50점</div>
              <div class="section-banner-desc">다음을 읽고 알맞은 것을 ①②③④ 중에서 고르십시오.</div>
            </div>
          </div>
        ''');
      }

      // 2. Listening Section Start Banner
      if (globalIdx == listeningStartIndex) {
        sb.writeln('''
          <div class="section-banner" style="margin-top: ${i == 0 ? 0 : 6}px; margin-bottom: 6px;">
            <div class="section-banner-content">
              <div class="section-banner-title">듣기 영역 (Listening) : ${listeningStartIndex + 1}번 ~ ${testSet.questions.length}번 / 50점</div>
              <div class="section-banner-desc">다음을 듣고 알맞은 것을 ①②③④ 중에서 고르십시오.</div>
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

      sb.writeln(_buildSingleQuestionHtml(
        qNo,
        q,
        qrCodeUrl: qQr,
        imageScale: imageScale,
        autoEnlargeCharts: autoEnlargeCharts,
        customChartOverrides: customChartOverrides,
      ));
    }
    sb.writeln('</div>'); // questions-list

    if (isLastPage) {
      sb.writeln('''
        <div class="exam-end-banner">
          ★ 이상으로 문제가 끝났습니다.  •  परीक्षाका सबै प्रश्नहरू यहाँ समाप्त हुन्छन्। ★
        </div>
      ''');
    }

    sb.writeln('</div>'); // page-body

    sb.writeln('''
      <div class="pbt-footer">
        <div class="footer-left">
          ${(logoUrl != null && logoUrl.trim().isNotEmpty)
              ? '<img src="$logoUrl" class="footer-mini-logo" alt="Logo" />'
              : ''}
          <span>EPS-TOPIK PBT  |  한국산업인력공단</span>
        </div>
        <div class="page-pill">- $pageNum -</div>
        <div class="footer-right">${_esc(institute)}</div>
      </div>
    ''');

    sb.writeln('</div>'); // pbt-page
    return sb.toString();
  }

  static String _buildSingleQuestionHtml(
    int no,
    QuestionTemplate q, {
    String? qrCodeUrl,
    double imageScale = 1.0,
    bool autoEnlargeCharts = true,
    Map<int, bool>? customChartOverrides,
  }) {
    final rawText = q.questionText.trim();
    final (qText, rawPassage) = _splitQuestionPrompt(rawText);
    final passage = (rawPassage != null && rawPassage.trim().isNotEmpty) ? rawPassage.trim() : null;

    final rawImg = (q is UniversalQuestion)
        ? q.questionImageUrl
        : (q is ReadingImageQuestion)
            ? q.imageAssetPath
            : null;
    final imgUrl = cleanImageUrl(rawImg);
    final bool hasValidImg = (imgUrl != null && imgUrl.isNotEmpty);

    List<String> textOpts = [];
    List<String?> imgOpts = [];
    if (q is UniversalQuestion) {
      textOpts = List<String>.from(q.textOptions);
      imgOpts = q.imageOptions;
    } else if (q is ReadingTextQuestion) {
      textOpts = List<String>.from(q.textOptions);
    } else if (q is ReadingImageQuestion) {
      textOpts = List<String>.from(q.textOptions);
    } else if (q is ListeningAudioQuestion) {
      textOpts = List<String>.from(q.textOptions);
    } else if (q is ListeningImageOptionsQuestion) {
      imgOpts = q.imageOptionPaths;
    }

    final bool hasImageOpts = imgOpts.isNotEmpty && imgOpts.any((x) => cleanImageUrl(x) != null);
    
    final bool isChartNotice = (customChartOverrides != null && customChartOverrides[no] != null)
        ? customChartOverrides[no]!
        : (autoEnlargeCharts && hasValidImg && isChartOrNoticeQuestion(no, q));
        
    final bool isSideBySide = !isChartNotice && hasValidImg && !hasImageOpts && (passage == null || passage.length <= 60);
    final bool hasMaterial = (passage != null && passage.isNotEmpty) || hasValidImg;

    final bool isSingleWord = passage != null &&
        !passage.contains('\n') &&
        !passage.contains('가:') &&
        !passage.contains('나:') &&
        passage.length <= 35;

    final sb = StringBuffer();
    sb.writeln('<div class="q-item">');

    // Title Row
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
      // ── Side-by-Side Layout: Picture Left (Large & Crisp), Options Right (NO Left Gap) ──
      sb.writeln('<div class="q-side-row">');
      sb.writeln('<div class="q-side-media">');
      sb.writeln('<div class="material-box">');
      sb.writeln('<img src="${_esc(imgUrl)}" alt="Question Image" />');
      sb.writeln('</div>');
      sb.writeln('</div>');

      sb.writeln('<div class="q-side-options">');
      sb.writeln(_buildTextOptionsHtml(textOpts, isSideBySide: true));
      sb.writeln('</div>');
      sb.writeln('</div>');
    } else {
      // ── Stacked Layout: ONLY render boxes if valid passage or valid image exists (NO empty box!) ──
      if (hasMaterial) {
        // 1. Passage box (ZERO left gap, font-size 13.5px)
        if (passage != null && passage.isNotEmpty) {
          final pClass = isSingleWord ? 'material-box single-word' : 'material-box paragraph';
          sb.writeln('<div class="$pClass">');
          sb.writeln(_esc(passage));
          sb.writeln('</div>');
        }
        // 2. Image box (Large, crisp, ONLY when image exists)
        if (hasValidImg) {
          final boxClass = isChartNotice ? 'material-box chart-box' : 'material-box';
          sb.writeln('<div class="$boxClass">');
          sb.writeln('<img src="${_esc(imgUrl)}" alt="Question Image" />');
          sb.writeln('</div>');
        }
      }

      // Options Rendering
      if (hasImageOpts) {
        sb.writeln('<div class="img-opts-grid">');
        const nums = ['①', '②', '③', '④'];
        for (int i = 0; i < 4; i++) {
          final rawOptImg = i < imgOpts.length ? imgOpts[i] : null;
          final optImg = cleanImageUrl(rawOptImg);
          sb.writeln('''
            <div class="img-opt-box">
              <span class="opt-num">${nums[i]}</span>
              ${optImg != null ? '<img src="${_esc(optImg)}" alt="Option $i" />' : '<span style="color:#94a3b8;font-size:11px;">(선택지 $i)</span>'}
            </div>
          ''');
        }
        sb.writeln('</div>');
      } else {
        // ALWAYS display 4 options clearly
        sb.writeln(_buildTextOptionsHtml(textOpts, isSideBySide: false));
      }
    }

    sb.writeln('</div>'); // q-item
    return sb.toString();
  }

  static String _buildTextOptionsHtml(List<String> textOpts, {bool isSideBySide = false}) {
    const nums = ['①', '②', '③', '④'];
    final rawCleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');
    
    // If all text options are empty (e.g. audio-only options), fallback to ( 1 ), ( 2 ), ( 3 ), ( 4 )
    final bool allEmpty = rawCleaned.every((o) => o.isEmpty);
    final List<String> cleaned = allEmpty
        ? ['( 1 )', '( 2 )', '( 3 )', '( 4 )']
        : rawCleaned;

    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
    final totalLen = cleaned.fold<int>(0, (sum, o) => sum + o.length);
    final count = cleaned.where((o) => o.isNotEmpty).length;

    int colCount = 1;
    if (isSideBySide) {
      if (!hasNewlines && count == 4 && maxLen <= 16 && totalLen <= 56) {
        colCount = 2;
      } else {
        colCount = 1;
      }
    } else {
      if (!hasNewlines && count > 0) {
        if (count == 4 && maxLen <= 14 && totalLen <= 48) {
          colCount = 4;
        } else if (maxLen <= 28 && totalLen <= 96) {
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
      final optText = cleaned[i];
      if (optText.isEmpty) continue;
      sb.writeln('''
        <div class="opt-item">
          <span class="opt-num">${nums[i]}</span>
          <span class="opt-text">${_esc(optText)}</span>
        </div>
      ''');
    }
    sb.writeln('</div>');
    return sb.toString();
  }

  static (String, String?) _splitQuestionPrompt(String rawText) {
    var text = rawText.trim();
    text = text.replaceFirst(RegExp(r'^\[?\d{1,2}\]?[.\s-]*'), '').trim();
    text = text.replaceAll(RegExp(r'^\s*\[?\d{1,2}\]?[번\s]*(?:문제|번)?[.\s-]*$', multiLine: true), '').trim();

    if (text.contains('\n')) {
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) return ('', null);

      final cleanedLines = lines.where((l) => !RegExp(r'^\s*\[?\d{1,2}\]?[번\s]*(?:문제|번)?[.\s-]*$').hasMatch(l)).toList();
      if (cleanedLines.isEmpty) return ('', null);

      final promptLines = <String>[];
      final passageLines = <String>[];
      bool inPassage = false;

      for (int i = 0; i < cleanedLines.length; i++) {
        final line = cleanedLines[i];
        if (line.startsWith('[보기]') || line.startsWith('<보기>')) {
          inPassage = true;
          final cleanP = line.replaceFirst(RegExp(r'^\[보기\]|<보기>'), '').trim();
          if (cleanP.isNotEmpty) passageLines.add(cleanP);
          continue;
        }

        if (inPassage) {
          passageLines.add(line);
        } else if (i == 0 ||
            line.endsWith('고르십시오.') ||
            line.endsWith('무엇입니까?') ||
            line.endsWith('답하십시오.') ||
            line.endsWith('맞는 것은?') ||
            line.endsWith('알맞은 것은?') ||
            line.endsWith('알맞은 것을?') ||
            (line.startsWith('[') && line.endsWith(']'))) {
          promptLines.add(line);
        } else {
          passageLines.add(line);
        }
      }

      final prompt = promptLines.isNotEmpty ? promptLines.join(' ') : cleanedLines.first;
      final passage = passageLines.isNotEmpty ? passageLines.join('\n') : null;
      return (prompt, passage);
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
    double imageScale = 1.0,
    double qrScale = 1.35,
    bool autoEnlargeCharts = true,
    Map<int, bool>? customChartOverrides,
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
    final heights = questions.asMap().entries.map((e) => _estimateHeight(
      e.value,
      e.key + 1,
      imageScale: imageScale,
      qrScale: qrScale,
      autoEnlargeCharts: autoEnlargeCharts,
      customChartOverrides: customChartOverrides,
    )).toList();

    const pageBudget = 980.0;
    final targetCount = n / 7.0;

    double pageCost(int i, int j, int p) {
      if (j <= i) return 1e9;
      double h = 0;
      for (int k = i; k < j; k++) {
        h += heights[k];
      }
      if (p == 0 && listeningStartIndex > 0) {
        h += 38.0;
      }
      if (i <= listeningStartIndex && listeningStartIndex < j && listeningStartIndex > 0) {
        h += (hasSectionQr ? (48.0 + 16.0 * qrScale) : 44.0);
      }
      if (p == 6) {
        h += 26.0;
      }

      final count = j - i;
      final countDiff = count - targetCount;
      double penalty = countDiff * countDiff * 120.0;

      if (h > pageBudget) {
        final overflow = h - pageBudget;
        penalty += 100000.0 + overflow * 5000.0;
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

  static double _estimateHeight(
    QuestionTemplate q,
    int qNo, {
    double imageScale = 1.0,
    double qrScale = 1.35,
    bool autoEnlargeCharts = true,
    Map<int, bool>? customChartOverrides,
  }) {
    double h = 24.0;
    final rawText = q.questionText.trim();
    final (qText, passage) = _splitQuestionPrompt(rawText);

    final rawImg = (q is UniversalQuestion)
        ? q.questionImageUrl
        : (q is ReadingImageQuestion)
            ? q.imageAssetPath
            : null;
    final imgUrl = cleanImageUrl(rawImg);
    final bool hasValidImg = (imgUrl != null && imgUrl.isNotEmpty);

    List<String> textOpts = [];
    List<String?> imgOpts = [];
    if (q is UniversalQuestion) {
      textOpts = q.textOptions;
      imgOpts = q.imageOptions;
    } else if (q is ReadingTextQuestion) {
      textOpts = q.textOptions;
    } else if (q is ReadingImageQuestion) {
      textOpts = q.textOptions;
    } else if (q is ListeningAudioQuestion) {
      textOpts = q.textOptions;
    } else if (q is ListeningImageOptionsQuestion) {
      imgOpts = q.imageOptionPaths;
    }

    final bool hasImageOpts = imgOpts.isNotEmpty && imgOpts.any((x) => cleanImageUrl(x) != null);
    final bool isChartNotice = (customChartOverrides != null && customChartOverrides[qNo] != null)
        ? customChartOverrides[qNo]!
        : (autoEnlargeCharts && hasValidImg && isChartOrNoticeQuestion(qNo, q));
    final bool isSideBySide = !isChartNotice && hasValidImg && !hasImageOpts && (passage == null || passage.length <= 60);

    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');
    final hasNewlines = cleaned.any((o) => o.contains('\n'));
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);

    if (qText.length > 45) {
      h += 16.0;
    }

    if (isSideBySide) {
      final double optionsH = (!hasNewlines && maxLen <= 10) ? 42.0 : 80.0;
      final mediaH = 135.0 * imageScale;
      h += (optionsH > mediaH ? optionsH : mediaH) + 4.0;
    } else {
      final bool hasMaterial = (passage != null && passage.isNotEmpty) || hasValidImg;
      if (hasMaterial) {
        h += 8.0;
        if (passage != null && passage.isNotEmpty) {
          final lines = (passage.length / 45.0).ceil();
          h += lines * 18.0;
        }
        if (hasValidImg) {
          h += isChartNotice ? (165.0 * imageScale) : (115.0 * imageScale);
        }
      }

      if (hasImageOpts) {
        h += 135.0 * imageScale;
      } else {
        if (!hasNewlines && maxLen <= 14) {
          h += 22.0;
        } else if (!hasNewlines && maxLen <= 28) {
          h += 42.0;
        } else {
          h += 84.0;
        }
      }
    }

    final bool isListeningQ = (q is UniversalQuestion && q.isListening) ||
        (q is ListeningAudioQuestion) ||
        (q is ListeningImageOptionsQuestion) ||
        (qNo >= 21);
    if (isListeningQ) {
      final qrMinH = (44.0 * qrScale) + 12.0;
      if (h < qrMinH) {
        h = qrMinH;
      }
    }

    h += 8.0;
    return h;
  }

  static String _esc(String? text) {
    if (text == null || text.isEmpty) return '';
    return const HtmlEscape().convert(text);
  }
}
