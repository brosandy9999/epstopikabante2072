import 'package:flutter/material.dart';
import '../../features/question_engine/question_template.dart';
import 'exam_service.dart';
import 'question_bank_service.dart';

enum TopicProficiency { critical, moderate, strong }

class TopicDiagnostic {
  final String id;
  final String titleNe;
  final String titleKo;
  final IconData icon;
  final Color color;
  final int totalQuestions;
  final int mistakes;
  final double accuracy;
  final TopicProficiency proficiency;
  final String adviceNe;

  TopicDiagnostic({
    required this.id,
    required this.titleNe,
    required this.titleKo,
    required this.icon,
    required this.color,
    required this.totalQuestions,
    required this.mistakes,
    required this.accuracy,
    required this.proficiency,
    required this.adviceNe,
  });
}

class WeaknessAnalysisService {
  static final WeaknessAnalysisService instance = WeaknessAnalysisService._internal();
  WeaknessAnalysisService._internal();

  final Map<String, Set<String>> _resolvedMistakes = {};

  void markQuestionResolved(String studentId, String questionId) {
    _resolvedMistakes.putIfAbsent(studentId, () => <String>{}).add(questionId);
  }

  bool isQuestionResolved(String studentId, String questionId) {
    return _resolvedMistakes[studentId]?.contains(questionId) ?? false;
  }

  String categorizeQuestion(QuestionTemplate q, int questionIndex) {
    if (q is ReadingTextQuestion) {
      if (questionIndex < 5) return 'visual_signs';
      if (questionIndex < 10) return 'grammar_vocab';
      if (questionIndex < 15) return 'notices_graphs';
      return 'reading_passage';
    } else {
      if (questionIndex < 26) return 'listening_words';
      if (questionIndex < 33) return 'listening_response';
      return 'listening_dialogue';
    }
  }

  List<TopicDiagnostic> analyzeStudent(String studentId) {
    final attempts = ExamHistoryService.instance.getAttemptsForStudent(studentId);
    final answerKeys = QuestionBankService.instance.getAnswerKeys();

    final Map<String, List<int>> stats = {
      'visual_signs': [0, 0],
      'grammar_vocab': [0, 0],
      'notices_graphs': [0, 0],
      'reading_passage': [0, 0],
      'listening_words': [0, 0],
      'listening_response': [0, 0],
      'listening_dialogue': [0, 0],
    };

    if (attempts.isEmpty) {
      return _generateDefaultDiagnostics();
    }

    for (final att in attempts) {
      final questions = QuestionBankService.instance.getFull40ExamQuestions();
      final answers = att.userAnswers;

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final topic = categorizeQuestion(q, i);
        if (!stats.containsKey(topic)) continue;

        stats[topic]![0]++;

        final selected = answers[i];
        final keyInfo = answerKeys[q.questionId];
        final isCorrect = (selected != null && keyInfo != null && selected == keyInfo.correctIndex);
        if (!isCorrect) {
          stats[topic]![1]++;
        }
      }
    }

    final List<TopicDiagnostic> results = [];
    final meta = _topicMeta();

    stats.forEach((topicId, data) {
      final total = data[0];
      final mistakes = data[1];
      final correct = total - mistakes;
      final accuracy = total > 0 ? (correct / total) : 0.0;

      TopicProficiency prof;
      if (total == 0) {
        prof = TopicProficiency.moderate;
      } else if (accuracy < 0.55) {
        prof = TopicProficiency.critical;
      } else if (accuracy < 0.80) {
        prof = TopicProficiency.moderate;
      } else {
        prof = TopicProficiency.strong;
      }

      final info = meta[topicId]!;
      results.add(
        TopicDiagnostic(
          id: topicId,
          titleNe: info['titleNe'] as String,
          titleKo: info['titleKo'] as String,
          icon: info['icon'] as IconData,
          color: info['color'] as Color,
          totalQuestions: total,
          mistakes: mistakes,
          accuracy: accuracy,
          proficiency: prof,
          adviceNe: info['adviceNe'] as String,
        ),
      );
    });

    results.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return results;
  }

  List<QuestionTemplate> getWeakQuestions(String studentId, {String? topicFilter}) {
    final attempts = ExamHistoryService.instance.getAttemptsForStudent(studentId);
    final answerKeys = QuestionBankService.instance.getAnswerKeys();
    final Set<String> seenQuestionIds = {};
    final List<QuestionTemplate> mistakeQuestions = [];

    for (final att in attempts) {
      final questions = QuestionBankService.instance.getFull40ExamQuestions();
      final answers = att.userAnswers;

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (seenQuestionIds.contains(q.questionId)) continue;
        if (isQuestionResolved(studentId, q.questionId)) continue;

        final topic = categorizeQuestion(q, i);
        if (topicFilter != null && topic != topicFilter) continue;

        final selected = answers[i];
        final keyInfo = answerKeys[q.questionId];
        final isCorrect = (selected != null && keyInfo != null && selected == keyInfo.correctIndex);
        if (!isCorrect) {
          seenQuestionIds.add(q.questionId);
          mistakeQuestions.add(q);
        }
      }
    }

    if (mistakeQuestions.isEmpty) {
      final allMockQuestions = QuestionBankService.instance.getFull40ExamQuestions();
      if (topicFilter != null) {
        return allMockQuestions
            .asMap()
            .entries
            .where((e) => categorizeQuestion(e.value, e.key) == topicFilter)
            .map((e) => e.value)
            .take(10)
            .toList();
      }
      return allMockQuestions.take(15).toList();
    }

    return mistakeQuestions;
  }

  List<TopicDiagnostic> _generateDefaultDiagnostics() {
    final meta = _topicMeta();
    final List<TopicDiagnostic> defaults = [];
    meta.forEach((id, info) {
      defaults.add(
        TopicDiagnostic(
          id: id,
          titleNe: info['titleNe'] as String,
          titleKo: info['titleKo'] as String,
          icon: info['icon'] as IconData,
          color: info['color'] as Color,
          totalQuestions: 0,
          mistakes: 0,
          accuracy: 0.70,
          proficiency: TopicProficiency.moderate,
          adviceNe: info['adviceNe'] as String,
        ),
      );
    });
    return defaults;
  }

  Map<String, Map<String, dynamic>> _topicMeta() {
    return {
      'visual_signs': {
        'titleNe': 'चित्र तथा सुरक्षा/ट्राफिक संकेत',
        'titleKo': '표지판 및 그림 어휘',
        'icon': Icons.image_search,
        'color': const Color(0xFF2563EB),
        'adviceNe': 'साइनबोर्ड र औजारका नामहरू बढी दोहोर्याउनुहोस्।',
      },
      'grammar_vocab': {
        'titleNe': 'व्याकरण तथा खाली ठाउँ भर्ने',
        'titleKo': '빈칸 문법 및 어휘',
        'icon': Icons.edit_note,
        'color': const Color(0xFF7C3AED),
        'adviceNe': '은/는, 이/가, -아서/어서, -으려고 जस्ता व्याकरण नियमहरू याद गर्नुहोस्।',
      },
      'notices_graphs': {
        'titleNe': 'सूचना पाटी, बिल र ग्राफ विश्लेषण',
        'titleKo': '안내문, 영수증, 그래프 분석',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF0D9488),
        'adviceNe': 'सबैभन्दा धेरै (가장 많은) र कम (가장 적은) प्रतिशत ध्यान दिनुहोस्।',
      },
      'reading_passage': {
        'titleNe': 'छोटो अनुच्छेद तथा सन्दर्भ बुझाइ',
        'titleKo': '단문 및 중문 독해',
        'icon': Icons.menu_book,
        'color': const Color(0xFF475569),
        'adviceNe': 'अनुच्छेदको मुख्य विषय (주제) र समान कुरा (같은 것) खोज्नुहोस्।',
      },
      'listening_words': {
        'titleNe': 'सुनेर शब्द वा चित्र पहिचान',
        'titleKo': '듣기: 들은 어휘 및 그림 파악',
        'icon': Icons.hearing,
        'color': const Color(0xFFEA580C),
        'adviceNe': 'संख्या, समय, र कार्यस्थलका सामग्रीहरूको उच्चारण ध्यानपूर्वक सुन्नुहोस्।',
      },
      'listening_response': {
        'titleNe': 'सुनेर उपयुक्त जवाफ छनौट',
        'titleKo': '듣기: 알맞은 대답 고르기',
        'icon': Icons.question_answer,
        'color': const Color(0xFFD97706),
        'adviceNe': 'सोधिएको प्रश्नको प्रकार (कहिलें, कहाँ, कसरी, किन) बुझ्नुहोस्।',
      },
      'listening_dialogue': {
        'titleNe': 'कार्यस्थल कुराकानी तथा संवाद',
        'titleKo': '듣기: 대화 및 장소 파악',
        'icon': Icons.record_voice_over,
        'color': const Color(0xFFDC2626),
        'adviceNe': 'दुई व्यक्तिको कुराकानीको ठाउँ र मुख्य काममा ध्यान दिनुहोस्।',
      },
    };
  }
}
