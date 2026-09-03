import 'package:flutter/material.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/mock_test_model.dart';
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
    '건설/안전 (Construction & Safety)',
    '어업 (Fishery)',
    '실전 종합 (Final Real Exam Simulation)',
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
    final titleCtrl = TextEditingController(text: '제${QuestionBankService.instance.getAllMockSets().length + 1}회 EPS-TOPIK 실전 모의고사');
    final descCtrl = TextEditingController(text: 'आधिकारिक EPS-TOPIK ब्लुप्रिन्ट अनुसार तयार पारिएको २० रिडिङ र २० लिसनिङ सहितको ४० प्रश्नहरूको आधिकारिक परीक्षा सेट।');
    String selectedSector = _sectorsList.first;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.library_add, color: Color(0xFF0F766E), size: 24),
              SizedBox(width: 8),
              Text('नयाँ ४०-प्रश्न सेट सिर्जना गर्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  decoration: const InputDecoration(labelText: 'सेटको शीर्षक (Set Title)*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSector,
                  decoration: const InputDecoration(labelText: 'औद्योगिक क्षेत्र (Sector)*', border: OutlineInputBorder()),
                  items: _sectorsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setDialogState(() => selectedSector = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'विवरण (Description)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'नोट: नयाँ सेट सिर्जना गर्दा स्वतः २० Reading र २० Listening गरी कुल ४० प्रश्नहरूको पूर्ण ब्लुप्रिन्ट तयार हुन्छ, जसलाई तपाईंले तुरुन्तै सम्पादन गर्न सक्नुहुन्छ।',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = 'कृपया सेटको शीर्षक भर्नुहोस्!');
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ नयाँ ४०-प्रश्न सेट सफलतापूर्वक सिर्जना भयो! अब प्रश्नहरू सम्पादन गर्नुहोस्।'), backgroundColor: Colors.teal),
                );
              },
              child: const Text('सेट सिर्जना गर्नुहोस् (Create Set)'),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                              'प्रश्न $questionNo (${isReading ? "READING" : "LISTENING"})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'सेट: ${set.title.split(' ')[0]}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 20),

                  // 1. Question Text
                  const Text('१. प्रश्न वाक्य / निर्देशन (Question Prompt & Text):*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      const Text('२. प्रश्नको तस्बिर / ग्राफ (Question Image or Graph):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () async {
                              final file = await FileUploadService.instance.pickImageFile();
                              if (file != null) {
                                setDialogState(() {
                                  imgCtrl.text = file.dataUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_photo_alternate, size: 18),
                            label: Text(imgCtrl.text.isEmpty ? '📁 डिभाइसबाट तस्बिर अपलोड गर्नुहोस् (Pick Image)' : 'तस्बिर लोड भयो ✅'),
                          ),
                          if (imgCtrl.text.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'तस्बिर हटाउनुहोस्',
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
                          hintText: 'वा वेब तस्बिर URL लिङ्क (Optional URL)',
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
                                const Row(
                                  children: [
                                    Icon(Icons.tune, size: 16, color: Color(0xFFEA580C)),
                                    SizedBox(width: 6),
                                    Text('अडियो प्रकार छनोट (Audio Mode):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9A3412))),
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
                                    const Expanded(
                                      child: Text('केवल अडियो फाइल मात्र (Pure Audio Only - TTS बन्द)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
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
                                    const Expanded(
                                      child: Text('स्वचालित TTS वा दुवै (Auto TTS from Script)', style: TextStyle(fontSize: 12)),
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
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('⚠️ ध्यान दिनुहोस्: यो "केवल अडियो" प्रश्न हो। तलको बटनबाट आफ्नो डिभाइसको वास्तविक MP3 अडियो अपलोड गर्नुहोस्!', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAudioOnly ? '🎧 वास्तविक अडियो फाइल (Pure Uploaded Audio):*' : '🎧 लिसनिङ अडियो (Audio वा TTS):',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                              ),
                              if (!isAudioOnly)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                  onPressed: () {
                                    final textToSpeak = scriptCtrl.text.isNotEmpty ? scriptCtrl.text : textCtrl.text;
                                    if (textToSpeak.isNotEmpty) {
                                      KoreanTtsService.instance.speakKorean(textToSpeak);
                                    }
                                  },
                                  icon: const Icon(Icons.volume_up, size: 16),
                                  label: const Text('TTS सुन्नुहोस्', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEA580C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () async {
                                  final file = await FileUploadService.instance.pickAudioFile();
                                  if (file != null) {
                                    setDialogState(() {
                                      audioCtrl.text = file.dataUrl;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.audio_file, size: 18),
                                label: Text(audioCtrl.text.isEmpty ? '🎵 डिभाइसबाट MP3 अडियो अपलोड गर्नुहोस्' : 'अडियो लोड भयो ✅'),
                              ),
                              if (audioCtrl.text.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => AudioPlaybackService.instance.playAudioUrl(audioCtrl.text),
                                  icon: const Icon(Icons.play_circle_filled, size: 18, color: Colors.green),
                                  label: const Text('प्ले', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'अडियो हटाउनुहोस्',
                                  onPressed: () => setDialogState(() => audioCtrl.clear()),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: audioCtrl,
                            decoration: const InputDecoration(
                              hintText: 'वा वेब अडियो URL लिङ्क (Optional URL)',
                              border: const OutlineInputBorder(),
                              fillColor: Colors.white,
                              filled: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: scriptCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'अडियो कोरियन संवाद (Korean Script)',
                                    border: OutlineInputBorder(),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: scriptNepCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'नेपाली अर्थ (Nepali Translation)',
                                    border: OutlineInputBorder(),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Options 1 to 4 (Support Text, Image, Audio)
                  const Text('४. चारवटा विकल्पहरू (Options 1 ~ 4):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  const Text('प्रत्येक विकल्पमा टेक्स्ट, तस्बिर (URL) वा अडियो राख्न सक्नुहुन्छ:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 10),

                  ...List.generate(4, (i) {
                    final isCorrect = selectedCorrectIndex == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCorrect ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300, width: isCorrect ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: selectedCorrectIndex,
                                activeColor: Colors.green,
                                onChanged: (val) => setDialogState(() => selectedCorrectIndex = val!),
                              ),
                              Text('विकल्प ${i + 1} ${isCorrect ? "✓ (सही उत्तर)" : ""}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isCorrect ? Colors.green.shade800 : Colors.black87)),
                              const Spacer(),
                              if (optionAudioCtrls[i].text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.volume_up, size: 18, color: Colors.orange),
                                  onPressed: () => KoreanTtsService.instance.speakKorean(optionTextCtrls[i].text.isNotEmpty ? optionTextCtrls[i].text : optionAudioCtrls[i].text),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: optionTextCtrls[i],
                                  decoration: InputDecoration(
                                    labelText: 'विकल्प ${i + 1} टेक्स्ट',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: optionImgCtrls[i],
                                  decoration: InputDecoration(
                                    labelText: 'तस्बिर URL (वैकल्पिक)',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.image, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  // 5. Correct Answer & Explanation
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedCorrectIndex,
                          decoration: const InputDecoration(labelText: 'सही उत्तर छान्नुहोस्*', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('विकल्प १ (Option 1)')),
                            DropdownMenuItem(value: 1, child: Text('विकल्प २ (Option 2)')),
                            DropdownMenuItem(value: 2, child: Text('विकल्प ३ (Option 3)')),
                            DropdownMenuItem(value: 3, child: Text('विकल्प ४ (Option 4)')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedCorrectIndex = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: explCtrl,
                          decoration: const InputDecoration(labelText: 'नेपाली व्याख्या (Nepali Explanation)*', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        onPressed: () {
                          final updatedQ = UniversalQuestion(
                            questionId: qId,
                            questionText: textCtrl.text.trim(),
                            questionNumber: questionNo,
                            isListening: !isReading,
                            questionImageUrl: imgCtrl.text.trim().isNotEmpty ? imgCtrl.text.trim() : null,
                            questionAudioUrl: audioCtrl.text.trim().isNotEmpty ? audioCtrl.text.trim() : null,
                            audioScript: scriptCtrl.text.trim().isNotEmpty ? scriptCtrl.text.trim() : null,
                            audioScriptNepali: scriptNepCtrl.text.trim().isNotEmpty ? scriptNepCtrl.text.trim() : null,
                            isAudioOnly: isAudioOnly,
                            textOptions: optionTextCtrls.map((c) => c.text.trim()).toList(),
                            imageOptions: optionImgCtrls.map((c) => c.text.trim().isNotEmpty ? c.text.trim() : null).toList(),
                            audioOptions: optionAudioCtrls.map((c) => c.text.trim().isNotEmpty ? c.text.trim() : null).toList(),
                          );

                          final updatedAns = QuestionAnswerInfo(
                            correctIndex: selectedCorrectIndex,
                            explanation: explCtrl.text.trim().isNotEmpty ? explCtrl.text.trim() : 'आधिकारिक समाधान।',
                          );

                          QuestionBankService.instance.updateQuestionInSet(
                            setId: set.id,
                            questionIndex: qIndex,
                            updatedQuestion: updatedQ,
                            updatedAnswer: updatedAns,
                          );

                          setState(() {
                            _selectedSet = QuestionBankService.instance.getMockSetById(set.id);
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ प्रश्न $questionNo सफलतापूर्वक अद्यावधिक भयो!'), backgroundColor: Colors.teal),
                          );
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('प्रश्न सुरक्षित गर्नुहोस् (Save)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSet != null) {
      return _buildSetQuestionInspector(_selectedSet!);
    }
    return _buildSetsList();
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EPS-TOPIK ४०-प्रश्न सेट व्यवस्थापन केन्द्र',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'प्रत्येक सेटमा २० रिडिङ र २० लिसनिङ प्रश्नहरू समावेश हुन्छन्। नयाँ सेट थप्न र सेट भित्रका प्रश्नहरू सम्पादन गर्न सक्नुहुन्छ।',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateNewSetDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('नयाँ प्रश्न सेट बनाउनुहोस्'),
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
              hintText: 'प्रश्न सेटको शीर्षक वा क्षेत्र खोज्नुहोस्...',
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
                                  child: const Text('४० प्रश्नहरू (२० R + २० L)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                ),
                                if (set.isLiveExam)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.radio_button_checked, size: 12, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text('🔴 आजको लाइभ परीक्षा (Daily Live)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
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
                                    set.isApproved ? '🟢 स्वीकृत (Approved for All)' : '⏳ सुपर एडमिन स्वीकृतिको पर्खाइमा',
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
                            label: const Text('४० प्रश्नहरू व्यवस्थापन गर्नुहोस्', style: TextStyle(fontSize: 12)),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(set.isLiveExam ? 'लाइभ परीक्षा हटाइयो।' : '🔴 ${set.title} आजको दैनिक लाइभ परीक्षा (Strict Mode) को रूपमा तोकियो!'),
                                  backgroundColor: set.isLiveExam ? Colors.blueGrey : Colors.teal,
                                ),
                              );
                            },
                            icon: Icon(set.isLiveExam ? Icons.cancel_outlined : Icons.flash_on, size: 14),
                            label: Text(set.isLiveExam ? 'लाइभ परीक्षा हटाउनुहोस्' : '🔴 आजको लाइभ परीक्षा बनाउनुहोस्', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                  tooltip: 'सबै सेटहरूमा फर्कनुहोस्',
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
                            child: const Text('कुल ४० प्रश्न', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  label: const Text('सेट सूची (Back to Sets)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Filter Tabs
          Row(
            children: [
              _buildFilterChip('सबै ४० प्रश्नहरू (${questions.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('📖 रिडिङ (प्रश्न १ ~ २०)', 'reading'),
              const SizedBox(width: 8),
              _buildFilterChip('🎧 लिसनिङ (प्रश्न २१ ~ ४०)', 'listening'),
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
                                child: Text('प्रश्न $qNo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                  child: const Text('🖼️ तस्बिर/ग्राफ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                                ),
                              ],
                              if (hasAud) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('🔊 अडियो', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ),
                              ],
                              if (hasOptionImg) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('🖼️ विकल्पमा चित्र', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
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
                            label: const Text('सम्पादन गर्नुहोस्', style: TextStyle(fontSize: 12)),
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
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('इन्स्टिच्युटहरूबाट स्वीकृतिको लागि कुनै पनि नयाँ सेट बाँकी छैन। सबै प्रश्न सेटहरू स्वीकृत छन्!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    '📥 इन्स्टिच्युटबाट आएका नयाँ प्रश्न सेटहरू (स्वीकृति सूची - ${pendingSets.length} वटा)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E)),
                  ),
                ],
              ),
              if (isSuperAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade900, borderRadius: BorderRadius.circular(4)),
                  child: const Text('सुपर एडमिन स्वीकृति आवश्यक', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'नियम: इन्स्टिच्युटले बनाएका प्रश्न सेटहरू सुपर एडमिनले जाँच र स्वीकृति (Approval) दिएपछि मात्र सबैतिर जान्छन्।',
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
                          Text('${pSet.sector} • पठाउने इन्स्टिच्युट: ${pSet.instituteName ?? "इन्स्टिच्युट"}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
                            SnackBar(content: Text('✅ ${pSet.title} सबैतिर पठाउनका लागि स्वीकृत गरियो!'), backgroundColor: Colors.teal),
                          );
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('✅ सबैतिर पठाउन स्वीकृत गर्नुहोस्', style: TextStyle(fontSize: 11)),
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
                        label: const Text('अस्वीकार', style: TextStyle(fontSize: 11)),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: const Text('⏳ स्वीकृतिको पर्खाइमा', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
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
