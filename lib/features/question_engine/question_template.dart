// Phase 4: Question Engine
// This file defines the different templates for EPS-TOPIK questions (Rule 16).

/// Base class for all EPS-TOPIK questions
abstract class QuestionTemplate {
  final String questionId;
  final String questionText;
  
  QuestionTemplate({
    required this.questionId,
    required this.questionText,
  });
}

// ---------------------------------------------------------
// READING QUESTIONS (रिडिङ सेक्सनका प्रकारहरू)
// ---------------------------------------------------------

/// 1. Text Question with Text Options (साधारण टेक्स्ट प्रश्न)
class ReadingTextQuestion extends QuestionTemplate {
  final List<String> textOptions;

  ReadingTextQuestion({
    required super.questionId,
    required super.questionText,
    required this.textOptions,
  });
}

/// 2. Image Question with Text Options (तस्बिर हेरेर उत्तर दिने - जस्तै Signboard)
class ReadingImageQuestion extends QuestionTemplate {
  final String imageAssetPath;
  final List<String> textOptions;

  ReadingImageQuestion({
    required super.questionId,
    required super.questionText,
    required this.imageAssetPath,
    required this.textOptions,
  });
}

// ---------------------------------------------------------
// LISTENING QUESTIONS (लिस्टेनिङ सेक्सनका प्रकारहरू)
// ---------------------------------------------------------

/// 3. Audio Question with Text Options (अडियो सुनेर टेक्स्ट छान्ने)
class ListeningAudioQuestion extends QuestionTemplate {
  final String audioAssetPath;
  final List<String> textOptions;
  final String? audioScript;
  final String? audioScriptNepali;

  ListeningAudioQuestion({
    required super.questionId,
    required super.questionText,
    required this.audioAssetPath,
    required this.textOptions,
    this.audioScript,
    this.audioScriptNepali,
  });
}

/// 4. Audio Question with Image Options (अडियो सुनेर ४ वटा तस्बिरमध्ये एउटा छान्ने)
class ListeningImageOptionsQuestion extends QuestionTemplate {
  final String audioAssetPath;
  final List<String> imageOptionPaths; // ४ वटा तस्बिरका बाटाहरू (Paths)
  final String? audioScript;
  final String? audioScriptNepali;

  ListeningImageOptionsQuestion({
    required super.questionId,
    required super.questionText,
    required this.audioAssetPath,
    required this.imageOptionPaths,
    this.audioScript,
    this.audioScriptNepali,
  });
}

/// 5. Universal Multi-Modal EPS-TOPIK Question
/// Supports ALL variations of Reading (Q1-Q20) and Listening (Q21-Q40):
/// - Question: Text, Image/Graph, Audio (or combination)
/// - Options 1-4: Text, Image, Audio (or combination)
class UniversalQuestion extends QuestionTemplate {
  final int questionNumber; // 1 to 40
  final bool isListening; // false: Reading (Q1-20), true: Listening (Q21-40)
  final String? questionImageUrl;
  final String? questionAudioUrl;
  final String? audioScript;
  final String? audioScriptNepali;
  final bool isAudioOnly;

  final List<String> textOptions;
  final List<String?> imageOptions;
  final List<String?> audioOptions;

  UniversalQuestion({
    required super.questionId,
    required super.questionText,
    required this.questionNumber,
    required this.isListening,
    this.questionImageUrl,
    this.questionAudioUrl,
    this.audioScript,
    this.audioScriptNepali,
    this.isAudioOnly = false,
    required this.textOptions,
    List<String?>? imageOptions,
    List<String?>? audioOptions,
  })  : imageOptions = imageOptions ?? const [null, null, null, null],
        audioOptions = audioOptions ?? const [null, null, null, null];

  bool get hasQuestionImage => questionImageUrl != null && questionImageUrl!.trim().isNotEmpty;
  bool get hasQuestionAudio => questionAudioUrl != null && questionAudioUrl!.trim().isNotEmpty;
  bool get hasOptionImages => imageOptions.any((img) => img != null && img.trim().isNotEmpty);
  bool get hasOptionAudios => audioOptions.any((aud) => aud != null && aud.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'questionText': questionText,
    'questionNumber': questionNumber,
    'isListening': isListening,
    'questionImageUrl': questionImageUrl,
    'questionAudioUrl': questionAudioUrl,
    'audioScript': audioScript,
    'audioScriptNepali': audioScriptNepali,
    'isAudioOnly': isAudioOnly,
    'textOptions': textOptions,
    'imageOptions': imageOptions,
    'audioOptions': audioOptions,
  };

  factory UniversalQuestion.fromJson(Map<String, dynamic> json) => UniversalQuestion(
    questionId: json['questionId'] as String? ?? 'q_01',
    questionText: json['questionText'] as String? ?? '',
    questionNumber: json['questionNumber'] as int? ?? 1,
    isListening: json['isListening'] as bool? ?? false,
    questionImageUrl: json['questionImageUrl'] as String?,
    questionAudioUrl: json['questionAudioUrl'] as String?,
    audioScript: json['audioScript'] as String?,
    audioScriptNepali: json['audioScriptNepali'] as String?,
    isAudioOnly: json['isAudioOnly'] as bool? ?? false,
    textOptions: (json['textOptions'] as List?)?.map((e) => e.toString()).toList() ?? ['', '', '', ''],
    imageOptions: (json['imageOptions'] as List?)?.map((e) => e?.toString()).toList(),
    audioOptions: (json['audioOptions'] as List?)?.map((e) => e?.toString()).toList(),
  );
}

