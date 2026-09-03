// Pure Dart Offline Database Models & Abstraction for Mobile (SQLite) and Web (IndexedDB)
// Phase 2: System Database Architecture (रुल ३, ४, ६)

enum UserRoleType { student, teacher, admin }
enum ExamStatusType { running, interrupted, submitted }
enum AudioStateType { ready, playingOnce, locked }

class DatabaseUser {
  final String id;
  final String name;
  final String? registrationNo;
  final UserRoleType role;
  final String? profilePicturePath;

  DatabaseUser({
    required this.id,
    required this.name,
    this.registrationNo,
    required this.role,
    this.profilePicturePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'registrationNo': registrationNo,
    'role': role.name,
    'profilePicturePath': profilePicturePath,
  };
}

class DatabaseQuestion {
  final String id;
  final String category; // READING or LISTENING
  final String? subCategory;
  final String? questionText;
  final String? questionImageAssetId;
  final String? audioAssetId;
  final String correctOptionId;
  final String? explanation;

  DatabaseQuestion({
    required this.id,
    required this.category,
    this.subCategory,
    this.questionText,
    this.questionImageAssetId,
    this.audioAssetId,
    required this.correctOptionId,
    this.explanation,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'subCategory': subCategory,
    'questionText': questionText,
    'questionImageAssetId': questionImageAssetId,
    'audioAssetId': audioAssetId,
    'correctOptionId': correctOptionId,
    'explanation': explanation,
  };
}

class DatabaseOption {
  final String id;
  final String questionId;
  final String? optionText;
  final String? optionImageAssetId;

  DatabaseOption({
    required this.id,
    required this.questionId,
    this.optionText,
    this.optionImageAssetId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'questionId': questionId,
    'optionText': optionText,
    'optionImageAssetId': optionImageAssetId,
  };
}

class DatabaseExamSession {
  final String sessionId;
  final String studentId;
  final String testPackageId;
  final int startTime;
  final int remainingSeconds;
  final ExamStatusType status;
  final AudioStateType audioLockState;

  DatabaseExamSession({
    required this.sessionId,
    required this.studentId,
    required this.testPackageId,
    required this.startTime,
    required this.remainingSeconds,
    required this.status,
    required this.audioLockState,
  });

  Map<String, dynamic> toMap() => {
    'sessionId': sessionId,
    'studentId': studentId,
    'testPackageId': testPackageId,
    'startTime': startTime,
    'remainingSeconds': remainingSeconds,
    'status': status.name,
    'audioLockState': audioLockState.name,
  };
}

class DatabaseAttemptAnswer {
  final String id;
  final String sessionId;
  final String questionId;
  final String? selectedOptionId;
  final bool? isCorrect;

  DatabaseAttemptAnswer({
    required this.id,
    required this.sessionId,
    required this.questionId,
    this.selectedOptionId,
    this.isCorrect,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sessionId': sessionId,
    'questionId': questionId,
    'selectedOptionId': selectedOptionId,
    'isCorrect': isCorrect,
  };
}
