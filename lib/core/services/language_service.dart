import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'auth_service.dart';

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
        return 'नेपाली';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.korean:
        return '한국어';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.nepali:
        return '🇳🇵';
      case AppLanguage.english:
        return '🇬🇧';
      case AppLanguage.korean:
        return '🇰🇷';
    }
  }
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  bool get isNepali => _currentLanguage == AppLanguage.nepali;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  bool get isKorean => _currentLanguage == AppLanguage.korean;

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
    if (savedCode == 'ne') {
      _currentLanguage = AppLanguage.nepali;
    } else if (savedCode == 'ko') {
      _currentLanguage = AppLanguage.korean;
    } else {
      _currentLanguage = AppLanguage.english;
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
    return _translations[key]?[langKey] ?? _translations[key]?['en'] ?? _translations[key]?['ne'] ?? key;
  }

  String trText({required String ne, required String en, required String ko}) {
    if (isNepali) return ne;
    if (isKorean) return ko;
    return en;
  }

  String batchText(String batch) {
    if (batch.contains('सबै') || batch.contains('All') || batch.contains('전체')) {
      return trText(ne: 'सबै ब्याचहरू', en: 'All Batches', ko: '전체 반');
    } else if (batch.contains('बिहानी') || batch.contains('Morning') || batch.contains('오전')) {
      return trText(ne: '2026 Batch A (बिहानी सत्र)', en: '2026 Batch A (Morning Session)', ko: '2026 1반 (오전)');
    } else if (batch.contains('दिवा') || batch.contains('Day') || batch.contains('오후')) {
      return trText(ne: '2026 Batch B (दिवा सत्र)', en: '2026 Batch B (Day Session)', ko: '2026 2반 (오후)');
    } else if (batch.contains('साँझ') || batch.contains('Evening') || batch.contains('저녁')) {
      return trText(ne: '2026 Batch C (साँझ सत्र)', en: '2026 Batch C (Evening Session)', ko: '2026 3반 (저녁)');
    } else if (batch.contains('बुटक्याम्प') || batch.contains('Bootcamp') || batch.contains('부트캠프')) {
      return trText(ne: 'विशेष UBT बुटक्याम्प', en: 'Special UBT Bootcamp', ko: '특별 UBT 부트캠프');
    }
    return batch;
  }

  String statusText(String status) {
    if (status.contains('सक्रिय') || status.contains('Active') || status.contains('정상')) {
      return trText(ne: 'सक्रिय', en: 'Active', ko: '활성');
    } else if (status.contains('निलम्बित') || status.contains('Suspended') || status.contains('정지')) {
      return trText(ne: 'निलम्बित', en: 'Suspended', ko: '정지');
    } else if (status.contains('म्याद') || status.contains('Expired') || status.contains('만료')) {
      return trText(ne: 'म्याद सकिएको', en: 'Expired', ko: '만료됨');
    } else if (status.contains('रोक्का') || status.contains('Blocked') || status.contains('차단')) {
      return trText(ne: 'रोक्का', en: 'Blocked', ko: '차단됨');
    }
    return status;
  }

  String roleText(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return trText(ne: 'मुख्य सुपर एडमिन', en: 'Super Admin', ko: '최고 관리자');
      case UserRole.admin:
        return trText(ne: 'इन्स्टिच्युट एडमिन', en: 'Institute Admin', ko: '학원 관리자');
      case UserRole.student:
        return trText(ne: 'विद्यार्थी / परीक्षार्थी', en: 'Student / Candidate', ko: '수험생 / 학생');
    }
  }

  String trExamResult(bool isPassed) {
    return isPassed
        ? trText(ne: 'उत्तीर्ण (Passed)', en: 'Passed', ko: '합격')
        : trText(ne: 'अनुत्तीर्ण (Failed)', en: 'Failed', ko: '불합격');
  }

  String trDifficulty(String diff) {
    final lower = diff.toLowerCase();
    if (lower.contains('कठिन') || lower.contains('hard') || lower.contains('advanced') || lower.contains('고급')) {
      return trText(ne: 'कठिन', en: 'Hard', ko: '고급');
    } else if (lower.contains('मध्यम') || lower.contains('medium') || lower.contains('intermediate') || lower.contains('중급')) {
      return trText(ne: 'मध्यम', en: 'Medium', ko: '중급');
    }
    return trText(ne: 'आधारभूत', en: 'Basic', ko: '초급');
  }

  String sectorText(String sectorKey) {
    if (sectorKey.contains('제조업') || sectorKey.contains('Manufacturing') || sectorKey.contains('उत्पादन')) {
      return trText(ne: 'उत्पादन क्षेत्र (제조업)', en: 'Manufacturing (제조업)', ko: '제조업 (Manufacturing)');
    } else if (sectorKey.contains('농축산') || sectorKey.contains('Agriculture') || sectorKey.contains('कृषि')) {
      return trText(ne: 'कृषि तथा पशुपालन (농축산)', en: 'Agriculture & Livestock (농축산)', ko: '농축산업 (Agriculture)');
    } else if (sectorKey.contains('건설') || sectorKey.contains('Construction') || sectorKey.contains('निर्माण')) {
      return trText(ne: 'निर्माण तथा सुरक्षा (건설업)', en: 'Construction & Safety (건설업)', ko: '건설업 (Construction)');
    } else if (sectorKey.contains('어업') || sectorKey.contains('Fishery') || sectorKey.contains('मत्स्य')) {
      return trText(ne: 'मत्स्यपालन (어업)', en: 'Fishery (어업)', ko: '어업 (Fishery)');
    } else if (sectorKey.contains('실전') || sectorKey.contains('Simulation') || sectorKey.contains('Final') || sectorKey.contains('नमुना')) {
      return trText(ne: 'अन्तिम परीक्षा नमुना', en: 'Exam Simulation', ko: '실전 모의고사');
    }
    return sectorKey;
  }

  String readingSectionText() {
    return trText(ne: 'रिडिङ (१-२०)', en: 'Reading (1-20)', ko: '읽기 (1-20)');
  }

  String listeningSectionText() {
    return trText(ne: 'लिसनिङ (२१-४०)', en: 'Listening (21-40)', ko: '듣기 (21-40)');
  }

  Widget buildLanguageSwitcherWidget({bool isDark = false, bool compact = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white24 : Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppLanguage.values.map((lang) {
          final isSel = _currentLanguage == lang;
          return InkWell(
            onTap: () => setLanguage(lang),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSel ? Colors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                compact ? lang.flag : '${lang.flag} ${lang.code.toUpperCase()}',
                style: TextStyle(
                  color: isSel ? Colors.black87 : Colors.white,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static const Map<String, Map<String, String>> _translations = {
    // -------------------------------------------------------------
    // Main Navigation Tabs
    // -------------------------------------------------------------
    'tab_home': {
      'ne': 'गृहपृष्ठ',
      'en': 'Home',
      'ko': '홈',
    },
    'tab_exam': {
      'ne': 'युबिट परीक्षा',
      'en': 'UBT Exam',
      'ko': '실전 시험',
    },
    'tab_study': {
      'ne': 'सिकाइ तथा अभ्यास',
      'en': 'Study & Practice',
      'ko': '학습 및 연습',
    },
    'tab_result': {
      'ne': 'परीक्षा नतिजा',
      'en': 'Results',
      'ko': '시험 결과',
    },
    'tab_dashboard': {
      'ne': 'ड्यासबोर्ड',
      'en': 'Dashboard',
      'ko': '대시보드',
    },
    'tab_profile': {
      'ne': 'प्रोफाइल',
      'en': 'Profile',
      'ko': '프로필',
    },

    // -------------------------------------------------------------
    // App Bar & Headers
    // -------------------------------------------------------------
    'app_title': {
      'ne': 'EPS-TOPIK UBT प्रणाली',
      'en': 'EPS-TOPIK UBT System',
      'ko': 'EPS-TOPIK UBT 시스템',
    },
    'app_subtitle': {
      'ne': 'नेपाल-कोरिया भाषा अध्ययन तथा UBT परीक्षा केन्द्र',
      'en': 'Nepal-Korea Language Institute & UBT Exam Center',
      'ko': '네팔-한국어 교육 및 UBT 시험 센터',
    },
    'settings': {
      'ne': 'सेटिङ',
      'en': 'Settings',
      'ko': '설정',
    },
    'language': {
      'ne': 'भाषा छनौट',
      'en': 'Language',
      'ko': '언어 설정',
    },
    'select_language': {
      'ne': 'प्रणालीको भाषा छान्नुहोस्',
      'en': 'Select System Language',
      'ko': '시스템 언어를 선택하세요',
    },
    'audio_speed': {
      'ne': 'अडियो गति',
      'en': 'Audio Speed',
      'ko': '오디오 재생 속도',
    },
    'available_sets': {
      'ne': 'उपलब्ध प्रश्न सेटहरू',
      'en': 'Available Test Sets',
      'ko': '실전 모의고사 세트',
    },
    'choose_set_desc': {
      'ne': 'आधिकारिक सेट छानेर परीक्षा वा अभ्यास सुरु गर्नुहोस्:',
      'en': 'Choose any official set to start exam or self-paced practice:',
      'ko': '원하는 공식 모의고사 세트를 선택하여 시험 또는 학습을 시작하세요:',
    },
    'offline_storage': {
      'ne': 'अफलाइन भण्डारण',
      'en': 'Offline Storage',
      'ko': '오프라인 저장소',
    },
    'zoom': {
      'ne': 'जुम',
      'en': 'Zoom',
      'ko': '화면 배율',
    },
    'super_admin_portal': {
      'ne': 'सुपर एडमिन पोर्टल',
      'en': 'Super Admin Portal',
      'ko': '최고 관리자 포털',
    },

    // -------------------------------------------------------------
    // Modes
    // -------------------------------------------------------------
    'mode_preference': {
      'ne': 'परीक्षा वा अभ्यास मोड छनौट',
      'en': 'Exam or Practice Mode Selection',
      'ko': '시험 및 학습 모드 선택',
    },
    'strict_exam_mode': {
      'ne': 'कडा UBT परीक्षा मोड',
      'en': 'Strict Official UBT Exam',
      'ko': '실전 UBT 모의고사',
    },
    'strict_exam_desc': {
      'ne': '५० मिनेट समय • कडा नियम • अडियो सीमित पटक • सबमिट गरेपछि मात्र नतिजा',
      'en': '50-minute timer • Strict rules • Limited audio replay • Results after submission',
      'ko': '50분 시험 시간 • 엄격한 시험 규정 • 제한된 오디오 재생 • 최종 제출 후 채점',
    },
    'study_practice_mode': {
      'ne': 'स्वतन्त्र सिकाइ तथा अभ्यास मोड',
      'en': 'Self-Paced Study & Practice',
      'ko': '자율 학습 및 연습 모드',
    },
    'study_practice_desc': {
      'ne': 'कुनै समय सीमा छैन • तत्काल सही उत्तर र व्याख्या • कोरियन अडियो अभ्यास',
      'en': 'No time pressure • Instant answers & explanations • Audio practice',
      'ko': '시간 제한 없음 • 즉시 정답 및 상세 해설 제공 • 반복 듣기 가능',
    },

    // -------------------------------------------------------------
    // Profile & Password
    // -------------------------------------------------------------
    'user_profile': {
      'ne': 'प्रयोगकर्ता प्रोफाइल',
      'en': 'User Profile',
      'ko': '사용자 프로필',
    },
    'profile_photo': {
      'ne': 'अवतार वा प्रोफाइल फोटो',
      'en': 'Profile Photo or Avatar',
      'ko': '프로필 사진 및 아바타',
    },
    'fullname': {
      'ne': 'पूरा नाम',
      'en': 'Full Name',
      'ko': '이름',
    },
    'mobile_number': {
      'ne': 'मोबाइल नम्बर',
      'en': 'Mobile Number',
      'ko': '휴대폰 번호',
    },
    'save_profile': {
      'ne': 'प्रोफाइल सुरक्षित गर्नुहोस्',
      'en': 'Save Profile',
      'ko': '프로필 저장하기',
    },
    'change_password': {
      'ne': 'पासवर्ड परिवर्तन',
      'en': 'Change Password',
      'ko': '비밀번호 변경',
    },
    'current_password': {
      'ne': 'हालको पासवर्ड',
      'en': 'Current Password',
      'ko': '현재 비밀번호',
    },
    'new_password': {
      'ne': 'नयाँ पासवर्ड',
      'en': 'New Password',
      'ko': '새 비밀번호',
    },
    'confirm_password': {
      'ne': 'नयाँ पासवर्ड पुष्टि',
      'en': 'Confirm New Password',
      'ko': '새 비밀번호 확인',
    },
    'update_password_btn': {
      'ne': 'पासवर्ड सुरक्षित गर्नुहोस्',
      'en': 'Save Password',
      'ko': '비밀번호 저장하기',
    },
    'security_preferences': {
      'ne': 'प्राथमिकता तथा सुरक्षा',
      'en': 'Preferences & Security',
      'ko': '환경설정 및 보안',
    },
    'cloud_sync': {
      'ne': 'क्लाउड सिङ्क',
      'en': 'Cloud Sync',
      'ko': '클라우드 동기화',
    },
    'system_info': {
      'ne': 'प्रणाली विवरण',
      'en': 'System Info',
      'ko': '시스템 정보',
    },

    // -------------------------------------------------------------
    // Study Materials & Categories
    // -------------------------------------------------------------
    'books': {
      'ne': 'किताबहरू',
      'en': 'Textbooks',
      'ko': '교재',
    },
    'dictionary': {
      'ne': 'डिक्सनरी',
      'en': 'Dictionary',
      'ko': '사전',
    },
    'flashcards': {
      'ne': 'चित्र फ्ल्यासकार्ड',
      'en': 'Flashcards',
      'ko': '그림 단어장',
    },
    'notices': {
      'ne': 'सूचनाहरू',
      'en': 'Notices',
      'ko': '공지사항',
    },
    'grammar': {
      'ne': 'व्याकरण',
      'en': 'Grammar',
      'ko': '문법',
    },
    'videos': {
      'ne': 'भिडियो कोर्स',
      'en': 'Video Lessons',
      'ko': '동영상 강의',
    },
    'chapter': {
      'ne': 'पाठ',
      'en': 'Chapter',
      'ko': '과',
    },
    'dialogue_1': {
      'ne': 'संवाद १',
      'en': 'Dialogue 1',
      'ko': '대화 1',
    },
    'dialogue_2': {
      'ne': 'संवाद २',
      'en': 'Dialogue 2',
      'ko': '대화 2',
    },
    'vocabulary': {
      'ne': 'शब्दावली',
      'en': 'Vocabulary',
      'ko': '어휘',
    },
    'listening_practice': {
      'ne': 'सुन्ने अभ्यास',
      'en': 'Listening Practice',
      'ko': '듣기 연습',
    },

    // -------------------------------------------------------------
    // Actions & Buttons
    // -------------------------------------------------------------
    'start_exam_btn': {
      'ne': 'परीक्षा सुरु गर्नुहोस्',
      'en': 'Start Exam',
      'ko': '실전 시험 시작',
    },
    'start_study_btn': {
      'ne': 'अभ्यास सुरु गर्नुहोस्',
      'en': 'Start Practice',
      'ko': '연습 시작하기',
    },
    'view_results': {
      'ne': 'विगत नतिजा तथा समीक्षा',
      'en': 'Past Results & Review',
      'ko': '지난 시험 결과 및 오답 복습',
    },
    'mistake_review': {
      'ne': 'कमजोरी समीक्षा',
      'en': 'Review Mistakes',
      'ko': '오답 복습하기',
    },
    'logout': {
      'ne': 'लगआउट',
      'en': 'Logout',
      'ko': '로그아웃',
    },
    'passed': {
      'ne': 'उत्तीर्ण',
      'en': 'Passed',
      'ko': '합격',
    },
    'failed': {
      'ne': 'अनुत्तीर्ण',
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
    'cancel': {
      'ne': 'रद्द',
      'en': 'Cancel',
      'ko': '취소',
    },
    'delete': {
      'ne': 'मेटाउनुहोस्',
      'en': 'Delete',
      'ko': '삭제',
    },
    'done': {
      'ne': 'सम्पन्न भयो',
      'en': 'Done',
      'ko': '완료',
    },
    'add': {
      'ne': 'थप्नुहोस्',
      'en': 'Add',
      'ko': '추가',
    },
    'edit': {
      'ne': 'सम्पादन',
      'en': 'Edit',
      'ko': '수정',
    },
    'search': {
      'ne': 'खोज्नुहोस्',
      'en': 'Search',
      'ko': '검색',
    },
    'reading': {
      'ne': 'रिडिङ',
      'en': 'Reading',
      'ko': '읽기',
    },
    'listening': {
      'ne': 'लिसनिङ',
      'en': 'Listening',
      'ko': '듣기',
    },
    'total_questions': {
      'ne': 'कुल प्रश्नहरू',
      'en': 'Total Questions',
      'ko': '총 문항',
    },
    'all_sets_btn': {
      'ne': 'सबै सेट पोर्टल',
      'en': 'All Sets Portal',
      'ko': '전체 세트 보기',
    },
    'role_super_admin': {
      'ne': 'सुपर एडमिन',
      'en': 'Super Admin',
      'ko': '최고 관리자',
    },
    'role_admin': {
      'ne': 'इन्स्टिच्युट एडमिन',
      'en': 'Institute Admin',
      'ko': '학원 관리자',
    },
    'role_student': {
      'ne': 'परीक्षार्थी',
      'en': 'Student Candidate',
      'ko': '수험생',
    },
    'all': {
      'ne': 'सबै',
      'en': 'All',
      'ko': '전체',
    },
    'new_edition': {
      'ne': 'नयाँ संस्करण',
      'en': 'New Edition',
      'ko': '신규판',
    },
    'old_edition': {
      'ne': 'पुरानो संस्करण',
      'en': 'Old Edition',
      'ko': '구판',
    },
    'special_guide': {
      'ne': 'विशेष गाइड',
      'en': 'Special Guide',
      'ko': '특별 가이드',
    },
    'highlights': {
      'ne': 'मुख्य विशेषताहरू',
      'en': 'Highlights',
      'ko': '주요 특징',
    },
    'mastered': {
      'ne': 'कण्ठ भयो',
      'en': 'Mastered',
      'ko': '암기완료',
    },
    'tap_to_flip': {
      'ne': 'कार्ड थिचेर अर्थ हेर्नुहोस्',
      'en': 'Tap card to flip',
      'ko': '카드를 눌러 뒤집기',
    },
    'swipe_to_next': {
      'ne': 'स्वाइप गर्नुहोस्',
      'en': 'Swipe to Next',
      'ko': '다음으로 넘기기',
    },
    'tts_listen': {
      'ne': 'उच्चारण सुन्नुहोस्',
      'en': 'Listen Audio',
      'ko': '발음 듣기',
    },
    'all_chapters': {
      'ne': 'सबै ६० अध्यायहरू',
      'en': 'All 60 Chapters',
      'ko': '전체 60과',
    },
    'noun': {
      'ne': 'संज्ञा',
      'en': 'Noun',
      'ko': '명사',
    },
    'verb': {
      'ne': 'क्रिया',
      'en': 'Verb',
      'ko': '동사',
    },
    'adjective': {
      'ne': 'विशेषण',
      'en': 'Adjective',
      'ko': '형용사',
    },
    'today_live_exam': {
      'ne': 'आजको दैनिक परीक्षा',
      'en': "Today's Live Exam",
      'ko': '오늘의 실전 시험',
    },
    'my_account': {
      'ne': 'मेरो खाता',
      'en': 'My Account',
      'ko': '내 계정',
    },
    'active': {
      'ne': 'सक्रिय',
      'en': 'Active',
      'ko': '활성',
    },
    'sector': {
      'ne': 'औद्योगिक क्षेत्र',
      'en': 'Sector',
      'ko': '업종',
    },
    'clear_cache': {
      'ne': 'क्यास खाली गर्नुहोस्',
      'en': 'Clear Cache',
      'ko': '캐시 삭제',
    },
    'resources_hub': {
      'ne': 'अध्ययन स्रोत केन्द्र',
      'en': 'Study Resources Hub',
      'ko': '학습 자료 센터',
    },
    'random_exam': {
      'ne': 'अनन्त र्‍यान्डम परीक्षा',
      'en': 'Random Blueprint Exam',
      'ko': '무작위 실전 모의고사',
    },
    'start_random_exam': {
      'ne': 'नयाँ र्‍यान्डम परीक्षा सुरु गर्नुहोस्',
      'en': 'Start Random Exam',
      'ko': '새 무작위 시험 시작',
    },
    'infinite_mock_sets': {
      'ne': 'असीमित नयाँ मोडल सेट',
      'en': 'Infinite Unique Mock Tests',
      'ko': '무제한 신규 모의고사',
    },
    'zoom_out': {
      'ne': 'जुम घटाउनुहोस्',
      'en': 'Zoom Out',
      'ko': '축소',
    },
    'zoom_in': {
      'ne': 'जुम बढाउनुहोस्',
      'en': 'Zoom In',
      'ko': '확대',
    },
    'answered': {
      'ne': 'हल गरिएको',
      'en': 'Answered',
      'ko': '답안 작성',
    },
    'unanswered': {
      'ne': 'बाँकी',
      'en': 'Unanswered',
      'ko': '미답안',
    },
    'active_q': {
      'ne': 'हालको प्रश्न',
      'en': 'Current Question',
      'ko': '현재 문항',
    },
    'exit_exam': {
      'ne': 'परीक्षा छोड्नुहोस्',
      'en': 'Exit Exam',
      'ko': '시험 종료',
    },
    'submit_exam': {
      'ne': 'सबमिट गर्नुहोस्',
      'en': 'Submit Exam',
      'ko': '시험 제출',
    },
    'view_result': {
      'ne': 'नतिजा हेर्नुहोस्',
      'en': 'View Result',
      'ko': '결과 보기',
    },
    'scorecard': {
      'ne': 'परीक्षा नतिजा',
      'en': 'Scorecard',
      'ko': '성적표',
    },
    'answer_breakdown': {
      'ne': 'प्रश्न उत्तर विश्लेषण',
      'en': 'Answer Breakdown',
      'ko': '답안 분석',
    },
    'correct': {
      'ne': 'सहि उत्तर',
      'en': 'Correct',
      'ko': '정답',
    },
    'incorrect': {
      'ne': 'गलत उत्तर',
      'en': 'Incorrect',
      'ko': '오답',
    },
    'accuracy': {
      'ne': 'समय र शुद्धता',
      'en': 'Accuracy & Time',
      'ko': '정확도 및 시간',
    },
    'attempted': {
      'ne': 'हल गरिएका',
      'en': 'Attempted',
      'ko': '응시 완료',
    },
    'review_all_answers': {
      'ne': 'विस्तृत उत्तर समीक्षा',
      'en': 'Review All Answers',
      'ko': '오답노트 확인',
    },
    'student_portal': {
      'ne': 'पोर्टलमा फर्कनुहोस्',
      'en': 'Back to Portal',
      'ko': '포털로 돌아가기',
    },
    'sign_in': {
      'ne': 'लगइन गर्नुहोस्',
      'en': 'Sign In',
      'ko': '로그인',
    },
    'register_account': {
      'ne': 'नयाँ खाता दर्ता',
      'en': 'Register Account',
      'ko': '회원가입',
    },
    'password': {
      'ne': 'पासवर्ड',
      'en': 'Password',
      'ko': '비밀번호',
    },
    'forgot_password': {
      'ne': 'पासवर्ड बिर्सनुभयो?',
      'en': 'Forgot Password?',
      'ko': '비밀번호 찾기',
    },
    'google_sign_in': {
      'ne': 'Google मार्फत लगइन',
      'en': 'Google Sign-In',
      'ko': 'Google 로그인',
    },
    'mobile_otp_login': {
      'ne': 'मोबाइल नम्बरबाट लगइन',
      'en': 'Mobile OTP Login',
      'ko': '휴대폰 번호 로그인',
    },
    'username': {
      'ne': 'प्रयोगकर्ता नाम',
      'en': 'Username',
      'ko': '사용자 아이디',
    },
    'batch': {
      'ne': 'ब्याच',
      'en': 'Batch',
      'ko': '기수',
    },
    'exam_duration': {
      'ne': 'परीक्षाको समय',
      'en': 'Exam Duration',
      'ko': '시험 시간',
    },
    'full_marks': {
      'ne': 'पूर्णाङ्क',
      'en': 'Full Marks',
      'ko': '만점',
    },
    'system_overview': {
      'ne': 'सिस्टम ओभरभ्यू',
      'en': 'System Overview',
      'ko': '시스템 개요',
    },
    'create_set': {
      'ne': 'नयाँ सेट निर्माण',
      'en': 'Create Set',
      'ko': '세트 생성',
    },
    'back_to_sets': {
      'ne': 'सेट सूची',
      'en': 'Back to Sets',
      'ko': '세트 목록',
    },
    'save_sync': {
      'ne': 'सुरक्षित गर्नुहोस्',
      'en': 'Save & Sync',
      'ko': '저장 및 동기화',
    },
    'instant_explanations': {
      'ne': 'तत्काल उत्तर र व्याख्या',
      'en': 'Instant Explanations',
      'ko': '즉시 정답 및 해설',
    },
    'self_paced_learning': {
      'ne': 'समयको कुनै दबाब छैन',
      'en': 'Self-paced Learning',
      'ko': '자율 학습',
    },
    'exit': {
      'ne': 'बाहिरिनुहोस्',
      'en': 'Exit',
      'ko': '나가기',
    },
    'confirm_reset': {
      'ne': 'डाटा रिसेट पुष्टि',
      'en': 'Confirm Reset',
      'ko': '데이터 초기화 확인',
    },
    'clear': {
      'ne': 'हटाउनुहोस्',
      'en': 'Clear',
      'ko': '삭제',
    },
    'questions': {
      'ne': 'प्रश्नहरू',
      'en': 'Questions',
      'ko': '문항',
    },
    'sets': {
      'ne': 'सेटहरू',
      'en': 'Sets',
      'ko': '세트',
    },
    'institutes': {
      'ne': 'इन्स्टिच्युटहरू',
      'en': 'Institutes',
      'ko': '학원 목록',
    },
    'students': {
      'ne': 'विद्यार्थीहरू',
      'en': 'Students',
      'ko': '수험생',
    },
    'analytics': {
      'ne': 'समग्र नतिजा',
      'en': 'Analytics',
      'ko': '통계 분석',
    },
    'bulk_import': {
      'ne': 'थोक आयात',
      'en': 'Bulk Import',
      'ko': '일괄 등록',
    },

    'nav_dashboard': {
      'ne': 'ड्यासबोर्ड',
      'en': 'Dashboard',
      'ko': '대시보드',
    },
    'nav_sets': {
      'ne': 'प्रश्न सेटहरू',
      'en': 'Question Sets',
      'ko': '문제 세트',
    },
    'nav_create_set': {
      'ne': 'नयाँ सेट',
      'en': 'New Set',
      'ko': '새 세트',
    },
    'nav_bulk_import': {
      'ne': 'थोक आयात',
      'en': 'Bulk Import',
      'ko': '일괄 등록',
    },
    'nav_students': {
      'ne': 'विद्यार्थी',
      'en': 'Students',
      'ko': '수험생 관리',
    },
    'nav_results': {
      'ne': 'नतिजा',
      'en': 'Results',
      'ko': '성적 분석',
    },
    'materials_management': {
      'ne': 'सामग्री तथा सूचना व्यवस्थापन',
      'en': 'Materials & Notice Management',
      'ko': '학습자료 및 공지 관리',
    },
    'super_admin_title': {
      'ne': 'EPS-TOPIK सुपर एडमिन',
      'en': 'EPS-TOPIK Super Admin',
      'ko': 'EPS-TOPIK 최고관리자',
    },
    'tab_institutes': {
      'ne': 'इन्स्टिच्युटहरू',
      'en': 'Institutes',
      'ko': '학원 목록',
    },
    'tab_central_resources': {
      'ne': 'केन्द्रीय रिसोर्स',
      'en': 'Central Resources',
      'ko': '중앙 리소스',
    },
    'tab_mock_sets': {
      'ne': 'प्रश्न सेटहरू',
      'en': 'Question Sets',
      'ko': '문제 세트',
    },
    'tab_analytics': {
      'ne': 'समग्र नतिजा',
      'en': 'Analytics',
      'ko': '통계 분석',
    },
    'registered_institutes': {
      'ne': 'दर्ता भएका इन्स्टिच्युटहरू',
      'en': 'Registered Institutes',
      'ko': '등록된 학원 목록',
    },
    'add_new_institute': {
      'ne': 'नयाँ इन्स्टिच्युट दर्ता',
      'en': 'Register New Institute',
      'ko': '새 학원 등록',
    },
    'total_institutes': {
      'ne': 'कुल इन्स्टिच्युटहरू',
      'en': 'Total Institutes',
      'ko': '전체 학원',
    },
    'active_institutes': {
      'ne': 'सक्रिय इन्स्टिच्युट',
      'en': 'Active Institutes',
      'ko': '활성 학원',
    },
    'expired_institutes': {
      'ne': 'म्याद सकिएका',
      'en': 'Expired Institutes',
      'ko': '만료된 학원',
    },
    'platform_copyright': {
      'ne': 'सुरक्षित प्रतिलिपि अधिकार',
      'en': 'Protected Copyright',
      'ko': '저작권 보호',
    },
    'confirm_logout': {
      'ne': 'लगआउट पुष्टि गर्नुहोस्',
      'en': 'Confirm Logout',
      'ko': '로그아웃 확인',
    },
    'logout_prompt': {
      'ne': 'के तपाईं आफ्नो खाताबाट लगआउट गर्न निश्चित हुनुहुन्छ?',
      'en': 'Are you sure you want to log out of your account?',
      'ko': '정말 계정에서 로그아웃하시겠습니까?',
    },
    'cancel_btn': {
      'ne': 'रद्द गर्नुहोस्',
      'en': 'Cancel',
      'ko': '취소',
    },
    'logout_btn': {
      'ne': 'हो, लगआउट गर्नुहोस्',
      'en': 'Yes, Log Out',
      'ko': '예, 로그아웃',
    },
    'close_btn': {
      'ne': 'बन्द गर्नुहोस्',
      'en': 'Close',
      'ko': '닫기',
    },
    'save_btn': {
      'ne': 'सुरक्षित गर्नुहोस्',
      'en': 'Save',
      'ko': '저장',
    },
    'reset_btn': {
      'ne': 'रिसेट गर्नुहोस्',
      'en': 'Reset',
      'ko': '초기화',
    },
    'prev_btn': {
      'ne': 'अघिल्लो',
      'en': 'Previous',
      'ko': '이전',
    },
    'next_btn': {
      'ne': 'अर्को',
      'en': 'Next',
      'ko': '다음',
    },
    'all_questions_grid': {
      'ne': 'सबै प्रश्नहरू',
      'en': 'All Questions',
      'ko': '전체문항',
    },
    'finish_exam': {
      'ne': 'सबमिट गर्नुहोस्',
      'en': 'Submit Exam',
      'ko': '최종 제출',
    },
    'profile_updated': {
      'ne': 'प्रोफाइल विवरण र फोटो सफलतापूर्वक सुरक्षित भयो!',
      'en': 'Profile details and photo saved successfully!',
      'ko': '프로필 정보와 사진이 성공적으로 저장되었습니다!',
    },
    'password_updated': {
      'ne': 'पासवर्ड सफलतापूर्वक परिवर्तन भयो र सुरक्षित गरियो!',
      'en': 'Password changed and saved successfully!',
      'ko': '비밀번호가 성공적으로 변경되었습니다!',
    },
    'all_questions_label': {
      'ne': 'सबै प्रश्नहरू (रिडिङ र लिसनिङ)',
      'en': 'All Questions (Reading & Listening)',
      'ko': '전체문항 (읽기 및 듣기)',
    },
  };
}
