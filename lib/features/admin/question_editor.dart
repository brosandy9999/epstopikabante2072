import '../../core/services/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import '../../core/services/question_bank_service.dart';
import '../question_engine/question_template.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/language_service.dart';
import '../../core/widgets/app_exit_dialog.dart';
import '../../core/widgets/smart_image_widget.dart';

/// Phase 11: Question Editor (रुल २९)
/// यो स्क्रिनबाट एडमिन/शिक्षकले नयाँ प्रश्नहरू टाइप गर्ने, फोटो हाल्ने र डेटाबेसमा सेभ गर्ने काम गर्छन्।
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedCategory = 'Reading';
  final TextEditingController _questionTextController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _optionImgControllers = List.generate(4, (index) => TextEditingController());
  final List<TextEditingController> _optionAudioControllers = List.generate(4, (index) => TextEditingController());
  final TextEditingController _explanationController = TextEditingController();
  
  int _correctOptionIndex = 0; // कुन अप्सन सही हो भनेर सेट गर्न
  String? _imagePath;
  String? _audioPath;

  @override
  void dispose() {
    AudioPlaybackService.instance.stop();
    _questionTextController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    for (var c in _optionImgControllers) {
      c.dispose();
    }
    for (var c in _optionAudioControllers) {
      c.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  bool _hasUnsavedData() {
    if (_questionTextController.text.trim().isNotEmpty) return true;
    if (_explanationController.text.trim().isNotEmpty) return true;
    if (_imagePath != null || _audioPath != null) return true;
    for (final c in _optionControllers) {
      if (c.text.trim().isNotEmpty) return true;
    }
    for (final c in _optionImgControllers) {
      if (c.text.trim().isNotEmpty) return true;
    }
    for (final c in _optionAudioControllers) {
      if (c.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: 'परिवर्तनहरू सुरक्षित गर्ने? (Save Changes?)',
                    en: 'Save Question Changes?',
                    ko: '문항 변경 사항을 저장하시겠습니까?',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            LanguageService.instance.trText(
              ne: 'यो प्रश्न सुरक्षित भई स्वतः क्लाउड तथा सबै डिभाइसहरूमा पृष्ठभूमिमा सिङ्क हुनेछ। के तपाईं सुरक्षित गर्न निश्चित हुनुहुन्छ?',
              en: 'This question will be saved and automatically synced to the cloud in the background. Do you wish to proceed?',
              ko: '저장된 문항은 배경에서 클라우드로 자동 동기화됩니다. 계속하시겠습니까?',
            ),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
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
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final qId = "Q_CUSTOM_${DateTime.now().millisecondsSinceEpoch}";
      final qText = _questionTextController.text.trim();
      final options = _optionControllers.map((c) => c.text.trim()).toList();
      final optionImages = _optionImgControllers.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList();
      final optionAudios = _optionAudioControllers.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList();
      final explanation = _explanationController.text.trim();

      QuestionTemplate newQ;
      if (_selectedCategory == 'Listening') {
        newQ = UniversalQuestion(
          questionId: qId,
          questionNumber: 21,
          questionText: qText,
          isListening: true,
          questionAudioUrl: _audioPath ?? 'assets/audio/sample_listening.mp3',
          questionImageUrl: _imagePath,
          textOptions: options,
          imageOptions: optionImages,
          audioOptions: optionAudios,
          audioScript: options.isNotEmpty ? options[_correctOptionIndex] : null,
          audioScriptNepali: explanation.isNotEmpty ? explanation : null,
        );
      } else {
        newQ = UniversalQuestion(
          questionId: qId,
          questionNumber: 1,
          questionText: qText,
          isListening: false,
          questionImageUrl: _imagePath,
          textOptions: options,
          imageOptions: optionImages,
          audioOptions: optionAudios,
        );
      }

      final ans = QuestionAnswerInfo(
        correctIndex: _correctOptionIndex,
        explanation: explanation.isNotEmpty ? explanation : "सही उत्तर छानिएको छ।",
      );

      QuestionBankService.instance.addCustomQuestion(newQ, ans);
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);

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
                      ne: "✅ प्रश्न सफलतापूर्वक सुरक्षित भयो र क्लाउडमा स्वतः सिङ्क भयो!",
                      en: "✅ Question saved and auto-synced to cloud in background!",
                      ko: "✅ 문항이 저장되었으며 클라우드에 자동 동기화되었습니다!",
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

      // फारम खाली गर्ने (Reset)
      _questionTextController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      for (var controller in _optionImgControllers) {
        controller.clear();
      }
      for (var controller in _optionAudioControllers) {
        controller.clear();
      }
      _explanationController.clear();
      AudioPlaybackService.instance.stop();
      setState(() {
        _imagePath = null;
        _audioPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        return PopScope(
          canPop: !_hasUnsavedData(),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldLeave = await showActionExitConfirmationDialog(
              context,
              titleNe: 'फारम छोड्ने निश्चित हुनुहुन्छ?',
              titleEn: 'Discard Question Draft?',
              titleKo: '작성 중인 문항을 취소하시겠습니까?',
              messageNe: 'तपाईंले भर्नुभएको प्रश्न विवरण अझै सेभ भएको छैन। बाहिर निस्कँदा नलेखिएको डाटा हराउन सक्छ।',
              messageEn: 'Your question draft has unsaved changes. Leaving now will discard these changes.',
              messageKo: '저장되지 않은 문항 변경 사항이 있습니다. 지금 나가시면 작성 중인 데이터가 삭제됩니다.',
              confirmBtnNe: 'हो, बाहिर निस्कनुहोस्',
              confirmBtnEn: 'Discard & Leave',
              confirmBtnKo: '나가기',
              cancelBtnNe: 'रद्द गर्नुहोस्',
              cancelBtnEn: 'Keep Editing',
              cancelBtnKo: '계속 작성',
              isDestructive: true,
            );
            if (shouldLeave == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.trText(
                      ne: "नयाँ प्रश्न बनाउनुहोस्",
                      en: "Create New Question",
                      ko: "새 문항 작성",
                    ),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),

              // Category Selection (Reading or Listening)
              Row(
                children: [
                  const Text("Category:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: ['Reading', 'Listening'].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Question Text
              TextFormField(
                controller: _questionTextController,
                decoration: const InputDecoration(
                  labelText: "प्रश्न वाक्य",
                  border: OutlineInputBorder(),
                  hintText: "जस्तै: 빈칸에 들어갈 가장 알맞은 것을 고르십시오.",
                ),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? "Please enter question text" : null,
              ),
              const SizedBox(height: 20),

              // Image / Audio Attachment (Rule 18, 24)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    onPressed: () async {
                      final file = await FileUploadService.instance.pickImageFile();
                      if (file != null) {
                        setState(() => _imagePath = file.dataUrl);
                      }
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: Text(_imagePath == null ? "📁 डिभाइसबाट फोटो" : "फोटो लोड भयो ✅", style: const TextStyle(fontSize: 12)),
                  ),
                  if (_imagePath != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _imagePath = null),
                      tooltip: 'Remove Image',
                    ),
                  ],
                  if (_selectedCategory == 'Listening') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                      onPressed: () async {
                        final file = await FileUploadService.instance.pickAudioFile();
                        if (file != null) {
                          setState(() => _audioPath = file.dataUrl);
                        }
                      },
                      icon: const Icon(Icons.audiotrack, size: 18),
                      label: Text(_audioPath == null ? "🎵 डिभाइसबाट MP3" : "अडियो लोड भयो ✅", style: const TextStyle(fontSize: 12)),
                    ),
                    if (_audioPath != null) ...[
                      IconButton(
                        icon: const Icon(Icons.play_circle_filled, color: Colors.green),
                        onPressed: () => AudioPlaybackService.instance.playAudioUrl(_audioPath!),
                        tooltip: 'Play Audio',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _audioPath = null),
                        tooltip: 'Remove Audio',
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 30),

              // 4 Options
              Text(
                lang.trText(ne: "४ वटा विकल्पहरू:", en: "4 Options:", ko: "4개 보기 항목:"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...List.generate(4, (index) {
                final isCorrect = _correctOptionIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.teal.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect ? Colors.teal.shade600 : Colors.grey.shade300,
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
                            groupValue: _correctOptionIndex,
                            activeColor: Colors.teal.shade700,
                            onChanged: (value) {
                              setState(() => _correctOptionIndex = value!);
                            },
                          ),
                          Text(
                            '${lang.trText(ne: "विकल्प", en: "Option", ko: "보기")} ${index + 1}${isCorrect ? " (✅ ${lang.trText(ne: "सही उत्तर", en: "Correct Answer", ko: "정답")})" : ""}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isCorrect ? Colors.teal.shade800 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: '${lang.trText(ne: "विकल्प", en: "Option", ko: "보기")} ${index + 1} ${lang.trText(ne: "पाठ / वाक्य", en: "Text", ko: "텍스트")}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) => value!.isEmpty ? "Enter option" : null,
                      ),
                      const SizedBox(height: 8),
                      // Option Image (Responsive Wrap / Row)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final pasted = await FileUploadService.instance.pasteImageFromClipboard();
                              if (pasted != null) {
                                setState(() {
                                  _optionImgControllers[index].text = pasted.bestUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.content_paste_rounded, size: 14),
                            label: Text(lang.trText(ne: 'पेस्ट', en: 'Paste', ko: '붙여넣기'), style: const TextStyle(fontSize: 11)),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final file = await FileUploadService.instance.pickImageFile();
                              if (file != null) {
                                setState(() {
                                  _optionImgControllers[index].text = file.bestUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.image, size: 14),
                            label: Text(lang.trText(ne: 'तस्बिर', en: 'Image', ko: '사진'), style: const TextStyle(fontSize: 11)),
                          ),
                          if (_optionImgControllers[index].text.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => setState(() => _optionImgControllers[index].clear()),
                              tooltip: 'Remove',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _optionImgControllers[index],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: lang.trText(ne: 'तस्बिर URL वा Base64', en: 'Image URL or Base64', ko: '이미지 URL'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                      if (_optionImgControllers[index].text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SmartImageWidget(imageSource: _optionImgControllers[index].text, height: 45, fit: BoxFit.contain),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Option Audio (Responsive Wrap / Row)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEA580C),
                              side: BorderSide(color: Colors.orange.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () async {
                              final file = await FileUploadService.instance.pickAudioFile();
                              if (file != null) {
                                setState(() {
                                  _optionAudioControllers[index].text = file.bestUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.audiotrack, size: 14),
                            label: Text(
                              lang.trText(ne: 'विकल्प अडियो', en: 'Option Audio', ko: '보기 오디오'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_optionAudioControllers[index].text.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
                              tooltip: lang.trText(ne: 'अडियो सुन्नुहोस्', en: 'Play Audio', ko: '오디오 재생'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                AudioPlaybackService.instance.playAudioUrl(_optionAudioControllers[index].text.trim());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              tooltip: lang.trText(ne: 'अडियो हटाउनुहोस्', en: 'Remove Audio', ko: '오디오 삭제'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() {
                                _optionAudioControllers[index].clear();
                                AudioPlaybackService.instance.stop();
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _optionAudioControllers[index],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: lang.trText(
                            ne: 'अडियो URL वा MP3/WAV फाइल',
                            en: 'Audio URL or MP3/WAV file',
                            ko: '보기용 오디오 URL 또는 파일',
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          suffixIcon: _optionAudioControllers[index].text.isNotEmpty
                              ? const Icon(Icons.music_note, color: Colors.orange, size: 16)
                              : null,
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
              const Text("💡 Note: Select the radio button for the correct answer.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // Explanation
              TextFormField(
                controller: _explanationController,
                decoration: InputDecoration(
                  labelText: lang.trText(ne: "विस्तृत व्याख्या", en: "Detailed Explanation", ko: "정답 상세 해설"),
                  border: const OutlineInputBorder(),
                  hintText: lang.trText(
                    ne: "विद्यार्थीले Study Mode मा हेर्ने व्याख्या लेख्नुहोस्।",
                    en: "Write explanation visible to students in review mode.",
                    ko: "오답노트 및 학습 모드에서 표시될 해설을 입력하세요.",
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),

              // Save Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveQuestion,
                  icon: const Icon(Icons.save),
                  label: Text(
                    lang.trText(
                      ne: "डेटाबेसमा प्रश्न सुरक्षित गर्नुहोस्",
                      en: "Save Question to Database",
                      ko: "문항 데이터베이스에 저장하기",
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
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
}
