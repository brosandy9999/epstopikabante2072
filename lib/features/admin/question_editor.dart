import 'package:flutter/material.dart';
import '../../core/services/question_bank_service.dart';
import '../question_engine/question_template.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/language_service.dart';
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
  final TextEditingController _explanationController = TextEditingController();
  
  int _correctOptionIndex = 0; // कुन अप्सन सही हो भनेर सेट गर्न
  String? _imagePath;
  String? _audioPath;

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      final qId = "Q_CUSTOM_${DateTime.now().millisecondsSinceEpoch}";
      final qText = _questionTextController.text.trim();
      final options = _optionControllers.map((c) => c.text.trim()).toList();
      final explanation = _explanationController.text.trim();

      QuestionTemplate newQ;
      if (_selectedCategory == 'Listening') {
        newQ = ListeningAudioQuestion(
          questionId: qId,
          questionText: qText,
          audioAssetPath: _audioPath ?? 'assets/audio/sample_listening.mp3',
          textOptions: options,
          audioScript: options.isNotEmpty ? options[_correctOptionIndex] : null,
          audioScriptNepali: explanation.isNotEmpty ? explanation : null,
        );
      } else if (_imagePath != null) {
        newQ = ReadingImageQuestion(
          questionId: qId,
          questionText: qText,
          imageAssetPath: _imagePath!,
          textOptions: options,
        );
      } else {
        newQ = ReadingTextQuestion(
          questionId: qId,
          questionText: qText,
          textOptions: options,
        );
      }

      final ans = QuestionAnswerInfo(
        correctIndex: _correctOptionIndex,
        explanation: explanation.isNotEmpty ? explanation : "सही उत्तर छानिएको छ।",
      );

      QuestionBankService.instance.addCustomQuestion(newQ, ans);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.instance.trText(
            ne: "✅ प्रश्न सफलतापूर्वक स्थानीय डाटाबेसमा सुरक्षित भयो!",
            en: "✅ Question saved successfully to local database!",
            ko: "✅ 문항이 로컬 데이터베이스에 저장되었습니다!",
          )),
          backgroundColor: Colors.green,
        ),
      );
      // फारम खाली गर्ने (Reset)
      _questionTextController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      _explanationController.clear();
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
        return SingleChildScrollView(
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
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    onPressed: () async {
                      final file = await FileUploadService.instance.pickImageFile();
                      if (file != null) {
                        setState(() => _imagePath = file.dataUrl);
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(_imagePath == null ? "📁 डिभाइसबाट फोटो रोज्नुहोस्" : "फोटो लोड भयो ✅"),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _imagePath = null),
                    ),
                  ],
                  const SizedBox(width: 15),
                  if (_selectedCategory == 'Listening') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                      onPressed: () async {
                        final file = await FileUploadService.instance.pickAudioFile();
                        if (file != null) {
                          setState(() => _audioPath = file.dataUrl);
                        }
                      },
                      icon: const Icon(Icons.audiotrack),
                      label: Text(_audioPath == null ? "🎵 डिभाइसबाट MP3 रोज्नुहोस्" : "अडियो लोड भयो ✅"),
                    ),
                    if (_audioPath != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.play_circle_filled, color: Colors.green),
                        onPressed: () => AudioPlaybackService.instance.playAudioUrl(_audioPath!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _audioPath = null),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 30),

              // 4 Options
              const Text("४ वटा विकल्पहरू:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctOptionIndex,
                        onChanged: (value) {
                          setState(() => _correctOptionIndex = value!);
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: "Option ${index + 1}",
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) => value!.isEmpty ? "Enter option" : null,
                        ),
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
              )
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
