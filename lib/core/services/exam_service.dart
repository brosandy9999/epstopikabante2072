import 'cloud_sync_service.dart';
import '../models/exam_session_model.dart';
import 'storage_service.dart';

class ExamAttemptRecord {
  final String setId;
  final String setTitle;
  final String studentId;
  final String studentName;
  final String registrationNo;
  final double score;
  final double readingScore;
  final double listeningScore;
  final bool isPassed;
  final DateTime completedAt;
  final int timeSpentSeconds;
  final Map<int, int> userAnswers;

  const ExamAttemptRecord({
    required this.setId,
    required this.setTitle,
    required this.studentId,
    this.studentName = 'विद्यार्थी',
    this.registrationNo = '01234567',
    required this.score,
    required this.readingScore,
    required this.listeningScore,
    required this.isPassed,
    required this.completedAt,
    this.timeSpentSeconds = 1500,
    this.userAnswers = const {},
  });

  bool get passed => isPassed;

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'setTitle': setTitle,
    'studentId': studentId,
    'studentName': studentName,
    'registrationNo': registrationNo,
    'score': score,
    'readingScore': readingScore,
    'listeningScore': listeningScore,
    'isPassed': isPassed,
    'completedAt': completedAt.toIso8601String(),
    'timeSpentSeconds': timeSpentSeconds,
    'userAnswers': userAnswers.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory ExamAttemptRecord.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['userAnswers'] as Map<String, dynamic>? ?? {};
    final Map<int, int> parsedAnswers = {};
    rawAnswers.forEach((k, v) {
      final keyInt = int.tryParse(k.toString());
      final valInt = v is int ? v : int.tryParse(v.toString()) ?? 0;
      if (keyInt != null) {
        parsedAnswers[keyInt] = valInt;
      }
    });

    return ExamAttemptRecord(
      setId: json['setId'] as String? ?? 'set_01',
      setTitle: json['setTitle'] as String? ?? '실전 모의고사',
      studentId: json['studentId'] as String? ?? 'student',
      studentName: json['studentName'] as String? ?? 'विद्यार्थी',
      registrationNo: json['registrationNo'] as String? ?? '01234567',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      readingScore: (json['readingScore'] as num?)?.toDouble() ?? 0.0,
      listeningScore: (json['listeningScore'] as num?)?.toDouble() ?? 0.0,
      isPassed: json['isPassed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 1500,
      userAnswers: parsedAnswers,
    );
  }
}

class ExamHistoryService {
  static final ExamHistoryService instance = ExamHistoryService._internal();
  ExamHistoryService._internal() {
    _initFromStorageOrSeed();
  }

  final List<ExamAttemptRecord> _attempts = [];

  void _initFromStorageOrSeed() {
    _seedInitialAttempts();
  }

  /// Initialize and load saved attempts from persistent offline storage (Non-Destructive)
  void loadFromStorage(List<ExamAttemptRecord> savedAttempts) {
    if (savedAttempts.isNotEmpty) {
      mergeAttemptsFromCloud(savedAttempts);
    }
  }

  /// Intelligent Non-Destructive Attempt Merge:
  /// Preserves all local test results and unions with remote/cloud attempts
  void mergeAttemptsFromCloud(List<ExamAttemptRecord> remoteAttempts) {
    for (final r in remoteAttempts) {
      final exists = _attempts.any((a) =>
          a.studentId == r.studentId &&
          a.setId == r.setId &&
          a.completedAt.difference(r.completedAt).inSeconds.abs() < 5);
      if (!exists) {
        _attempts.add(r);
      }
    }
    StorageService.instance.saveExamAttempts(_attempts);
  }

  void _seedInitialAttempts() {
    final now = DateTime.now();
    _attempts.addAll([
      ExamAttemptRecord(
        setId: 'set_01',
        setTitle: '제1회 EPS-TOPIK 실전 모의고사 (제조업)',
        studentId: 'student',
        studentName: 'राम थापा (Ram Thapa)',
        registrationNo: '2026-001',
        score: 87.5,
        readingScore: 42.5,
        listeningScore: 45.0,
        isPassed: true,
        completedAt: now.subtract(const Duration(hours: 2)),
        timeSpentSeconds: 1620,
      ),
      ExamAttemptRecord(
        setId: 'set_02',
        setTitle: '제2회 농축산업 실전 모의고사 (농축산)',
        studentId: 'sita_g',
        studentName: 'सिता गुरुङ (Sita Gurung)',
        registrationNo: '2026-002',
        score: 72.5,
        readingScore: 35.0,
        listeningScore: 37.5,
        isPassed: true,
        completedAt: now.subtract(const Duration(hours: 5)),
        timeSpentSeconds: 1840,
      ),
      ExamAttemptRecord(
        setId: 'set_03',
        setTitle: '제3회 건설 및 현장안전 모의고사 (건설)',
        studentId: 'bikash_s',
        studentName: 'विकास श्रेष्ठ (Bikash Shrestha)',
        registrationNo: '2026-003',
        score: 47.5,
        readingScore: 22.5,
        listeningScore: 25.0,
        isPassed: false,
        completedAt: now.subtract(const Duration(hours: 9)),
        timeSpentSeconds: 2100,
      ),
      ExamAttemptRecord(
        setId: 'set_04',
        setTitle: '제4회 직장생활 및 한국문화 모의고사 (문화)',
        studentId: 'sujan_r',
        studentName: 'सुजन राई (Sujan Rai)',
        registrationNo: '2026-004',
        score: 77.5,
        readingScore: 37.5,
        listeningScore: 40.0,
        isPassed: true,
        completedAt: now.subtract(const Duration(days: 1)),
        timeSpentSeconds: 1530,
      ),
      ExamAttemptRecord(
        setId: 'set_05',
        setTitle: '제5회 최종 실전 종합 모의고사 (종합)',
        studentId: 'anita_t',
        studentName: 'अनिता तामाङ (Anita Tamang)',
        registrationNo: '2026-005',
        score: 92.5,
        readingScore: 45.0,
        listeningScore: 47.5,
        isPassed: true,
        completedAt: now.subtract(const Duration(days: 1, hours: 4)),
        timeSpentSeconds: 1480,
      ),
    ]);
  }

  void saveAttempt(ExamAttemptRecord record) {
    _attempts.insert(0, record); // Most recent first
    StorageService.instance.saveExamAttempts(_attempts);
    CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
  }

  List<ExamAttemptRecord> getAllAttempts() => List.unmodifiable(_attempts);

  ExamAttemptRecord? getBestAttempt(String setId) {
    final setAttempts = _attempts.where((a) => a.setId == setId).toList();
    if (setAttempts.isEmpty) return null;
    setAttempts.sort((a, b) => b.score.compareTo(a.score));
    return setAttempts.first;
  }

  int get completedSetsCount {
    final uniqueSetIds = _attempts.map((a) => a.setId).toSet();
    return uniqueSetIds.length;
  }

  List<ExamAttemptRecord> getAttemptsForStudent(String studentId) {
    return _attempts.where((a) => a.studentId == studentId).toList();
  }
}

class ExamService {
  Future<ExamSessionModel> startExam(String studentId, String testPackageId, int totalDurationSeconds) async {
    final sessionId = 'SESSION_';
    final startTime = DateTime.now();
    return ExamSessionModel(
      sessionId: sessionId,
      studentId: studentId,
      testPackageId: testPackageId,
      startTime: startTime,
      remainingSeconds: totalDurationSeconds,
      status: ExamStatus.running,
      audioLockState: AudioState.ready,
    );
  }

  Future<void> saveInterruptedExam(String sessionId, int currentRemainingSeconds) async {}

  Future<void> submitExam(String sessionId) async {}
}
