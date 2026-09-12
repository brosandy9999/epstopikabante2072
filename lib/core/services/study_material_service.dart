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

  /// Filters books based on user role and approval status
  List<StudyBook> getBooksForRole({required bool isSuperAdmin, required bool isAdmin, String? instituteCode}) {
    final all = getAllBooks();
    if (isSuperAdmin) {
      return all; // Super Admin sees all books including pending drafts
    }
    if (isAdmin) {
      // Institute Admin sees all approved/public books plus their own submitted books
      return all.where((b) {
        if (b.isApprovedBySuperAdmin && b.isPublished) return true;
        if (b.addedByRole == 'institute_admin' && instituteCode != null && b.addedByName.contains(instituteCode)) return true;
        return false;
      }).toList();
    }
    // Students only see officially approved and published books
    return all.where((b) => b.isApprovedBySuperAdmin && b.isPublished).toList();
  }

  void addBook(StudyBook book) {
    getAllBooks();
    _booksList!.removeWhere((b) => b.id == book.id);
    _booksList!.insert(0, book);
    _saveBooksToStorage();
  }

  void approveBook(String id) {
    getAllBooks();
    final idx = _booksList!.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _booksList![idx] = _booksList![idx].copyWith(
        isApprovedBySuperAdmin: true,
        isPublished: true,
      );
      _saveBooksToStorage();
    }
  }

  void rejectBook(String id) {
    getAllBooks();
    final idx = _booksList!.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _booksList![idx] = _booksList![idx].copyWith(
        isApprovedBySuperAdmin: false,
        isPublished: false,
      );
      _saveBooksToStorage();
    }
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
      final loaded = decoded.map((e) => StudyBook.fromJson(Map<String, dynamic>.from(e))).toList();
      if (loaded.isEmpty) return null;
      return loaded;
    } catch (_) {
      return null;
    }
  }

  void mergeBooksFromCloud(List<StudyBook> remoteBooks) {
    if (remoteBooks.isEmpty) return;
    getAllBooks();
    bool hasChanges = false;
    for (final rBook in remoteBooks) {
      final idx = _booksList!.indexWhere((b) => b.id == rBook.id);
      if (idx == -1) {
        _booksList!.add(rBook);
        hasChanges = true;
      } else {
        _booksList![idx] = rBook;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveBooksToStorage(triggerCloudPush: false);
      notifyListeners();
    }
  }

  void _saveBooksToStorage({bool triggerCloudPush = true}) {
    if (_booksList == null) return;
    try {
      final list = _booksList!.map((b) => b.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyBooks, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyBooks}_backup', encoded);
      }
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save books: $e');
    }
  }

  List<StudyBook> _getDefaultBooks() {
    // Map Book 1 chapters (1-30)
    final Map<String, String> book1Pdfs = {};
    for (int i = 1; i <= 30; i++) {
      final pad = i.toString().padLeft(2, '0');
      book1Pdfs['$i'] = 'chapters/Book-1_Chapter-${pad}_Lesson-${pad}.html';
    }

    // Map Book 2 chapters (31-60)
    final Map<String, String> book2Pdfs = {};
    for (int i = 31; i <= 60; i++) {
      final pad = i.toString().padLeft(2, '0');
      book2Pdfs['$i'] = 'chapters/Book-2_Chapter-${pad}_Lesson-${pad}.html';
    }

    return <StudyBook>[
      StudyBook(
        id: 'book_new_01',
        title: 'EPS-TOPIK कोरियन भाषा पाठ्यपुस्तक १ (2024 नयाँ संस्करण)',
        subtitle: 'आधारभूत कोरियन भाषा तथा दैनिक जीवनयापन (अध्याय ०१ देखि ३०)',
        editionType: 'नयाँ संस्करण (New 2024)',
        level: 'Book 1',
        chaptersCount: 30,
        description: 'वर्णमाला (हन्गुल), अभिवादन, किनमेल, दिशा, मिति/समय, मौसम, परिवार, खाना र दैनिक कार्यस्थल संवादहरू समेटिएको आधिकारिक स्मार्ट इन्टरएक्टिभ अडियो बुक।',
        pdfUrl: 'chapters/Book-1_Chapter-01_Lesson-01.html',
        chapterPdfs: book1Pdfs,
        chapterTitles: const {
          '1': '안녕하세요 (नमस्कार)',
          '2': '여기가 사무실이에요 (यहाँ कार्यालय हो)',
          '3': '한국어 표준교재 (कोरियन भाषा पाठ्यपुस्तक)',
          '4': '한글 익히기 I (हन्गुल सिकाइ १)',
          '5': '한글 익히기 II (हन्गुल सिकाइ २)',
          '6': '저는 투안입니다 (म थुवान हुँ)',
          '7': '여기가 사무실이에요 (यो कार्यालय हो)',
          '8': '12시 30분에 점심을 먹어요 (१२:३० मा खाना खान्छु)',
          '9': '가족이 몇 명이에요? (परिवारमा कति जना हुनुहुन्छ?)',
          '10': '어제 도서관에서 한국어를 공부했어요 (हिजो पुस्तकालयमा भाषा पढें)',
          '11': '사과 다섯 개 주세요 (स्याउ पाँचवटा दिनुहोस्)',
          '12': '병원 옆에 약국이 있어요 (अस्पताल छेउमा फार्मेसी छ)',
          '13': '시청 앞에서 7시에 만나요 (नगरपालिका अगाडि भेटौं)',
          '14': '저는 비빔밥을 먹을래요 (म बिबिमबाप खान्छु)',
          '15': '날씨가 맑아서 기분이 좋아요 (मौसम सफा भएर खुसी लाग्यो)',
          '16': '시간이 있을 때 주로 운동을 해요 (फुर्सदमा व्यायाम गर्छु)',
          '17': '휴가 때 제주도에 다녀올 거예요 (बिदामा जेजुदो जान्छु)',
          '18': '버스나 지하철을 타고 가요 (बस वा सबवे चढेर जानुहोस्)',
          '19': '거기 한국가구지요? (त्यहाँ कोरियन फर्निचर हो?)',
          '20': '저는 설거지를 할게요 (म भाँडा माझ्नेछु)',
          '21': '상 차리는 것을 도와줄까요? (टेबल मिलाउन मद्दत गरूँ?)',
          '22': '무단횡단을 하면 안 돼요 (जथाभावी बाटो काट्नु हुँदैन)',
          '23': '어르신께는 두 손으로 물건을 드려야 해요 (दुई हातले दिनुहोस्)',
          '24': '한국 영화를 보면서 공부해요 (चलचित्र हेर्दै अध्ययन गर्छु)',
          '25': '일요일마다 교회에 가요 (हरेक आइतबार चर्च जान्छु)',
          '26': '밥을 먹은 후에 이 약을 드세요 (खाना खाएपछि औषधि खानुहोस्)',
          '27': '어디가 아프십니까? (कहाँ दुख्यो?)',
          '28': '통장을 만들려고 왔어요 (बैंक खाता खोल्न आएको)',
          '29': '필리핀으로 엽서를 보내고 싶은데요 (पोस्टकार्ड पठाउन चाहन्छु)',
          '30': '거기서 한국어 교육을 받을 수 있어요? (तालिम लिन सकिन्छ?)',
        },
        highlightTopics: const [
          '제1과~5과: 한글 익히기 (वर्णमाला र उच्चारण)',
          '제6과~10과: 자기소개 및 일상생활 (आत्मपरिचय र दिनचर्या)',
          '제11과~15과: 물건 사기 एवं मौसम (किनमेल र मौसम)',
          '제16과~20과: 취미 및 교통 (रुचि र यातायात)',
          '제21과~30과: 약속, 전화 एवं 병원 (भेटघाट र स्वास्थ्य)',
        ],
        isApprovedBySuperAdmin: true,
        isPublished: true,
        addedByRole: 'super_admin',
        addedByName: 'Super Admin Master',
        interactiveType: 'studio_html',
        createdAt: DateTime(2024, 1, 1),
      ),
      StudyBook(
        id: 'book_new_02',
        title: 'EPS-TOPIK कोरियन भाषा पाठ्यपुस्तक २ (2024 नयाँ संस्करण)',
        subtitle: 'कार्यस्थल भाषा, सुरक्षा, श्रम कानुन तथा संस्कृति (अध्याय ३१ देखि ६०)',
        editionType: 'नयाँ संस्करण (New 2024)',
        level: 'Book 2',
        chaptersCount: 30,
        description: 'कारखाना औजार, कार्यस्थल सुरक्षा, औद्योगिक दुर्घटना रोकथाम, कृषि र निर्माण शब्दावली, कोरियाली संस्कृति, श्रम सम्झौता, तलब र बिमा सम्बन्धी आधिकारिक स्मार्ट इन्टरएक्टिभ अडियो बुक।',
        pdfUrl: 'chapters/Book-2_Chapter-31_Lesson-31.html',
        chapterPdfs: book2Pdfs,
        chapterTitles: const {
          '31': '우리 고향은 서울보다 공기가 맑아요 (हाम्रो गाउँको हावा सफा छ)',
          '32': '복날에는 삼계탕을 먹어요 (बोकनालमा सामग्येथाङ खाइन्छ)',
          '33': '송편을 만드는 체험도 할 수 있어요 (सोङफ्योन बनाउन सकिन्छ)',
          '34': '아기 옷을 선물하는 게 어때요? (बच्चाको कपडा उपहार दिने कि?)',
          '35': '한국 드라마가 재미있잖아요 (कोरियन नाटक रमाइलो हुन्छ)',
          '36': '단정한 모습이 좋아 보여요 (सफा चिटिक्क देखिनु राम्रो)',
          '37': '출입문을 꼭 닫읍시다 (ढोका अनिवार्य रूपमा बन्द गरौं)',
          '38': '일할 맛이 나요 (काम गर्ने जाँगर चल्छ)',
          '39': '오늘 회식을 하자고 해요 (आज कम्पनी डिनर गर्ने भन्छन्)',
          '40': '불쾌감을 느꼈다면 그건 성희롱이에요 (यौन दुर्व्यवहार)',
          '41': '드라이버로 해 보세요 (स्क्रू ड्राइभरले गरेर हेर्नुहोस्)',
          '42': '이 기계 어떻게 작동하는지 알아요? (मेसिन सञ्चालन विधि)',
          '43': '철근을 옮겨 놓으세요 (रड सारेर राख्नुहोस्)',
          '44': '페인트 작업을 했거든요 (पेन्टिङको काम गरें)',
          '45': '호미를 챙겼는데요 (कोदालो तयार पारें)',
          '46': '더 신경 쓰도록 하자 (थप ध्यान दिऊँ)',
          '47': '재고를 파악하는 것이 중요해요 (स्टक जाँच महत्त्वपूर्ण)',
          '48': '다치지 않게 조심하세요 (सुरक्षा सतर्कता)',
          '49': '안전화를 안 신으면 다칠 수 있어요 (सुरक्षा जुत्ता लगाउनुहोस्)',
          '50': '열심히 해 준 덕분이에요 (मिहिनेतको प्रतिफल)',
          '51': '한국에 가서 일을 하고 싶어요 (कोरिया गएर काम गर्न चाहन्छु)',
          '52': '근로 조건이 좋은 편이에요 (राम्रो श्रम सर्तहरू)',
          '53': '외국인 등록을 하러 가요 (विदेशी दर्ता गर्न जाँदैछु)',
          '54': '보험금을 신청하려고 해요 (बिमा रकम दाबी गर्न चाहन्छु)',
          '55': '급여 명세서를 확인해 보세요 (तलब विवरण पत्र हेर्नुहोस्)',
          '56': '이번 여름휴가 계획은 세웠어? (गर्मी बिदाको योजना)',
          '57': '사업장을 변경하고 싶은데 (कम्पनी परिवर्तन गर्न चाहन्छु)',
          '58': '체류 기간을 연장해야 해요 (भिसा अवधि थप गर्नुपर्छ)',
          '59': '산업 안전 교육을 받았어요 (औद्योगिक सुरक्षा तालिम)',
          '60': '귀국 준비는 잘 되고 있어요? (स्वदेश फिर्ताको तयारी)',
        },
        highlightTopics: const [
          '제31과~40과: 한국 문화 एवं 직장 예절 (संस्कृति र कार्यस्थल मर्यादा)',
          '제41과~50과: 제조업 도구 एवं 안전 수칙 (उत्पादन औजार र सुरक्षा)',
          '제51과~55과: 고용허가제 एवं 근로계약 (श्रम कानुन र सम्झौता)',
          '제56과~60과: 휴가, 체류 연장 एवं 귀국 (बिदा, भिसा थप र स्वदेश फिर्ता)',
        ],
        isApprovedBySuperAdmin: true,
        isPublished: true,
        addedByRole: 'super_admin',
        addedByName: 'Super Admin Master',
        interactiveType: 'studio_html',
        createdAt: DateTime(2024, 1, 1),
      ),
    ];
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

  void mergeDictionaryFromCloud(List<DictionaryWord> remoteWords) {
    if (remoteWords.isEmpty) return;
    getAllDictionaryWords();
    bool hasChanges = false;
    for (final rWord in remoteWords) {
      final idx = _dictionaryList!.indexWhere((w) => w.id == rWord.id);
      if (idx == -1) {
        _dictionaryList!.add(rWord);
        hasChanges = true;
      } else {
        _dictionaryList![idx] = rWord;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveDictionaryToStorage(triggerCloudPush: false);
      notifyListeners();
    }
  }

  void _saveDictionaryToStorage({bool triggerCloudPush = true}) {
    if (_dictionaryList == null) return;
    try {
      final list = _dictionaryList!.map((w) => w.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyDict, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyDict}_backup', encoded);
      }
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
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

  void mergeFlashcardsFromCloud(List<VisualFlashcard> remoteCards) {
    if (remoteCards.isEmpty) return;
    getAllVisualFlashcards();
    bool hasChanges = false;
    for (final rCard in remoteCards) {
      final idx = _visualCardsList!.indexWhere((c) => c.id == rCard.id);
      if (idx == -1) {
        _visualCardsList!.add(rCard);
        hasChanges = true;
      } else {
        _visualCardsList![idx] = rCard;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveVisualCardsToStorage(triggerCloudPush: false);
      notifyListeners();
    }
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

  void _saveVisualCardsToStorage({bool triggerCloudPush = true}) {
    if (_visualCardsList == null) return;
    try {
      final list = _visualCardsList!.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(list);
      StorageService.instance.setString(_keyVisualCards, encoded);
      if (encoded.length < 500000) {
        StorageService.instance.setString('${_keyVisualCards}_backup', encoded);
      }
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
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

  void mergeNoticesFromCloud(List<InstituteNotice> remoteNotices) {
    if (remoteNotices.isEmpty) return;
    getAllNotices();
    bool hasChanges = false;
    for (final rNotice in remoteNotices) {
      final idx = _notices!.indexWhere((n) => n.id == rNotice.id);
      if (idx == -1) {
        _notices!.add(rNotice);
        hasChanges = true;
      } else {
        _notices![idx] = rNotice;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveNoticesToStorage(triggerCloudPush: false);
      notifyListeners();
    }
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

  void _saveNoticesToStorage({bool triggerCloudPush = true}) {
    if (_notices == null) return;
    try {
      final list = _notices!.map((n) => n.toJson()).toList();
      StorageService.instance.setString(_keyNotices, jsonEncode(list));
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
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

  void mergeGrammarFromCloud(List<GrammarTopic> remoteGrammar) {
    if (remoteGrammar.isEmpty) return;
    getAllGrammar();
    bool hasChanges = false;
    for (final rG in remoteGrammar) {
      final idx = _grammarList!.indexWhere((g) => g.id == rG.id);
      if (idx == -1) {
        _grammarList!.add(rG);
        hasChanges = true;
      } else {
        _grammarList![idx] = rG;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveGrammarToStorage(triggerCloudPush: false);
      notifyListeners();
    }
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

  void _saveGrammarToStorage({bool triggerCloudPush = true}) {
    if (_grammarList == null) return;
    try {
      final list = _grammarList!.map((g) => g.toJson()).toList();
      StorageService.instance.setString(_keyGrammar, jsonEncode(list));
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
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

  void mergeVideosFromCloud(List<VideoCourse> remoteVideos) {
    if (remoteVideos.isEmpty) return;
    getAllVideos();
    bool hasChanges = false;
    for (final rV in remoteVideos) {
      final idx = _videoList!.indexWhere((v) => v.id == rV.id);
      if (idx == -1) {
        _videoList!.add(rV);
        hasChanges = true;
      } else {
        _videoList![idx] = rV;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveVideosToStorage(triggerCloudPush: false);
      notifyListeners();
    }
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

  void _saveVideosToStorage({bool triggerCloudPush = true}) {
    if (_videoList == null) return;
    try {
      final list = _videoList!.map((v) => v.toJson()).toList();
      StorageService.instance.setString(_keyVideos, jsonEncode(list));
      if (triggerCloudPush) {
        CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[StudyMaterialService] Failed to save videos: $e');
    }
  }

  List<VideoCourse> _getDefaultVideos() {
    return <VideoCourse>[];
  }
}
