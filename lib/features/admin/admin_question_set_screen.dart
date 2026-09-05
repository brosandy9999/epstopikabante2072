import 'package:flutter/material.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/language_service.dart';
import '../question_engine/question_template.dart';

/// Admin 40-Question Set Management & Multi-Modal Question Editor
/// Manages strict 40-question sets (20 Reading + 20 Listening)
/// and allows editing every question with Text, Image, Graph, and Audio modalities.
class AdminQuestionSetScreen extends StatefulWidget {
  final bool initialOpenCreate;
  const AdminQuestionSetScreen({super.key, this.initialOpenCreate = false});

  @override
  State<AdminQuestionSetScreen> createState() => _AdminQuestionSetScreenState();
}

class _AdminQuestionSetScreenState extends State<AdminQuestionSetScreen> {
  MockTestSet? _selectedSet;
  String _questionFilter = 'all'; // 'all', 'reading', 'listening'
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sectorsList = [
    '제조업 (Manufacturing)',
    '농축산업 (Agriculture & Livestock)',
    '건설업 (Construction & Safety)',
    '어업 (Fishery)',
    '실전 모의고사 (Final Real Exam Simulation)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialOpenCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateNewSetDialog();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateNewSetDialog() {
    final titleCtrl = TextEditingController(text: '제\회 EPS-TOPIK 실전 모의고사');
    final descCtrl = TextEditingController(text: '표준 EPS-TOPIK 실전 모의고사 40문항 풀 세트 (20 읽기 + 20 듣기)');
    String selectedSector = _sectorsList.first;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                LanguageService.instance.trText(
                  ne: 'नयाँ ४०-प्रश्न सेट सिर्जना गर्नुहोस्',
                  en: 'Create New 40-Question Set',
                  ko: '새 40문항 세트 만들기',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'सेटको शीर्षक*', en: 'Set Title*', ko: '세트 제목*'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSector,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'औद्योगिक क्षेत्र (Sector)*', en: 'Industry Sector*', ko: '업종 분야*'),
                    border: const OutlineInputBorder(),
                  ),
                  items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setDialogState(() => selectedSector = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'विवरण', en: 'Description', ko: '설명'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LanguageService.instance.trText(
                            ne: 'नोट: नयाँ सेट सिर्जना गर्दा स्वतः २० Reading र २० Listening गरी कुल ४० प्रश्नहरूको पूर्ण ब्लुप्रिन्ट तयार हुन्छ, जसलाई तपाईंले तुरुन्तै सम्पादन गर्न सक्नुहुन्छ।',
                            en: 'Note: Creating a new set automatically generates a 40-question blueprint (20 Reading + 20 Listening) ready for instant editing.',
                            ko: '참고: 새 세트 생성 시 즉시 편집 가능한 40문항 청사진(20 읽기 + 20 듣기)이 자동 생성됩니다.',
                          ),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'कृपया सेटको शीर्षक भर्नुहोस्!',
                    en: 'Please enter a set title!',
                    ko: '세트 제목을 입력해주세요!',
                  ));
                  return;
                }
                final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
                final newSet = QuestionBankService.instance.createBlank40QuestionSet(
                  title: titleCtrl.text.trim(),
                  sector: selectedSector,
                  description: descCtrl.text.trim(),
                  isApproved: isSuperAdmin,
                  createdByRole: isSuperAdmin ? 'superAdmin' : 'admin',
                  instituteId: AuthService.instance.currentUser?.instituteId,
                  instituteName: AuthService.instance.currentUser?.instituteName,
                );
                QuestionBankService.instance.addNewMockSet(newSet);
                setState(() {
                  _selectedSet = newSet;
                });
                Navigator.pop(ctx);
                CloudSyncService.instance.pushToCloud();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LanguageService.instance.trText(
                        ne: '✅ नयाँ ४०-प्रश्न सेट सिर्जना भयो र क्लाउडमा स्वतः सिङ्क भयो!',
                        en: '✅ New 40-question set created and synced to cloud!',
                        ko: '✅ 새 40문항 세트가 생성되었고 클라우드에 동기화되었습니다!',
                      ),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'सेट सिर्जना गर्नुहोस्', en: 'Create Set', ko: '세트 생성')),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionEditorDialog(MockTestSet set, int qIndex, QuestionTemplate q) {
    // Extract properties
    final isReading = (q is ReadingTextQuestion) || (q is UniversalQuestion && !q.isListening);
    final questionNo = qIndex + 1;
    final qId = q.questionId;
    final ansInfo = set.answerKeys[qId] ?? const QuestionAnswerInfo(correctIndex: 0, explanation: 'सही उत्तर');

    final textCtrl = TextEditingController(text: q.questionText);
    String? imgUrl = (q is UniversalQuestion) ? q.questionImageUrl : (q is ReadingImageQuestion ? q.imageAssetPath : null);
    final imgCtrl = TextEditingController(text: imgUrl ?? '');
    
    String? audioUrl = (q is UniversalQuestion) ? q.questionAudioUrl : (q is ListeningAudioQuestion ? q.audioAssetPath : null);
    final audioCtrl = TextEditingController(text: audioUrl ?? '');

    String? script = (q is UniversalQuestion) ? q.audioScript : (q is ListeningAudioQuestion ? q.audioScript : null);
    final scriptCtrl = TextEditingController(text: script ?? '');

    String? scriptNep = (q is UniversalQuestion) ? q.audioScriptNepali : (q is ListeningAudioQuestion ? q.audioScriptNepali : null);
    final scriptNepCtrl = TextEditingController(text: scriptNep ?? '');
    bool isAudioOnly = (q is UniversalQuestion) ? q.isAudioOnly : false;

    // 4 Options
    List<String> rawTexts = ['', '', '', ''];
    if (q is UniversalQuestion) rawTexts = q.textOptions;
    else if (q is ReadingTextQuestion) rawTexts = q.textOptions;
    else if (q is ListeningAudioQuestion) rawTexts = q.textOptions;
    while (rawTexts.length < 4) rawTexts.add('');

    final optionTextCtrls = List.generate(4, (i) => TextEditingController(text: i < rawTexts.length ? rawTexts[i] : ''));
    final optionImgCtrls = List.generate(4, (i) => TextEditingController(text: (q is UniversalQuestion && i < q.imageOptions.length) ? (q.imageOptions[i] ?? '') : ''));
    final optionAudioCtrls = List.generate(4, (i) => TextEditingController(text: (q is UniversalQuestion && i < q.audioOptions.length) ? (q.audioOptions[i] ?? '') : ''));

    final explCtrl = TextEditingController(text: ansInfo.explanation);
    int selectedCorrectIndex = ansInfo.correctIndex;

    // Snapshot initial values to detect unsaved changes accurately
    final initialQuestionText = q.questionText;
    final initialImgUrl = imgUrl ?? '';
    final initialAudioUrl = audioUrl ?? '';
    final initialScript = script ?? '';
    final initialScriptNep = scriptNep ?? '';
    final initialAudioOnly = isAudioOnly;
    final initialOptionTexts = List<String>.from(rawTexts);
    final initialOptionImgs = List.generate(4, (i) => (q is UniversalQuestion && i < q.imageOptions.length) ? (q.imageOptions[i] ?? '') : '');
    final initialOptionAudios = List.generate(4, (i) => (q is UniversalQuestion && i < q.audioOptions.length) ? (q.audioOptions[i] ?? '') : '');
    final initialExpl = ansInfo.explanation;
    final initialCorrectIndex = ansInfo.correctIndex;

    bool hasUnsavedChanges() {
      if (textCtrl.text.trim() != initialQuestionText.trim()) return true;
      if (imgCtrl.text.trim() != initialImgUrl.trim()) return true;
      if (audioCtrl.text.trim() != initialAudioUrl.trim()) return true;
      if (scriptCtrl.text.trim() != initialScript.trim()) return true;
      if (scriptNepCtrl.text.trim() != initialScriptNep.trim()) return true;
      if (isAudioOnly != initialAudioOnly) return true;
      if (explCtrl.text.trim() != initialExpl.trim()) return true;
      if (selectedCorrectIndex != initialCorrectIndex) return true;
      for (int i = 0; i < 4; i++) {
        if (optionTextCtrls[i].text.trim() != (i < initialOptionTexts.length ? initialOptionTexts[i].trim() : '')) return true;
        if (optionImgCtrls[i].text.trim() != (i < initialOptionImgs.length ? initialOptionImgs[i].trim() : '')) return true;
        if (optionAudioCtrls[i].text.trim() != (i < initialOptionAudios.length ? initialOptionAudios[i].trim() : '')) return true;
      }
      return false;
    }

    Future<void> performSaveAndSync(BuildContext dialogCtx) async {
      final updatedText = textCtrl.text.trim().isEmpty ? q.questionText : textCtrl.text.trim();
      final finalOptions = optionTextCtrls.map((c) => c.text.trim()).toList();
      final finalImageOptions = optionImgCtrls.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList();
      final finalAudioOptions = optionAudioCtrls.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList();
      final finalExpl = explCtrl.text.trim().isEmpty ? 'सही उत्तर' : explCtrl.text.trim();

      final updatedAns = QuestionAnswerInfo(
        correctIndex: selectedCorrectIndex,
        explanation: finalExpl,
      );

      final updatedQ = UniversalQuestion(
        questionId: qId,
        questionNumber: questionNo,
        questionText: updatedText,
        questionImageUrl: imgCtrl.text.trim().isEmpty ? null : imgCtrl.text.trim(),
        questionAudioUrl: audioCtrl.text.trim().isEmpty ? null : audioCtrl.text.trim(),
        audioScript: scriptCtrl.text.trim().isEmpty ? null : scriptCtrl.text.trim(),
        audioScriptNepali: scriptNepCtrl.text.trim().isEmpty ? null : scriptNepCtrl.text.trim(),
        isListening: !isReading,
        isAudioOnly: isAudioOnly,
        textOptions: finalOptions,
        imageOptions: finalImageOptions,
        audioOptions: finalAudioOptions,
      );

      // १. लोकल डेटाबेसमा सेभ
      QuestionBankService.instance.updateQuestionInSet(
        setId: set.id,
        questionIndex: qIndex,
        updatedQuestion: updatedQ,
        updatedAnswer: updatedAns,
      );

      if (mounted) {
        setState(() {
          _selectedSet = QuestionBankService.instance.getMockSetById(set.id);
        });
      }

      // २. पृष्ठभूमिमा स्वतः क्लाउड सिङ्क (Silent Background Auto-Sync)
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);

      // ३. सम्पादन मोडल बन्द गर्ने
      if (dialogCtx.mounted) {
        Navigator.pop(dialogCtx);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(
                      ne: '✅ प्रश्न $questionNo सेभ भयो र ब्याकग्राउन्डमा स्वतः सिङ्क भयो!',
                      en: '✅ Question $questionNo saved and auto-synced!',
                      ko: '✅ 문항 $questionNo 저장 및 자동 동기화 완료!',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    Future<void> handleExitAttempt(BuildContext dialogCtx) async {
      if (!hasUnsavedChanges()) {
        Navigator.pop(dialogCtx);
        return;
      }

      // परिवर्तनहरू सुरक्षित गर्ने कि नगर्ने कन्फर्मेसन डाइलग
      final result = await showDialog<String>(
        context: context,
        builder: (confirmCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.save_as_rounded, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: 'परिवर्तनहरू सुरक्षित गर्नुहुन्छ? (Save Changes?)',
                    en: 'Save Changes Before Leaving?',
                    ko: '변경 사항을 저장하시겠습니까?',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            LanguageService.instance.trText(
              ne: 'तपाईंले प्रश्न $questionNo मा परिमार्जन गर्नुभएको छ। बन्द गर्नु अगाडि यसलाई सेभ तथा स्वतः क्लाउडमा सिङ्क गर्न चाहनुहुन्छ?',
              en: 'You have unsaved changes on Question $questionNo. Would you like to save and auto-sync before closing?',
              ko: '문항 $questionNo에 저장되지 않은 변경 사항이 있습니다. 닫기 전에 저장하고 자동 동기화하시겠습니까?',
            ),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmCtx, 'cancel'),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(confirmCtx, 'discard'),
              child: Text(
                LanguageService.instance.trText(
                  ne: 'छोड्नुहोस् (Discard)',
                  en: 'Discard',
                  ko: '저장 안 함',
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.save, size: 16),
              label: Text(
                LanguageService.instance.trText(
                  ne: 'सेभ गरी बन्द गर्नुहोस् (Save & Exit)',
                  en: 'Save & Exit',
                  ko: '저장 후 닫기',
                ),
              ),
              onPressed: () => Navigator.pop(confirmCtx, 'save'),
            ),
          ],
        ),
      );

      if (result == 'save') {
        await performSaveAndSync(dialogCtx);
      } else if (result == 'discard') {
        if (dialogCtx.mounted) {
          Navigator.pop(dialogCtx);
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            handleExitAttempt(ctx);
          },
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReading ? const Color(0xFF1E3A8A) : const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${LanguageService.instance.trText(ne: "प्रश्न", en: "Q", ko: "문항")} $questionNo (${isReading ? "READING" : "LISTENING"})',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${LanguageService.instance.trText(ne: "सेट:", en: "Set:", ko: "세트:")} ${set.title.split(' ')[0]}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: LanguageService.instance.tr('close'),
                          onPressed: () => handleExitAttempt(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1. Question Text
                    Text(
                      LanguageService.instance.trText(
                        ne: '१. प्रश्न वाक्य / निर्देशन:*',
                        en: '1. Question Text / Instruction:*',
                        ko: '1. 지문 / 발문 내용:*',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 다음 그림을 보고 맞는 단어를 고르십시오.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Question Image / Graph (Optional)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageService.instance.trText(
                            ne: '२. प्रश्नको तस्बिर / ग्राफ:',
                            en: '2. Question Image / Graph:',
                            ko: '2. 문제 이미지 / 그림 자료:',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey.shade800,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final uploaded = await FileUploadService.instance.pickImageFile();
                                if (uploaded != null) {
                                  setDialogState(() {
                                    imgCtrl.text = uploaded.bestUrl;
                                  });
                                }
                              },
                              icon: const Icon(Icons.cloud_upload, size: 16),
                              label: Text(LanguageService.instance.trText(ne: 'तस्बिर अपलोड गर्नुहोस्', en: 'Upload Image', ko: '이미지 업로드')),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                imgCtrl.text.isEmpty
                                    ? LanguageService.instance.trText(ne: '(कुनै तस्बिर छैन)', en: '(No image selected)', ko: '(이미지 없음)')
                                    : (imgCtrl.text.startsWith('data:image')
                                        ? '🖼️ Base64 Image (${(imgCtrl.text.length / 1024).toStringAsFixed(1)} KB)'
                                        : (imgCtrl.text.startsWith('https://firebasestorage')
                                            ? '☁️ Firebase ✅'
                                            : LanguageService.instance.trText(ne: 'तस्बिर लोड भयो ✅', en: 'Image Loaded ✅', ko: '이미지 로드됨 ✅'))),
                              ),
                            ),
                            if (imgCtrl.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: LanguageService.instance.trText(ne: 'तस्बिर हटाउनुहोस्', en: 'Remove image', ko: '이미지 제거'),
                                onPressed: () => setDialogState(() => imgCtrl.clear()),
                              ),
                            ],
                          ],
                        ),
                        if (imgCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 90,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: SmartImageWidget(imageSource: imgCtrl.text, height: 80, fit: BoxFit.contain),
                          ),
                        ],
                        const SizedBox(height: 6),
                        TextField(
                          controller: imgCtrl,
                          decoration: InputDecoration(
                            hintText: LanguageService.instance.trText(ne: 'वा तस्बिरको वेब लिङ्क', en: 'Or Image Web URL', ko: '또는 이미지 웹 링크 URL'),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            suffixIcon: imgCtrl.text.isNotEmpty
                                ? const Icon(Icons.image, color: Colors.blue, size: 18)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Question Audio & Script (For Listening questions)
                    if (!isReading) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Audio Mode Choice: Pure Uploaded Audio vs TTS
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.tune, size: 16, color: Color(0xFFEA580C)),
                                      const SizedBox(width: 6),
                                      Text(
                                        LanguageService.instance.trText(ne: 'अडियो प्रकार छनोट:', en: 'Audio Type Selection:', ko: '오디오 유형 선택:'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9A3412)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: isAudioOnly,
                                        activeColor: const Color(0xFFEA580C),
                                        onChanged: (v) => setDialogState(() => isAudioOnly = v!),
                                      ),
                                      Expanded(
                                        child: Text(
                                          LanguageService.instance.trText(ne: 'केवल अडियो फाइल मात्र', en: 'Audio File Only (Strict Audio)', ko: '오디오 전용 문항'),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Radio<bool>(
                                        value: false,
                                        groupValue: isAudioOnly,
                                        activeColor: const Color(0xFFEA580C),
                                        onChanged: (v) => setDialogState(() => isAudioOnly = v!),
                                      ),
                                      Expanded(
                                        child: Text(
                                          LanguageService.instance.trText(ne: 'स्वचालित अडियो वा दुवै', en: 'Auto Speech / Dual Audio', ko: '음성 합성(TTS) 또는 겸용'),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (isAudioOnly && audioCtrl.text.isEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        LanguageService.instance.trText(
                                          ne: '⚠️ अडियो फाइल अपलोड गर्न बाँकी छ!',
                                          en: '⚠️ Audio file upload required for Audio-Only mode!',
                                          ko: '⚠️ 오디오 전용 모드는 오디오 파일 업로드가 필수입니다!',
                                        ),
                                        style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Text(
                              LanguageService.instance.trText(
                                ne: '३.१ अडियो फाइल (MP3 / WAV):',
                                en: '3.1 Question Audio File:',
                                ko: '3.1 문제 오디오 파일:',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                                  onPressed: () async {
                                    final uploaded = await FileUploadService.instance.pickAudioFile();
                                    if (uploaded != null) {
                                      setDialogState(() {
                                        audioCtrl.text = uploaded.bestUrl;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: Text(LanguageService.instance.trText(ne: 'अडियो अपलोड गर्नुहोस्', en: 'Upload Audio', ko: '오디오 업로드')),
                                ),
                                if (audioCtrl.text.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.play_circle_fill, color: Colors.green),
                                    tooltip: LanguageService.instance.trText(ne: 'अडियो सुन्नुहोस्', en: 'Play Audio', ko: '오디오 재생'),
                                    onPressed: () {
                                      AudioPlaybackService.instance.playAudioUrl(audioCtrl.text);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: LanguageService.instance.trText(ne: 'अडियो हटाउनुहोस्', en: 'Remove Audio', ko: '오디오 제거'),
                                    onPressed: () => setDialogState(() => audioCtrl.clear()),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: audioCtrl,
                              decoration: InputDecoration(
                                hintText: LanguageService.instance.trText(ne: 'वा अडियो वेब लिङ्क URL', en: 'Or Audio Web URL', ko: '또는 오디오 웹 URL'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3.2 Korean Script for TTS
                            Text(
                              LanguageService.instance.trText(
                                ne: '३.२ अडियो स्क्रिप्ट (कोरियाली भाषामा):',
                                en: '3.2 Audio Script (Korean text for Speech/Review):',
                                ko: '3.2 듣기 대본 (한국어 스크립트):',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: scriptCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 남: 어디에 가요? \n여: 시장에 가요.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (scriptCtrl.text.trim().isNotEmpty) {
                                      KoreanTtsService.instance.speakKorean(scriptCtrl.text.trim());
                                    }
                                  },
                                  icon: const Icon(Icons.volume_up, size: 16),
                                  label: Text(LanguageService.instance.trText(ne: 'कोरियाली आवाज सुन्नुहोस् (TTS)', en: 'Test TTS Voice', ko: '음성 듣기 테스트')),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 3.3 Nepali Translation for Review
                            Text(
                              LanguageService.instance.trText(
                                ne: '३.३ अडियोको नेपाली अनुवाद (समीक्षाको लागि):',
                                en: '3.3 Audio Script Nepali Translation:',
                                ko: '3.3 오디오 스크립트 네팔어 번역:',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: scriptNepCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'e.g. केटा: कहाँ जाँदै हुनुहुन्छ? \nकेटी: बजार जाँदै छु।',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. Options 1 to 4 with Text / Image / Audio
                    Text(
                      LanguageService.instance.trText(
                        ne: '४. विकल्पहरू (४ वटा विकल्प र सही उत्तर छनोट):*',
                        en: '4. Options (4 Choices & Select Correct Answer):*',
                        ko: '4. 보기 항목 (4개 보기 및 정답 선택):*',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(4, (index) {
                      final isCorrect = selectedCorrectIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCorrect ? Colors.green.shade600 : Colors.grey.shade300,
                            width: isCorrect ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: selectedCorrectIndex,
                                  activeColor: Colors.green.shade700,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedCorrectIndex = val);
                                    }
                                  },
                                ),
                                Text(
                                  '${LanguageService.instance.trText(ne: "विकल्प", en: "Option", ko: "보기")} ${index + 1}${isCorrect ? " (✅ " + LanguageService.instance.trText(ne: "सही उत्तर", en: "Correct Answer", ko: "정답") + ")" : ""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isCorrect ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                // Quick TTS for option
                                if (optionTextCtrls[index].text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, size: 18),
                                    tooltip: 'TTS',
                                    onPressed: () => KoreanTtsService.instance.speakKorean(optionTextCtrls[index].text),
                                  ),
                              ],
                            ),
                            TextField(
                              controller: optionTextCtrls[index],
                              decoration: InputDecoration(
                                labelText: '${LanguageService.instance.trText(ne: "विकल्प", en: "Option", ko: "보기")} ${index + 1} ${LanguageService.instance.trText(ne: "पाठ", en: "Text", ko: "텍스트")}',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final uploaded = await FileUploadService.instance.pickImageFile();
                                    if (uploaded != null) {
                                      setDialogState(() {
                                        optionImgCtrls[index].text = uploaded.bestUrl;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 14),
                                  label: Text(LanguageService.instance.trText(ne: 'तस्बिर', en: 'Image', ko: '그림'), style: const TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: optionImgCtrls[index],
                                    decoration: InputDecoration(
                                      hintText: LanguageService.instance.trText(ne: 'तस्बिर URL / Base64', en: 'Image URL / Base64', ko: '이미지 URL'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                if (optionImgCtrls[index].text.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => setDialogState(() => optionImgCtrls[index].clear()),
                                  ),
                                ],
                              ],
                            ),
                            if (optionImgCtrls[index].text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SmartImageWidget(imageSource: optionImgCtrls[index].text, height: 45, fit: BoxFit.contain),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // 5. Answer Explanation (Nepali & Korean)
                    Text(
                      LanguageService.instance.trText(
                        ne: '५. उत्तरको व्याख्या / कारण (विद्यार्थीको समीक्षाको लागि):',
                        en: '5. Answer Explanation / Rationale:',
                        ko: '5. 정답 해설 및 오답 피드백:',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: explCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: LanguageService.instance.trText(
                          ne: 'e.g. १ नम्बर विकल्प सही हो किनभने...',
                          en: 'e.g. Option 1 is correct because...',
                          ko: 'e.g. 1번이 정답인 이유는...',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Cancel / Discard / Save Changes)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => handleExitAttempt(ctx),
                          child: Text(LanguageService.instance.tr('cancel')),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            // "Save Changes?" Confirmation Dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (confirmCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        LanguageService.instance.trText(
                                          ne: 'परिवर्तनहरू सुरक्षित गर्ने? (Save Changes?)',
                                          en: 'Save Changes for Question $questionNo?',
                                          ko: '문항 $questionNo 변경 사항을 저장하시겠습니까?',
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  LanguageService.instance.trText(
                                    ne: 'यो प्रश्न सुरक्षित भई स्वतः क्लाउडमा सिङ्क हुनेछ। सबै विद्यार्थीहरू तथा डिभाइसहरूले नयाँ अपडेट तुरुन्तै प्राप्त गर्नेछन्। के तपाईं सुरक्षित गर्न निश्चित हुनुहुन्छ?',
                                    en: 'This question will be saved and auto-synced to the cloud in real-time. Do you want to proceed?',
                                    ko: '저장된 문항은 클라우드에 자동 동기화되어 즉시 반영됩니다. 계속하시겠습니까?',
                                  ),
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(confirmCtx, false),
                                    child: Text(LanguageService.instance.tr('cancel')),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.save, size: 16),
                                    label: Text(
                                      LanguageService.instance.trText(
                                        ne: 'हुन्छ, सेभ गर्नुहोस् (Save Changes)',
                                        en: 'Save Changes',
                                        ko: '저장하기',
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(confirmCtx, true),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await performSaveAndSync(ctx);
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(
                            LanguageService.instance.trText(
                              ne: 'परिवर्तन सुरक्षित गर्नुहोस् (Save Changes)',
                              en: 'Save Changes',
                              ko: '변경 사항 저장',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        if (_selectedSet != null) {
          return _buildSetQuestionInspector(_selectedSet!);
        }
        return _buildSetsList();
      },
    );
  }

  /// 1. Sets List View
  Widget _buildSetsList() {
    final allSets = QuestionBankService.instance.getAllMockSets();
    final query = _searchController.text.trim().toLowerCase();
    final filteredSets = allSets.where((s) {
      return query.isEmpty || s.title.toLowerCase().contains(query) || s.sector.toLowerCase().contains(query);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: 'EPS-TOPIK ४०-प्रश्न सेट व्यवस्थापन केन्द्र',
                          en: 'EPS-TOPIK 40-Question Set Hub',
                          ko: 'EPS-TOPIK 40문항 세트 관리 센터',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'प्रत्येक सेटमा २० रिडिङ र २० लिसनिङ प्रश्नहरू समावेश हुन्छन्। नयाँ सेट थप्न र सेट भित्रका प्रश्नहरू सम्पादन गर्न सक्नुहुन्छ।',
                          en: 'Each set contains 20 Reading and 20 Listening questions. Create and edit multi-modal questions with audio and images.',
                          ko: '각 세트는 20개 읽기 및 20개 듣기 문항으로 구성됩니다. 새 세트를 추가하고 오디오/이미지 문항을 편집할 수 있습니다.',
                        ),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateNewSetDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(LanguageService.instance.trText(ne: 'नयाँ प्रश्न सेट बनाउनुहोस्', en: 'Create Question Set', ko: '새 문제 세트 만들기')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: LanguageService.instance.trText(ne: 'प्रश्न सेटको शीर्षक वा क्षेत्र खोज्नुहोस्...', en: 'Search question set title or sector...', ko: '문제 세트 제목 또는 분야 검색...'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Super Admin Approval Queue
          _buildApprovalQueueSection(),
          const SizedBox(height: 16),

          // Sets Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final set = filteredSets[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                        child: Text(
                          'S${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(LanguageService.instance.trText(ne: '४० प्रश्नहरू (२० R + २० L)', en: '40 Questions (20 R + 20 L)', ko: '40문항 (20 R + 20 L)'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                ),
                                if (set.isLiveExam)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.radio_button_checked, size: 12, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text(LanguageService.instance.trText(ne: '🔴 आजको दैनिक परीक्षा', en: "🔴 Today's Live Exam", ko: '🔴 오늘의 라이브 시험'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: set.isApproved ? Colors.green.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: set.isApproved ? Colors.green : Colors.amber.shade700),
                                  ),
                                  child: Text(
                                    set.isApproved ? LanguageService.instance.trText(ne: '🟢 सबैका लागि स्वीकृत', en: '🟢 Approved for All', ko: '🟢 전체 승인됨') : LanguageService.instance.trText(ne: '⏳ सुपर एडमिन स्वीकृतिको पर्खाइमा', en: '⏳ Awaiting Super Admin Approval', ko: '⏳ 최고관리자 승인 대기중'),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: set.isApproved ? Colors.green.shade900 : Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${set.sector}  •  ${set.description}${set.instituteName != null ? " • इन्स्टिच्युट: " + set.instituteName! : ""}', style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedSet = set;
                                _questionFilter = 'all';
                              });
                            },
                            icon: const Icon(Icons.manage_search, size: 16),
                            label: Text(LanguageService.instance.trText(ne: '४० प्रश्नहरू व्यवस्थापन गर्नुहोस्', en: 'Manage 40 Questions', ko: '40문항 관리'), style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: set.isLiveExam ? Colors.red : const Color(0xFF0F766E),
                              side: BorderSide(color: set.isLiveExam ? Colors.red : const Color(0xFF0F766E)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setState(() {
                                QuestionBankService.instance.setLiveDailyExam(set.id, isLive: !set.isLiveExam);
                              });
                              CloudSyncService.instance.pushToCloud();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(set.isLiveExam ? LanguageService.instance.trText(ne: 'लाइभ परीक्षा हटाइयो।', en: 'Live exam removed.', ko: '라이브 시험이 해제되었습니다.') : LanguageService.instance.trText(ne: '🔴 ${set.title} आजको दैनिक लाइभ परीक्षा (Strict Mode) को रूपमा तोकियो!', en: "🔴 ${set.title} set as Today's Live Exam (Strict Mode)!", ko: '🔴 ${set.title} 오늘의 라이브 시험(엄격 모드)으로 지정되었습니다!')),
                                  backgroundColor: set.isLiveExam ? Colors.blueGrey : Colors.teal,
                                ),
                              );
                            },
                            icon: Icon(set.isLiveExam ? Icons.cancel_outlined : Icons.flash_on, size: 14),
                            label: Text(set.isLiveExam ? LanguageService.instance.trText(ne: 'लाइभ परीक्षा हटाउनुहोस्', en: 'Remove Live Exam', ko: '라이브 시험 해제') : LanguageService.instance.trText(ne: '🔴 आजको लाइभ परीक्षा बनाउनुहोस्', en: '🔴 Make Live Exam', ko: '🔴 오늘 라이브 시험 설정'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// 2. Set Question Inspector View
  Widget _buildSetQuestionInspector(MockTestSet set) {
    final questions = set.questions;
    final filteredQuestions = questions.asMap().entries.where((entry) {
      final idx = entry.key;
      if (_questionFilter == 'reading') return idx < 20;
      if (_questionFilter == 'listening') return idx >= 20;
      return true;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button & Set Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: LanguageService.instance.trText(ne: 'सबै सेटहरूमा फर्कनुहोस्', en: 'Back to all sets', ko: '모든 세트로 돌아가기'),
                  onPressed: () => setState(() => _selectedSet = null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(LanguageService.instance.trText(ne: 'कुल ४० प्रश्न', en: 'Total 40 Questions', ko: '총 40문항'), style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${set.sector}  •  २० Reading (Q1-20) र २० Listening (Q21-40)', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedSet = null),
                  icon: const Icon(Icons.list, size: 18),
                  label: Text(LanguageService.instance.trText(ne: 'सेट सूची', en: 'Set List', ko: '세트 목록')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Filter Tabs
          Row(
            children: [
              _buildFilterChip(LanguageService.instance.trText(ne: 'सबै ४० प्रश्नहरू (${questions.length})', en: 'All 40 Questions (${questions.length})', ko: '전체 40문항 (${questions.length})'), 'all'),
              const SizedBox(width: 8),
              _buildFilterChip(LanguageService.instance.trText(ne: '📖 रिडिङ (प्रश्न १ ~ २०)', en: '📖 Reading (Q1 ~ 20)', ko: '📖 읽기 (1~20번)'), 'reading'),
              const SizedBox(width: 8),
              _buildFilterChip(LanguageService.instance.trText(ne: '🎧 लिसनिङ (प्रश्न २१ ~ ४०)', en: '🎧 Listening (Q21 ~ 40)', ko: '🎧 듣기 (21~40번)'), 'listening'),
            ],
          ),
          const SizedBox(height: 16),

          // Questions List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredQuestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final entry = filteredQuestions[i];
              final qIndex = entry.key;
              final q = entry.value;
              final qNo = qIndex + 1;
              final isReading = qIndex < 20;
              final ans = set.answerKeys[q.questionId];

              // Modality tags
              bool hasImg = false;
              bool hasAud = false;
              bool hasOptionImg = false;
              List<String> options = [];

              if (q is UniversalQuestion) {
                hasImg = q.hasQuestionImage;
                hasAud = q.hasQuestionAudio;
                hasOptionImg = q.hasOptionImages;
                options = q.textOptions;
              } else if (q is ReadingImageQuestion) {
                hasImg = true;
                options = q.textOptions;
              } else if (q is ReadingTextQuestion) {
                options = q.textOptions;
              } else if (q is ListeningAudioQuestion) {
                hasAud = true;
                options = q.textOptions;
              }

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isReading ? const Color(0xFF1E3A8A) : const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(LanguageService.instance.trText(ne: 'प्रश्न $qNo', en: 'Question $qNo', ko: '문항 $qNo'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text(isReading ? 'READING' : 'LISTENING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isReading ? Colors.blue : Colors.orange)),
                              ),
                              if (hasImg) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(LanguageService.instance.trText(ne: '🖼️ तस्बिर/ग्राफ', en: '🖼️ Image/Graph', ko: '🖼️ 사진/그래프'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                                ),
                              ],
                              if (hasAud) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(LanguageService.instance.trText(ne: '🔊 अडियो', en: '🔊 Audio', ko: '🔊 오디오'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                              ],
                              if (hasOptionImg) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(LanguageService.instance.trText(ne: '🖼️ विकल्पमा चित्र', en: '🖼️ Image in Option', ko: '🖼️ 선택지 이미지'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                                ),
                              ],
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _showQuestionEditorDialog(set, qIndex, q),
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(LanguageService.instance.trText(ne: 'सम्पादन गर्नुहोस्', en: 'Edit', ko: '편집'), style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Question Text
                      Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),

                      // Options Row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: List.generate(options.length, (optIdx) {
                          final isCorrect = ans?.correctIndex == optIdx;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrect ? const Color(0xFFDCFCE7) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300),
                            ),
                            child: Text(
                              '${optIdx + 1}) ${options[optIdx]} ${isCorrect ? "✓" : ""}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                color: isCorrect ? Colors.green.shade900 : Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSel = _questionFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
      selected: isSel,
      selectedColor: const Color(0xFF0F766E),
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _questionFilter = value),
    );
  }

  Widget _buildApprovalQueueSection() {
    final pendingSets = QuestionBankService.instance.getPendingApprovalSets();
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;

    if (pendingSets.isEmpty) {
      if (!isSuperAdmin) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(LanguageService.instance.trText(ne: 'इन्स्टिच्युटहरूबाट स्वीकृतिको लागि कुनै पनि नयाँ सेट बाँकी छैन। सबै प्रश्न सेटहरू स्वीकृत छन्!', en: 'No pending question sets from institutes. All sets are approved!', ko: '학원에서 대기 중인 문제 세트가 없습니다. 모두 승인되었습니다!'), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending_actions, color: Color(0xFFB45309), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    LanguageService.instance.trText(ne: '📥 इन्स्टिच्युटबाट आएका नयाँ प्रश्न सेटहरू (स्वीकृति सूची - ${pendingSets.length} वटा)', en: '📥 New Question Sets from Institutes (Pending Approval - ${pendingSets.length})', ko: '📥 학원에서 제출한 새 문제 세트 (승인 대기 - ${pendingSets.length}개)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                  ),
                ],
              ),
              if (isSuperAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade900, borderRadius: BorderRadius.circular(4)),
                  child: Text(LanguageService.instance.trText(ne: 'सुपर एडमिन स्वीकृति आवश्यक', en: 'Super Admin Approval Required', ko: '최고관리자 승인 필요'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            LanguageService.instance.trText(ne: 'नियम: इन्स्टिच्युटले बनाएका प्रश्न सेटहरू सुपर एडमिनले जाँच र स्वीकृति (Approval) दिएपछि मात्र सबैतिर जान्छन्।', en: 'Rule: Question sets created by institutes will only be published after Super Admin review and approval.', ko: '규칙: 학원에서 생성한 문제 세트는 최고관리자의 검토 및 승인 후에만 배포됩니다.'),
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const Divider(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingSets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final pSet = pendingSets[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.amber.shade100, child: const Icon(Icons.help_outline, color: Colors.amber, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pSet.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${pSet.sector} • ' + LanguageService.instance.trText(ne: 'पठाउने इन्स्टिच्युट: ', en: 'Submitting Institute: ', ko: '제출 학원: ') + (pSet.instituteName ?? LanguageService.instance.trText(ne: 'इन्स्टिच्युट', en: 'Institute', ko: '학원')), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (isSuperAdmin) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setState(() {
                            QuestionBankService.instance.approveMockSet(pSet.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(LanguageService.instance.trText(ne: '✅ ${pSet.title} सबैतिर पठाउनका लागि स्वीकृत गरियो!', en: '✅ ${pSet.title} approved and published for all!', ko: '✅ ${pSet.title} 전체 배포용으로 승인되었습니다!')), backgroundColor: Colors.teal),
                          );
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: Text(LanguageService.instance.trText(ne: '✅ सबैतिर पठाउन स्वीकृत गर्नुहोस्', en: '✅ Approve for All', ko: '✅ 전체 승인 및 배포'), style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setState(() {
                            QuestionBankService.instance.rejectMockSet(pSet.id);
                          });
                        },
                        icon: const Icon(Icons.close, size: 14),
                        label: Text(LanguageService.instance.trText(ne: 'अस्वीकार', en: 'Reject', ko: '반려'), style: const TextStyle(fontSize: 11)),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(LanguageService.instance.trText(ne: '⏳ स्वीकृतिको पर्खाइमा', en: '⏳ Pending Approval', ko: '⏳ 승인 대기중'), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
