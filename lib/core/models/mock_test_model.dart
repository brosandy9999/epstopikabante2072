import '../../features/question_engine/question_template.dart';
import '../services/question_bank_service.dart';

class MockTestSet {
  final String id;
  final String title;
  final String sector;
  final String description;
  final int totalQuestions;
  final int durationMinutes;
  final double passMarks;
  final List<QuestionTemplate> questions;
  final Map<String, QuestionAnswerInfo> answerKeys;
  final bool isApproved;
  final String createdByRole; // 'superAdmin' or 'admin'
  final String? instituteId;
  final String? instituteName;
  final bool isLiveExam;
  final String? liveExamDate;
  final bool isStrictMode;
  final String? listeningSectionQrUrl;
  final Map<String, String>? listeningQrCodes; // questionId or questionNumber (e.g. '21') -> qrCodeUrl/base64

  const MockTestSet({
    required this.id,
    required this.title,
    required this.sector,
    required this.description,
    this.totalQuestions = 40,
    this.durationMinutes = 50,
    this.passMarks = 50.0,
    required this.questions,
    required this.answerKeys,
    this.isApproved = true,
    this.createdByRole = 'superAdmin',
    this.instituteId,
    this.instituteName,
    this.isLiveExam = false,
    this.liveExamDate,
    this.isStrictMode = true,
    this.listeningSectionQrUrl,
    this.listeningQrCodes,
  });

  int get readingQuestionCount =>
      questions.where((q) => q is ReadingTextQuestion || (q is UniversalQuestion && !q.isListening)).length;

  int get listeningQuestionCount =>
      questions.where((q) => q is ListeningAudioQuestion || (q is UniversalQuestion && q.isListening)).length;

  MockTestSet copyWith({
    String? id,
    String? title,
    String? sector,
    String? description,
    int? totalQuestions,
    int? durationMinutes,
    double? passMarks,
    List<QuestionTemplate>? questions,
    Map<String, QuestionAnswerInfo>? answerKeys,
    bool? isApproved,
    String? createdByRole,
    String? instituteId,
    String? instituteName,
    bool? isLiveExam,
    String? liveExamDate,
    bool? isStrictMode,
    String? listeningSectionQrUrl,
    Map<String, String>? listeningQrCodes,
  }) {
    return MockTestSet(
      id: id ?? this.id,
      title: title ?? this.title,
      sector: sector ?? this.sector,
      description: description ?? this.description,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      passMarks: passMarks ?? this.passMarks,
      questions: questions ?? this.questions,
      answerKeys: answerKeys ?? this.answerKeys,
      isApproved: isApproved ?? this.isApproved,
      createdByRole: createdByRole ?? this.createdByRole,
      instituteId: instituteId ?? this.instituteId,
      instituteName: instituteName ?? this.instituteName,
      isLiveExam: isLiveExam ?? this.isLiveExam,
      liveExamDate: liveExamDate ?? this.liveExamDate,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      listeningSectionQrUrl: listeningSectionQrUrl ?? this.listeningSectionQrUrl,
      listeningQrCodes: listeningQrCodes ?? this.listeningQrCodes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sector': sector,
    'description': description,
    'totalQuestions': totalQuestions,
    'durationMinutes': durationMinutes,
    'passMarks': passMarks,
    'isApproved': isApproved,
    'createdByRole': createdByRole,
    'instituteId': instituteId,
    'instituteName': instituteName,
    'isLiveExam': isLiveExam,
    'liveExamDate': liveExamDate,
    'isStrictMode': isStrictMode,
    'listeningSectionQrUrl': listeningSectionQrUrl,
    'listeningQrCodes': listeningQrCodes,
    'questions': questions.asMap().entries.map((entry) {
      final idx = entry.key;
      final q = entry.value;
      if (q is UniversalQuestion) return q.toJson();
      if (q is ReadingTextQuestion) {
        return {
          'type': 'UniversalQuestion',
          'questionId': q.questionId,
          'questionText': q.questionText,
          'questionNumber': idx + 1,
          'isListening': false,
          'textOptions': q.textOptions,
        };
      }
      if (q is ReadingImageQuestion) {
        return {
          'type': 'UniversalQuestion',
          'questionId': q.questionId,
          'questionText': q.questionText,
          'questionNumber': idx + 1,
          'isListening': false,
          'questionImageUrl': q.imageAssetPath,
          'textOptions': q.textOptions,
        };
      }
      if (q is ListeningAudioQuestion) {
        return {
          'type': 'UniversalQuestion',
          'questionId': q.questionId,
          'questionText': q.questionText,
          'questionNumber': idx + 1,
          'isListening': true,
          'questionAudioUrl': q.audioAssetPath,
          'textOptions': q.textOptions,
          'audioScript': q.audioScript,
          'audioScriptNepali': q.audioScriptNepali,
        };
      }
      if (q is ListeningImageOptionsQuestion) {
        return {
          'type': 'UniversalQuestion',
          'questionId': q.questionId,
          'questionText': q.questionText,
          'questionNumber': idx + 1,
          'isListening': true,
          'questionAudioUrl': q.audioAssetPath,
          'imageOptions': q.imageOptionPaths,
          'textOptions': const ['', '', '', ''],
          'audioScript': q.audioScript,
          'audioScriptNepali': q.audioScriptNepali,
        };
      }
      return {
        'type': 'UniversalQuestion',
        'questionId': q.questionId,
        'questionText': q.questionText,
        'questionNumber': idx + 1,
        'isListening': idx >= 20,
        'textOptions': const ['', '', '', ''],
      };
    }).toList(),
    'answerKeys': answerKeys.map((k, v) => MapEntry(k, {
      'correctIndex': v.correctIndex,
      'explanation': v.explanation,
    })),
  };

  factory MockTestSet.fromJson(Map<String, dynamic> json) {
    final rawQ = json['questions'] as List? ?? [];
    final List<QuestionTemplate> parsedQ = [];
    for (int i = 0; i < rawQ.length; i++) {
      final item = rawQ[i];
      if (item is Map) {
        parsedQ.add(UniversalQuestion.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final rawAns = json['answerKeys'] as Map? ?? {};
    final Map<String, QuestionAnswerInfo> parsedAns = {};
    rawAns.forEach((k, v) {
      if (v is Map) {
        final vMap = Map<String, dynamic>.from(v);
        parsedAns[k.toString()] = QuestionAnswerInfo(
          correctIndex: vMap['correctIndex'] as int? ?? 0,
          explanation: vMap['explanation'] as String? ?? '',
        );
      }
    });

    Map<String, String>? parsedQrMap;
    if (json['listeningQrCodes'] is Map) {
      parsedQrMap = {};
      (json['listeningQrCodes'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          parsedQrMap![k.toString()] = v.toString();
        }
      });
    }

    return MockTestSet(
      id: json['id'] as String? ?? 'set_custom',
      title: json['title'] as String? ?? 'नयाँ मोडल सेट',
      sector: json['sector'] as String? ?? '제조업 (Manufacturing)',
      description: json['description'] as String? ?? '',
      totalQuestions: json['totalQuestions'] as int? ?? 40,
      durationMinutes: json['durationMinutes'] as int? ?? 50,
      passMarks: (json['passMarks'] as num?)?.toDouble() ?? 50.0,
      isApproved: json['isApproved'] as bool? ?? true,
      createdByRole: json['createdByRole'] as String? ?? 'superAdmin',
      instituteId: json['instituteId'] as String?,
      instituteName: json['instituteName'] as String?,
      isLiveExam: json['isLiveExam'] as bool? ?? false,
      liveExamDate: json['liveExamDate'] as String?,
      isStrictMode: json['isStrictMode'] as bool? ?? true,
      listeningSectionQrUrl: json['listeningSectionQrUrl'] as String?,
      listeningQrCodes: parsedQrMap,
      questions: parsedQ,
      answerKeys: parsedAns,
    );
  }
}
