import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/offline_download_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import 'book_reader_screen.dart';
import 'fullscreen_flashcard_screen.dart';
import 'video_course_player_screen.dart';

/// Central Student Resources Screen (रिसोर्स सेक्सन)
/// Features Unlimited Books, Korean-Nepali Dictionary, Visual Swipeable Flashcards with Audio & Chapters,
/// Grammar, Video Courses, and Notices.
class StudentStudyHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const StudentStudyHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StudentStudyHubScreen> createState() => _StudentStudyHubScreenState();
}

class _StudentStudyHubScreenState extends State<StudentStudyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Book filters
  String _selectedBookEdition = 'all';

  // Dictionary search and filters
  String _dictSearch = '';
  String _selectedPartOfSpeech = 'all';

  // Chapter titles map for EPS-TOPIK
  static final Map<int, String> _chapterTitleMap = {
    1: '제1과: 한글 익히기 (वर्णमाला र अभिवादन)',
    2: '제2과: 교실 한국어 (कक्षाकोठा अभिव्यक्ति)',
    3: '제3과: 한국어 기본 대화 (आधारभूत संवाद)',
    4: '제4과: 자기소개 (आत्मपरिचय र देश)',
    5: '제5과: 일상생활 (दैनिक दिनचर्या)',
    6: '제6과: 저는 투안입니다 (पेशा र राष्ट्रियता)',
    7: '제7과: 여기가 사무실이에요 (स्थान र कार्यालय)',
    8: '제8과: 12시 30분에 밥을 먹어요 (समय र तालिका)',
    9: '제9과: 가족이 몇 명이에요? (परिवार र उमेर)',
    10: '제10과: 어제 도서관에서 한국어를 공부했어요 (विगत काल)',
    11: '제11과: 사과 다섯 개 주세요 (किनमेल र गन्ती)',
    12: '제12과: 병원 옆에 약국이 있어요 (दिशा र स्थान)',
    13: '제13과: 시청 앞에서 7시에 만나요 (भेटघाटको समय)',
    14: '제14과: 저는 비빔밥을 먹을래요 (खाना र अर्डर)',
    15: '제15과: 날씨가 맑아서 기분이 좋아요 (मौसम र भावना)',
    16: '제16과: 시간이 있을 때 주로 운동해요 (रुचि र फुर्सद)',
    17: '제17과: 휴가 때 제주도에 다녀올 거예요 (भ्रमण र योजना)',
    18: '제18과: 버스나 지하철을 타고 가요 (यातायात साधन)',
    19: '제19과: 거기 한국가구지요? (टेलिफोन संवाद)',
    20: '제20과: 저는 설거지를 할게요 (घरायसी सरसफाइ)',
    41: '제41과: 뻰치로 철사를 끊으세요 (हातहतियार)',
    42: '제42과: 이 기계 어떻게 작동해요? (मेसिन सञ्चालन)',
    43: '제43과: 철근을 옮겨 놓으세요 (निर्माण तथा ढुवानी)',
    45: '제45과: 호미를 챙겼어요? (कृषि तथा पशुपालन)',
    48: '제48과: 다치지 않게 조심하세요 (सुरक्षा सुत्र)',
    51: '제51과: 한국에 가서 일을 하고 싶어요 (श्रम सम्झौता)',
  };

  String _getChapterName(int chap) {
    if (chap == 0) return '📚 ' + LanguageService.instance.tr('all_chapters');
    return _chapterTitleMap[chap] ?? LanguageService.instance.trText(
      ne: '제${chap}과: 표준교재 단어장 (अध्याय $chap)',
      en: 'Chap ${chap}: Standard Vocab',
      ko: '제${chap}과: 표준교재 단어장',
    );
  }

  // Visual Flashcard state
  int _selectedFlashcardChapter = 0; // 0 = all chapters
  String _selectedFlashcardTopic = 'all';
  int _currentFlashcardIndex = 0;
  bool _autoPlayTts = true;
  final Set<String> _flippedFlashcardIds = {};
  late PageController _flashcardPageController;

  // Grammar search
  String _grammarSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
    _flashcardPageController = PageController();

    // पृष्ठभूमिमा स्वतः सिङ्क गर्ने (Silent background sync on open without manual buttons)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CloudSyncService.instance.pullFromCloud().catchError((_) => false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flashcardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.folder_special, size: 24),
            const SizedBox(width: 10),
            Text(
              LanguageService.instance.tr('resources_hub'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
                    const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 3.5,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.menu_book, size: 18), text: LanguageService.instance.tr('books')),
            Tab(icon: const Icon(Icons.auto_stories, size: 18), text: LanguageService.instance.tr('dictionary')),
            Tab(icon: const Icon(Icons.style, size: 18), text: LanguageService.instance.tr('flashcards')),
            Tab(icon: const Icon(Icons.translate, size: 18), text: LanguageService.instance.tr('grammar')),
            Tab(icon: const Icon(Icons.play_circle_filled, size: 18), text: LanguageService.instance.tr('videos')),
            Tab(icon: const Icon(Icons.campaign, size: 18), text: LanguageService.instance.tr('notices')),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([LanguageService.instance, StudyMaterialService.instance]),
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: _buildBooksTab())),
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: _buildDictionaryTab())),
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _buildVisualFlashcardsTab())),
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: _buildGrammarTab())),
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: _buildVideoCourseTab())),
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: _buildNoticesTab())),
            ],
          );
        },
      ),
    ),
  );
}

  // -------------------------------------------------------------
  // TAB 1: UNLIMITED BOOKS (नयाँ तथा पुराना असीमित किताबहरू)
  // -------------------------------------------------------------
  Widget _buildBooksTab() {
    final allBooks = StudyMaterialService.instance.getAllBooks();
    final lang = LanguageService.instance;
    final editions = [
      {'key': 'all', 'label': lang.tr('all')},
      {'key': 'नयाँ', 'label': lang.tr('new_edition')},
      {'key': 'पुरानो', 'label': lang.tr('old_edition')},
      {'key': 'विशेष', 'label': lang.tr('special_guide')},
    ];

    final filtered = allBooks.where((b) {
      if (_selectedBookEdition == 'all') return true;
      return b.editionType.contains(_selectedBookEdition);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: editions.map((ed) {
                final isSel = _selectedBookEdition == ed['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ed['label']!, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E3A8A),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) => setState(() => _selectedBookEdition = ed['key']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(LanguageService.instance.trText(ne: 'कुनै किताब भेटिएन।', en: 'No books found.', ko: '교재를 찾을 수 없습니다.'), style: const TextStyle(color: Colors.black54)))
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final bool isWide = constraints.maxWidth > 700;
                    if (!isWide) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) => _buildBookCard(filtered[i]),
                      );
                    }
                    final double cardWidth = (constraints.maxWidth - 48) / 2;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: filtered.map((b) => SizedBox(width: cardWidth, child: _buildBookCard(b))).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }


  Widget _buildBookCard(StudyBook b) {
    final isNew = b.editionType.contains('नयाँ');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isNew ? const Color(0xFF1E3A8A) : const Color(0xFFB45309),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isNew ? Colors.blue.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isNew ? Colors.blue : Colors.amber.shade700),
                            ),
                            child: Text(
                              b.localizedEditionType(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNew ? Colors.blue.shade900 : Colors.amber.shade900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(LanguageService.instance.trText(ne: '${b.chaptersCount} वटा अध्याय', en: '${b.chaptersCount} Chapters', ko: '${b.chaptersCount}개 과'), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.localizedTitle(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(b.localizedSubtitle(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(b.localizedDescription(), style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('📌 ' + LanguageService.instance.tr('highlights') + ':', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 6),
            ...b.localizedHighlights().map((topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(topic, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final isFullDownloaded = OfflineDownloadService.instance.isBookDownloaded(b.id);
                final downloadedCount = OfflineDownloadService.instance.getDownloadedChaptersCount(b.id);

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BookReaderScreen(book: b)),
                          );
                        },
                        icon: const Icon(Icons.chrome_reader_mode, size: 18),
                        label: Text(LanguageService.instance.trText(ne: 'अडियोसहित पुस्तक खोल्नुहोस्', en: 'Open Book with Audio', ko: '오디오 포함 교재 열기')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: (isFullDownloaded || downloadedCount > 0) ? Colors.teal.shade50 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (isFullDownloaded || downloadedCount > 0) ? Colors.teal.shade300 : Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: Icon(
                          (isFullDownloaded || downloadedCount > 0) ? Icons.offline_pin : Icons.download_for_offline_outlined,
                          color: (isFullDownloaded || downloadedCount > 0) ? Colors.green.shade700 : const Color(0xFF0F766E),
                          size: 22,
                        ),
                        tooltip: LanguageService.instance.trText(
                          ne: (isFullDownloaded || downloadedCount > 0)
                              ? 'अध्यायगत अफलाइन डाउनलोड (${isFullDownloaded ? "सबै" : "$downloadedCount"} सुरक्षित)'
                              : 'च्याप्टर अनुसार अफलाइन डाउनलोड सूची खोल्नुहोस्',
                          en: 'Chapter offline download list',
                          ko: '단원별 오프라인 다운로드 목록',
                        ),
                        onPressed: () => _showBookChaptersDownloadModal(b),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookChaptersDownloadModal(StudyBook b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: Color(0xFF1E3A8A), size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${b.title} - ${LanguageService.instance.trText(ne: 'अध्यायगत अफलाइन डाउनलोड', en: 'Chapter Offline Downloads', ko: '단원별 오프라인 저장')}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(
                LanguageService.instance.trText(
                  ne: 'आफूलाई पढ्न मन लागेको च्याप्टरको साइडमा रहेको ⬇️ डाउनलोड बटन थिचेर अफलाइन सेभ गर्नुहोस्:',
                  en: 'Tap ⬇️ download button next to any chapter to save it for offline study:',
                  ko: '오프라인 학습을 원하는 단원 옆의 ⬇️ 다운로드 버튼을 누르세요:',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: b.chaptersCount,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ch = i + 1;
                    final isDownloaded = OfflineDownloadService.instance.isChapterDownloaded(b.id, ch);
                    final tracksCount = b.audioTracks.where((t) => t.chapterNo == ch).length;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isDownloaded ? Colors.teal.shade50 : Colors.grey.shade200,
                        child: Text('$ch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDownloaded ? Colors.teal.shade900 : Colors.black87)),
                      ),
                      title: Text(
                        LanguageService.instance.trText(ne: 'अध्याय $ch', en: 'Chapter $ch', ko: '제$ch과'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        LanguageService.instance.trText(
                          ne: '$tracksCount वटा अडियो ट्र्याक • ${isDownloaded ? "✅ अफलाइन सुरक्षित" : "अनलाइन"}',
                          en: '$tracksCount Audio tracks • ${isDownloaded ? "✅ Offline Saved" : "Online"}',
                          ko: '$tracksCount개 오디오 • ${isDownloaded ? "✅ 오프라인 저장됨" : "온라인"}',
                        ),
                        style: TextStyle(fontSize: 11, color: isDownloaded ? Colors.teal.shade700 : Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined,
                              color: isDownloaded ? Colors.green.shade700 : const Color(0xFF0F766E),
                              size: 22,
                            ),
                            tooltip: isDownloaded
                                ? LanguageService.instance.trText(ne: 'अध्याय $ch अफलाइन सुरक्षित छ (हटाउन ट्याप गर्नुहोस्)', en: 'Chapter $ch saved offline (Tap to remove)', ko: '제$ch과 오프라인 저장됨')
                                : LanguageService.instance.trText(ne: 'अध्याय $ch अफलाइन डाउनलोड गर्नुहोस्', en: 'Download Chapter $ch offline', ko: '제$ch과 오프라인 다운로드'),
                            onPressed: () async {
                              await OfflineDownloadService.instance.toggleChapterDownload(b.id, ch);
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E3A8A)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BookReaderScreen(book: b, initialChapter: ch)),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: DICTIONARY (कोरियन-नेपाली स्मार्ट डिक्सनरी)
  // -------------------------------------------------------------
  Widget _buildDictionaryTab() {
    final allWords = StudyMaterialService.instance.getAllDictionaryWords();
    final lang = LanguageService.instance;
    final parts = [
      {'key': 'all', 'label': lang.tr('all')},
      {'key': 'संज्ञा', 'label': lang.tr('noun')},
      {'key': 'क्रिया', 'label': lang.tr('verb')},
      {'key': 'विशेषण', 'label': lang.tr('adjective')},
    ];

    final filtered = allWords.where((w) {
      if (_selectedPartOfSpeech != 'all') {
        if (!w.partOfSpeech.contains(_selectedPartOfSpeech)) return false;
      }
      if (_dictSearch.isEmpty) return true;
      final q = _dictSearch.toLowerCase();
      return w.koreanWord.toLowerCase().contains(q) ||
          w.pronunciation.toLowerCase().contains(q) ||
          w.nepaliMeaning.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: LanguageService.instance.isEnglish
                      ? 'Search words (e.g. helmet, hammer, welding)...'
                      : (LanguageService.instance.isKorean
                          ? '단어 검색 (예: 안전모, 망치, 용접)...'
                          : 'शब्द खोज्नुहोस् (जस्तै: 안전모, हथौडा, 용접)...'),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                  suffixIcon: _dictSearch.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dictSearch = ''))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _dictSearch = val),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: parts.map((p) {
                    final isSel = _selectedPartOfSpeech == p['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p['label']!, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) => setState(() => _selectedPartOfSpeech = p['key']!),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(LanguageService.instance.trText(ne: 'डिक्सनरीमा कुनै शब्द भेटिएन।', en: 'No words found in dictionary.', ko: '사전에서 단어를 찾을 수 없습니다.'), style: const TextStyle(color: Colors.black54)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final w = filtered[i];

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      w.koreanWord,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '[ ${w.pronunciation} ]',
                                      style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.volume_up, color: Color(0xFF1E3A8A), size: 22),
                                      tooltip: LanguageService.instance.tr('tts_listen'),
                                      onPressed: () => KoreanTtsService.instance.speakKorean(w.koreanWord),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(LanguageService.instance.trText(ne: 'अध्याय ${w.chapterNo} • ${w.partOfSpeech.split(" ")[0]}', en: 'Chap ${w.chapterNo} • ${w.partOfSpeech.split(" ")[0]}', ko: '제${w.chapterNo}과 • ${w.partOfSpeech.split(" ")[0]}'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              w.nepaliMeaning,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🇰🇷 ${w.exampleKorean}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 2),
                                  Text('🇳🇵 ${w.exampleNepali}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: VISUAL SWIPEABLE FLASHCARDS (चित्र, अडियो र स्वाइप सहित)
  // -------------------------------------------------------------
  Widget _buildVisualFlashcardsTab() {
    final allCards = StudyMaterialService.instance.getAllVisualFlashcards();
    final lang = LanguageService.instance;
    final topics = [
      {'key': 'all', 'label': lang.tr('all')},
      {'key': 'कारखाना औजार', 'label': lang.isEnglish ? 'Factory Tools' : (lang.isKorean ? '공장 도구' : 'कारखाना औजार')},
      {'key': 'सुरक्षा सामग्री', 'label': lang.isEnglish ? 'Safety Equipment' : (lang.isKorean ? '안전 장비' : 'सुरक्षा सामग्री')},
      {'key': 'कृषि तथा पशुपालन', 'label': lang.isEnglish ? 'Agriculture & Livestock' : (lang.isKorean ? '농축산업' : 'कृषि तथा पशुपालन')},
      {'key': 'निर्माण तथा ढुवानी', 'label': lang.isEnglish ? 'Construction & Transport' : (lang.isKorean ? '건설 및 운송' : 'निर्माण तथा ढुवानी')},
    ];

    final filtered = allCards.where((c) {
      if (_selectedFlashcardChapter > 0 && c.chapterNo != _selectedFlashcardChapter) return false;
      if (_selectedFlashcardTopic != 'all' && !c.topic.contains(_selectedFlashcardTopic)) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar: Chapter & Topic selectors
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(LanguageService.instance.tr('chapter') + ':', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _selectedFlashcardChapter,
                        isDense: true,
                        items: [
                          DropdownMenuItem(value: 0, child: Text('📚 ' + LanguageService.instance.tr('all_chapters'))),
                          ...List.generate(60, (index) {
                            final ch = index + 1;
                            final cardCount = allCards.where((c) => c.chapterNo == ch).length;
                            final countBadge = cardCount > 0 ? ' ($cardCount वटा)' : '';
                            return DropdownMenuItem(
                              value: ch,
                              child: Text('${_getChapterName(ch)}$countBadge'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedFlashcardChapter = val ?? 0;
                            _currentFlashcardIndex = 0;
                            if (_flashcardPageController.hasClients) {
                              _flashcardPageController.jumpToPage(0);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.volume_up, size: 18, color: _autoPlayTts ? const Color(0xFF1E3A8A) : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        LanguageService.instance.trText(ne: 'अटो TTS:', en: 'Auto TTS:', ko: '자동 발음:'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _autoPlayTts ? const Color(0xFF1E3A8A) : Colors.grey),
                      ),
                      Switch(
                        value: _autoPlayTts,
                        activeColor: const Color(0xFF1E3A8A),
                        onChanged: (val) {
                          setState(() => _autoPlayTts = val);
                          if (val && filtered.isNotEmpty && _currentFlashcardIndex < filtered.length) {
                            KoreanTtsService.instance.speakKorean(filtered[_currentFlashcardIndex].koreanWord);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: topics.map((t) {
                    final isSel = _selectedFlashcardTopic == t['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t['label']!, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) {
                          setState(() {
                            _selectedFlashcardTopic = t['key']!;
                            _currentFlashcardIndex = 0;
                            if (_flashcardPageController.hasClients) {
                              _flashcardPageController.jumpToPage(0);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Flashcard Swipeable Deck
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(LanguageService.instance.trText(ne: 'कुनै फ्ल्यासकार्ड भेटिएन।', en: 'No flashcards found.', ko: '단어장을 찾을 수 없습니다.'), style: const TextStyle(color: Colors.black54)))
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    // Progress, Counter & Fullscreen Mode Action
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'कार्ड ${_currentFlashcardIndex + 1} / ${filtered.length}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'कण्ठ: ${filtered.where((c) => c.isMastered).length}/${filtered.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),

                          // PROMINENT FULLSCREEN MODE BUTTON
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenFlashcardScreen(
                                    flashcards: filtered,
                                    initialIndex: _currentFlashcardIndex,
                                    chapterTitle: _getChapterName(_selectedFlashcardChapter),
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            icon: const Icon(Icons.fullscreen, size: 18),
                            label: Text(
                              LanguageService.instance.trText(
                                ne: '🚀 फुल स्क्रिन मोड',
                                en: '🚀 Full Screen Mode',
                                ko: '🚀 전체화면 모드',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Swipeable PageView
                    Expanded(
                      child: PageView.builder(
                        controller: _flashcardPageController,
                        itemCount: filtered.length,
                        onPageChanged: (i) {
                          setState(() => _currentFlashcardIndex = i);
                          if (_autoPlayTts && i < filtered.length) {
                            KoreanTtsService.instance.speakKorean(filtered[i].koreanWord);
                          }
                        },
                        itemBuilder: (context, i) {
                          final card = filtered[i];
                          final isFlipped = _flippedFlashcardIds.contains(card.id);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: InteractiveViewer(
                              minScale: 0.85,
                              maxScale: 3.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isFlipped ? const Color(0xFFF0FDF4) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: card.isMastered ? Colors.green : (isFlipped ? const Color(0xFF15803D) : const Color(0xFF1E3A8A).withOpacity(0.4)),
                                  width: 2.2,
                                ),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setState(() {
                                    if (isFlipped) {
                                      _flippedFlashcardIds.remove(card.id);
                                    } else {
                                      _flippedFlashcardIds.add(card.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Header tags & Fullscreen Icon Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                            child: Text('제${card.chapterNo}과 • ${card.topic}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isFlipped ? '🇳🇵 पछाडिको भाग (अर्थ)' : '🇰🇷 अगाडिको भाग (शब्द)',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isFlipped ? Colors.green.shade800 : const Color(0xFF1E3A8A)),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.fullscreen, color: Color(0xFF1E3A8A), size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: LanguageService.instance.trText(ne: 'फुल स्क्रिन', en: 'Full Screen', ko: '전체화면'),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => FullscreenFlashcardScreen(
                                                        flashcards: filtered,
                                                        initialIndex: i,
                                                        chapterTitle: _getChapterName(_selectedFlashcardChapter),
                                                      ),
                                                    ),
                                                  ).then((_) => setState(() {}));
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Center: Image & Word
                                      if (!isFlipped) ...[
                                        // Big Visual Illustration from textbook
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2), width: 2),
                                          ),
                                          alignment: Alignment.center,
                                          child: (card.visualIcon.startsWith('data:image') || card.visualIcon.startsWith('http'))
                                              ? ClipOval(child: SmartImageWidget(imageSource: card.visualIcon, width: 90, height: 90, fit: BoxFit.cover))
                                              : Text(
                                                  card.visualIcon,
                                                  style: const TextStyle(fontSize: 52),
                                                ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              card.koreanWord,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0F172A), letterSpacing: 1.5),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '[ ${card.pronunciation} ]',
                                              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            // 1. Korean Native Pronunciation Button
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E3A8A),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                              onPressed: () => KoreanTtsService.instance.speakKorean(card.koreanWord),
                                              icon: const Icon(Icons.volume_up, size: 18),
                                              label: Text(
                                                LanguageService.instance.trText(
                                                  ne: '🔊 उच्चारण सुन्नुहोस्',
                                                  en: '🔊 Listen',
                                                  ko: '🔊 발음 듣기',
                                                ),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            // 2. Slow Speed Pronunciation
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF1E3A8A),
                                                side: const BorderSide(color: Color(0xFF1E3A8A)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                              onPressed: () => KoreanTtsService.instance.speakKorean(card.koreanWord),
                                              icon: const Icon(Icons.speed, size: 16),
                                              label: Text(
                                                LanguageService.instance.trText(
                                                  ne: '🐢 बिस्तारै',
                                                  en: '🐢 Slow',
                                                  ko: '🐢 느리게',
                                                ),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            // 3. Official Textbook Audio (Only if available)
                                            if (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.teal.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                ),
                                                onPressed: () => AudioPlaybackService.instance.playAudioUrl(card.audioUrl!),
                                                icon: const Icon(Icons.play_circle_filled, size: 18),
                                                label: Text(
                                                  LanguageService.instance.trText(
                                                    ne: '🎧 पाठ्यपुस्तक अडियो',
                                                    en: '🎧 Textbook Audio',
                                                    ko: '🎧 교재 음원',
                                                  ),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text('👆 ' + LanguageService.instance.tr('tap_to_flip'), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                      ] else ...[
                                        // Back: Nepali Meaning & Examples
                                        Column(
                                          children: [
                                            Text(
                                              card.nepaliMeaning,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF15803D)),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(LanguageService.instance.trText(ne: 'कार्यस्थल उदाहरण वाक्य:', en: 'Workplace Example Sentence:', ko: '직장 실무 예문:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                                                  const SizedBox(height: 4),
                                                  Text(card.exampleSentence, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: card.isMastered ? Colors.green : const Color(0xFF1E3A8A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              StudyMaterialService.instance.toggleFlashcardMastered(card.id);
                                            });
                                          },
                                          icon: Icon(card.isMastered ? Icons.check_circle : Icons.bookmark_add, size: 18),
                                          label: Text(card.isMastered ? '✓ ' + LanguageService.instance.tr('mastered') : (LanguageService.instance.isEnglish ? 'Mark as Mastered' : (LanguageService.instance.isKorean ? '암기완료로 표시' : 'कण्ठ भयो भनी चिन्ह लगाउनुहोस्'))),
                                        ),
                                      ],

                                      // Swipe indicator
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_back, size: 12, color: Colors.black38),
                                          SizedBox(width: 6),
                                          Text(LanguageService.instance.tr('swipe_to_next'), style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                          SizedBox(width: 6),
                                          Icon(Icons.arrow_forward, size: 12, color: Colors.black38),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        },
                      ),
                    ),

                    // Bottom Navigation Buttons with Center Fullscreen Action
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _currentFlashcardIndex > 0
                                ? () {
                                    _flashcardPageController.previousPage(
                                       duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: Text(LanguageService.instance.trText(ne: 'अघिल्लो', en: 'Previous', ko: '이전')),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            tooltip: LanguageService.instance.trText(ne: 'फुल स्क्रिन मोड', en: 'Fullscreen Mode', ko: '전체화면 모드'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenFlashcardScreen(
                                    flashcards: filtered,
                                    initialIndex: _currentFlashcardIndex,
                                    chapterTitle: _getChapterName(_selectedFlashcardChapter),
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                            onPressed: _currentFlashcardIndex < filtered.length - 1
                                ? () {
                                    _flashcardPageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: Text(LanguageService.instance.trText(ne: 'अर्को कार्ड', en: 'Next Card', ko: '다음 카드')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: GRAMMAR (व्याकरण बैंक)
  // -------------------------------------------------------------
  Widget _buildGrammarTab() {
    final allGrammar = StudyMaterialService.instance.getAllGrammar();
    final filtered = allGrammar.where((g) {
      if (_grammarSearch.isEmpty) return true;
      final q = _grammarSearch.toLowerCase();
      return g.title.toLowerCase().contains(q) ||
          g.nepaliExplanation.toLowerCase().contains(q) ||
          g.category.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'व्याकरण खोज्नुहोस् (जस्तै: -아/어서, -면, क्षमता...)',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
              suffixIcon: _grammarSearch.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _grammarSearch = ''))
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _grammarSearch = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('कुनै व्याकरण भेटिएन।', style: TextStyle(color: Colors.black54)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final g = filtered[i];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(g.category, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500))),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(LanguageService.instance.trText(ne: 'संरचना: ${g.structure}', en: 'Structure: ${g.structure}', ko: '문형: ${g.structure}'), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFFF8FAFC),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(LanguageService.instance.trText(ne: 'नियम र व्याख्या:', en: 'Rules & Explanation:', ko: '문법 규칙 및 해설:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text(g.nepaliExplanation, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                                const SizedBox(height: 14),
                                Text(LanguageService.instance.trText(ne: 'कार्यस्थल तथा परीक्षा उदाहरण वाक्यहरू:', en: 'Workplace & Exam Example Sentences:', ko: '실무 및 시험 예문:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                                const SizedBox(height: 8),
                                ...g.examples.map((ex) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('🇰🇷 ${ex.korean}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                          const SizedBox(height: 2),
                                          Text('🇳🇵 ${ex.nepali}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 5: VIDEO COURSES (भिडियो कोर्स)
  // -------------------------------------------------------------
  Widget _buildVideoCourseTab() {
    final videos = StudyMaterialService.instance.getAllVideos();

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              LanguageService.instance.trText(
                ne: 'कुनै भिडियो पाठ भेटिएन।',
                en: 'No video lessons available.',
                ko: '등록된 동영상 강의가 없습니다.',
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final v = videos[i];
        final lessons = v.effectiveLessons;

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VideoCoursePlayerScreen(course: v)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Thumbnail Box with Play Overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      color: const Color(0xFF0F172A),
                      child: v.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              v.thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 160,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                    ),
                    Container(
                      height: 160,
                      color: Colors.black38,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 10),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            LanguageService.instance.trText(
                              ne: '🔒 युट्युब पाठ्यक्रम प्लेयर • ${lessons.length} वटा पाठ',
                              en: '🔒 YouTube Course Player • ${lessons.length} Lessons',
                              ko: '🔒 유튜브 집중 강의 • ${lessons.length}강',
                            ),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⏱️ ${v.duration}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(v.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                          ),
                          Text('👨‍🏫 ${v.instructor}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text(v.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VideoCoursePlayerScreen(course: v)),
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill, size: 18),
                        label: Text(
                          LanguageService.instance.trText(
                            ne: 'भिडियो क्लास खोल्नुहोस् (सुरक्षित प्लेयर)',
                            en: 'Open Video Class (Safe Player)',
                            ko: '동영상 강의 시작 (집중 모드)',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 6: NOTICES (सूचना पाटी)
  // -------------------------------------------------------------
  Widget _buildNoticesTab() {
    final notices = StudyMaterialService.instance.getAllNotices();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: notices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final n = notices[i];
        final dateStr = '${n.date.year}.${n.date.month.toString().padLeft(2, '0')}.${n.date.day.toString().padLeft(2, '0')}';
        final isUrgent = n.priority.contains('जरुरी');

        return Card(
          elevation: n.isPinned ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: n.isPinned ? Colors.amber.shade600 : Colors.grey.shade200,
              width: n.isPinned ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red.shade50 : const Color(0xFF1E3A8A).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(n.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red.shade800 : const Color(0xFF1E3A8A))),
                    ),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text(n.content, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }
}
