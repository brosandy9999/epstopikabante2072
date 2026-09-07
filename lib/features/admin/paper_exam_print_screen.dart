import 'package:flutter/material.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/file_upload_web.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/question_bank_service.dart';
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
  late MockTestSet _currentSet;
  late Map<String, String> _questionQrCodes;
  String? _listeningSectionQrUrl;

  // Image scaling & chart customization for PBT PDF booklet
  double _imageScale = 1.0;
  bool _autoEnlargeCharts = true;
  final Map<int, bool> _customChartOverrides = {};

  // Custom institute branding for Cover Page (Page 1) & Footers
  late String _instituteName;
  String? _instituteLogo;
  String _instituteInfo = '';
  String _examSubtitle = '';

  @override
  void initState() {
    super.initState();
    _currentSet = widget.testSet;
    _listeningSectionQrUrl = widget.testSet.listeningSectionQrUrl;
    _questionQrCodes = Map<String, String>.from(widget.testSet.listeningQrCodes ?? {});

    // Also check individual UniversalQuestion.questionQrCodeUrl
    final qs = widget.testSet.questions;
    for (int i = 20; i < qs.length && i < 40; i++) {
      final q = qs[i];
      final qNum = '${i + 1}';
      if (!_questionQrCodes.containsKey(qNum) || _questionQrCodes[qNum]!.trim().isEmpty) {
        if (q is UniversalQuestion && q.questionQrCodeUrl != null && q.questionQrCodeUrl!.trim().isNotEmpty) {
          _questionQrCodes[qNum] = q.questionQrCodeUrl!.trim();
        }
      }
    }

    // Initialize institute branding
    final user = AuthService.instance.currentUser;
    final instId = user?.instituteId ?? 'inst_01';
    final profile = InstituteService.instance.getInstituteById(instId) ??
        InstituteService.instance.getDefaultInstitute();

    _instituteName = widget.testSet.instituteName ?? user?.instituteName ?? profile.name;
    final userLogo = user?.instituteLogo;
    _instituteLogo = (profile.logoUrl.isNotEmpty && !profile.logoUrl.contains('institute_logo_default.png'))
        ? profile.logoUrl
        : (userLogo != null && userLogo.isNotEmpty && !userLogo.contains('institute_logo_default.png'))
            ? userLogo
            : null;

    final contactParts = <String>[];
    if (profile.address.trim().isNotEmpty) contactParts.add(profile.address.trim());
    if (profile.phone.trim().isNotEmpty) contactParts.add('Tel: ${profile.phone.trim()}');
    if (profile.email.trim().isNotEmpty) contactParts.add(profile.email.trim());
    _instituteInfo = contactParts.join('  •  ');
    _examSubtitle = '${widget.testSet.sector}  •  공식 지필시험 형태 문제지';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _configuredQrCount => _questionQrCodes.values.where((v) => v.trim().isNotEmpty).length;

  void _triggerPrint() {
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    if (!isSuperAdmin && !_currentSet.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 सुपर एडमिनको स्वीकृति बिना यो प्रश्नपत्र डाउनलोड गर्न मिल्दैन।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final htmlContent = PaperExamHtmlBuilder.buildExamHtml(
      _currentSet,
      customQrCodes: _questionQrCodes,
      customSectionQr: _listeningSectionQrUrl,
      imageScale: _imageScale,
      autoEnlargeCharts: _autoEnlargeCharts,
      customChartOverrides: _customChartOverrides,
      customInstituteName: _instituteName,
      customInstituteLogo: _instituteLogo,
      customInstituteInfo: _instituteInfo,
      customExamSubtitle: _examSubtitle,
    );
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
    if (!isSuperAdmin && !_currentSet.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 सुपर एडमिनको स्वीकृति बिना यो प्रश्नपत्र खोल्न मिल्दैन।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final htmlContent = PaperExamHtmlBuilder.buildExamHtml(
      _currentSet,
      customQrCodes: _questionQrCodes,
      customSectionQr: _listeningSectionQrUrl,
      imageScale: _imageScale,
      autoEnlargeCharts: _autoEnlargeCharts,
      customChartOverrides: _customChartOverrides,
      customInstituteName: _instituteName,
      customInstituteLogo: _instituteLogo,
      customInstituteInfo: _instituteInfo,
      customExamSubtitle: _examSubtitle,
    );
    openExamInNewTab(htmlContent);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌐 नयाँ ट्याबमा ८ पृष्ठको PBT प्रश्नपत्र खुल्यो। त्यहाँ माथिको Print बटनबाट PDF save गर्न सक्नुहुन्छ।'),
        backgroundColor: Color(0xFF1E3A8A),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openListeningQrManagerDialog() async {
    final tempQrMap = Map<String, String>.from(_questionQrCodes);
    String? tempSectionQr = _listeningSectionQrUrl;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final listeningQuestions = _currentSet.questions.skip(20).take(20).toList();
            final count = tempQrMap.values.where((v) => v.trim().isNotEmpty).length;

            return Dialog(
              backgroundColor: const Color(0xFF0F172A),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 900,
                height: 750,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                          ),
                          child: const Icon(Icons.qr_code_2, color: Color(0xFF60A5FA), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🎧 लिसनिङ अडियो QR कोड व्यवस्थापन (Listening Audio QR Manager)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PBT PDF मा प्रत्येक लिसनिङ प्रश्न (२१–४०) वा पेज ६ को ब्यानरमा अडियो सुन्न मिल्ने QR कोड फोटो पेस्ट वा अपलोड गर्नुहोस्।',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'सेट भएका QR: $count / 20',
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ─── MASTER SECTION QR ───
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.library_music, color: Color(0xFF38BDF8), size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '📢 समग्र लिसनिङ QR (Master Listening QR — Page 6 Banner)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (tempSectionQr != null && tempSectionQr!.isNotEmpty) ...[
                                        TextButton.icon(
                                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
                                          icon: const Icon(Icons.copy_all, size: 16),
                                          label: const Text('सबै प्रश्नमा (२१–४०) यही QR लागू गर्नुहोस्', style: TextStyle(fontSize: 11)),
                                          onPressed: () {
                                            for (int i = 21; i <= 40; i++) {
                                              tempQrMap['$i'] = tempSectionQr!;
                                            }
                                            setModalState(() {});
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✅ समग्र QR २१ देखि ४० सम्मका सबै प्रश्नमा कपी गरियो!'),
                                                  backgroundColor: Color(0xFF16A34A),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          tooltip: 'समग्र QR हटाउनुहोस्',
                                          onPressed: () => setModalState(() => tempSectionQr = null),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'यो QR कोड Page 6 को Listening ब्यानर दायाँपट्टी "전체 듣기 (Full Audio)" को रूपमा देखिनेछ।',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Preview box
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade600),
                                        ),
                                        alignment: Alignment.center,
                                        child: (tempSectionQr != null && tempSectionQr!.isNotEmpty)
                                            ? SmartImageWidget(imageSource: tempSectionQr!, fit: BoxFit.contain)
                                            : Icon(Icons.qr_code_2, color: Colors.grey.shade400, size: 36),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              ),
                                              icon: const Icon(Icons.content_paste, size: 16),
                                              label: const Text('📋 क्लिपबोर्डबाट फोटो पेस्ट (Ctrl+V)', style: TextStyle(fontSize: 12)),
                                              onPressed: () async {
                                                final res = await FileUploadService.instance.pasteImageFromClipboard();
                                                if (res != null && res.dataUrl.isNotEmpty) {
                                                  setModalState(() => tempSectionQr = res.dataUrl);
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('⚠️ क्लिपबोर्डमा कुनै फोटो फेला परेन। पहिले QR फोटो Copy (Ctrl+C) गर्नुहोस्।'),
                                                        backgroundColor: Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: const BorderSide(color: Colors.white38),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              ),
                                              icon: const Icon(Icons.upload_file, size: 16),
                                              label: const Text('📁 फोटो छान्नुहोस् (Upload)', style: TextStyle(fontSize: 12)),
                                              onPressed: () async {
                                                final res = await FileUploadService.instance.pickImageFile();
                                                if (res != null && res.dataUrl.isNotEmpty) {
                                                  setModalState(() => tempSectionQr = res.dataUrl);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── PER-QUESTION LISTENING QRs (Q21 to Q40) ───
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🎯 प्रत्येक लिसनिङ प्रश्नको QR कोड (Questions 21 – 40)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'प्रत्येक प्रश्नको आफ्नै QR भएमा सोही प्रश्नको टाइटल दायाँपट्टी प्रिन्ट हुनेछ।',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            ...List.generate(listeningQuestions.length, (idx) {
                              final qNo = 21 + idx;
                              final q = listeningQuestions[idx];
                              final qNumStr = '$qNo';
                              final currentQr = tempQrMap[qNumStr];
                              final hasQr = currentQr != null && currentQr.trim().isNotEmpty;

                              // Extract question title snippet
                              String titleSnippet = q.questionText.trim();
                              if (titleSnippet.contains('\n')) {
                                titleSnippet = titleSnippet.split('\n').first.trim();
                              }
                              titleSnippet = titleSnippet.replaceFirst(RegExp(r'^\[?\d{1,2}\]?[.\s-]*'), '').trim();
                              if (titleSnippet.length > 55) {
                                titleSnippet = '${titleSnippet.substring(0, 52)}...';
                              }

                              final String? audioUrl = (q is UniversalQuestion)
                                  ? q.questionAudioUrl
                                  : (q is ListeningAudioQuestion)
                                      ? q.audioAssetPath
                                      : (q is ListeningImageOptionsQuestion)
                                          ? q.audioAssetPath
                                          : null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: hasQr ? const Color(0xFF1E293B) : const Color(0xFF141E33),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasQr ? const Color(0xFF2563EB).withValues(alpha: 0.6) : const Color(0xFF1E293B),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Question Number Badge
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: hasQr ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$qNo',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Snippet
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titleSnippet,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (audioUrl != null && audioUrl.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '🎵 $audioUrl',
                                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // QR Thumbnail preview
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: hasQr ? Colors.blueAccent : Colors.grey.shade600),
                                      ),
                                      alignment: Alignment.center,
                                      child: hasQr
                                          ? SmartImageWidget(imageSource: currentQr, fit: BoxFit.contain)
                                          : Icon(Icons.qr_code, color: Colors.grey.shade400, size: 24),
                                    ),
                                    const SizedBox(width: 10),

                                    // Action buttons
                                    // 1. Paste from clipboard
                                    IconButton(
                                      icon: const Icon(Icons.content_paste, size: 18, color: Color(0xFF60A5FA)),
                                      tooltip: 'क्लिपबोर्डबाट फोटो पेस्ट (Ctrl+V)',
                                      onPressed: () async {
                                        final res = await FileUploadService.instance.pasteImageFromClipboard();
                                        if (res != null && res.dataUrl.isNotEmpty) {
                                          setModalState(() => tempQrMap[qNumStr] = res.dataUrl);
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('⚠️ Q$qNo को लागि क्लिपबोर्डमा कुनै फोटो फेला परेन। पहिले QR फोटो Copy (Ctrl+C) गर्नुहोस्।'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    // 2. Upload file
                                    IconButton(
                                      icon: const Icon(Icons.upload_file, size: 18, color: Colors.white70),
                                      tooltip: 'फोटो फाइल अपलोड गर्नुहोस्',
                                      onPressed: () async {
                                        final res = await FileUploadService.instance.pickImageFile();
                                        if (res != null && res.dataUrl.isNotEmpty) {
                                          setModalState(() => tempQrMap[qNumStr] = res.dataUrl);
                                        }
                                      },
                                    ),
                                    // 3. Auto generate QR if audioUrl exists
                                    if (audioUrl != null && audioUrl.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFFFBBF24)),
                                        tooltip: 'अडियो लिंकबाट स्वचालित QR कोड सिर्जना गर्नुहोस्',
                                        onPressed: () {
                                          final genUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(audioUrl)}';
                                          setModalState(() => tempQrMap[qNumStr] = genUrl);
                                        },
                                      ),
                                    // 4. Delete
                                    if (hasQr)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        tooltip: 'QR हटाउनुहोस्',
                                        onPressed: () => setModalState(() => tempQrMap.remove(qNumStr)),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),

                    // Dialog Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💡 नोट: तपाईंले यहाँ थपेका QR कोडहरू सिधै PDF प्रिन्ट र प्रश्न सेटमा सुरक्षित हुनेछन्।',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () => Navigator.pop(modalCtx),
                              child: const Text('रद्द गर्नुहोस् (Cancel)'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('💾 सुरक्षित गरी PDF मा लागू गर्नुहोस् (Save & Apply)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() {
                                  _questionQrCodes = tempQrMap;
                                  _listeningSectionQrUrl = tempSectionQr;

                                  // Update questions in _currentSet
                                  final updatedQuestions = List<QuestionTemplate>.from(_currentSet.questions);
                                  for (int i = 20; i < updatedQuestions.length && i < 40; i++) {
                                    final qNumStr = '${i + 1}';
                                    final qr = _questionQrCodes[qNumStr];
                                    final orig = updatedQuestions[i];
                                    if (orig is UniversalQuestion) {
                                      updatedQuestions[i] = orig.copyWith(questionQrCodeUrl: qr ?? '');
                                    }
                                  }

                                  _currentSet = _currentSet.copyWith(
                                    listeningSectionQrUrl: _listeningSectionQrUrl,
                                    listeningQrCodes: _questionQrCodes,
                                    questions: updatedQuestions,
                                  );
                                });

                                // Persist to QuestionBankService custom sets
                                QuestionBankService.instance.updateMockSet(_currentSet);

                                Navigator.pop(modalCtx);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ लिसनिङ QR कोडहरू सफलतापूर्वक सुरक्षित गरियो र PDF मा लागू भयो!'),
                                    backgroundColor: Color(0xFF16A34A),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openImageSizeDialog() async {
    double tempScale = _imageScale;
    bool tempAutoEnlarge = _autoEnlargeCharts;
    final tempOverrides = Map<int, bool>.from(_customChartOverrides);

    // Identify candidate questions (Q5-Q10 or chart/notice keywords)
    final allQs = _currentSet.questions;
    final candidateIndices = <int>[];
    for (int i = 0; i < allQs.length && i < 20; i++) {
      final qNo = i + 1;
      if (PaperExamHtmlBuilder.isChartOrNoticeQuestion(qNo, allQs[i])) {
        candidateIndices.add(qNo);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
                padding: const EdgeInsets.all(24),
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
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.photo_size_select_large, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🖼️ फोटो / चित्रको साइज समायोजन',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Image Scaling & Chart Settings (PBT PDF)',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Chart / Notice Enlarge Switch
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  '📊 पाईचार्ट / नोटिस बोर्ड ठूलो देखाउने',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Q5–Q10, प्रतिशत, ग्राफ र सूचना पाटी भएका चित्रहरूलाई साइड-बाइ-साइड नराखी पुरै चौडाइमा ठूलो र स्पष्ट देखाउँछ।',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                                  ),
                                ),
                                value: tempAutoEnlarge,
                                activeThumbColor: const Color(0xFF0D9488),
                                onChanged: (val) {
                                  setModalState(() => tempAutoEnlarge = val);
                                },
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 2. Global Scale Presets
                            const Text(
                              '🎯 फोटोको समग्र साइज (Overall Image Scale)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PDF मा सम्पूर्ण फोटोहरूको आकार प्रतिशतमा घटबढ गर्नुहोस्:',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                            ),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _presetChip('८५% (सानो)', 0.85, tempScale, (v) => setModalState(() => tempScale = v)),
                                _presetChip('१००% (सामान्य)', 1.0, tempScale, (v) => setModalState(() => tempScale = v)),
                                _presetChip('११५% (सिफारिस)', 1.15, tempScale, (v) => setModalState(() => tempScale = v)),
                                _presetChip('१३०% (ठूलो)', 1.30, tempScale, (v) => setModalState(() => tempScale = v)),
                                _presetChip('१४५% (धेरै ठूलो)', 1.45, tempScale, (v) => setModalState(() => tempScale = v)),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Slider with live percentage
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_size_select_small, color: Colors.white70, size: 20),
                                  Expanded(
                                    child: Slider(
                                      value: tempScale,
                                      min: 0.70,
                                      max: 1.50,
                                      divisions: 16,
                                      activeColor: const Color(0xFF0D9488),
                                      inactiveColor: Colors.grey.shade700,
                                      onChanged: (val) {
                                        setModalState(() => tempScale = double.parse(val.toStringAsFixed(2)));
                                      },
                                    ),
                                  ),
                                  Container(
                                    width: 58,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${(tempScale * 100).round()}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (candidateIndices.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text(
                                '⚙️ प्रश्न अनुसार पाईचार्ट / ग्राफ लेआउट नियन्त्रण (Per-Question)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'विशेष प्रश्नलाई ठूलो चार्ट बक्स वा सानो साइड-बाइ-साइड बक्समा राख्ने छनौट गर्नुहोस्:',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              ...candidateIndices.map((qNo) {
                                final isEnlarged = tempOverrides[qNo] ?? tempAutoEnlarge;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'प्रश्न $qNo (Question $qNo)',
                                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                      Row(
                                        children: [
                                          ChoiceChip(
                                            label: const Text('ठूलो चार्ट', style: TextStyle(fontSize: 11)),
                                            selected: isEnlarged,
                                            selectedColor: const Color(0xFF0D9488),
                                            labelStyle: TextStyle(color: isEnlarged ? Colors.white : Colors.white70),
                                            onSelected: (_) {
                                              setModalState(() => tempOverrides[qNo] = true);
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          ChoiceChip(
                                            label: const Text('साइड-बाइ-साइड', style: TextStyle(fontSize: 11)),
                                            selected: !isEnlarged,
                                            selectedColor: const Color(0xFF475569),
                                            labelStyle: TextStyle(color: !isEnlarged ? Colors.white : Colors.white70),
                                            onSelected: (_) {
                                              setModalState(() => tempOverrides[qNo] = false);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                          label: const Text('डिफल्ट (100%) मा फर्काउनुहोस्', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          onPressed: () {
                            setModalState(() {
                              tempScale = 1.0;
                              tempAutoEnlarge = true;
                              tempOverrides.clear();
                            });
                          },
                        ),
                        Row(
                          children: [
                            TextButton(
                              child: const Text('रद्द गर्नुहोस् (Cancel)', style: TextStyle(color: Colors.white60)),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('लागू गर्नुहोस् (Apply)', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                setState(() {
                                  _imageScale = tempScale;
                                  _autoEnlargeCharts = tempAutoEnlarge;
                                  _customChartOverrides
                                    ..clear()
                                    ..addAll(tempOverrides);
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ फोटो साइज ${(_imageScale * 100).round()}% मा सेट गरियो। PDF र प्रिन्टमा लागू भएको छ।'),
                                    backgroundColor: const Color(0xFF0D9488),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _presetChip(String label, double scaleVal, double currentScale, ValueChanged<double> onSelect) {
    final isSelected = (currentScale - scaleVal).abs() < 0.03;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF0D9488),
      backgroundColor: const Color(0xFF0F172A),
      side: BorderSide(color: isSelected ? const Color(0xFF0D9488) : Colors.white24),
      onSelected: (_) => onSelect(scaleVal),
    );
  }

  Future<void> _openInstituteCoverDialog() async {
    final nameCtrl = TextEditingController(text: _instituteName);
    final infoCtrl = TextEditingController(text: _instituteInfo);
    final subCtrl = TextEditingController(text: _examSubtitle);
    String? tempLogo = _instituteLogo;
    bool saveToProfile = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
                padding: const EdgeInsets.all(24),
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
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🏫 इन्स्टिच्युट कभर तथा ब्राण्डिङ सम्पादन',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Edit Institute Name, Logo & Contact Info for Cover Page',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Institute Name
                            const Text(
                              '🏢 इन्स्टिच्युटको नाम (Institute Name)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'e.g. SEOUL KOREAN LANGUAGE INSTITUTE',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 2. Institute Logo
                            const Text(
                              '🖼️ इन्स्टिच्युटको लोगो (Logo)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  // Logo preview box
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    child: (tempLogo != null && tempLogo!.trim().isNotEmpty)
                                        ? SmartImageWidget(imageSource: tempLogo!, fit: BoxFit.contain)
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.school, color: Color(0xFF1E3A8A), size: 28),
                                              Text('HRD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          ),
                                          icon: const Icon(Icons.content_paste, size: 16),
                                          label: const Text('📋 क्लिपबोर्डबाट पेस्ट (Ctrl+V)', style: TextStyle(fontSize: 12)),
                                          onPressed: () async {
                                            final res = await FileUploadService.instance.pasteImageFromClipboard();
                                            if (res != null && res.dataUrl.isNotEmpty) {
                                              setModalState(() => tempLogo = res.dataUrl);
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('⚠️ क्लिपबोर्डमा कुनै फोटो फेला परेन। पहिले लोगो Copy (Ctrl+C) गर्नुहोस्।'),
                                                    backgroundColor: Colors.orange,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white38),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          ),
                                          icon: const Icon(Icons.upload_file, size: 16),
                                          label: const Text('📁 लोगो अपलोड (Upload)', style: TextStyle(fontSize: 12)),
                                          onPressed: () async {
                                            final res = await FileUploadService.instance.pickImageFile();
                                            if (res != null && res.dataUrl.isNotEmpty) {
                                              setModalState(() => tempLogo = res.dataUrl);
                                            }
                                          },
                                        ),
                                        if (tempLogo != null && tempLogo!.isNotEmpty)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                            ),
                                            icon: const Icon(Icons.delete_outline, size: 16),
                                            label: const Text('❌ हटाउनुहोस्', style: TextStyle(fontSize: 12)),
                                            onPressed: () => setModalState(() => tempLogo = null),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 3. Contact & Information
                            const Text(
                              '📍 ठेगाना, फोन तथा सम्पर्क विवरण (Address & Contact Info)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'यो विवरण कभर पृष्ठको माथि इन्स्टिच्युट नामको तल सानो अक्षरमा देखिनेछ:',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: infoCtrl,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'e.g. बागबजार, काठमाडौँ  •  सम्पर्क: ९८XXXXXXXX, ०१-XXXXXXX  •  info@institute.com',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 4. Exam Subtitle / Extra Note
                            const Text(
                              '📝 कभर उप-शीर्षक / परीक्षा विवरण (Exam Subtitle / Sector Note)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: subCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'e.g. 제조업 (Manufacturing)  •  공식 지필시험 형태 문제지',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 5. Save to Profile switch
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                '💾 यो विवरण इन्स्टिच्युट प्रोफाइलमा पनि सेभ गर्नुहोस् (Save to Institute Profile)',
                                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'भविष्यमा अन्य सेट प्रिन्ट गर्दा पनि यही नाम र लोगो स्वतः प्रयोग हुनेछ।',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              value: saveToProfile,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) => setModalState(() => saveToProfile = val ?? false),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text('रद्द गर्नुहोस् (Cancel)', style: TextStyle(color: Colors.white60)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('लागू गर्नुहोस् (Apply & Update PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final newName = nameCtrl.text.trim();
                            final newInfo = infoCtrl.text.trim();
                            final newSub = subCtrl.text.trim();

                            setState(() {
                              if (newName.isNotEmpty) _instituteName = newName;
                              _instituteLogo = tempLogo;
                              _instituteInfo = newInfo;
                              if (newSub.isNotEmpty) _examSubtitle = newSub;
                            });

                            if (saveToProfile) {
                              final user = AuthService.instance.currentUser;
                              final instId = user?.instituteId ?? 'inst_01';
                              final profile = InstituteService.instance.getInstituteById(instId) ??
                                  InstituteService.instance.getDefaultInstitute();
                              if (newName.isNotEmpty) profile.name = newName;
                              if (tempLogo != null) profile.logoUrl = tempLogo!;
                              InstituteService.instance.updateInstitute(profile);
                              AuthService.instance.updateInstituteBranding(
                                instituteId: profile.id,
                                instituteName: profile.name,
                                instituteLogo: profile.logoUrl,
                              );
                            }

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ इन्स्टिच्युटको नाम, लोगो र कभर विवरण सफलतापूर्वक अपडेट भयो! PDF मा लागू भएको छ।'),
                                backgroundColor: Color(0xFF16A34A),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    final isAllowed = isSuperAdmin || _currentSet.isApproved;

    if (!isAllowed) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: Text(_currentSet.title),
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

    final allQs = _currentSet.questions; // up to 40 questions

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

    final pages = PaperExamHtmlBuilder.partitionAcross7Pages(
      allQs,
      listeningStartIndex,
      hasSectionQr: _listeningSectionQrUrl != null && _listeningSectionQrUrl!.isNotEmpty,
      imageScale: _imageScale,
      autoEnlargeCharts: _autoEnlargeCharts,
      customChartOverrides: _customChartOverrides,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 3,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_currentSet.title}  —  PBT Paper Exam (८ पृष्ठ)',
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
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.school, size: 18),
              label: const Text('🏫 फ्रन्ट कभर सम्पादन',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _openInstituteCoverDialog,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.photo_size_select_large, size: 18),
              label: Text('🖼️ फोटो साइज (${(_imageScale * 100).round()}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _openImageSizeDialog,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: Text('🎧 लिसनिङ QR ($_configuredQrCount/20)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _openListeningQrManagerDialog,
            ),
          ),
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

                // ── PAGES 2–8: 7 CONTINUOUS QUESTION PAGES ───────────────
                ...List.generate(7, (p) {
                  final pageQs = pages[p];
                  final pageNum = p + 2;
                  int startIdx = 0;
                  for (int k = 0; k < p; k++) {
                    startIdx += pages[k].length;
                  }
                  return Column(
                    children: [
                      _page(
                        pageNum,
                        _buildContinuousQPage(
                          pageQuestions: pageQs,
                          startQuestionIndex: startIdx,
                          listeningStartIndex: listeningStartIndex,
                          isLastPage: (p == 6),
                        ),
                      ),
                      if (p < 6) _gap,
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const Widget _gap = SizedBox(height: 32);



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
                Text(_instituteName,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 6, color: const Color(0xFF1E3A8A)),
        const SizedBox(height: 3),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 16),

        // Interactive Cover Header (Clickable to Edit)
        InkWell(
          onTap: _openInstituteCoverDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo or HRD fallback
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: (_instituteLogo != null && _instituteLogo!.trim().isNotEmpty)
                      ? SmartImageWidget(imageSource: _instituteLogo!, fit: BoxFit.contain)
                      : Container(
                          color: const Color(0xFF1E3A8A),
                          width: double.infinity,
                          height: double.infinity,
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
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '고용허가제 한국어능력시험 (EPS-TOPIK)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 10, color: Color(0xFF1E3A8A)),
                                SizedBox(width: 3),
                                Text('सम्पादन', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Employment Permit System — Test of Proficiency in Korean',
                        style: TextStyle(fontSize: 9.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _instituteName.toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.8),
                      ),
                      if (_instituteInfo.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _instituteInfo,
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569), height: 1.25),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PBT\n문제지',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Container(height: 2, color: Colors.black87),
        const SizedBox(height: 14),

        Center(child: Text(widget.testSet.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF0F172A)))),
        const SizedBox(height: 4),
        if (_examSubtitle.isNotEmpty) ...[
          Center(child: Text(_examSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)))),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 6),
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
  // PAGES 2–8 — 7 CONTINUOUS SINGLE COLUMN HRD-STYLE QUESTION PAGES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContinuousQPage({
    required List<QuestionTemplate> pageQuestions,
    required int startQuestionIndex,
    required int listeningStartIndex,
    bool isLastPage = false,
  }) {
    if (pageQuestions.isEmpty) {
      return const SizedBox();
    }

    final endQuestionIndex = startQuestionIndex + pageQuestions.length - 1;
    final String runningHeaderTitle;
    if (endQuestionIndex < listeningStartIndex) {
      runningHeaderTitle = '읽기 (Reading)';
    } else if (startQuestionIndex >= listeningStartIndex) {
      runningHeaderTitle = '듣기 (Listening)';
    } else {
      runningHeaderTitle = '읽기 & 듣기 (Reading & Listening)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Running header
        _runningHeader(runningHeaderTitle),
        const SizedBox(height: 12),

        // Questions & Dynamic Section Banners
        ...pageQuestions.asMap().entries.expand((e) {
          final localIdx = e.key;
          final globalIdx = startQuestionIndex + localIdx;
          final qNo = globalIdx + 1;
          final q = e.value;

          final widgets = <Widget>[];

          // 1. Reading Section Banner at question #1 (globalIdx == 0)
          if (globalIdx == 0) {
            widgets.add(
              _sectionBanner(
                '읽기 영역 (Reading)  :  1번 ~ 20번  /  50점',
                '아래 내용을 읽고 물음에 맞는 가장 알맞은 것을 ①②③④ 중에서 고르십시오. / Q1–Q20 सम्म पढेर सही उत्तर ①②③④ मा छान्नुहोस्।',
              ),
            );
            widgets.add(const SizedBox(height: 14));
          }

          // 2. Listening Section Banner right before listening starts (globalIdx == listeningStartIndex)
          if (globalIdx == listeningStartIndex) {
            widgets.add(
              _sectionBanner(
                '듣기 영역 (Listening)  :  21번 ~ 40번  /  50점',
                '다음을 듣고 알맞은 것을 ①②③④ 중에서 고르십시오. / Q21–Q40 सम्म सुनेर सही उत्तर ①②③④ मा छान्नुहोस्।',
                qrUrl: _listeningSectionQrUrl,
              ),
            );
            widgets.add(const SizedBox(height: 14));
          }

          // 3. Question Item
          final qrUrl = _questionQrCodes['$qNo'] ??
              ((q is UniversalQuestion) ? q.questionQrCodeUrl : null);

          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _hrdQuestion(qNo, q, qrUrl: qrUrl),
            ),
          );

          return widgets;
        }),

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
        Text('${_currentSet.title}  •  $sectionTitle',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const Text('EPS-TOPIK  PBT  지필 모의고사',
            style: TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    );
  }

  Widget _sectionBanner(String title, String subtitle, {String? qrUrl}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ),
          if (qrUrl != null && qrUrl.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: SmartImageWidget(imageSource: qrUrl, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 2),
                  const Text('🎧 전체 듣기',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HRD-STYLE SINGLE QUESTION WIDGET
  // Bold question title + rounded-border material box + options ①②③④
  // ─────────────────────────────────────────────────────────────────────────
  Widget _hrdQuestion(int no, QuestionTemplate q, {String? qrUrl}) {
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
    final bool isChartCandidate = PaperExamHtmlBuilder.isChartOrNoticeQuestion(no, q);
    final bool isChartNotice = (_customChartOverrides.containsKey(no))
        ? _customChartOverrides[no]!
        : (_autoEnlargeCharts && isChartCandidate);

    final bool isSideBySide = !isChartNotice && (imgUrl != null && imgUrl.isNotEmpty && !hasImageOpts && (passage == null || passage.length <= 80));
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
        // ── Question Number Badge + Bold Title + QR Code (if available) ─────────────────────────
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
          if (qrUrl != null && qrUrl.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87, width: 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: SmartImageWidget(imageSource: qrUrl, fit: BoxFit.contain),
                ),
                const SizedBox(height: 2),
                const Text('🎧 듣기 QR',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
          ],
        ]),

        if (isSideBySide) ...[
          // ── Side-by-Side: Picture on Left, Options on Right ──
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Picture Box
                Container(
                  width: (240 * _imageScale).clamp(180.0, 320.0),
                  constraints: BoxConstraints(maxHeight: (110 * _imageScale).clamp(70.0, 180.0)),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: Colors.black87, width: 1.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (passage != null && passage.isNotEmpty) ...[
                        Text(
                          passage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: (95 * _imageScale).clamp(60.0, 160.0),
                            maxWidth: (225 * _imageScale).clamp(150.0, 300.0),
                          ),
                          child: SmartImageWidget(imageSource: imgUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                // Right Column: Options based on length
                Expanded(
                  child: _buildDynamicTextOptions(textOpts, isSideBySide: true),
                ),
              ],
            ),
          ),
        ] else ...[
          // ── Standard Stacked Layout: Material on Top, Options Below ──
          if (hasMaterial) ...[
            if (isChartNotice && imgUrl != null && imgUrl.isNotEmpty) ...[
              // Dedicated full-width chart / notice box
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 36, top: 6, bottom: 4),
                padding: EdgeInsets.symmetric(
                  horizontal: (12 * _imageScale).clamp(8.0, 20.0),
                  vertical: (8 * _imageScale).clamp(6.0, 16.0),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border.all(color: Colors.black87, width: 1.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (passage != null && passage.isNotEmpty) ...[
                      Text(
                        passage,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: (165 * _imageScale).clamp(100.0, 260.0),
                          maxWidth: (480 * _imageScale).clamp(280.0, 640.0),
                        ),
                        child: SmartImageWidget(imageSource: imgUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(left: 36, top: 6, bottom: 4),
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
                          constraints: BoxConstraints(
                            maxHeight: (110 * _imageScale).clamp(70.0, 200.0),
                            maxWidth: (280 * _imageScale).clamp(180.0, 500.0),
                          ),
                          child: SmartImageWidget(imageSource: imgUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 4),

          if (hasImageOpts)
            Container(
              margin: const EdgeInsets.only(left: 36),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: List.generate(4, (i) {
                  final img = i < imgOpts.length ? imgOpts[i] : null;
                  return Expanded(
                    child: Container(
                      height: (85 * _imageScale).clamp(60.0, 130.0),
                      margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == 3 ? 0 : 4,
                      ),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(nums[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          if (img != null && img.isNotEmpty)
                            Expanded(child: SmartImageWidget(imageSource: img, fit: BoxFit.contain)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            )
          else
            _buildDynamicTextOptions(textOpts, isSideBySide: false),
        ],
      ],
    );
  }

  Widget _buildDynamicTextOptions(List<String> textOpts, {bool isSideBySide = false}) {
    const nums = ['①', '②', '③', '④'];
    final cleaned = List.generate(4, (i) => i < textOpts.length ? textOpts[i].trim() : '');

    // Check if options have newlines
    final hasNewlines = cleaned.any((o) => o.contains('\n'));

    // Find the max length among all options
    final maxLen = cleaned.fold<int>(0, (max, o) => o.length > max ? o.length : max);
    final count = cleaned.where((o) => o.isNotEmpty).length;

    int colCount = 1;
    if (isSideBySide) {
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

    final padLeft = isSideBySide ? 0.0 : 36.0;

    if (colCount == 4) {
      return Padding(
        padding: EdgeInsets.only(left: padLeft, top: 4),
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
        padding: EdgeInsets.only(left: padLeft, top: 4),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildOptionItem(0)),
                const SizedBox(width: 14),
                Expanded(child: buildOptionItem(1)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildOptionItem(2)),
                const SizedBox(width: 14),
                Expanded(child: buildOptionItem(3)),
              ],
            ),
          ],
        ),
      );
    } else {
      // 1 column (vertical list)
      return Padding(
        padding: EdgeInsets.only(left: padLeft, top: 4),
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
