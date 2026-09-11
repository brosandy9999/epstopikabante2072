import 'cloud_sync_service.dart';
import 'auth_service.dart';
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

  Map<String, dynamic> toJson() => {
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuestionAnswerInfo.fromJson(Map<String, dynamic> json) =>
      QuestionAnswerInfo(
        correctIndex: json['correctIndex'] as int? ?? 0,
        explanation: json['explanation'] as String? ?? '',
      );
}

class QuestionBankService extends ChangeNotifier {
  static final QuestionBankService instance = QuestionBankService._internal();
  QuestionBankService._internal();

  List<QuestionTemplate> getFull40ExamQuestions() {
    final all = getAllMockSets();
    return all.isNotEmpty ? all.first.questions : <QuestionTemplate>[];
  }

  Map<String, QuestionAnswerInfo> getAnswerKeys() {
    final all = getAllMockSets();
    return all.isNotEmpty ? all.first.answerKeys : <String, QuestionAnswerInfo>{};
  }

  final List<MockTestSet> _customSets = [];
  bool _customSetsLoaded = false;

  void _ensureCustomSetsLoaded() {
    if (_customSetsLoaded) return;
    _customSetsLoaded = true;
    try {
      final rawJson = StorageService.instance.getString('custom_mock_sets') ??
          StorageService.instance.getString('custom_mock_sets_backup');
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
      final encoded = jsonEncode(list);
      StorageService.instance.setString('custom_mock_sets', encoded);
      StorageService.instance.setString('custom_mock_sets_backup', encoded);
      StorageService.instance.saveCustomQuestions(list);
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    } catch (_) {}
    notifyListeners();
  }

  static const String _keyDeletedSets = 'eps_deleted_sets_v1';
  static const String _keyCleanSlateMode = 'eps_clean_slate_mode_v1';

  bool isCleanSlateMode() {
    try {
      return StorageService.instance.getString(_keyCleanSlateMode) == 'true';
    } catch (_) {
      return false;
    }
  }

  void setCleanSlateMode(bool enable) {
    try {
      StorageService.instance.setString(_keyCleanSlateMode, enable ? 'true' : 'false');
    } catch (_) {}
    notifyListeners();
  }

  List<String> _getDeletedSetIds() {
    try {
      final str = StorageService.instance.getString(_keyDeletedSets);
      if (str != null && str.isNotEmpty) {
        final List decoded = jsonDecode(str);
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  void _saveDeletedSetIds(List<String> ids) {
    try {
      StorageService.instance.setString(_keyDeletedSets, jsonEncode(ids));
    } catch (_) {}
  }

  void deleteMockSet(String setId) {
    _ensureCustomSetsLoaded();
    final deleted = _getDeletedSetIds();
    if (!deleted.contains(setId)) {
      deleted.add(setId);
      _saveDeletedSetIds(deleted);
    }
    _customSets.removeWhere((s) => s.id == setId);
    _saveCustomSets();
    notifyListeners();
  }

  void clearAllSampleSets() {
    clearAllMockSets();
  }

  void clearAllMockSets() {
    _ensureCustomSetsLoaded();
    _customSets.clear();
    _saveCustomSets();
    notifyListeners();
  }

  void restoreSampleSets() {
    _saveDeletedSetIds([]);
    notifyListeners();
  }

  List<MockTestSet> getAllMockSets() {
    _ensureCustomSetsLoaded();
    final deletedIds = _getDeletedSetIds();
    final combined = <MockTestSet>[];
    for (final c in _customSets) {
      if (deletedIds.contains(c.id)) continue;
      combined.add(c);
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
        final isListen = (q is UniversalQuestion)
            ? q.isListening
            : (q is ListeningAudioQuestion || q is ListeningImageOptionsQuestion);
        if (!isListen) {
          if (!poolReading.any((item) => item.questionId == q.questionId)) {
            poolReading.add(q);
          }
        } else {
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
      title: '제$uniqueNo회 EPS-TOPIK 실전 무작위 모의고사',
      sector: '무작위 실전 (Random Blueprint)',
      description: 'आधिकारिक EPS-TOPIK ब्लुप्रिन्ट अनुसार प्रश्न बैंकबाट स्वचालित रूपमा छानिएका नयाँ ४० प्रश्नहरूको परीक्षा सेट।',
      questions: combinedQuestions,
      answerKeys: poolKeys,
    );
  }

  /// Intelligent Non-Destructive Question Set Merge
  void mergeSetsFromCloud(List<MockTestSet> remoteSets) {
    _ensureCustomSetsLoaded();
    bool hasChanges = false;
    for (final rSet in remoteSets) {
      final localIdx = _customSets.indexWhere((s) => s.id == rSet.id);
      if (localIdx == -1) {
        _customSets.add(rSet);
        hasChanges = true;
      } else {
        final localSet = _customSets[localIdx];
        if (localSet.questions.length < rSet.questions.length) {
          _customSets[localIdx] = rSet;
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _saveCustomSets();
    }
  }

  void updateMockSet(MockTestSet set) => addOrUpdateMockSet(set);

  void addOrUpdateMockSet(MockTestSet set) {
    _ensureCustomSetsLoaded();
    final cIndex = _customSets.indexWhere((s) => s.id == set.id);
    if (cIndex >= 0) {
      _customSets[cIndex] = set;
    } else {
      _customSets.add(set);
    }
    _saveCustomSets();
  }

  void approveMockSet(String setId) {
    _ensureCustomSetsLoaded();
    for (int i = 0; i < _customSets.length; i++) {
      if (_customSets[i].id == setId) {
        _customSets[i] = _customSets[i].copyWith(isApproved: true);
      }
    }
    _saveCustomSets();
    CloudSyncService.instance.pushToCloud();
  }

  void rejectMockSet(String setId) {
    _ensureCustomSetsLoaded();
    for (int i = 0; i < _customSets.length; i++) {
      if (_customSets[i].id == setId) {
        _customSets[i] = _customSets[i].copyWith(isApproved: false);
      }
    }
    _saveCustomSets();
    CloudSyncService.instance.pushToCloud();
  }

  void setLiveDailyExam(String setId, {bool isLive = true, String? date}) {
    _ensureCustomSetsLoaded();
    final today = date ?? DateTime.now().toIso8601String().split('T')[0];

    if (isLive) {
      for (int i = 0; i < _customSets.length; i++) {
        if (_customSets[i].id != setId && _customSets[i].isLiveExam) {
          _customSets[i] = _customSets[i].copyWith(isLiveExam: false);
        }
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
    CloudSyncService.instance.pushToCloud();
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

  void addCustomQuestion(QuestionTemplate question, QuestionAnswerInfo answerInfo, {String setId = ''}) {
    final sets = getAllMockSets();
    if (sets.isEmpty) return;
    final targetSet = sets.firstWhere((s) => s.id == setId, orElse: () => sets.first);
    final updatedQuestions = List<QuestionTemplate>.from(targetSet.questions)..add(question);
    final updatedAnswerKeys = Map<String, QuestionAnswerInfo>.from(targetSet.answerKeys)..[question.questionId] = answerInfo;

    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;

    final updatedSet = targetSet.copyWith(
      totalQuestions: updatedQuestions.length,
      questions: updatedQuestions,
      answerKeys: updatedAnswerKeys,
      isApproved: isSuperAdmin ? targetSet.isApproved : false,
      createdByRole: isSuperAdmin ? targetSet.createdByRole : 'admin',
    );

    addOrUpdateMockSet(updatedSet);
  }

  void loadFromStorage(List<Map<String, dynamic>> savedSets) {
    if (savedSets.isEmpty) return;
    _ensureCustomSetsLoaded();
    for (final map in savedSets) {
      final sId = map['id'] as String? ?? '';
      if (sId.isEmpty) continue;
      try {
        final loadedSet = MockTestSet.fromJson(map);
        _customSets.removeWhere((s) => s.id == sId);
        _customSets.add(loadedSet);
      } catch (e) {
        debugPrint('[QuestionBankService] Error parsing set $sId: $e');
      }
    }
    notifyListeners();
  }

  MockTestSet getMockSetById(String setId) {
    final sets = getAllMockSets();
    return sets.firstWhere(
      (s) => s.id == setId,
      orElse: () => sets.isNotEmpty
          ? sets.first
          : MockTestSet(
              id: setId,
              title: 'EPS-TOPIK Question Set',
              sector: 'General',
              description: '',
              questions: const [],
              answerKeys: const {},
            ),
    );
  }

  MockTestSet createBlank40QuestionSet({
    required String title,
    required String sector,
    required String description,
    bool isApproved = false,
    String createdByRole = 'admin',
    String? instituteId,
    String? instituteName,
    bool isLiveExam = false,
  }) {
    final setId = 'set_${DateTime.now().millisecondsSinceEpoch}';
    final List<QuestionTemplate> questions = [];
    final Map<String, QuestionAnswerInfo> answerKeys = {};

    for (int i = 1; i <= 40; i++) {
      final qId = 'Q${i.toString().padLeft(2, '0')}';
      final isListening = i > 20;
      questions.add(UniversalQuestion(
        questionId: qId,
        questionNumber: i,
        isListening: isListening,
        questionText: isListening
            ? '[$i] 들은 것을 고르십시오.'
            : '[$i] 다음 질문에 답하십시오.',
        textOptions: const ['1번', '2번', '3번', '4번'],
      ));
      answerKeys[qId] = const QuestionAnswerInfo(
        correctIndex: 0,
        explanation: '',
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
    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    final setWithApproval = newSet.copyWith(
      isApproved: isSuperAdmin ? newSet.isApproved : false,
      createdByRole: isSuperAdmin ? 'superAdmin' : 'admin',
    );
    _customSets.add(setWithApproval);
    _saveCustomSets();
  }

  void updateQuestionInSet({
    required String setId,
    required int questionIndex,
    required QuestionTemplate updatedQuestion,
    required QuestionAnswerInfo updatedAnswer,
  }) {
    _ensureCustomSetsLoaded();

    final customIdx = _customSets.indexWhere((s) => s.id == setId);
    if (customIdx != -1) {
      final currentSet = _customSets[customIdx];
      final newQuestions = List<QuestionTemplate>.from(currentSet.questions);
      final newAnswers = Map<String, QuestionAnswerInfo>.from(currentSet.answerKeys);

      if (questionIndex >= 0 && questionIndex < newQuestions.length) {
        newQuestions[questionIndex] = updatedQuestion;
        newAnswers[updatedQuestion.questionId] = updatedAnswer;

        final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;

        _customSets[customIdx] = currentSet.copyWith(
          questions: newQuestions,
          answerKeys: newAnswers,
          isApproved: isSuperAdmin ? currentSet.isApproved : false,
          createdByRole: isSuperAdmin ? currentSet.createdByRole : 'admin',
        );
        _saveCustomSets();
      }
    }
  }
}
