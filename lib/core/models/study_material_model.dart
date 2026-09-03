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

  const BookAudioTrack({
    required this.id,
    required this.chapterNo,
    required this.label,
    this.sectionType = 'dialogue_1',
    required this.audioUrl,
    this.transcript,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterNo': chapterNo,
        'label': label,
        'sectionType': sectionType,
        'audioUrl': audioUrl,
        'transcript': transcript,
      };

  factory BookAudioTrack.fromJson(Map<String, dynamic> json) => BookAudioTrack(
        id: json['id'] ?? '',
        chapterNo: json['chapterNo'] ?? 1,
        label: json['label'] ?? 'Track 01',
        sectionType: json['sectionType'] ?? 'dialogue_1',
        audioUrl: json['audioUrl'] ?? '',
        transcript: json['transcript'],
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
        'highlightTopics': highlightTopics,
        'audioTracks': audioTracks.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory StudyBook.fromJson(Map<String, dynamic> json) => StudyBook(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        editionType: json['editionType'] ?? 'नयाँ संस्करण (New Edition)',
        level: json['level'] ?? 'Book 1',
        chaptersCount: json['chaptersCount'] ?? 30,
        description: json['description'] ?? '',
        pdfUrl: json['pdfUrl'] ?? '',
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
