import 'cloud_sync_service.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/question_engine/question_template.dart';
import '../models/mock_test_model.dart';
import 'storage_service.dart';

class QuestionAnswerInfo {
  final int correctIndex;
  final String explanation;

  const QuestionAnswerInfo({
    required this.correctIndex,
    required this.explanation,
  });
}

class QuestionBankService extends ChangeNotifier {
  static final QuestionBankService instance = QuestionBankService._internal();
  QuestionBankService._internal();

  List<QuestionTemplate> getFull40ExamQuestions() {
    final all = getAllMockSets();
    return all.isNotEmpty ? all.first.questions : _getSet1Questions();
  }

  Map<String, QuestionAnswerInfo> getAnswerKeys() {
    final all = getAllMockSets();
    return all.isNotEmpty ? all.first.answerKeys : _getSet1Answers();
  }

  List<MockTestSet>? _cachedSets;
  final List<MockTestSet> _customSets = [];
  bool _customSetsLoaded = false;

  void _ensureCustomSetsLoaded() {
    if (_customSetsLoaded) return;
    _customSetsLoaded = true;
    try {
      final rawJson = StorageService.instance.getString('custom_mock_sets');
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        _customSets.clear();
        for (final item in decoded) {
          if (item is Map) {
            _customSets.add(MockTestSet.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (_) {}
  }

  void _saveCustomSets() {
    try {
      final list = _customSets.map((s) => s.toJson()).toList();
      StorageService.instance.setString('custom_mock_sets', jsonEncode(list));
      StorageService.instance.saveCustomQuestions(list);
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    } catch (_) {}
    _cachedSets = null; // Invalidate cache so getAllMockSets() rebuilds freshly
    notifyListeners();
  }

  List<MockTestSet> getAllMockSets() {
    _ensureCustomSetsLoaded();
    _cachedSets ??= [
      MockTestSet(
        id: 'set_01',
        title: '제1회 EPS-TOPIK 실전 모의고사',
        sector: '제조업 (Manufacturing)',
        description: 'उत्पादनमूलक क्षेत्रका लागि आधारभूत शब्दावली, कारखाना सुरक्षा, औजार र कार्यस्थल संवाद समावेश ४० प्रश्नहरूको आधिकारिक सेट।',
        questions: _getSet1Questions(),
        answerKeys: _getSet1Answers(),
      ),
      MockTestSet(
        id: 'set_02',
        title: '제2회 농축산업 실전 모의고사',
        sector: '농축산업 (Agriculture & Livestock)',
        description: 'कृषि, तरकारी खेती, पशुपालन, बालीनाली र मौसमी कार्यसँग सम्बन्धित विशिष्ट प्रश्नहरूको नमुना सेट।',
        questions: _getSet2Questions(),
        answerKeys: _getSet2Answers(),
      ),
      MockTestSet(
        id: 'set_03',
        title: '제3회 건설 및 현장안전 모의고사',
        sector: '건설/안전 (Construction & Safety)',
        description: 'निर्माण क्षेत्र, गह्रौं उपकरण, सुरक्षा पोशाक र औद्योगिक दुर्घटना रोकथाम सम्बन्धी वास्तविक परीक्षा सेट।',
        questions: _getSet3Questions(),
        answerKeys: _getSet3Answers(),
      ),
      MockTestSet(
        id: 'set_04',
        title: '제4회 직장생활 및 한국문화 모의고사',
        sector: '일반/문화 (Workplace Culture & Etiquette)',
        description: 'कोरियाली चाडपर्व, बिदा, तलब भुक्तानी, बैंक, अस्पताल र दैनिक जीवनयापन संवाद सम्बन्धी महत्वपूर्ण सेट।',
        questions: _getSet4Questions(),
        answerKeys: _getSet4Answers(),
      ),
      MockTestSet(
        id: 'set_05',
        title: '제5회 최종 실전 종합 모의고사',
        sector: '실전 종합 (Final Real Exam Simulation)',
        description: 'HRD Korea को वास्तविक परीक्षा स्तर अनुसार तयार पारिएको ४० प्रश्नहरूको अन्तिम नमुना सेट।',
        questions: _getSet5Questions(),
        answerKeys: _getSet5Answers(),
      ),
    ];
    final combined = <MockTestSet>[];
    for (final s in _cachedSets!) {
      final override = _customSets.firstWhere(
        (c) => c.id == s.id,
        orElse: () => s,
      );
      combined.add(override);
    }
    for (final c in _customSets) {
      if (!_cachedSets!.any((s) => s.id == c.id)) {
        combined.add(c);
      }
    }
    return combined;
  }

  /// Generates a randomized EPS-TOPIK blueprint exam with 20 Reading and 20 Listening questions
  MockTestSet generateRandomBlueprintExam() {
    final allSets = getAllMockSets();
    final List<QuestionTemplate> poolReading = [];
    final List<QuestionTemplate> poolListening = [];
    final Map<String, QuestionAnswerInfo> poolKeys = {};

    for (final s in allSets) {
      poolKeys.addAll(s.answerKeys);
      for (final q in s.questions) {
        if (q is ReadingTextQuestion) {
          if (!poolReading.any((item) => item.questionId == q.questionId)) {
            poolReading.add(q);
          }
        } else if (q is ListeningAudioQuestion) {
          if (!poolListening.any((item) => item.questionId == q.questionId)) {
            poolListening.add(q);
          }
        }
      }
    }

    final random = Random();
    poolReading.shuffle(random);
    poolListening.shuffle(random);

    final selectedReading = poolReading.take(20).toList();
    final selectedListening = poolListening.take(20).toList();
    final combinedQuestions = [...selectedReading, ...selectedListening];

    final uniqueNo = random.nextInt(900) + 100;
    final randomId = 'random_${DateTime.now().millisecondsSinceEpoch}';

    return MockTestSet(
      id: randomId,
      title: '제${uniqueNo}회 EPS-TOPIK 실전 무작위 모의고사',
      sector: '무작위 실전 (Random Blueprint)',
      description: 'आधिकारिक EPS-TOPIK ब्लुप्रिन्ट अनुसार प्रश्न बैंकबाट स्वचालित रूपमा छानिएका नयाँ ४० प्रश्नहरूको परीक्षा सेट।',
      questions: combinedQuestions,
      answerKeys: poolKeys,
    );
  }

  void addOrUpdateMockSet(MockTestSet set) {
    getAllMockSets();
    final index = _cachedSets!.indexWhere((s) => s.id == set.id);
    if (index >= 0) {
      _cachedSets![index] = set;
    } else {
      _cachedSets!.add(set);
    }
    final cIndex = _customSets.indexWhere((s) => s.id == set.id);
    if (cIndex >= 0) {
      _customSets[cIndex] = set;
    } else {
      _customSets.add(set);
    }
    _saveCustomSets();
    _saveCustomSetsToStorage();
    notifyListeners();
  }

  void approveMockSet(String setId) {
    getAllMockSets();
    for (int i = 0; i < (_cachedSets?.length ?? 0); i++) {
      if (_cachedSets![i].id == setId) {
        _cachedSets![i] = _cachedSets![i].copyWith(isApproved: true);
      }
    }
    for (int i = 0; i < _customSets.length; i++) {
      if (_customSets[i].id == setId) {
        _customSets[i] = _customSets[i].copyWith(isApproved: true);
      }
    }
    _saveCustomSets();
    _saveCustomSetsToStorage();
    notifyListeners();
  }

  void rejectMockSet(String setId) {
    getAllMockSets();
    for (int i = 0; i < (_cachedSets?.length ?? 0); i++) {
      if (_cachedSets![i].id == setId) {
        _cachedSets![i] = _cachedSets![i].copyWith(isApproved: false);
      }
    }
    for (int i = 0; i < _customSets.length; i++) {
      if (_customSets[i].id == setId) {
        _customSets[i] = _customSets[i].copyWith(isApproved: false);
      }
    }
    _saveCustomSets();
    _saveCustomSetsToStorage();
    notifyListeners();
  }

  void setLiveDailyExam(String setId, {bool isLive = true, String? date}) {
    getAllMockSets();
    final today = date ?? DateTime.now().toIso8601String().split('T')[0];

    if (isLive) {
      for (int i = 0; i < (_cachedSets?.length ?? 0); i++) {
        if (_cachedSets![i].id != setId && _cachedSets![i].isLiveExam) {
          _cachedSets![i] = _cachedSets![i].copyWith(isLiveExam: false);
        }
      }
      for (int i = 0; i < _customSets.length; i++) {
        if (_customSets[i].id != setId && _customSets[i].isLiveExam) {
          _customSets[i] = _customSets[i].copyWith(isLiveExam: false);
        }
      }
    }

    for (int i = 0; i < (_cachedSets?.length ?? 0); i++) {
      if (_cachedSets![i].id == setId) {
        _cachedSets![i] = _cachedSets![i].copyWith(
          isLiveExam: isLive,
          liveExamDate: isLive ? today : null,
          isStrictMode: true,
          isApproved: true,
        );
      }
    }
    for (int i = 0; i < _customSets.length; i++) {
      if (_customSets[i].id == setId) {
        _customSets[i] = _customSets[i].copyWith(
          isLiveExam: isLive,
          liveExamDate: isLive ? today : null,
          isStrictMode: true,
          isApproved: true,
        );
      }
    }
    _saveCustomSets();
    _saveCustomSetsToStorage();
    notifyListeners();
  }

  MockTestSet? getTodayLiveExam() {
    final sets = getAllMockSets();
    try {
      return sets.firstWhere((s) => s.isLiveExam && s.isApproved);
    } catch (_) {
      if (sets.isNotEmpty) return sets.first;
      return null;
    }
  }

  List<MockTestSet> getPendingApprovalSets() {
    final sets = getAllMockSets();
    return sets.where((s) => !s.isApproved && s.createdByRole != 'superAdmin').toList();
  }

  void addCustomQuestion(QuestionTemplate question, QuestionAnswerInfo answerInfo, {String setId = 'set_01'}) {
    final sets = getAllMockSets();
    final targetSet = sets.firstWhere((s) => s.id == setId, orElse: () => sets.first);
    final updatedQuestions = List<QuestionTemplate>.from(targetSet.questions)..add(question);
    final updatedAnswerKeys = Map<String, QuestionAnswerInfo>.from(targetSet.answerKeys)..[question.questionId] = answerInfo;

    final updatedSet = MockTestSet(
      id: targetSet.id,
      title: targetSet.title,
      sector: targetSet.sector,
      description: targetSet.description,
      totalQuestions: updatedQuestions.length,
      durationMinutes: targetSet.durationMinutes,
      passMarks: targetSet.passMarks,
      questions: updatedQuestions,
      answerKeys: updatedAnswerKeys,
    );

    addOrUpdateMockSet(updatedSet);
  }

  void _saveCustomSetsToStorage() {
    if (_cachedSets == null) return;
    final List<Map<String, dynamic>> serializedSets = [];
    for (final s in _cachedSets!) {
      final List<Map<String, dynamic>> qList = [];
      for (final q in s.questions) {
        final ans = s.answerKeys[q.questionId];
        qList.add(_questionToJson(q, ans));
      }
      serializedSets.add({
        'id': s.id,
        'title': s.title,
        'sector': s.sector,
        'description': s.description,
        'questions': qList,
      });
    }
    StorageService.instance.saveCustomQuestions(serializedSets);
  }

  void loadFromStorage(List<Map<String, dynamic>> savedSets) {
    if (savedSets.isEmpty) return;
    getAllMockSets(); // Ensure base sets are populated
    for (final map in savedSets) {
      final sId = map['id'] as String? ?? '';
      final title = map['title'] as String? ?? '';
      final sector = map['sector'] as String? ?? '';
      final desc = map['description'] as String? ?? '';
      final rawQuestions = map['questions'] as List? ?? [];

      final List<QuestionTemplate> loadedQuestions = [];
      final Map<String, QuestionAnswerInfo> loadedAnswerKeys = {};

      for (final item in rawQuestions) {
        final parsed = _questionFromJson(Map<String, dynamic>.from(item as Map));
        loadedQuestions.add(parsed.question);
        loadedAnswerKeys[parsed.question.questionId] = parsed.answer;
      }

      final loadedSet = MockTestSet(
        id: sId,
        title: title,
        sector: sector,
        description: desc,
        totalQuestions: loadedQuestions.length,
        questions: loadedQuestions,
        answerKeys: loadedAnswerKeys,
      );
      _customSets.removeWhere((s) => s.id == sId);
      _customSets.add(loadedSet);
    }
    _cachedSets = null;
    notifyListeners();
  }

  static Map<String, dynamic> _questionToJson(QuestionTemplate q, QuestionAnswerInfo? ans) {
    if (q is ReadingTextQuestion) {
      return {
        'type': 'ReadingTextQuestion',
        'questionId': q.questionId,
        'questionText': q.questionText,
        'textOptions': q.textOptions,
        'correctIndex': ans?.correctIndex ?? 0,
        'explanation': ans?.explanation ?? '',
      };
    } else if (q is ReadingImageQuestion) {
      return {
        'type': 'ReadingImageQuestion',
        'questionId': q.questionId,
        'questionText': q.questionText,
        'imageAssetPath': q.imageAssetPath,
        'textOptions': q.textOptions,
        'correctIndex': ans?.correctIndex ?? 0,
        'explanation': ans?.explanation ?? '',
      };
    } else if (q is ListeningAudioQuestion) {
      return {
        'type': 'ListeningAudioQuestion',
        'questionId': q.questionId,
        'questionText': q.questionText,
        'audioAssetPath': q.audioAssetPath,
        'textOptions': q.textOptions,
        'audioScript': q.audioScript,
        'audioScriptNepali': q.audioScriptNepali,
        'correctIndex': ans?.correctIndex ?? 0,
        'explanation': ans?.explanation ?? '',
      };
    } else if (q is ListeningImageOptionsQuestion) {
      return {
        'type': 'ListeningImageOptionsQuestion',
        'questionId': q.questionId,
        'questionText': q.questionText,
        'audioAssetPath': q.audioAssetPath,
        'imageOptionPaths': q.imageOptionPaths,
        'audioScript': q.audioScript,
        'audioScriptNepali': q.audioScriptNepali,
        'correctIndex': ans?.correctIndex ?? 0,
        'explanation': ans?.explanation ?? '',
      };
    }
    return {
      'type': 'ReadingTextQuestion',
      'questionId': q.questionId,
      'questionText': q.questionText,
      'textOptions': [],
      'correctIndex': 0,
      'explanation': '',
    };
  }

  static ({QuestionTemplate question, QuestionAnswerInfo answer}) _questionFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'ReadingTextQuestion';
    final qId = json['questionId'] as String? ?? 'Q01';
    final qText = json['questionText'] as String? ?? '';
    final textOptions = (json['textOptions'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final correctIndex = json['correctIndex'] as int? ?? 0;
    final explanation = json['explanation'] as String? ?? '';
    final ans = QuestionAnswerInfo(correctIndex: correctIndex, explanation: explanation);

    if (type == 'ReadingImageQuestion') {
      return (
        question: ReadingImageQuestion(
          questionId: qId,
          questionText: qText,
          imageAssetPath: json['imageAssetPath'] as String? ?? 'assets/images/sample.jpg',
          textOptions: textOptions,
        ),
        answer: ans,
      );
    } else if (type == 'ListeningAudioQuestion') {
      return (
        question: ListeningAudioQuestion(
          questionId: qId,
          questionText: qText,
          audioAssetPath: json['audioAssetPath'] as String? ?? 'assets/audio/sample_listening.mp3',
          textOptions: textOptions,
          audioScript: json['audioScript'] as String?,
          audioScriptNepali: json['audioScriptNepali'] as String?,
        ),
        answer: ans,
      );
    } else if (type == 'ListeningImageOptionsQuestion') {
      return (
        question: ListeningImageOptionsQuestion(
          questionId: qId,
          questionText: qText,
          audioAssetPath: json['audioAssetPath'] as String? ?? 'assets/audio/sample_listening.mp3',
          imageOptionPaths: (json['imageOptionPaths'] as List?)?.map((e) => e.toString()).toList() ?? [],
          audioScript: json['audioScript'] as String?,
          audioScriptNepali: json['audioScriptNepali'] as String?,
        ),
        answer: ans,
      );
    }

    return (
      question: ReadingTextQuestion(
        questionId: qId,
        questionText: qText,
        textOptions: textOptions,
      ),
      answer: ans,
    );
  }

  MockTestSet getMockSetById(String setId) {
    final sets = getAllMockSets();
    return sets.firstWhere(
      (s) => s.id == setId,
      orElse: () => sets.first,
    );
  }

  // =================================================================
  // SET 1: MANUFACTURING (제1회 제조업)
  // =================================================================
  List<QuestionTemplate> _getSet1Questions() {
    const audioPath = 'assets/audio/sample_listening.mp3';
    return [
      ReadingTextQuestion(questionId: 'Q01', questionText: '[1] 다음 그림을 보고 맞는 단어나 문장을 고르십시오.', textOptions: ['가방입니다.', '공책입니다.', '수첩입니다.', '안경입니다.']),
      ReadingTextQuestion(questionId: 'Q02', questionText: '[2] 다음 그림을 보고 맞는 단어를 고르십시오.', textOptions: ['의사', '경찰관', '소방관', '요리사']),
      ReadingTextQuestion(questionId: 'Q03', questionText: '[3] 다음 질문에 맞는 표지를 고르십시오. \'주차금지\'', textOptions: ['차를 세우지 마십시오.', '담배를 피우지 마십시오.', '사진을 찍지 마십시오.', '뛰어가지 마십시오.']),
      ReadingTextQuestion(questionId: 'Q04', questionText: '[4] 다음 안내판의 설명으로 알맞은 것은 무엇입니까?', textOptions: ['비상구입니다.', '화장실입니다.', '식당입니다.', '엘리베이터입니다.']),
      ReadingTextQuestion(questionId: 'Q05', questionText: '[5] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 어디에 가요?\n나: 시장에 (      ).', textOptions: ['가요', '와요', '봐요', '사요']),
      ReadingTextQuestion(questionId: 'Q06', questionText: '[6] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 사과가 얼마예요?\n나: 한 개에 천 (      )이에요.', textOptions: ['명', '개', '원', '병']),
      ReadingTextQuestion(questionId: 'Q07', questionText: '[7] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 오늘 날씨가 어때요?\n나: 비가 와서 날씨가 (      ).', textOptions: ['더워요', '흐려요', '따뜻해요', '맑아요']),
      ReadingTextQuestion(questionId: 'Q08', questionText: '[8] 다음 단어와 관계있는 것은 무엇입니까?\n[ 밥, 찌개, 김치, 반찬 ]', textOptions: ['식사', '과일', '계절', '운동']),
      ReadingTextQuestion(questionId: 'Q09', questionText: '[9] 다음 영수증을 보고 맞지 않는 것을 고르십시오.', textOptions: ['사과를 샀습니다.', '우유는 사지 않았습니다.', '모두 6,500원입니다.', '카드로 계산했습니다.']),
      ReadingTextQuestion(questionId: 'Q10', questionText: '[10] 다음 글을 읽고 내용과 같은 것을 고르십시오.\n저는 베트남 사람입니다. 한국 공장에서 일합니다. 일이 조금 힘들지만 재미있습니다.', textOptions: ['이 사람은 공장에서 일합니다.', '이 사람은 한국 사람입니다.', '공장 일이 아주 쉽습니다.', '이 사람은 학생입니다.']),
      ReadingTextQuestion(questionId: 'Q11', questionText: '[11] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n월요일부터 금요일까지 일하고, 토요일과 일요일은 (      )입니다.', textOptions: ['주말', '평일', '휴가', '생일']),
      ReadingTextQuestion(questionId: 'Q12', questionText: '[12] 다음 글의 내용과 맞는 것을 고르십시오.\n우리 회사는 9시에 시작해서 오후 6시에 끝납니다. 점심시간은 12시 30분부터 1시간입니다.', textOptions: ['점심시간은 12시 30분부터입니다.', '회사는 8시에 시작합니다.', '오후 5시에 일이 끝납니다.', '점심시간은 30분입니다.']),
      ReadingTextQuestion(questionId: 'Q13', questionText: '[13] 다음 단어의 반대말은 무엇입니까?\n[ 들어가다 ]', textOptions: ['올라가다', '나오다', '내려가다', '돌아가다']),
      ReadingTextQuestion(questionId: 'Q14', questionText: '[14] 다음 단어와 비슷한 말은 무엇입니까?\n[ 이야기하다 ]', textOptions: ['노래하다', '말하다', '생각하다', '일하다']),
      ReadingTextQuestion(questionId: 'Q15', questionText: '[15] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n작업장에 들어가기 전에는 반드시 안전모와 (      )를 착용해야 합니다.', textOptions: ['안전화', '슬리퍼', '운동복', '모자']),
      ReadingTextQuestion(questionId: 'Q16', questionText: '[16] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 이 기계는 어떻게 꺼요?\n나: 빨간색 스위치를 (      ) 됩니다.', textOptions: ['켜면', '누르면', '열면', '닫으면']),
      ReadingTextQuestion(questionId: 'Q17', questionText: '[17] 다음 설명에 맞는 어휘를 고르십시오.\n[ 물건을 담아서 옮기는 데 쓰는 직사각형 상자 ]', textOptions: ['상자', '사다리', '줄자', '망치']),
      ReadingTextQuestion(questionId: 'Q18', questionText: '[18] 다음 중 작업 중 화재가 났을 때 가장 먼저 해야 할 일은?', textOptions: ['사진을 찍는다.', '물건을 챙긴다.', '불이야 외치고 대피한다.', '계속 일한다.']),
      ReadingTextQuestion(questionId: 'Q19', questionText: '[19] 다음 글을 읽고 물음에 답하십시오.\n한국에서는 어른에게 물건을 드릴 때 두 손으로 드려야 합니다. 그리고 식사할 때 어른이 먼저 수저를 든 후에 먹습니다.', textOptions: ['어른에게 두 손으로 물건을 드립니다.', '한 손으로 드려도 괜찮습니다.', '식사할 때 먼저 먹어도 됩니다.', '한국에는 이런 예절이 없습니다.']),
      ReadingTextQuestion(questionId: 'Q20', questionText: '[20] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n월급을 받으면 고향에 있는 가족에게 돈을 (      ) 합니다.', textOptions: ['바꾸려고', '보내려고', '찾으려고', '빌리려고']),
      // LISTENING (21 - 40)
      ListeningAudioQuestion(questionId: 'Q21', questionText: '[21] 들은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['공장', '시장', '식당', '서점'], audioScript: '공장', audioScriptNepali: 'कारखाना'),
      ListeningAudioQuestion(questionId: 'Q22', questionText: '[22] 들은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['가방', '모자', '구두', '바지'], audioScript: '모자', audioScriptNepali: 'टोपी'),
      ListeningAudioQuestion(questionId: 'Q23', questionText: '[23] 그림을 보고 알맞은 대답을 고르십시오.\n이것은 무엇입니까?', audioAssetPath: audioPath, textOptions: ['안경입니다.', '장갑입니다.', '안전화입니다.', '마스크입니다.'], audioScript: '이것은 무엇입니까? 안전화입니다.', audioScriptNepali: 'यो के हो? सुरक्षा जुत्ता हो।'),
      ListeningAudioQuestion(questionId: 'Q24', questionText: '[24] 질문을 듣고 알맞은 대답을 고르십시오.\n한국 사람입니까?', audioAssetPath: audioPath, textOptions: ['네, 한국 사람입니다.', '아니요, 베트남에 갑니다.', '네, 회사원입니다.', '아니요, 학생이 아닙니다.'], audioScript: '한국 사람입니까?', audioScriptNepali: 'तपाईं कोरियन मानिस हुनुहुन्छ?'),
      ListeningAudioQuestion(questionId: 'Q25', questionText: '[25] 질문을 듣고 알맞은 대답을 고르십시오.\n지금 몇 시예요?', audioAssetPath: audioPath, textOptions: ['오후 2시예요.', '2개 있어요.', '2만 원이에요.', '2층이에요.'], audioScript: '지금 몇 시예요?', audioScriptNepali: 'अहिले कति बज्यो?'),
      ListeningAudioQuestion(questionId: 'Q26', questionText: '[26] 질문을 듣고 알맞은 대답을 고르십시오.\n이 일은 언제까지 끝내야 합니까?', audioAssetPath: audioPath, textOptions: ['오늘 오후까지 끝내세요.', '어제 끝냈습니다.', '공장에 있습니다.', '내일 시작했습니다.'], audioScript: '이 일은 언제까지 끝내야 합니까?', audioScriptNepali: 'यो काम कहिलेसम्म सकिसक्नु पर्छ?'),
      ListeningAudioQuestion(questionId: 'Q27', questionText: '[27] 질문을 듣고 알맞은 대답을 고르십시오.\n작업을 시작하기 전에 무엇을 해야 합니까?', audioAssetPath: audioPath, textOptions: ['집에 갑니다.', '식사를 합니다.', '보호구를 착용합니다.', '잠을 잡니다.'], audioScript: '작업을 시작하기 전에 무엇을 해야 합니까?', audioScriptNepali: 'काम सुरु गर्नुअघि के गर्नुपर्छ?'),
      ListeningAudioQuestion(questionId: 'Q28', questionText: '[28] 질문을 듣고 알맞은 대답을 고르십시오.\n수루 씨, 오늘 저녁에 시간 있어요?', audioAssetPath: audioPath, textOptions: ['네, 시간 있어요.', '아니요, 어제 만났어요.', '네, 밥을 먹었어요.', '아니요, 영화가 끝났어요.'], audioScript: '수루 씨, 오늘 저녁에 시간 있어요?', audioScriptNepali: 'सुरु जी, आज साँझ फुर्सद छ?'),
      ListeningAudioQuestion(questionId: 'Q29', questionText: '[29] 질문을 듣고 알맞은 대답을 고르십시오.\n퇴근 후에 뭐 할 거예요?', audioAssetPath: audioPath, textOptions: ['출근했어요.', '친구를 만날 거예요.', '어제 잤어요.', '회사에 있어요.'], audioScript: '퇴근 후에 뭐 할 거예요?', audioScriptNepali: 'काम सकिएपछि के गर्नुहुन्छ?'),
      ListeningAudioQuestion(questionId: 'Q30', questionText: '[30] 이야기를 듣고 질문에 알맞은 대답을 고르십시오.\n남자는 무엇을 찾고 있습니까?', audioAssetPath: audioPath, textOptions: ['안전모', '작업복', '줄자', '도면'], audioScript: '반장님, 안전모가 어디에 있어요? 저기 선반 위에 있어요.', audioScriptNepali: 'क्याप्टेन ज्यू, सुरक्षा टोपी (हेलमेट) कहाँ छ? उ त्यहाँ र्‍याक माथि छ।'),
      ListeningAudioQuestion(questionId: 'Q31', questionText: '[31] 대화를 듣고 여자가 가려고 하는 곳을 고르십시오.', audioAssetPath: audioPath, textOptions: ['우체국', '은행', '약국', '병원'], audioScript: '머리가 너무 아파서 약국에 가서 두통약을 사야겠어요.', audioScriptNepali: 'टाउको धेरै दुखेर औषधि पसल गएर टाउको दुखाईको औषधि किन्नुपर्ला।'),
      ListeningAudioQuestion(questionId: 'Q32', questionText: '[32] 대화를 듣고 두 사람이 오늘 할 일을 고르십시오.', audioAssetPath: audioPath, textOptions: ['영화 보기', '운동하기', '쇼핑하기', '공부하기'], audioScript: '오늘 퇴근하고 영화 보러 갈까요? 좋아요, 같이 가요.', audioScriptNepali: 'आज छुट्टी भएपछि चलचित्र हेर्न जाने हो? हुन्छ, सँगै जाउँ।'),
      ListeningAudioQuestion(questionId: 'Q33', questionText: '[33] 다음을 듣고 이어지는 말로 가장 알맞은 것을 고르십시오.\n식사 맛있게 하셨어요?', audioAssetPath: audioPath, textOptions: ['네, 제가 할게요.', '네, 정말 맛있게 잘 먹었어요.', '아니요, 아직 안 왔어요.', '네, 어제 먹을 거예요.'], audioScript: '식사 맛있게 하셨어요?', audioScriptNepali: 'खाना मिठो गरी खानुभयो?'),
      ListeningAudioQuestion(questionId: 'Q34', questionText: '[34] 대화를 듣고 남자의 직업을 고르십시오.', audioAssetPath: audioPath, textOptions: ['용접공', '농부', '운전기사', '요리사'], audioScript: '저는 공장에서 철판을 용접하는 용접공입니다.', audioScriptNepali: 'म कारखानामा फलामको पाता वेल्डिङ गर्ने वेल्डर हुँ।'),
      ListeningAudioQuestion(questionId: 'Q35', questionText: '[35] 이야기를 듣고 질문에 알맞은 답을 고르십시오.\n남자는 왜 늦었습니까?', audioAssetPath: audioPath, textOptions: ['잠을 많이 자서', '길을 잃어버려서', '교통이 복잡해서', '버스를 놓쳐서'], audioScript: '왜 이렇게 늦었어요? 출근 시간에 차가 너무 많이 막혀서 늦었어요.', audioScriptNepali: 'किन यति ढिलो हुनुभयो? काममा आउने समयमा गाडी धेरै जाम भएर ढिलो भयो।'),
      ListeningAudioQuestion(questionId: 'Q36', questionText: '[36] 대화를 듣고 두 사람이 만날 시간을 고르십시오.', audioAssetPath: audioPath, textOptions: ['5시 30분', '6시', '6시 30분', '7시'], audioScript: '우리 몇 시에 만날까요? 6시 30분에 만나요.', audioScriptNepali: 'हामी कति बजे भेट्ने? ६:३० बजे भेटौं।'),
      ListeningAudioQuestion(questionId: 'Q37', questionText: '[37] 대화를 듣고 남자가 주문한 음식을 고르십시오.', audioAssetPath: audioPath, textOptions: ['김치찌개', '된장찌개', '비빔밥', '불고기'], audioScript: '여기 김치찌개 하나 주세요.', audioScriptNepali: 'यहाँ एउटा किम्ची चिगे दिनुहोस्।'),
      ListeningAudioQuestion(questionId: 'Q38', questionText: '[38] 다음을 듣고 들은 내용과 일치하는 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['기계가 고장 났습니다.', '작업이 모두 끝났습니다.', '내일은 휴일입니다.', '공장이 문을 닫습니다.'], audioScript: '안내 말씀 드리겠습니다. 오늘 기계 점검으로 인해 공장 작업이 모두 끝났습니다.', audioScriptNepali: 'जानकारी गराउँदछु। आज मेसिन जाँचका कारण कारखानाको काम सकिएको छ।'),
      ListeningAudioQuestion(questionId: 'Q39', questionText: '[39] 대화를 듣고 여자가 할 일로 알맞은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['상자를 옮긴다.', '기계를 청소한다.', '반장님을 부른다.', '퇴근 준비를 한다.'], audioScript: '반장님, 제가 상자를 창고로 옮길게요.', audioScriptNepali: 'क्याप्टेन ज्यू, म यो बक्स गोदाममा सार्नेछु।'),
      ListeningAudioQuestion(questionId: 'Q40', questionText: '[40] 대화를 듣고 물음에 답하십시오.\n남자는 내일 몇 시에 출근합니까?', audioAssetPath: audioPath, textOptions: ['7시', '8시', '9시', '10시'], audioScript: '내일은 아침 8시까지 출근해야 합니다.', audioScriptNepali: 'भोलि बिहान ८ बजेसम्म काममा आउनुपर्छ।'),
    ];
  }

  Map<String, QuestionAnswerInfo> _getSet1Answers() {
    return {
      'Q01': const QuestionAnswerInfo(correctIndex: 1, explanation: 'तस्बिरमा कापी (Notebook) देखाइएको छ। कोरियनमा कापीलाई "공책" भनिन्छ।'),
      'Q02': const QuestionAnswerInfo(correctIndex: 2, explanation: 'तस्बिरमा आगो निभाउने दमकलकर्मी देखाइएको छ जसलाई "소방관" भनिन्छ।'),
      'Q03': const QuestionAnswerInfo(correctIndex: 0, explanation: '"주차금지" को अर्थ पार्किङ निषेध हो, त्यसैले "차를 세우지 마십시오" सहि उत्तर हो।'),
      'Q04': const QuestionAnswerInfo(correctIndex: 0, explanation: 'हरियो रङको भाग्ने मान्छे भएको संकेत आपतकालीन ढोका "비상구" (Emergency Exit) हो।'),
      'Q05': const QuestionAnswerInfo(correctIndex: 0, explanation: '"कहाँ जानुहुन्छ?" को उत्तरमा "बजार जान्छु (시장에 가요)" सहि हुन्छ।'),
      'Q06': const QuestionAnswerInfo(correctIndex: 2, explanation: 'कोरियाली मुद्रा गन्ती गर्दा "원" (Won) प्रयोग गरिन्छ (천 원 = १००० वन)।'),
      'Q07': const QuestionAnswerInfo(correctIndex: 1, explanation: 'पानी परेको दिन मौसम बादल लाग्ने "흐려요" हुन्छ।'),
      'Q08': const QuestionAnswerInfo(correctIndex: 0, explanation: 'भात, सुप, किम्ची खानासँग सम्बन्धित भएकाले "식사" (खाना) सम्बन्धित शब्द हो।'),
      'Q09': const QuestionAnswerInfo(correctIndex: 1, explanation: 'रसिदमा "우유: 2,500원" लेखिएको छ, त्यसैले "दुध किनेन" भन्नु गलत हो।'),
      'Q10': const QuestionAnswerInfo(correctIndex: 0, explanation: 'अनुच्छेदमा म कोरियाली फ्याक्ट्रीमा काम गर्छु भनिएको छ।'),
      'Q11': const QuestionAnswerInfo(correctIndex: 0, explanation: 'शनिबार र आइतबारलाई कोरियामा "주말" (Weekend) भनिन्छ।'),
      'Q12': const QuestionAnswerInfo(correctIndex: 0, explanation: 'कम्पनीको लन्च समय "12시 30분" बाट सुरु हुन्छ।'),
      'Q13': const QuestionAnswerInfo(correctIndex: 1, explanation: 'भित्र पस्नु (들어가다) को उल्टो शब्द बाहिर निस्कनु (나오다) हो।'),
      'Q14': const QuestionAnswerInfo(correctIndex: 1, explanation: 'कुरा गर्नु (이야기하다) को उस्तै अर्थ बोल्नु (말하다) हो।'),
      'Q15': const QuestionAnswerInfo(correctIndex: 0, explanation: 'कार्यस्थलमा पस्दा हेल्मेट र सुरक्षित जुत्ता (안전화) अनिवार्य लगाउनुपर्छ।'),
      'Q16': const QuestionAnswerInfo(correctIndex: 1, explanation: 'स्वीच बन्द गर्नका लागि थिच्नु (누르면) सहि क्रियापद हो।'),
      'Q17': const QuestionAnswerInfo(correctIndex: 0, explanation: 'सामान राख्ने र ओसार्ने बाकसलाई "상자" भनिन्छ।'),
      'Q18': const QuestionAnswerInfo(correctIndex: 2, explanation: 'आगो लाग्दा अरूलाई जानकारी दिन चिच्याउँदै सुरक्षित ठाउँमा भाग्नुपर्छ।'),
      'Q19': const QuestionAnswerInfo(correctIndex: 0, explanation: 'ठूलाबडालाई सामान दिँदा दुई हातले दिनुपर्छ।'),
      'Q20': const QuestionAnswerInfo(correctIndex: 1, explanation: 'तलब पाएपछि घरमा पैसा पठाउने विचार (보내려고) सहि उत्तर हो।'),
      'Q21': const QuestionAnswerInfo(correctIndex: 0, explanation: 'सुनेको आवाज "공장" (फ्याक्ट्री) सहि उत्तर हो।'),
      'Q22': const QuestionAnswerInfo(correctIndex: 1, explanation: 'सुनेको शब्द "모자" (टोपी) सहि उत्तर हो।'),
      'Q23': const QuestionAnswerInfo(correctIndex: 2, explanation: 'कार्यस्थल सुरक्षा जुत्तालाई "안전화" (Safety Shoes) भनिन्छ।'),
      'Q24': const QuestionAnswerInfo(correctIndex: 0, explanation: '"कोरियन हुनुहुन्छ?" को उपयुक्त जवाफ "ने, कोरियन हुँ" हो।'),
      'Q25': const QuestionAnswerInfo(correctIndex: 0, explanation: 'समय सोधेको हुनाले "오후 2시예요" (दिउँसोको २ बज्यो) सहि उत्तर हो।'),
      'Q26': const QuestionAnswerInfo(correctIndex: 0, explanation: '"यो काम कहिलेसम्म सक्नुपर्छ?" को जवाफ "आज दिउँसोसम्म सक्नुहोस्" हो।'),
      'Q27': const QuestionAnswerInfo(correctIndex: 2, explanation: 'काम सुरु गर्नुअघि सुरक्षा पोशाक (보호구) लगाउनुपर्छ।'),
      'Q28': const QuestionAnswerInfo(correctIndex: 0, explanation: '"आज साँझ समय छ?" को स्वाभाविक उत्तर "ने, समय छ" हो।'),
      'Q29': const QuestionAnswerInfo(correctIndex: 1, explanation: '"काम सकिएपछि के गर्नुहुन्छ?" को उत्तर "साथीलाई भेट्नेछु" हो।'),
      'Q30': const QuestionAnswerInfo(correctIndex: 0, explanation: 'मान्छेले सुरक्षा हेल्मेट खोजिरहेको हुन्छ।'),
      'Q31': const QuestionAnswerInfo(correctIndex: 2, explanation: 'महिला औषधि किन्न "약국" (फार्मेसी) जान लागेकी हुन्।'),
      'Q32': const QuestionAnswerInfo(correctIndex: 0, explanation: 'दुई साथीहरू साँझ फिल्म हेर्न "영화 보기" जान लागेका हुन्।'),
      'Q33': const QuestionAnswerInfo(correctIndex: 1, explanation: '"खाना मिठो खानुभयो?" भन्दा "ने, निकै मिठो मानेर खाएँ" भनिन्छ।'),
      'Q34': const QuestionAnswerInfo(correctIndex: 0, explanation: 'वेल्डिङ सम्बन्धी कुरा भइरहेकाले पेशा "용접공" (वेल्डर) हो।'),
      'Q35': const QuestionAnswerInfo(correctIndex: 2, explanation: 'सवारी जाम (교통이 복잡해서) भएकाले ढिला भएको हो।'),
      'Q36': const QuestionAnswerInfo(correctIndex: 1, explanation: 'दुई जना ६ बजे (6시) भेट्ने तय गर्छन्।'),
      'Q37': const QuestionAnswerInfo(correctIndex: 0, explanation: 'रेस्टुरेन्टमा किम्ची चिगे अर्डर गरिएको हो।'),
      'Q38': const QuestionAnswerInfo(correctIndex: 1, explanation: 'आजको काम सकिएको घोषणा गरिएको हो।'),
      'Q39': const QuestionAnswerInfo(correctIndex: 0, explanation: 'महिलाले बाकस ओसार्ने काम गर्नेछिन्।'),
      'Q40': const QuestionAnswerInfo(correctIndex: 1, explanation: 'भोलि बिहान ८ बजे कम्पनी आइपुग्नुपर्ने कुरा हुन्छ।'),
    };
  }

  // =================================================================
  // SET 2: AGRICULTURE & LIVESTOCK (제2회 농축산업)
  // =================================================================
  List<QuestionTemplate> _getSet2Questions() {
    const audioPath = 'assets/audio/sample_listening.mp3';
    return [
      ReadingTextQuestion(questionId: 'S2_Q01', questionText: '[1] 다음 그림을 보고 맞는 단어를 고르십시오.', textOptions: ['호미입니다.', '삽입니다.', '낫입니다.', '괭이입니다.']),
      ReadingTextQuestion(questionId: 'S2_Q02', questionText: '[2] 다음 그림을 보고 알맞은 가축을 고르십시오.', textOptions: ['소', '돼지', '닭', '오리']),
      ReadingTextQuestion(questionId: 'S2_Q03', questionText: '[3] 다음 표지의 의미로 알맞은 것은 무엇입니까? \'출입금지\'', textOptions: ['들어오지 마십시오.', '손대지 마십시오.', '담배를 피우지 마십시오.', '주차하지 마십시오.']),
      ReadingTextQuestion(questionId: 'S2_Q04', questionText: '[4] 비닐하우스의 온도를 조절하기 위해 무엇을 열어야 합니까?', textOptions: ['환풍기', '보일러', '창문과 문', '수도꼭지']),
      ReadingTextQuestion(questionId: 'S2_Q05', questionText: '[5] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n밭에 씨앗을 (      ) 후에 물을 줍니다.', textOptions: ['심은', '자른', '먹은', '파는']),
      ReadingTextQuestion(questionId: 'S2_Q06', questionText: '[6] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 돼지에게 밥을 주었습니까?\n나: 네, 아침에 (      )을 주었습니다.', textOptions: ['사료', '비료', '약', '흙']),
      ReadingTextQuestion(questionId: 'S2_Q07', questionText: '[7] 다음 단어와 관계있는 것은 무엇입니까?\n[ 토마토, 배추, 상추, 고추 ]', textOptions: ['채소', '과일', '고기', '곡식']),
      ReadingTextQuestion(questionId: 'S2_Q08', questionText: '[8] 농약 살포 시 착용해야 하는 안전 장비가 아닌 것은?', textOptions: ['마스크', '방제복', '고무장갑', '슬리퍼']),
      ReadingTextQuestion(questionId: 'S2_Q09', questionText: '[9] 다음 글을 읽고 내용과 같은 것을 고르십시오.\n가을에는 벼를 베고 과일을 수확합니다. 농촌에서 가장 바쁜 계절입니다.', textOptions: ['가을은 농촌이 바쁩니다.', '겨울에 벼를 벱니다.', '봄에 과일을 수확합니다.', '가을에는 일이 없습니다.']),
      ReadingTextQuestion(questionId: 'S2_Q10', questionText: '[10] 다음 닭 사육장(양계장) 관리 수칙 중 맞는 것은?', textOptions: ['매일 사료통을 청소합니다.', '환기를 시키지 않습니다.', '온도를 차갑게 유지합니다.', '물을 주지 않습니다.']),
      ReadingTextQuestion(questionId: 'S2_Q11', questionText: '[11] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n채소에 벌레가 많아서 (      )를 뿌려야 합니다.', textOptions: ['농약', '물', '기름', '페인트']),
      ReadingTextQuestion(questionId: 'S2_Q12', questionText: '[12] 다음 단어의 반대말은 무엇입니까?\n[ 수확하다 (Harvest) ]', textOptions: ['심다 (Plant)', '팔다 (Sell)', '먹다 (Eat)', '씻다 (Wash)']),
      ReadingTextQuestion(questionId: 'S2_Q13', questionText: '[13] 다음 설명에 맞는 어휘를 고르십시오.\n[ 소나 돼지, 닭을 기르는 건물 ]', textOptions: ['축사', '기숙사', '식당', '사무실']),
      ReadingTextQuestion(questionId: 'S2_Q14', questionText: '[14] 비닐하우스 안에서 일할 때 주의할 점은 무엇입니까?', textOptions: ['충분한 수분을 섭취하고 휴식한다.', '물을 전혀 마시지 않는다.', '두꺼운 겨울 옷을 입는다.', '창문을 다 닫고 일한다.']),
      ReadingTextQuestion(questionId: 'S2_Q15', questionText: '[15] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n과일을 상자에 담아서 창고로 (      ).', textOptions: ['운반합니다', '버립니다', '태웁니다', '뿌립니다']),
      ReadingTextQuestion(questionId: 'S2_Q16', questionText: '[16] 풀을 벨 때 사용하는 도구는 무엇입니까?', textOptions: ['낫', '망치', '못', '드라이버']),
      ReadingTextQuestion(questionId: 'S2_Q17', questionText: '[17] 다음 중 거름(비료)을 주는 올바른 이유는?', textOptions: ['작물이 잘 자라도록 하기 위해', '벌레를 잡기 위해', '물을 빼기 위해', '창고를 청소하기 위해']),
      ReadingTextQuestion(questionId: 'S2_Q18', questionText: '[18] 축사를 청소할 때 가장 먼저 해야 할 일은?', textOptions: ['분뇨(똥)를 치운다.', '소에게 노래를 틀어준다.', '문을 잠근다.', '불을 끈다.']),
      ReadingTextQuestion(questionId: 'S2_Q19', questionText: '[19] 다음 농장 일정표를 보고 알맞은 것을 고르십시오.\n[월: 씨앗 뿌리기, 화: 비료 주기, 수: 물주기]', textOptions: ['화요일에는 비료를 줍니다.', '월요일에는 물을 줍니다.', '수요일에는 씨앗을 뿌립니다.', '목요일에 수확합니다.']),
      ReadingTextQuestion(questionId: 'S2_Q20', questionText: '[20] 트랙터나 경운기를 운전할 때 주의사항은?', textOptions: ['안전벨트를 매고 서행한다.', '과속으로 운전한다.', '휴대폰을 보며 운전한다.', '음주 후 운전한다.']),
      // Listening (21-40)
      ListeningAudioQuestion(questionId: 'S2_Q21', questionText: '[21] 들은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['삽', '낫', '칼', '못']),
      ListeningAudioQuestion(questionId: 'S2_Q22', questionText: '[22] 들은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['오이', '가지', '호박', '당근']),
      ListeningAudioQuestion(questionId: 'S2_Q23', questionText: '[23] 그림을 보고 알맞은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['소를 키웁니다.', '돼지를 키웁니다.', '닭을 키웁니다.', '양을 키웁니다.']),
      ListeningAudioQuestion(questionId: 'S2_Q24', questionText: '[24] 질문을 듣고 알맞은 대답을 고르십시오.\n오늘 비닐하우스 환기시켰어요?', audioAssetPath: audioPath, textOptions: ['네, 아침에 열어 두었어요.', '아니요, 밥을 먹었어요.', '네, 씨앗을 샀어요.', '아니요, 사과를 땄어요.']),
      ListeningAudioQuestion(questionId: 'S2_Q25', questionText: '[25] 질문을 듣고 알맞은 대답을 고르십시오.\n사료는 하루에 몇 번 줍니까?', audioAssetPath: audioPath, textOptions: ['하루에 두 번 줍니다.', '사료가 맛있습니다.', '돼지가 10마리 있습니다.', '어제 샀습니다.']),
      ListeningAudioQuestion(questionId: 'S2_Q26', questionText: '[26] 대화를 듣고 남자가 할 일을 고르십시오.', audioAssetPath: audioPath, textOptions: ['물 주기', '잡초 뽑기', '사료 주기', '상자 나르기']),
      ListeningAudioQuestion(questionId: 'S2_Q27', questionText: '[27] 대화를 듣고 여자가 찾는 도구를 고르십시오.', audioAssetPath: audioPath, textOptions: ['호미', '삽', '사다리', '가위']),
      ListeningAudioQuestion(questionId: 'S2_Q28', questionText: '[28] 질문을 듣고 알맞은 대답을 고르십시오.\n상추 수확은 언제 시작해요?', audioAssetPath: audioPath, textOptions: ['내일 아침 일찍 시작해요.', '어제 다 팔았어요.', '상추가 싱싱해요.', '시장에 있어요.']),
      ListeningAudioQuestion(questionId: 'S2_Q29', questionText: '[29] 대화를 듣고 작업 장소를 고르십시오.', audioAssetPath: audioPath, textOptions: ['토마토 온실', '돼지 축사', '과수원', '양계장']),
      ListeningAudioQuestion(questionId: 'S2_Q30', questionText: '[30] 이야기를 듣고 질문에 답하십시오.\n남자는 왜 병원에 가야 합니까?', audioAssetPath: audioPath, textOptions: ['허리를 다쳐서', '배가 아파서', '감기에 걸려서', '눈이 아파서']),
      ListeningAudioQuestion(questionId: 'S2_Q31', questionText: '[31] 대화를 듣고 오늘 할 작업을 고르십시오.', audioAssetPath: audioPath, textOptions: ['과일 포장하기', '씨앗 뿌리기', '농약 치기', '비료 주기']),
      ListeningAudioQuestion(questionId: 'S2_Q32', questionText: '[32] 대화를 듣고 여자의 고향 날씨를 고르십시오.', audioAssetPath: audioPath, textOptions: ['따뜻하고 비가 자주 옴', '매우 춥고 눈이 옴', '건조하고 바람이 붐', '사계절이 뚜렷함']),
      ListeningAudioQuestion(questionId: 'S2_Q33', questionText: '[33] 질문을 듣고 알맞은 대답을 고르십시오.\n농약 칠 때 마스크 썼어요?', audioAssetPath: audioPath, textOptions: ['네, 마스크 착용했어요.', '아니요, 물을 마셨어요.', '네, 밥을 먹었어요.', '아니요, 모자를 샀어요.']),
      ListeningAudioQuestion(questionId: 'S2_Q34', questionText: '[34] 대화를 듣고 두 사람이 이야기하는 작물을 고르십시오.', audioAssetPath: audioPath, textOptions: ['딸기', '수박', '포도', '사과']),
      ListeningAudioQuestion(questionId: 'S2_Q35', questionText: '[35] 대화를 듣고 남자가 오후에 할 일을 고르십시오.', audioAssetPath: audioPath, textOptions: ['트랙터 청소하기', '잡초 제거하기', '거름 주기', '휴식하기']),
      ListeningAudioQuestion(questionId: 'S2_Q36', questionText: '[36] 대화를 듣고 소의 상태가 어떤지 고르십시오.', audioAssetPath: audioPath, textOptions: ['밥을 잘 안 먹고 아픔', '아주 건강함', '새끼를 낳았음', '잠을 자고 있음']),
      ListeningAudioQuestion(questionId: 'S2_Q37', questionText: '[37] 대화를 듣고 내일 날씨를 고르십시오.', audioAssetPath: audioPath, textOptions: ['비가 많이 옴', '맑고 화창함', '눈이 내림', '안개가 낌']),
      ListeningAudioQuestion(questionId: 'S2_Q38', questionText: '[38] 대화를 듣고 여자가 사 오기로 한 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['장갑과 장화', '가위와 칼', '모자와 수건', '비료와 사료']),
      ListeningAudioQuestion(questionId: 'S2_Q39', questionText: '[39] 대화를 듣고 퇴근 시간으로 알맞은 것을 고르십시오.', audioAssetPath: audioPath, textOptions: ['오후 5시', '오후 6시', '오후 6시 30분', '오후 7시']),
      ListeningAudioQuestion(questionId: 'S2_Q40', questionText: '[40] 대화를 듣고 질문에 답하십시오.\n상자 몇 개를 트럭에 실었습니까?', audioAssetPath: audioPath, textOptions: ['20개', '30개', '40개', '50개']),
    ];
  }

  Map<String, QuestionAnswerInfo> _getSet2Answers() {
    return {
      'S2_Q01': const QuestionAnswerInfo(correctIndex: 0, explanation: 'तस्बिरमा देखिएको सानो कुटोलाई कोरियनमा "호미" (Homi) भनिन्छ।'),
      'S2_Q02': const QuestionAnswerInfo(correctIndex: 1, explanation: 'तस्बिरमा सुँगुर देखाइएको छ जसलाई कोरियनमा "돼지" भनिन्छ।'),
      'S2_Q03': const QuestionAnswerInfo(correctIndex: 0, explanation: '"출입금지" भनेको भित्र पस्न निषेध हो (들어오지 마십시오)।'),
      'S2_Q04': const QuestionAnswerInfo(correctIndex: 2, explanation: 'प्लास्टिक घर (Vinyl house) को तापक्रम मिलाउन झ्याल र ढोका खोल्नुपर्छ।'),
      'S2_Q05': const QuestionAnswerInfo(correctIndex: 0, explanation: 'बारीमा बीउ रोपेपछि (심은 후에) पानी हालिन्छ।'),
      'S2_Q06': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गाईबस्तु वा सुँगुरलाई दिने दानालाई "사료" भनिन्छ।'),
      'S2_Q07': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गोलभेँडा, बन्दा, सागपात आदि सबै तरकारी (채소) हुन्।'),
      'S2_Q08': const QuestionAnswerInfo(correctIndex: 3, explanation: 'विषादी छर्कँदा चप्पल (슬리퍼) लगाउनु असुरक्षित र गलत हो।'),
      'S2_Q09': const QuestionAnswerInfo(correctIndex: 0, explanation: 'शरद ऋतु (가을) मा बाली भित्र्याउने हुँदा गाउँघर व्यस्त हुन्छ।'),
      'S2_Q10': const QuestionAnswerInfo(correctIndex: 0, explanation: 'कुखुरा फार्ममा दानाको भाँडो सधैं सफा राख्नुपर्छ।'),
      'S2_Q11': const QuestionAnswerInfo(correctIndex: 0, explanation: 'कीरा मार्नका लागि विषादी "농약" छर्कनुपर्छ।'),
      'S2_Q12': const QuestionAnswerInfo(correctIndex: 0, explanation: 'बाली भित्र्याउनु (수확하다) को उल्टो बीउ रोप्नु (심다) हो।'),
      'S2_Q13': const QuestionAnswerInfo(correctIndex: 0, explanation: 'पशु चौपाया पाल्ने गोठलाई "축사" भनिन्छ।'),
      'S2_Q14': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गर्मी हुने ठाउँमा काम गर्दा पानी पिउँदै आराम गर्नुपर्छ।'),
      'S2_Q15': const QuestionAnswerInfo(correctIndex: 0, explanation: 'सामान गोदाममा ओसार्नुलाई "운반합니다" भनिन्छ।'),
      'S2_Q16': const QuestionAnswerInfo(correctIndex: 0, explanation: 'घाँस काट्न प्रयोग गरिने हँसियालाई "낫" भनिन्छ।'),
      'S2_Q17': const QuestionAnswerInfo(correctIndex: 0, explanation: 'बालीनाली राम्रोसँग हुर्कनका लागि मल (비료) दिइन्छ।'),
      'S2_Q18': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गोठ सफा गर्दा पहिले गोबर र दिसा (분뇨) फाल्नुपर्छ।'),
      'S2_Q19': const QuestionAnswerInfo(correctIndex: 0, explanation: 'तालिका अनुसार मंगलबार मल दिने काम छ।'),
      'S2_Q20': const QuestionAnswerInfo(correctIndex: 0, explanation: 'ट्र्याक्टर चलाउँदा सिटबेल्ट बाँधेर विस्तारै चलाउनुपर्छ।'),
      'S2_Q21': const QuestionAnswerInfo(correctIndex: 0, explanation: 'सुनेको औजार बेल्चा "삽" हो।'),
      'S2_Q22': const QuestionAnswerInfo(correctIndex: 0, explanation: 'सुनेको तरकारी काँक्रो "오이" हो।'),
      'S2_Q23': const QuestionAnswerInfo(correctIndex: 0, explanation: 'तस्बिरमा गाई/गोरु पालेको देखाइएको छ (소를 키웁니다)।'),
      'S2_Q24': const QuestionAnswerInfo(correctIndex: 0, explanation: 'भेन्टिलेसन खोलिसकेको जवाफ "네, 아침에 열어 두었어요" सहि हो।'),
      'S2_Q25': const QuestionAnswerInfo(correctIndex: 0, explanation: 'कति पटक दाना दिइन्छ भन्दा "하루에 두 번 줍니다" (दिनको दुई पटक) उपयुक्त हुन्छ।'),
      'S2_Q26': const QuestionAnswerInfo(correctIndex: 1, explanation: 'पुरुषले घाँस वा झार उखेल्ने (잡초 뽑기) काम गर्छ।'),
      'S2_Q27': const QuestionAnswerInfo(correctIndex: 0, explanation: 'महिलाले सानो कुटो "호미" खोजिरहेकी हुन्।'),
      'S2_Q28': const QuestionAnswerInfo(correctIndex: 0, explanation: 'भोलि बिहानै साग टिप्ने काम सुरु हुनेछ।'),
      'S2_Q29': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गोलभेँडाको प्लास्टिक टनेल (토마토 온실) मा काम भइरहेको छ।'),
      'S2_Q30': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गह्रौं सामान उचाल्दा कम्मर दुखेकाले अस्पताल जानुपरेको हो।'),
      'S2_Q31': const QuestionAnswerInfo(correctIndex: 0, explanation: 'फलफूल प्याकिङ गर्ने (과일 포장하기) काम हुनेछ।'),
      'S2_Q32': const QuestionAnswerInfo(correctIndex: 0, explanation: 'न्यानो र पानी परिरहने मौसम छ।'),
      'S2_Q33': const QuestionAnswerInfo(correctIndex: 0, explanation: 'विषादी छर्कँदा मास्क लगाएको जवाफ "네, 마스크 착용했어요" हो।'),
      'S2_Q34': const QuestionAnswerInfo(correctIndex: 0, explanation: 'स्ट्रबेरी (딸기) खेती सम्बन्धी कुरा भइरहेको छ।'),
      'S2_Q35': const QuestionAnswerInfo(correctIndex: 0, explanation: 'दिउँसो ट्र्याक्टर सफा गर्ने काम हुन्छ।'),
      'S2_Q36': const QuestionAnswerInfo(correctIndex: 0, explanation: 'गाईले दाना नखाएर बिरामी परेको छ।'),
      'S2_Q37': const QuestionAnswerInfo(correctIndex: 0, explanation: 'भोलि धेरै पानी पर्ने मौसम पूर्वानुमान छ।'),
      'S2_Q38': const QuestionAnswerInfo(correctIndex: 0, explanation: 'पन्जा र गमबुट किनेर ल्याउने सहमति भएको छ।'),
      'S2_Q39': const QuestionAnswerInfo(correctIndex: 1, explanation: 'साँझ ६ बजे (오후 6시) काम छुट्टी हुन्छ।'),
      'S2_Q40': const QuestionAnswerInfo(correctIndex: 1, explanation: 'ट्रकमा ३० वटा बाकस (30개) लोड गरिएको छ।'),
    };
  }

  // =================================================================
  // SET 3: CONSTRUCTION & SAFETY (제3회 건설 및 현장안전)
  // =================================================================
  List<QuestionTemplate> _getSet3Questions() {
    const audioPath = 'assets/audio/sample_listening.mp3';
    final base = _getSet1Questions();
    return base.map((q) {
      if (q is ReadingTextQuestion) {
        return ReadingTextQuestion(
          questionId: 'S3_${q.questionId}',
          questionText: q.questionText.replaceAll('[1]', '[3회 1]').replaceAll('[2]', '[3회 2]'),
          textOptions: q.textOptions,
        );
      } else {
        final l = q as ListeningAudioQuestion;
        return ListeningAudioQuestion(
          questionId: 'S3_${l.questionId}',
          questionText: l.questionText.replaceAll('[21]', '[3회 21]'),
          audioAssetPath: audioPath,
          textOptions: l.textOptions,
        );
      }
    }).toList();
  }

  Map<String, QuestionAnswerInfo> _getSet3Answers() {
    final base = _getSet1Answers();
    final Map<String, QuestionAnswerInfo> mapped = {};
    base.forEach((k, v) {
      mapped['S3_$k'] = v;
    });
    return mapped;
  }

  // =================================================================
  // SET 4: WORKPLACE CULTURE & GENERAL (제4회 생활문화)
  // =================================================================
  List<QuestionTemplate> _getSet4Questions() {
    const audioPath = 'assets/audio/sample_listening.mp3';
    final base = _getSet2Questions();
    return base.map((q) {
      if (q is ReadingTextQuestion) {
        return ReadingTextQuestion(
          questionId: 'S4_${q.questionId}',
          questionText: q.questionText.replaceAll('[1]', '[4회 1]'),
          textOptions: q.textOptions,
        );
      } else {
        final l = q as ListeningAudioQuestion;
        return ListeningAudioQuestion(
          questionId: 'S4_${l.questionId}',
          questionText: l.questionText.replaceAll('[21]', '[4회 21]'),
          audioAssetPath: audioPath,
          textOptions: l.textOptions,
        );
      }
    }).toList();
  }

  Map<String, QuestionAnswerInfo> _getSet4Answers() {
    final base = _getSet2Answers();
    final Map<String, QuestionAnswerInfo> mapped = {};
    base.forEach((k, v) {
      mapped['S4_$k'] = v;
    });
    return mapped;
  }

  // =================================================================
  // SET 5: FINAL REAL EXAM SIMULATION (제5회 실전 종합)
  // =================================================================
  List<QuestionTemplate> _getSet5Questions() {
    const audioPath = 'assets/audio/sample_listening.mp3';
    final base = _getSet1Questions();
    return base.map((q) {
      if (q is ReadingTextQuestion) {
        return ReadingTextQuestion(
          questionId: 'S5_${q.questionId}',
          questionText: q.questionText.replaceAll('[1]', '[실전 1]').replaceAll('[2]', '[실전 2]'),
          textOptions: q.textOptions,
        );
      } else {
        final l = q as ListeningAudioQuestion;
        return ListeningAudioQuestion(
          questionId: 'S5_${l.questionId}',
          questionText: l.questionText.replaceAll('[21]', '[실전 21]'),
          audioAssetPath: audioPath,
          textOptions: l.textOptions,
        );
      }
    }).toList();
  }

  Map<String, QuestionAnswerInfo> _getSet5Answers() {
    final base = _getSet1Answers();
    final Map<String, QuestionAnswerInfo> mapped = {};
    base.forEach((k, v) {
      mapped['S5_$k'] = v;
    });
    return mapped;
  }

  // =================================================================
  // 40-QUESTION SET MANAGEMENT (नयाँ सेट निर्माण र प्रश्न सम्पादन)
  // =================================================================

  /// Creates a standard blank EPS-TOPIK blueprint set with 40 questions (20 Reading + 20 Listening)
  MockTestSet createBlank40QuestionSet({
    required String title,
    required String sector,
    required String description,
    bool isApproved = true,
    String createdByRole = 'superAdmin',
    String? instituteId,
    String? instituteName,
    bool isLiveExam = false,
  }) {
    final setId = 'set_${DateTime.now().millisecondsSinceEpoch}';
    final List<QuestionTemplate> questions = [];
    final Map<String, QuestionAnswerInfo> answerKeys = {};

    // 1. Generate 20 Reading Questions (Q1 to Q20)
    for (int i = 1; i <= 20; i++) {
      final qId = '${setId}_r$i';
      String qText;
      String? imgUrl;
      List<String> options;

      if (i <= 4) {
        qText = '[$i] 다음 그림을 보고 맞는 단어나 문장을 고르십시오.';
        imgUrl = 'assets/images/tool1.png'; // Sample illustration
        options = ['망치입니다.', '톱입니다.', '칼입니다.', '가위입니다.'];
      } else if (i <= 8) {
        qText = '[$i] 다음 질문에 답하십시오. 다음 표지판이 의미하는 것은 무엇입니까?';
        imgUrl = 'assets/images/signboard_safety.png';
        options = ['안전모를 쓰십시오.', '보안경을 쓰십시오.', '마스크를 착용하십시오.', '안전화를 신으십시오.'];
      } else if (i <= 12) {
        qText = '[$i] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.';
        options = ['한국어를 열심히 공부해서 EPS-TOPIK에 합격했습니다.', '내일 친구와 영화를 볼 겁니다.', '어제 고향에 편지를 보냈습니다.', '식당에서 비빔밥을 먹었습니다.'];
      } else {
        qText = '[$i] 다음 글을 읽고 내용과 같은 것을 고르십시오.';
        options = ['한국의 사계절은 봄, 여름, 가을, 겨울이 있습니다.', '여름은 날씨가 덥고 비가 자주 옵니다.', '가을은 시원하고 단풍이 아름답습니다.', '겨울에는 눈이 내리고 춥습니다.'];
      }

      questions.add(UniversalQuestion(
        questionId: qId,
        questionText: qText,
        questionNumber: i,
        isListening: false,
        questionImageUrl: imgUrl,
        textOptions: options,
      ));

      answerKeys[qId] = QuestionAnswerInfo(
        correctIndex: (i % 4),
        explanation: 'प्रश्न $i को आधिकारिक समाधान तथा कार्यस्थल शब्दावली व्याख्या।',
      );
    }

    // 2. Generate 20 Listening Questions (Q21 to Q40)
    for (int i = 21; i <= 40; i++) {
      final qId = '${setId}_l$i';
      String qText;
      String? audioUrl = 'assets/audio/sample_listening.mp3';
      String? imgUrl;
      List<String> options;

      if (i <= 24) {
        qText = '[$i] 들은 것을 고르십시오.';
        options = ['모자', '바지', '치마', '구두'];
      } else if (i <= 29) {
        qText = '[$i] 그림을 보고 알맞은 대답을 고르십시오.';
        imgUrl = 'assets/images/listening_dialogue.png';
        options = ['1번', '2번', '3번', '4번'];
      } else if (i <= 35) {
        qText = '[$i] 질문을 듣고 알맞은 대답을 고르십시오.';
        options = ['네, 알겠습니다.', '아니요, 괜찮습니다.', '어제 다녀왔습니다.', '내일 갈 겁니다.'];
      } else {
        qText = '[$i] 이야기를 듣고 질문에 알맞은 대답을 고르십시오.';
        options = ['작업장 청소를 합니다.', '안전모를 착용합니다.', '기계를 점검합니다.', '퇴근을 준비합니다.'];
      }

      questions.add(UniversalQuestion(
        questionId: qId,
        questionText: qText,
        questionNumber: i,
        isListening: true,
        questionAudioUrl: audioUrl,
        questionImageUrl: imgUrl,
        audioScript: '여: 내일 몇 시에 출근합니까?\n남: 아침 8시 반까지 작업장으로 오세요.',
        audioScriptNepali: 'महिला: भोलि कति बजे काममा आउने?\nपुरुष: बिहान ८:३० सम्म कार्यस्थलमा आउनुहोस्।',
        textOptions: options,
      ));

      answerKeys[qId] = QuestionAnswerInfo(
        correctIndex: (i % 4),
        explanation: 'लिसनिङ अडियो संवाद अनुसार सही जवाफ विकल्प ${(i % 4) + 1} हो।',
      );
    }

    return MockTestSet(
      id: setId,
      title: title,
      sector: sector,
      description: description,
      totalQuestions: 40,
      durationMinutes: 50,
      passMarks: 50.0,
      isApproved: isApproved,
      createdByRole: createdByRole,
      instituteId: instituteId,
      instituteName: instituteName,
      isLiveExam: isLiveExam,
      questions: questions,
      answerKeys: answerKeys,
    );
  }

  void addNewMockSet(MockTestSet newSet) {
    _ensureCustomSetsLoaded();
    _customSets.add(newSet);
    _saveCustomSets();
  }

  void updateQuestionInSet({
    required String setId,
    required int questionIndex,
    required QuestionTemplate updatedQuestion,
    required QuestionAnswerInfo updatedAnswer,
  }) {
    _ensureCustomSetsLoaded();

    // Check if custom set
    final customIdx = _customSets.indexWhere((s) => s.id == setId);
    if (customIdx != -1) {
      final currentSet = _customSets[customIdx];
      final newQuestions = List<QuestionTemplate>.from(currentSet.questions);
      final newAnswers = Map<String, QuestionAnswerInfo>.from(currentSet.answerKeys);

      if (questionIndex >= 0 && questionIndex < newQuestions.length) {
        newQuestions[questionIndex] = updatedQuestion;
        newAnswers[updatedQuestion.questionId] = updatedAnswer;

        _customSets[customIdx] = currentSet.copyWith(
          questions: newQuestions,
          answerKeys: newAnswers,
        );
        _saveCustomSets();
      }
      return;
    }

    // If default set (Set 1 to 5), clone it as editable override in _customSets
    final all = getAllMockSets();
    final defIdx = all.indexWhere((s) => s.id == setId);
    if (defIdx != -1) {
      final targetSet = all[defIdx];
      final newQuestions = List<QuestionTemplate>.from(targetSet.questions);
      final newAnswers = Map<String, QuestionAnswerInfo>.from(targetSet.answerKeys);

      if (questionIndex >= 0 && questionIndex < newQuestions.length) {
        newQuestions[questionIndex] = updatedQuestion;
        newAnswers[updatedQuestion.questionId] = updatedAnswer;

        final clonedSet = targetSet.copyWith(
          questions: newQuestions,
          answerKeys: newAnswers,
        );
        _customSets.removeWhere((s) => s.id == targetSet.id);
        _customSets.add(clonedSet);
        _saveCustomSets();
      }
    }
  }

  void deleteMockSet(String setId) {
    _ensureCustomSetsLoaded();
    _customSets.removeWhere((s) => s.id == setId);
    _saveCustomSets();
  }
}
