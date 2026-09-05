import '../services/language_service.dart';
class GrammarExample {
  final String korean;
  final String nepali;

  const GrammarExample({required this.korean, required this.nepali});

  Map<String, dynamic> toJson() => {'korean': korean, 'nepali': nepali};
  factory GrammarExample.fromJson(Map<String, dynamic> json) => GrammarExample(
        korean: json['korean'] ?? '',
        nepali: json['nepali'] ?? '',
      );
}

class GrammarTopic {
  final String id;
  final String title;
  final String structure;
  final String category;
  final String nepaliExplanation;
  final List<GrammarExample> examples;
  final DateTime createdAt;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.structure,
    required this.category,
    required this.nepaliExplanation,
    required this.examples,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'structure': structure,
        'category': category,
        'nepaliExplanation': nepaliExplanation,
        'examples': examples.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GrammarTopic.fromJson(Map<String, dynamic> json) => GrammarTopic(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        structure: json['structure'] ?? '',
        category: json['category'] ?? 'सामान्य',
        nepaliExplanation: json['nepaliExplanation'] ?? '',
        examples: (json['examples'] as List? ?? [])
            .map((e) => GrammarExample.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class VocabularyItem {
  final String id;
  final String koreanWord;
  final String pronunciation;
  final String nepaliMeaning;
  final String category;
  final String exampleSentence;
  final DateTime? createdAt;

  const VocabularyItem({
    required this.id,
    required this.koreanWord,
    required this.pronunciation,
    required this.nepaliMeaning,
    required this.category,
    required this.exampleSentence,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'koreanWord': koreanWord,
        'pronunciation': pronunciation,
        'nepaliMeaning': nepaliMeaning,
        'category': category,
        'exampleSentence': exampleSentence,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory VocabularyItem.fromJson(Map<String, dynamic> json) => VocabularyItem(
        id: json['id'] ?? '',
        koreanWord: json['koreanWord'] ?? '',
        pronunciation: json['pronunciation'] ?? '',
        nepaliMeaning: json['nepaliMeaning'] ?? '',
        category: json['category'] ?? 'सामान्य',
        exampleSentence: json['exampleSentence'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Visual Flashcard with Book Illustration, Korean-first presentation,
/// chapter-wise and topic-wise tags, audio, and swipe capability.
class VisualFlashcard {
  final String id;
  final String koreanWord;
  final String pronunciation;
  final String nepaliMeaning;
  final int chapterNo;
  final String chapterTitle;
  final String topic;
  final String visualIcon;
  final String exampleSentence;
  bool isMastered;
  final String? audioUrl;

  VisualFlashcard({
    required this.id,
    required this.koreanWord,
    required this.pronunciation,
    required this.nepaliMeaning,
    this.chapterNo = 1,
    this.chapterTitle = '기초 한국어',
    required this.topic,
    this.visualIcon = '📦',
    required this.exampleSentence,
    this.isMastered = false,
    this.audioUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'koreanWord': koreanWord,
        'pronunciation': pronunciation,
        'nepaliMeaning': nepaliMeaning,
        'chapterNo': chapterNo,
        'chapterTitle': chapterTitle,
        'topic': topic,
        'visualIcon': visualIcon,
        'exampleSentence': exampleSentence,
        'isMastered': isMastered,
        'audioUrl': audioUrl,
      };

  factory VisualFlashcard.fromJson(Map<String, dynamic> json) => VisualFlashcard(
        id: json['id'] ?? '',
        koreanWord: json['koreanWord'] ?? '',
        pronunciation: json['pronunciation'] ?? '',
        nepaliMeaning: json['nepaliMeaning'] ?? '',
        chapterNo: json['chapterNo'] ?? 1,
        chapterTitle: json['chapterTitle'] ?? '기초 한국어',
        topic: json['topic'] ?? 'सामान्य',
        visualIcon: json['visualIcon'] ?? '📦',
        exampleSentence: json['exampleSentence'] ?? '',
        isMastered: json['isMastered'] ?? false,
        audioUrl: json['audioUrl'] as String?,
      );
}

/// Smart Korean-Nepali Dictionary Entry
class DictionaryWord {
  final String id;
  final String koreanWord;
  final String pronunciation;
  final String nepaliMeaning;
  final String partOfSpeech; // संज्ञा (Noun), क्रिया (Verb), विशेषण (Adjective)
  final int chapterNo;
  final String category;
  final String exampleKorean;
  final String exampleNepali;

  const DictionaryWord({
    required this.id,
    required this.koreanWord,
    required this.pronunciation,
    required this.nepaliMeaning,
    required this.partOfSpeech,
    this.chapterNo = 1,
    required this.category,
    required this.exampleKorean,
    required this.exampleNepali,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'koreanWord': koreanWord,
        'pronunciation': pronunciation,
        'nepaliMeaning': nepaliMeaning,
        'partOfSpeech': partOfSpeech,
        'chapterNo': chapterNo,
        'category': category,
        'exampleKorean': exampleKorean,
        'exampleNepali': exampleNepali,
      };

  factory DictionaryWord.fromJson(Map<String, dynamic> json) => DictionaryWord(
        id: json['id'] ?? '',
        koreanWord: json['koreanWord'] ?? '',
        pronunciation: json['pronunciation'] ?? '',
        nepaliMeaning: json['nepaliMeaning'] ?? '',
        partOfSpeech: json['partOfSpeech'] ?? 'संज्ञा (Noun)',
        chapterNo: json['chapterNo'] ?? 1,
        category: json['category'] ?? 'सामान्य',
        exampleKorean: json['exampleKorean'] ?? '',
        exampleNepali: json['exampleNepali'] ?? '',
      );
}

class VideoCourse {
  final String id;
  final String title;
  final String instructor;
  final String duration;
  final String videoUrl;
  final String category;
  final String description;
  final bool isFree;
  final DateTime createdAt;

  const VideoCourse({
    required this.id,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.videoUrl,
    required this.category,
    required this.description,
    this.isFree = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instructor': instructor,
        'duration': duration,
        'videoUrl': videoUrl,
        'category': category,
        'description': description,
        'isFree': isFree,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VideoCourse.fromJson(Map<String, dynamic> json) => VideoCourse(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        instructor: json['instructor'] ?? 'कोरियाली भाषा प्रशिक्षक',
        duration: json['duration'] ?? '15분',
        videoUrl: json['videoUrl'] ?? '',
        category: json['category'] ?? 'सामान्य',
        description: json['description'] ?? '',
        isFree: json['isFree'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Comprehensive Study Book supporting Unlimited Admin Uploads (old and new editions)
/// Represents an inline audio track for Textbook dialogues and exercises
class BookAudioTrack {
  final String id;
  final int chapterNo;
  final String label; // e.g. "Track 01", "대화 1", "Track 15"
  final String sectionType; // 'dialogue_1', 'dialogue_2', 'vocabulary', 'listening'
  final String audioUrl;
  final String? transcript;
  final double? posX; // Relative X coordinate (0.0 - 1.0) on PDF / page image
  final double? posY; // Relative Y coordinate (0.0 - 1.0) on PDF / page image
  final int? pageNumber; // Page number within the PDF / chapter

  const BookAudioTrack({
    required this.id,
    required this.chapterNo,
    required this.label,
    this.sectionType = 'dialogue_1',
    required this.audioUrl,
    this.transcript,
    this.posX,
    this.posY,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterNo': chapterNo,
        'label': label,
        'sectionType': sectionType,
        'audioUrl': audioUrl,
        'transcript': transcript,
        'posX': posX,
        'posY': posY,
        'pageNumber': pageNumber,
      };

  factory BookAudioTrack.fromJson(Map<String, dynamic> json) => BookAudioTrack(
        id: json['id'] ?? '',
        chapterNo: json['chapterNo'] ?? 1,
        label: json['label'] ?? 'Track 01',
        sectionType: json['sectionType'] ?? 'dialogue_1',
        audioUrl: json['audioUrl'] ?? '',
        transcript: json['transcript'],
        posX: (json['posX'] as num?)?.toDouble(),
        posY: (json['posY'] as num?)?.toDouble(),
        pageNumber: json['pageNumber'] as int?,
      );
}

class StudyBook {
  final String id;
  final String title;
  final String subtitle;
  final String editionType; // 'नयाँ संस्करण (New 2024)', 'पुरानो संस्करण (Old 2013)', 'विशेष गाइड'
  final String level;
  final int chaptersCount;
  final String description;
  final String pdfUrl;
  final Map<String, String> chapterPdfs; // Map chapter number to PDF or page image URL
  final List<String> highlightTopics;
  final List<BookAudioTrack> audioTracks;
  final DateTime createdAt;

  const StudyBook({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.editionType,
    required this.level,
    required this.chaptersCount,
    required this.description,
    this.pdfUrl = '',
    this.chapterPdfs = const {},
    required this.highlightTopics,
    this.audioTracks = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'editionType': editionType,
        'level': level,
        'chaptersCount': chaptersCount,
        'description': description,
        'pdfUrl': pdfUrl,
        'chapterPdfs': chapterPdfs,
        'highlightTopics': highlightTopics,
        'audioTracks': audioTracks.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };


  String localizedTitle([AppLanguage? lang]) {
    final curLang = lang ?? LanguageService.instance.currentLanguage;
    if (id == 'book_new_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return 'EPS-TOPIK 한국어 표준교재 1권 (2024 개정판)';
        case AppLanguage.english:
          return 'EPS-TOPIK Korean Standard Textbook 1 (2024 Revised Edition)';
        case AppLanguage.nepali:
          return 'EPS-TOPIK कोरियन भाषा पाठ्यपुस्तक १ (२०२४ नयाँ परिमार्जित संस्करण)';
      }
    } else if (id == 'book_new_02') {
      switch (curLang) {
        case AppLanguage.korean:
          return 'EPS-TOPIK 한국어 표준교재 2권 (2024 개정판)';
        case AppLanguage.english:
          return 'EPS-TOPIK Korean Standard Textbook 2 (2024 Revised Edition)';
        case AppLanguage.nepali:
          return 'EPS-TOPIK कोरियन भाषा पाठ्यपुस्तक २ (२०२४ नयाँ परिमार्जित संस्करण)';
      }
    } else if (id == 'book_old_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return 'EPS-TOPIK 한국어 표준교재 (2013 구판 - Classic)';
        case AppLanguage.english:
          return 'EPS-TOPIK Korean Standard Textbook (2013 Classic Edition)';
        case AppLanguage.nepali:
          return 'EPS-TOPIK कोरियन भाषा पाठ्यपुस्तक (२०१३ पुरानो क्लासिक संस्करण)';
      }
    } else if (id == 'book_guide_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '고용허가제 표준 한국어 실전 단어장 (특수 어휘집)';
        case AppLanguage.english:
          return 'EPS-TOPIK Standard Industry Vocabulary Guide';
        case AppLanguage.nepali:
          return 'रोजगार अनुमति प्रणाली (EPS) औद्योगिक शब्दावली गाइड';
      }
    }
    return title;
  }

  String localizedSubtitle([AppLanguage? lang]) {
    final curLang = lang ?? LanguageService.instance.currentLanguage;
    if (id == 'book_new_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '기초 한국어 및 일상생활 (제01과 ~ 제30과)';
        case AppLanguage.english:
          return 'Basic Korean Language & Daily Living (Chapters 01 to 30)';
        case AppLanguage.nepali:
          return 'आधारभूत कोरियन भाषा तथा दैनिक जीवनयापन (अध्याय ०१ देखि ३०)';
      }
    } else if (id == 'book_new_02') {
      switch (curLang) {
        case AppLanguage.korean:
          return '직장 언어, 안전, 근로기준법 및 문화 (제31과 ~ 제60과)';
        case AppLanguage.english:
          return 'Workplace Language, Safety, Labor Law & Culture (Chapters 31 to 60)';
        case AppLanguage.nepali:
          return 'कार्यस्थल भाषा, सुरक्षा, श्रम कानुन तथा संस्कृति (अध्याय ३१ देखि ६०)';
      }
    } else if (id == 'book_old_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '클래식 기초 표준교재 1 & 2 (제01과 ~ 제60과)';
        case AppLanguage.english:
          return 'Classic Standard Textbook 1 & 2 (Chapters 01 to 60)';
        case AppLanguage.nepali:
          return 'क्लासिक आधारभूत पाठ्यपुस्तक १ र २ (अध्याय ०१ देखि ६०)';
      }
    } else if (id == 'book_guide_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '직장 및 제조업/농축산/건설/어업 핵심 2000 단어';
        case AppLanguage.english:
          return 'Essential 2,000 Vocabulary Words for Workplace & Industry';
        case AppLanguage.nepali:
          return 'कार्यस्थल तथा उद्योग क्षेत्र अनुसारका २००० अत्यावश्यक मिनिङहरू';
      }
    }
    return subtitle;
  }

  String localizedEditionType([AppLanguage? lang]) {
    final curLang = lang ?? LanguageService.instance.currentLanguage;
    if (editionType.contains('नयाँ') || editionType.toLowerCase().contains('new') || id.contains('new')) {
      switch (curLang) {
        case AppLanguage.korean:
          return '신규 개정판';
        case AppLanguage.english:
          return 'New Edition';
        case AppLanguage.nepali:
          return 'नयाँ संस्करण';
      }
    } else if (editionType.contains('पुरानो') || editionType.toLowerCase().contains('old') || id.contains('old')) {
      switch (curLang) {
        case AppLanguage.korean:
          return '클래식 구판';
        case AppLanguage.english:
          return 'Old Edition';
        case AppLanguage.nepali:
          return 'पुरानो संस्करण';
      }
    } else if (editionType.contains('विशेष') || editionType.toLowerCase().contains('special') || id.contains('guide')) {
      switch (curLang) {
        case AppLanguage.korean:
          return '특수 가이드';
        case AppLanguage.english:
          return 'Special Guide';
        case AppLanguage.nepali:
          return 'विशेष गाइड';
      }
    }
    return editionType;
  }

  String localizedDescription([AppLanguage? lang]) {
    final curLang = lang ?? LanguageService.instance.currentLanguage;
    if (id == 'book_new_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '한글 익히기, 인사, 쇼핑, 길찾기, 날짜/시간, 날씨, 가족, 음식 및 일상 직장 대화를 수록한 공식 표준교재입니다.';
        case AppLanguage.english:
          return 'Official updated textbook covering Hangul alphabet, greetings, shopping, directions, date/time, weather, family, food and daily workplace conversations.';
        case AppLanguage.nepali:
          return 'वर्णमाला (हन्गुल), अभिवादन, किनमेल, दिशा, मिति/समय, मौसम, परिवार, खाना र दैनिक कार्यस्थल संवादहरू समेटिएको नवीनतम परिमार्जित आधिकारिक पाठ्यपुस्तक।';
      }
    } else if (id == 'book_new_02') {
      switch (curLang) {
        case AppLanguage.korean:
          return '제조업 공구, 작업장 안전, 산업재해 예방, 농축산/건설 어휘, 한국 문화, 근로계약, 급여 및 보험 관련 공식 표준교재입니다.';
        case AppLanguage.english:
          return 'Official textbook covering factory tools, workplace safety, accident prevention, agriculture/construction terms, Korean culture, labor contracts, salary, and insurance.';
        case AppLanguage.nepali:
          return 'कारखाना औजार, कार्यस्थल सुरक्षा, औद्योगिक दुर्घटना रोकथाम, कृषि र निर्माण शब्दावली, कोरियाली संस्कृति, श्रम सम्झौता, तलब र बिमा सम्बन्धी आधिकारिक पाठ्यपुस्तक।';
      }
    } else if (id == 'book_old_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '기존에 검증된 기본 어휘, 문법 구조 및 기출 문제 유형을 폭넓게 수록한 클래식 구 표준교재입니다.';
        case AppLanguage.english:
          return 'Classic standard edition covering foundational vocabulary, grammatical structures, and traditional past exam topics.';
        case AppLanguage.nepali:
          return 'पहिलेदेखि नै अभ्यास गरिँदै आएका आधारभूत शब्दहरू, व्याकरणका संरचनाहरू र विगतका परीक्षामा धेरै सोधिएका प्रश्नहरू भएको क्लासिक पुरानो संस्करण।';
      }
    } else if (id == 'book_guide_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return '제조업, 농축산업, 건설업, 어업 분야별 실전 필수 어휘와 그림, 예문을 담은 특별 단어장 가이드입니다.';
        case AppLanguage.english:
          return 'Special pocket guide with official vocabulary, illustrations, and examples for manufacturing, agriculture, construction, and fishery sectors.';
        case AppLanguage.nepali:
          return 'म्यानुफ्याक्चरिङ, कृषि, निर्माण, र मत्स्यपालन क्षेत्रका आधिकारिक शब्दावली, चित्र र उदाहरण सहितको विशेष पकेट गाइड।';
      }
    }
    return description;
  }

  List<String> localizedHighlights([AppLanguage? lang]) {
    final curLang = lang ?? LanguageService.instance.currentLanguage;
    if (id == 'book_new_01') {
      switch (curLang) {
        case AppLanguage.korean:
          return [
            '제1과~5과: 한글 익히기 (자음/모음 및 발음)',
            '제6과~10과: 자기소개 및 일상생활',
            '제11과~15과: 물건 사기 및 날씨',
            '제16과~20과: 취미 및 교통',
            '제21과~30과: 약속, 전화 및 병원',
          ];
        case AppLanguage.english:
          return [
            'Ch. 1~5: Learn Hangul (Alphabet & Pronunciation)',
            'Ch. 6~10: Self-introduction & Daily Routine',
            'Ch. 11~15: Shopping & Weather',
            'Ch. 16~20: Hobbies & Transportation',
            'Ch. 21~30: Appointments, Calls & Healthcare',
          ];
        case AppLanguage.nepali:
          return [
            '제1과~5과: 한글 익히기 (वर्णमाला र उच्चारण)',
            '제6과~10과: 자기소개 및 일상생활 (आत्मपरिचय र दिनचर्या)',
            '제11과~15과: 물건 사기 एवं मौसम (किनमेल र मौसम)',
            '제16과~20과: 취미 및 교통 (रुचि र यातायात)',
            '제21과~30과: 약속, 전화 एवं 병원 (भेटघाट र स्वास्थ्य)',
          ];
      }
    } else if (id == 'book_new_02') {
      switch (curLang) {
        case AppLanguage.korean:
          return [
            '제31과~40과: 한국 문화 및 직장 예절',
            '제41과~50과: 제조업 도구 및 안전 수칙',
            '제51과~55과: 고용허가제 및 근로계약',
            '제56과~60과: 휴가, 체류 연장 및 귀국',
          ];
        case AppLanguage.english:
          return [
            'Ch. 31~40: Korean Culture & Workplace Etiquette',
            'Ch. 41~50: Manufacturing Tools & Safety Rules',
            'Ch. 51~55: Employment Permit System & Contracts',
            'Ch. 56~60: Leaves, Visa Extensions & Return',
          ];
        case AppLanguage.nepali:
          return [
            '제31과~40과: 한국 문화 एवं 직장 예절 (कोरियाली संस्कृति र मर्यादा)',
            '제41과~50과: 제조업 도구 एवं 안전 수칙 (उत्पादन औजार र सुरक्षा)',
            '제51과~55과: 고용허가제 एवं 근로계약 (श्रम कानुन र सम्झौता)',
            '제56과~60과: 휴가, 체류 연장 एवं 귀국 (बिदा, भिसा थप र स्वदेश फिर्ता)',
          ];
      }
    }
    return highlightTopics;
  }

  factory StudyBook.fromJson(Map<String, dynamic> json) => StudyBook(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        editionType: json['editionType'] ?? 'नयाँ संस्करण (New Edition)',
        level: json['level'] ?? 'Book 1',
        chaptersCount: json['chaptersCount'] ?? 30,
        description: json['description'] ?? '',
        pdfUrl: json['pdfUrl'] ?? '',
        chapterPdfs: (json['chapterPdfs'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {},
        highlightTopics: List<String>.from(json['highlightTopics'] ?? []),
        audioTracks: (json['audioTracks'] as List?)
                ?.map((e) => BookAudioTrack.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class InstituteNotice {
  final String id;
  final String title;
  final String content;
  final String author;
  final String priority;
  final String category;
  final DateTime date;
  final bool isPinned;

  const InstituteNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.priority,
    required this.category,
    required this.date,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'priority': priority,
        'category': category,
        'date': date.toIso8601String(),
        'isPinned': isPinned,
      };

  factory InstituteNotice.fromJson(Map<String, dynamic> json) => InstituteNotice(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        author: json['author'] ?? 'Admin',
        priority: json['priority'] ?? 'सामान्य',
        category: json['category'] ?? 'सामान्य',
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
        isPinned: json['isPinned'] ?? false,
      );
}
