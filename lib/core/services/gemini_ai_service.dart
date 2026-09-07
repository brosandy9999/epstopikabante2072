import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/question_engine/question_template.dart';


class AiExtractedQuestion {
  final int number;
  final String type; // 'reading' or 'listening'
  final String questionText;
  final String? passage;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? imageDescription;

  AiExtractedQuestion({
    required this.number,
    required this.type,
    required this.questionText,
    this.passage,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.imageDescription,
  });

  factory AiExtractedQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString().trim()).toList();
    } else if (rawOptions is Map) {
      final sortedKeys = rawOptions.keys.toList()..sort();
      parsedOptions = sortedKeys.map((k) => rawOptions[k].toString().trim()).toList();
    }

    // Ensure exactly 4 options
    while (parsedOptions.length < 4) {
      parsedOptions.add('선택지 ${parsedOptions.length + 1}');
    }
    if (parsedOptions.length > 4) {
      parsedOptions = parsedOptions.sublist(0, 4);
    }

    int cIndex = 0;
    if (json['correctIndex'] is int) {
      cIndex = json['correctIndex'];
    } else if (json['answer'] is int) {
      final a = json['answer'] as int;
      cIndex = a >= 1 && a <= 4 ? a - 1 : a;
    } else if (json['correctIndex'] != null) {
      cIndex = int.tryParse(json['correctIndex'].toString()) ?? 0;
    }

    return AiExtractedQuestion(
      number: json['number'] is int ? json['number'] : int.tryParse(json['number']?.toString() ?? '1') ?? 1,
      type: (json['type']?.toString().toLowerCase().contains('listen') ?? false) ? 'listening' : 'reading',
      questionText: json['questionText']?.toString().trim() ?? '다음 질문에 답하십시오.',
      passage: json['passage']?.toString().trim().isNotEmpty == true ? json['passage'].toString().trim() : null,
      options: parsedOptions,
      correctIndex: cIndex.clamp(0, 3),
      explanation: json['explanation']?.toString().trim() ?? '정답은 ${cIndex + 1}번입니다.',
      imageDescription: json['imageDescription']?.toString().trim(),
    );
  }

  UniversalQuestion toUniversalQuestion(String questionId) {
    final isL = type == 'listening';
    return UniversalQuestion(
      questionId: questionId,
      questionNumber: number,
      questionText: passage != null && passage!.isNotEmpty ? '$questionText\n$passage' : questionText,
      isListening: isL,
      questionAudioUrl: isL ? 'assets/audio/sample_listening.mp3' : null,
      textOptions: options,
    );
  }
}

class GeminiAiService {
  GeminiAiService._internal();
  static final GeminiAiService instance = GeminiAiService._internal();

  static String get _defaultApiKey {
    const encoded = 'QVEuQWI4Uk42Slo1bGdjRjdvNzROY2ZhNXhHUmxHS0lNLTc0Nnl1Ym9XcnVoOWpLN0twUEE=';
    return utf8.decode(base64.decode(encoded));
  }
  static const String _primaryModel = 'gemini-flash-latest';
  static const String _prefKey = 'gemini_api_key';

  String? _customApiKey;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customApiKey = prefs.getString(_prefKey);
    } catch (_) {}
  }

  String get apiKey => (_customApiKey != null && _customApiKey!.isNotEmpty) ? _customApiKey! : _defaultApiKey;

  Future<void> setApiKey(String key) async {
    _customApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _customApiKey!);
    } catch (_) {}
  }

  /// Extracts EPS-TOPIK questions from raw text (copied from PDF or typed)
  Future<List<AiExtractedQuestion>> parseQuestionsFromText(String rawText) async {
    final prompt = '''
You are an expert EPS-TOPIK Korean Language Examination Parser and Tutor.
Given the following raw text from an EPS-TOPIK exam (or PDF extract), parse every question into a JSON array.

Guidelines:
1. Identify all questions with their numbers.
2. Determine if each question is "reading" (Questions 1 to 20) or "listening" (Questions 21 to 40).
3. "questionText": The instruction or question prompt (e.g. "다음 그림을 보고 맞는 단어나 문장을 고르십시오." or "다음 질문에 답하십시오.").
4. "passage": If the question contains a reading passage, a notice, a conversation (가: / 나:), or a word inside brackets/quotes (e.g. "[들어가다]" or "'주차금지'"), extract it here. Otherwise, set it to null.
5. "options": Exactly 4 options extracted as an array of 4 strings.
6. "correctIndex": Integer 0, 1, 2, or 3 (0-indexed) representing which option is correct. Solve and identify the correct answer based on standard EPS-TOPIK standards.
7. "explanation": A clear explanation in Nepali explaining WHY that answer is correct.

Raw Input:
$rawText

Return ONLY a valid JSON array of objects. No markdown backticks, no introductory text.
Schema:
[
  {
    "number": 1,
    "type": "reading",
    "questionText": "다음 그림을 보고 맞는 단어를 고르십시오.",
    "passage": null,
    "options": ["가방", "공책", "수첩", "안경"],
    "correctIndex": 1,
    "explanation": "तस्बिरमा कापी (공책) देखाइएको हुनाले सहि उत्तर २ नम्बर हो।"
  }
]
''';

    return _callGeminiApi(prompt: prompt);
  }

  /// Extracts EPS-TOPIK questions from an uploaded PDF or Image file (base64 encoded)
  Future<List<AiExtractedQuestion>> parseQuestionsFromFile({
    required String base64Data,
    required String mimeType,
  }) async {
    // Strip header prefix if present (e.g., 'data:application/pdf;base64,')
    String cleanBase64 = base64Data;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',')[1];
    }
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

    final prompt = '''
You are an expert EPS-TOPIK Korean Language Examination Parser and Tutor.
Carefully examine the attached exam document/image page and parse every question into structured JSON.

Guidelines:
1. Identify all questions with their numbers (1 to 40).
2. Determine if each question is "reading" (Q1 to Q20) or "listening" (Q21 to Q40).
3. "questionText": The instruction or question prompt in Korean.
4. "passage": If the question has a reading passage, notice, table, dialog (가/나), or bracketed word, extract it cleanly.
5. "options": Exactly 4 options extracted as an array of strings.
6. "correctIndex": Integer 0, 1, 2, or 3 representing the correct answer.
7. "explanation": A clear, educational explanation in Nepali.
8. "imageDescription": If the question includes an image/sign/photo, describe what is depicted (e.g. "주차금지 표지판" or "가방 그림").

Return ONLY a valid JSON array of objects.
''';

    return _callGeminiApi(
      prompt: prompt,
      inlineFile: {
        'mimeType': mimeType,
        'data': cleanBase64,
      },
    );
  }

  Future<List<AiExtractedQuestion>> _callGeminiApi({
    required String prompt,
    Map<String, String>? inlineFile,
  }) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_primaryModel:generateContent?key=$apiKey');

    final List<Map<String, dynamic>> parts = [];
    if (inlineFile != null) {
      parts.add({
        'inlineData': {
          'mimeType': inlineFile['mimeType'],
          'data': inlineFile['data'],
        },
      });
    }
    parts.add({'text': prompt});

    final payload = {
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.2,
      },
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini AI बाट कुनै प्रतिक्रिया प्राप्त भएन।');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final partsList = content?['parts'] as List?;
    if (partsList == null || partsList.isEmpty) {
      throw Exception('Gemini AI बाट खाली उत्तर आयो।');
    }

    final rawText = partsList[0]['text'] as String;
    return _parseJsonQuestions(rawText);
  }

  List<AiExtractedQuestion> _parseJsonQuestions(String rawText) {
    String cleaned = rawText.trim();

    // Remove markdown code block if present
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      final lastBacktick = cleaned.lastIndexOf('```');
      if (firstNewline != -1 && lastBacktick > firstNewline) {
        cleaned = cleaned.substring(firstNewline + 1, lastBacktick).trim();
      }
    }

    // Try finding JSON array [ ... ]
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      cleaned = cleaned.substring(startIdx, endIdx + 1);
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(cleaned);
    } catch (e) {
      debugPrint('JSON Decode failed: $e, raw: $cleaned');
      throw Exception('AI द्वारा पठाइएको डेटा JSON ढाँचामा छैन: $e');
    }

    if (parsed is! List) {
      if (parsed is Map && parsed.containsKey('questions') && parsed['questions'] is List) {
        parsed = parsed['questions'] as List;
      } else {
        throw Exception('JSON डेटा सूची (Array) को रूपमा छैन।');
      }
    }

    return parsed.map((item) => AiExtractedQuestion.fromJson(item as Map<String, dynamic>)).toList();
  }
}
