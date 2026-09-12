import 'cloud_sync_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/study_material_model.dart';
import 'storage_service.dart';

/// Central Study Material, Resources, Dictionary & Notice Management Service
/// Supports unlimited book uploads, dictionary lookup, visual flashcards with chapters and topics.
class StudyMaterialService extends ChangeNotifier {
  static final StudyMaterialService instance = StudyMaterialService._internal();
  StudyMaterialService._internal();

  static const String _keyNotices = 'eps_notices_v1';
  static const String _keyGrammar = 'eps_grammar_v1';
  static const String _keyBooks = 'eps_books_unlimited_v2';
  static const String _keyDict = 'eps_dictionary_v2';
  static const String _keyVisualCards = 'eps_visual_cards_v2';
  static const String _keyVideos = 'eps_videos_v1';

  List<InstituteNotice>? _notices;
  List<GrammarTopic>? _grammarList;
  List<StudyBook>? _booksList;
  List<DictionaryWord>? _dictionaryList;
  List<VisualFlashcard>? _visualCardsList;
  List<VideoCourse>? _videoList;

  // -------------------------------------------------------------
  // 1. UNLIMITED BOOKS (असीमित नयाँ र पुराना किताबहरू)
  // -------------------------------------------------------------
    static const String _keyCleanSlateStudy = 'eps_clean_slate_study_v1';

  bool isCleanSlateMode() {
    try {
      return StorageService.instance.getString(_keyCleanSlateStudy) == 'true';
    } catch (_) {
      return false;
    }
  }

  void setCleanSlateMode(bool enable) {
    try {
      StorageService.instance.setString(_keyCleanSlateStudy, enable ? 'true' : 'false');
    } catch (_) {}
    _booksList = null;
    notifyListeners();
  }

  void clearAllBooks() {
    _booksList = [];
    _saveBooksToStorage();
    setCleanSlateMode(true);
    notifyListeners();
  }

  void clearAllStudyMaterials() {
    _booksList = [];
    _dictionaryList = [];
    _visualCardsList = [];
    _notices = [];
    _grammarList = [];
    _videoList = [];
    _saveBooksToStorage();
    setCleanSlateMode(true);
    notifyListeners();
  }

  void restoreSampleBooks() {
    setCleanSlateMode(false);
    _booksList = null;
    notifyListeners();
  }

  List<StudyBook> getAllBooks() {
    _booksList ??= _loadBooksFromStorage() ?? (isCleanSlateMode() ? <StudyBook>[] : _getDefaultBooks());
    return List.unmodifiable(_booksList!);
  }

  void addBook(StudyBook book) {
    getAllBooks();
    _booksList!.removeWhere((b) => b.id == book.id);
    _booksList!.insert(0, book);
    _saveBooksToStorage();
  }

  void deleteBook(String id) {
    getAllBooks();
    _booksList!.removeWhere((b) => b.id == id);
    _saveBooksToStorage();
  }

  List<StudyBook>? _loadBooksFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyBooks) ??
          StorageService.instance.getString('${_keyBooks}_backup');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => StudyBook.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveBooksToStorage() {
    if (_booksList == null) return;
    try {
      final list = _booksList!.map((b) => b.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyBooks, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyBooks}_backup', encoded);
      }
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save books: $e');
    }
  }

  List<StudyBook> _getDefaultBooks() {
    return <StudyBook>[];
  }

  // -------------------------------------------------------------
  // 2. DICTIONARY (कोरियन-नेपाली स्मार्ट डिक्सनरी)
  // -------------------------------------------------------------
  List<DictionaryWord> getAllDictionaryWords() {
    _dictionaryList ??= _loadDictionaryFromStorage() ?? _getDefaultDictionary();
    return List.unmodifiable(_dictionaryList!);
  }

  void addDictionaryWord(DictionaryWord word) {
    getAllDictionaryWords();
    _dictionaryList!.removeWhere((w) => w.id == word.id);
    _dictionaryList!.insert(0, word);
    _saveDictionaryToStorage();
  }

  void deleteDictionaryWord(String id) {
    getAllDictionaryWords();
    _dictionaryList!.removeWhere((w) => w.id == id);
    _saveDictionaryToStorage();
  }

  List<DictionaryWord>? _loadDictionaryFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyDict) ??
          StorageService.instance.getString('${_keyDict}_backup');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => DictionaryWord.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveDictionaryToStorage() {
    if (_dictionaryList == null) return;
    try {
      final list = _dictionaryList!.map((w) => w.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyDict, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyDict}_backup', encoded);
      }
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save dictionary: $e');
    }
  }

  List<DictionaryWord> _getDefaultDictionary() {
    return <DictionaryWord>[];
  }

  // -------------------------------------------------------------
  // 3. VISUAL FLASHCARDS (चित्र, अडियो, च्याप्टर र टपिक सहितको कार्ड)
  // -------------------------------------------------------------
  List<VisualFlashcard> getAllVisualFlashcards() {
    _visualCardsList ??= _loadVisualCardsFromStorage() ?? _getDefaultVisualCards();
    return _visualCardsList!;
  }

  List<int> getDistinctChapters() {
    final all = getAllVisualFlashcards();
    final chaps = all.map((c) => c.chapterNo).toSet().toList();
    chaps.sort();
    return chaps;
  }

  List<VisualFlashcard> getFlashcardsByChapter(int chapterNo) {
    final all = getAllVisualFlashcards();
    if (chapterNo <= 0) return all;
    return all.where((c) => c.chapterNo == chapterNo).toList();
  }

  void addVisualFlashcard(VisualFlashcard card) {
    getAllVisualFlashcards();
    _visualCardsList!.removeWhere((c) => c.id == card.id);
    _visualCardsList!.insert(0, card);
    _saveVisualCardsToStorage();
  }

  void deleteVisualFlashcard(String id) {
    getAllVisualFlashcards();
    _visualCardsList!.removeWhere((c) => c.id == id);
    _saveVisualCardsToStorage();
  }

  void toggleFlashcardMastered(String id) {
    getAllVisualFlashcards();
    final idx = _visualCardsList!.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _visualCardsList![idx].isMastered = !_visualCardsList![idx].isMastered;
      _saveVisualCardsToStorage();
    }
  }

  List<VisualFlashcard>? _loadVisualCardsFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyVisualCards) ??
          StorageService.instance.getString('${_keyVisualCards}_backup');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => VisualFlashcard.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveVisualCardsToStorage() {
    if (_visualCardsList == null) return;
    try {
      final list = _visualCardsList!.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyVisualCards, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyVisualCards}_backup', encoded);
      }
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save visual flashcards: $e');
    }
  }

  List<VisualFlashcard> _getDefaultVisualCards() {
    return [
      VisualFlashcard(
        id: 'vfc_01',
        koreanWord: '안전모',
        pronunciation: 'आन्जनमो',
        nepaliMeaning: 'सुरक्षा हेल्मेट (Safety Helmet)',
        chapterNo: 48,
        topic: 'सुरक्षा सामग्री',
        visualIcon: '⛑️',
        exampleSentence: '머리를 보호하기 위해 공사장에서 항상 안전모를 착용합니다.',
      ),
      VisualFlashcard(
        id: 'vfc_02',
        koreanWord: '안전화',
        pronunciation: 'आन्जन्व्हा',
        nepaliMeaning: 'सुरक्षा जुत्ता (Safety Shoes)',
        chapterNo: 48,
        topic: 'सुरक्षा सामग्री',
        visualIcon: '🥾',
        exampleSentence: '발에 무거운 철판이 떨어지지 않도록 안전화를 신으세요.',
      ),
      VisualFlashcard(
        id: 'vfc_03',
        koreanWord: '망치',
        pronunciation: 'माङ्छी',
        nepaliMeaning: 'हथौडा (Hammer)',
        chapterNo: 41,
        topic: 'कारखाना औजार',
        visualIcon: '🔨',
        exampleSentence: '못을 박을 때 손을 다치지 않게 망치를 조심해서 쓰세요.',
      ),
      VisualFlashcard(
        id: 'vfc_04',
        koreanWord: '톱',
        pronunciation: 'थोप',
        nepaliMeaning: 'करौंती (Hand Saw)',
        chapterNo: 41,
        topic: 'कारखाना औजार',
        visualIcon: '🪚',
        exampleSentence: '목재를 원하는 크기로 톱을 이용해 자릅니다.',
      ),
      VisualFlashcard(
        id: 'vfc_05',
        koreanWord: '사다리',
        pronunciation: 'सादारी',
        nepaliMeaning: 'भर्याङ (Ladder)',
        chapterNo: 41,
        topic: 'कारखाना औजार',
        visualIcon: '🪜',
        exampleSentence: '높은 벽에 페인트를 칠할 때 사다리를 바닥에 단단히 고정하세요.',
      ),
      VisualFlashcard(
        id: 'vfc_06',
        koreanWord: '비닐하우스',
        pronunciation: 'बिनिल्हाउसु',
        nepaliMeaning: 'टनेल / हरितगृह (Greenhouse)',
        chapterNo: 45,
        topic: 'कृषि तथा पशुपालन',
        visualIcon: '🏡',
        exampleSentence: '겨울철에는 비닐하우스 안에서 토마토와 오이를 키웁니다.',
      ),
      VisualFlashcard(
        id: 'vfc_07',
        koreanWord: '소화기',
        pronunciation: 'सोह्वागी',
        nepaliMeaning: 'अग्नि नियन्त्रक उपकरण (Fire Extinguisher)',
        chapterNo: 48,
        topic: 'सुरक्षा सामग्री',
        visualIcon: '🧯',
        exampleSentence: '불이 났을 때는 즉시 소화기의 안전핀을 뽑고 분사하세요.',
      ),
      VisualFlashcard(
        id: 'vfc_08',
        koreanWord: '지게차',
        pronunciation: 'चिगेछा',
        nepaliMeaning: 'फोर्कलिफ्ट गाडी (Forklift)',
        chapterNo: 43,
        topic: 'निर्माण तथा ढुवानी',
        visualIcon: '🚜',
        exampleSentence: '무거운 파렛트를 지게차로 트럭에 싣습니다.',
      ),
      VisualFlashcard(
        id: 'vfc_09',
        koreanWord: '보안경',
        pronunciation: 'पोआनग्योङ',
        nepaliMeaning: 'सुरक्षा चस्मा (Safety Glasses)',
        chapterNo: 48,
        chapterTitle: '다치지 않게 조심하세요 (सुरक्षा सतर्कता)',
        topic: 'सुरक्षा सामग्री',
        visualIcon: '🥽',
        exampleSentence: '용접이나 그라인더 작업 시에는 눈을 보호하기 위해 보안경을 쓰세요.',
      ),
      // Chapter 1: 인사말 (अभिवादन)
      VisualFlashcard(
        id: 'vfc_c1_01',
        koreanWord: '안녕하세요',
        pronunciation: 'आन्न्योङ्हासेयो',
        nepaliMeaning: 'नमस्ते / नमस्कार (Hello / Good day)',
        chapterNo: 1,
        chapterTitle: '한글 익히기 및 인사말 (वर्णमाला र अभिवादन)',
        topic: 'अभिवादन',
        visualIcon: '🤝',
        exampleSentence: '선생님을 만났을 때 공손하게 "안녕하세요"라고 인사합니다.',
      ),
      VisualFlashcard(
        id: 'vfc_c1_02',
        koreanWord: '감사합니다',
        pronunciation: 'खाम्साहाम्निदा',
        nepaliMeaning: 'धन्यवाद (Thank you)',
        chapterNo: 1,
        chapterTitle: '한글 익히기 및 인사말 (वर्णमाला र अभिवादन)',
        topic: 'अभिवादन',
        visualIcon: '🙏',
        exampleSentence: '도움을 받았을 때는 항상 "감사합니다"라고 인사하세요.',
      ),
      VisualFlashcard(
        id: 'vfc_c1_03',
        koreanWord: '죄송합니다',
        pronunciation: 'श्वेसोङहाम्निदा',
        nepaliMeaning: 'माफ गर्नुहोस् (I am sorry)',
        chapterNo: 1,
        chapterTitle: '한글 익히기 및 인사말 (वर्णमाला र अभिवादन)',
        topic: 'अभिवादन',
        visualIcon: '🙇',
        exampleSentence: '실수를 했을 때는 정중하게 "죄송합니다"라고 사과합니다.',
      ),

      // Chapter 6: 자기소개 (आत्मपरिचय)
      VisualFlashcard(
        id: 'vfc_c6_01',
        koreanWord: '네팔 사람',
        pronunciation: 'नेपाल साराम',
        nepaliMeaning: 'नेपाली नागरिक (Nepali Citizen)',
        chapterNo: 6,
        chapterTitle: '저는 투안입니다 (आत्मपरिचय)',
        topic: 'आत्मपरिचय',
        visualIcon: '🇳🇵',
        exampleSentence: '저는 네팔에서 온 투안이라고 합니다.',
      ),
      VisualFlashcard(
        id: 'vfc_c6_02',
        koreanWord: '회사원',
        pronunciation: 'ह्वेसावन',
        nepaliMeaning: 'कम्पनी कर्मचारी (Company Employee)',
        chapterNo: 6,
        chapterTitle: '저는 투안입니다 (आत्मपरिचय)',
        topic: 'पेशा',
        visualIcon: '💼',
        exampleSentence: '저는 한국 가구 공장에서 일하는 회사원입니다.',
      ),

      // Chapter 7: 장소 (स्थान तथा कार्यालय)
      VisualFlashcard(
        id: 'vfc_c7_01',
        koreanWord: '화장실',
        pronunciation: 'ह्वाजाङ्सिल',
        nepaliMeaning: 'शौचालय (Restroom / Toilet)',
        chapterNo: 7,
        chapterTitle: '여기가 사무실이에요 (स्थान र कार्यालय)',
        topic: 'दैनिक स्थान',
        visualIcon: '🚻',
        exampleSentence: '화장실이 어디에 있는지 가르쳐 주세요.',
      ),
      VisualFlashcard(
        id: 'vfc_c7_02',
        koreanWord: '기숙사',
        pronunciation: 'खिसुकसा',
        nepaliMeaning: 'होस्टेल / आवासगृह (Dormitory)',
        chapterNo: 7,
        chapterTitle: '여기가 사무실이에요 (स्थान र कार्यालय)',
        topic: 'दैनिक स्थान',
        visualIcon: '🏢',
        exampleSentence: '퇴근 후에는 공장 옆 기숙사에서 휴식을 취합니다.',
      ),

      // Chapter 11: 물건 사기 (किनमेल र गन्ती)
      VisualFlashcard(
        id: 'vfc_c11_01',
        koreanWord: '얼마예요?',
        pronunciation: 'अलमायेयो?',
        nepaliMeaning: 'कति मूल्य पर्छ? (How much is it?)',
        chapterNo: 11,
        chapterTitle: '사과 다섯 개 주세요 (किनमेल र गन्ती)',
        topic: 'किनमेल',
        visualIcon: '💰',
        exampleSentence: '이 신선한 사과 한 상자에 얼마예요?',
      ),
      VisualFlashcard(
        id: 'vfc_c11_02',
        koreanWord: '깎아 주세요',
        pronunciation: 'क्काक्का छुसेयो',
        nepaliMeaning: 'अलि छुट दिनुहोस् (Please give a discount)',
        chapterNo: 11,
        chapterTitle: '사과 다섯 개 주세요 (किनमेल र गन्ती)',
        topic: 'किनमेल',
        visualIcon: '🏷️',
        exampleSentence: '조금 비싸네요, 천 원만 깎아 주세요.',
      ),

      // Chapter 42: 기계 작동 (मेसिन सञ्चालन)
      VisualFlashcard(
        id: 'vfc_c42_01',
        koreanWord: '프레스 기계',
        pronunciation: 'फुरेस खिग्ये',
        nepaliMeaning: 'प्रेस मेसिन (Press Machine)',
        chapterNo: 42,
        chapterTitle: '이 기계 어떻게 작동해요? (मेसिन सञ्चालन)',
        topic: 'कारखाना औजार',
        visualIcon: '⚙️',
        exampleSentence: '프레스 기계를 작동할 때는 손가락이 끼이지 않게 두 손으로 버튼을 누르세요.',
      ),
      VisualFlashcard(
        id: 'vfc_c42_02',
        koreanWord: '비상 스위치',
        pronunciation: 'पिसाङ सुविछि',
        nepaliMeaning: 'आपतकालीन स्विच (Emergency Switch)',
        chapterNo: 42,
        chapterTitle: '이 기계 어떻게 작동해요? (मेसिन सञ्चालन)',
        topic: 'सुरक्षा सामग्री',
        visualIcon: '🛑',
        exampleSentence: '위험한 상황이 발생하면 즉시 빨간색 비상 스위치를 누르세요.',
      ),

      // Chapter 51: 고용허가제 (श्रम सम्झौता र कानुन)
      VisualFlashcard(
        id: 'vfc_c51_01',
        koreanWord: '표준근로계약서',
        pronunciation: 'फ्योजुन-कुन्रो-ख्येयाक्स',
        nepaliMeaning: 'आधिकारिक श्रम सम्झौता पत्र (Standard Labor Contract)',
        chapterNo: 51,
        chapterTitle: '한국에 가서 일을 하고 싶어요 (श्रम सम्झौता)',
        topic: 'श्रम कानुन',
        visualIcon: '📜',
        exampleSentence: '한국에 입국하기 전에 표준근로계약서의 근무 조건과 임금을 꼼꼼히 확인하세요.',
      ),
      VisualFlashcard(
        id: 'vfc_c51_02',
        koreanWord: '수습기간',
        pronunciation: 'सुसुपखिगान',
        nepaliMeaning: 'परीक्षण कार्य अवधि (Probation Period)',
        chapterNo: 51,
        chapterTitle: '한국에 가서 일을 하고 싶어요 (श्रम सम्झौता)',
        topic: 'श्रम कानुन',
        visualIcon: '⏳',
        exampleSentence: '수습기간은 보통 3개월 이내로 정해져 있습니다.',
      ),
    ];
  }

  // -------------------------------------------------------------
  // 4. NOTICES, GRAMMAR, VIDEOS
  // -------------------------------------------------------------
  List<InstituteNotice> getAllNotices() {
    _notices ??= _loadNoticesFromStorage() ?? _getDefaultNotices();
    return List.unmodifiable(_notices!);
  }

  void addNotice(InstituteNotice notice) {
    getAllNotices();
    _notices!.insert(0, notice);
    _saveNoticesToStorage();
  }

  void deleteNotice(String id) {
    getAllNotices();
    _notices!.removeWhere((n) => n.id == id);
    _saveNoticesToStorage();
  }

  List<InstituteNotice>? _loadNoticesFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyNotices);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => InstituteNotice.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveNoticesToStorage() {
    if (_notices == null) return;
    try {
      final list = _notices!.map((n) => n.toJson()).toList();
      StorageService.instance.setString(_keyNotices, jsonEncode(list));
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save notices: $e');
    }
  }

  List<InstituteNotice> _getDefaultNotices() {
    return <InstituteNotice>[];
  }

  List<GrammarTopic> getAllGrammar() {
    _grammarList ??= _loadGrammarFromStorage() ?? _getDefaultGrammar();
    return List.unmodifiable(_grammarList!);
  }

  void addGrammar(GrammarTopic topic) {
    getAllGrammar();
    _grammarList!.insert(0, topic);
    _saveGrammarToStorage();
  }

  void deleteGrammar(String id) {
    getAllGrammar();
    _grammarList!.removeWhere((g) => g.id == id);
    _saveGrammarToStorage();
  }

  List<GrammarTopic>? _loadGrammarFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyGrammar);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => GrammarTopic.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveGrammarToStorage() {
    if (_grammarList == null) return;
    try {
      final list = _grammarList!.map((g) => g.toJson()).toList();
      StorageService.instance.setString(_keyGrammar, jsonEncode(list));
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save grammar: $e');
    }
  }

  List<GrammarTopic> _getDefaultGrammar() {
    return <GrammarTopic>[];
  }

  List<VideoCourse> getAllVideos() {
    _videoList ??= _loadVideosFromStorage() ?? _getDefaultVideos();
    return List.unmodifiable(_videoList!);
  }

  void addVideo(VideoCourse video) {
    getAllVideos();
    _videoList!.insert(0, video);
    _saveVideosToStorage();
  }

  void deleteVideo(String id) {
    getAllVideos();
    _videoList!.removeWhere((v) => v.id == id);
    _saveVideosToStorage();
  }

  List<VideoCourse>? _loadVideosFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyVideos);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => VideoCourse.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveVideosToStorage() {
    if (_videoList == null) return;
    try {
      final list = _videoList!.map((v) => v.toJson()).toList();
      StorageService.instance.setString(_keyVideos, jsonEncode(list));
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save videos: $e');
    }
  }

  List<VideoCourse> _getDefaultVideos() {
    return <VideoCourse>[];
  }
}
