import 'package:flutter/foundation.dart';
import 'storage_service.dart';

enum AppLanguage { nepali, english, korean }

enum ExamModePreference { strictExam, studyPractice }

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.nepali:
        return 'ne';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.korean:
        return 'ko';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.nepali:
        return '🇳🇵 नेपाली (Nepali)';
      case AppLanguage.english:
        return '🇬🇧 English';
      case AppLanguage.korean:
        return '🇰🇷 한국어 (Korean)';
    }
  }
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  AppLanguage _currentLanguage = AppLanguage.nepali;
  AppLanguage get currentLanguage => _currentLanguage;

  ExamModePreference _modePreference = ExamModePreference.strictExam;
  ExamModePreference get modePreference => _modePreference;

  double _audioSpeed = 1.0;
  double get audioSpeed => _audioSpeed;

  void setAudioSpeed(double speed) {
    _audioSpeed = speed;
    notifyListeners();
  }

  void setModePreference(ExamModePreference mode) {
    _modePreference = mode;
    notifyListeners();
  }

  void init() {
    final savedCode = StorageService.instance.loadLanguage();
    if (savedCode == 'en') {
      _currentLanguage = AppLanguage.english;
    } else if (savedCode == 'ko') {
      _currentLanguage = AppLanguage.korean;
    } else {
      _currentLanguage = AppLanguage.nepali;
    }
  }

  void setLanguage(AppLanguage lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      StorageService.instance.saveLanguage(lang.code);
      notifyListeners();
    }
  }

  String tr(String key) {
    final langKey = _currentLanguage.code;
    return _translations[key]?[langKey] ?? _translations[key]?['ne'] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // Tabs
    'tab_profile': {
      'ne': 'प्रोफाइल',
      'en': 'Profile',
      'ko': '프로필',
    },
    'tab_exam': {
      'ne': 'युबिट एक्जाम',
      'en': 'UBT Exam',
      'ko': '실전 시험',
    },
    'tab_study': {
      'ne': 'स्टडी प्राक्टिस',
      'en': 'Study & Practice',
      'ko': '학습 모드',
    },
    'tab_result': {
      'ne': 'रिजल्ट',
      'en': 'Results',
      'ko': '시험 결과',
    },
    'tab_dashboard': {
      'ne': 'ड्यासबोर्ड',
      'en': 'Dashboard',
      'ko': '대시보드',
    },

    // App Bar & Headers
    'app_title': {
      'ne': 'EPS-TOPIK UBT प्रणाली',
      'en': 'EPS-TOPIK UBT System',
      'ko': 'EPS-TOPIK UBT 시스템',
    },
    'settings': {
      'ne': 'सेटिङ (Settings)',
      'en': 'Settings',
      'ko': '설정',
    },
    'language': {
      'ne': 'भाषा छनौट (Language)',
      'en': 'Language Preferences',
      'ko': '언어 설정',
    },
    'audio_speed': {
      'ne': 'कोरियन अडियो गति (Audio Speed)',
      'en': 'Audio Playback Speed',
      'ko': '한국어 음성 재생 속도',
    },
    'available_sets': {
      'ne': 'EPS-TOPIK बहु Mock Test सेटहरू (Available Test Sets)',
      'en': 'Available EPS-TOPIK Mock Test Sets',
      'ko': 'EPS-TOPIK 실전 모의고사 세트',
    },
    'choose_set_desc': {
      'ne': 'सेट १ देखि ५ सम्मका आधिकारिक प्रश्न सेटहरू — जुनसुकै सेट छानेर परीक्षा वा अभ्यास सुरु गर्नुहोस्:',
      'en': 'Official Mock Test Sets 1 to 5 — Choose any set to start exam or self-paced practice:',
      'ko': '1회부터 5회까지 공식 모의고사 — 원하는 세트를 선택하여 시험 또는 학습을 시작하세요:',
    },

    // Modes
    'mode_preference': {
      'ne': 'परीक्षा वा अभ्यास मोड छनौट (Mode Selection)',
      'en': 'Examination vs Study Mode Preference',
      'ko': '시험 및 학습 모드 선택',
    },
    'strict_exam_mode': {
      'ne': '실전 UBT कडा परीक्षा मोड (Strict Real Exam)',
      'en': 'Strict Official UBT Exam Mode',
      'ko': '실전 UBT 모의고사 (타이머/실전)',
    },
    'strict_exam_desc': {
      'ne': '५० मिनेट टाइमर • कडा नियम • अडियो दोहोर्याउन नपाइने • पूरा भएपछि मात्र नतिजा',
      'en': '50-minute timer • Strict rules • One-time audio • Results after submit',
      'ko': '50분 시험 시간 • 엄격한 규정 • 2회 연속 재생 • 최종 제출 후 채점',
    },
    'study_practice_mode': {
      'ne': 'Study & Practice अध्ययन तथा अभ्यास मोड',
      'en': 'Self-Paced Study & Practice Mode',
      'ko': '자율 학습 및 연습 모드',
    },
    'study_practice_desc': {
      'ne': 'कुनै समय सीमा छैन • तत्काल सहि/गलत उत्तर • नेपालीमा विस्तृत व्याख्या र अडियो',
      'en': 'No time pressure • Instant answers & explanations • Korean audio practice',
      'ko': '시간제한 없음 • 즉시 정답 및 상세 해설 제공 • 반복 청취 가능',
    },

    // Password
    'change_password': {
      'ne': 'पासवर्ड तथा सुरक्षा परिवर्तन (Change Password)',
      'en': 'Change Account Password',
      'ko': '비밀번호 및 보안 변경',
    },
    'current_password': {
      'ne': 'हालको पासवर्ड (Current Password)',
      'en': 'Current Password',
      'ko': '현재 비밀번호',
    },
    'new_password': {
      'ne': 'नयाँ पासवर्ड (New Password)',
      'en': 'New Password',
      'ko': '새 비밀번호',
    },
    'confirm_password': {
      'ne': 'नयाँ पासवर्ड पुष्टि (Confirm Password)',
      'en': 'Confirm New Password',
      'ko': '새 비밀번호 확인',
    },
    'update_password_btn': {
      'ne': 'पासवर्ड सुरक्षित गर्नुहोस् (Save Password)',
      'en': 'Save New Password',
      'ko': '비밀번호 저장하기',
    },

    // Actions & Buttons
    'start_exam_btn': {
      'ne': '실전 시험 (Exam)',
      'en': 'Start Exam',
      'ko': '실전 시험 응시',
    },
    'start_study_btn': {
      'ne': 'Study Mode',
      'en': 'Study Mode',
      'ko': '연습/학습 모드',
    },
    'view_results': {
      'ne': 'विगत नतिजा तथा समीक्षा',
      'en': 'Past Attempts & Review',
      'ko': '지난 시험 및 오답 복습',
    },
    'mistake_review': {
      'ne': 'कमजोरी समीक्षा (Mistakes)',
      'en': 'Review Mistakes',
      'ko': '오답 복습하기',
    },
    'logout': {
      'ne': 'लगआउट (Logout)',
      'en': 'Logout',
      'ko': '로그아웃',
    },
    'passed': {
      'ne': 'उत्तीर्ण (Pass)',
      'en': 'Passed',
      'ko': '합격',
    },
    'failed': {
      'ne': 'अनुत्तीर्ण (Fail)',
      'en': 'Failed',
      'ko': '불합격',
    },
    'score': {
      'ne': 'प्राप्ताङ्क',
      'en': 'Score',
      'ko': '점수',
    },
    'close': {
      'ne': 'बन्द गर्नुहोस्',
      'en': 'Close',
      'ko': '닫기',
    },
    'save': {
      'ne': 'सुरक्षित गर्नुहोस्',
      'en': 'Save',
      'ko': '저장',
    },
    'all_sets_btn': {
      'ne': 'सबै सेट पोर्टल',
      'en': 'All Sets Portal',
      'ko': '전체 세트 보기',
    },
  };
}
