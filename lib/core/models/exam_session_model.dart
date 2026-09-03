enum ExamStatus {
  created,
  preflight, // परीक्षा सुरु हुनुअघिको भेरिफिकेसन (रुल १०)
  ready,
  running, // परीक्षा चलिरहेको (टाइमर सुरु)
  interrupted, // क्र्यास भएको वा रोकिएको
  recovering,
  submitting,
  submitted,
  finalized
}

enum AudioState {
  locked, // दुईपटक बजेपछि लक हुने (रुल २१)
  ready,
  playingFirst,
  firstComplete,
  playingSecond,
  complete,
  aborted
}

class ExamSessionModel {
  final String sessionId;
  final String studentId;
  final String testPackageId;
  final DateTime startTime;
  final int remainingSeconds; // बाँकी समय
  final ExamStatus status;
  final AudioState audioLockState;

  ExamSessionModel({
    required this.sessionId,
    required this.studentId,
    required this.testPackageId,
    required this.startTime,
    required this.remainingSeconds,
    required this.status,
    required this.audioLockState,
  });
}
