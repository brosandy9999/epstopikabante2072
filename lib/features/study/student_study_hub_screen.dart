import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/offline_download_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import 'book_reader_screen.dart';

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
  String _selectedBookEdition = 'सबै (All)';

  // Dictionary search and filters
  String _dictSearch = '';
  String _selectedPartOfSpeech = 'सबै (All)';

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
    if (chap == 0) return 'सबै ६० अध्यायहरू (All 60 Chapters)';
    return _chapterTitleMap[chap] ?? '제${chap}과: 표준교재 단어장 (अध्याय $chap)';
  }

  void _showAttachAudioDialog(VisualFlashcard card) {
    final urlCtrl = TextEditingController(text: card.audioUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.audiotrack, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text('${card.koreanWord} - अडियो जोड्नुहोस्', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('यस शब्दका लागि कम्प्युटर/मोबाइलबाट MP3 अडियो रोज्नुहोस्:', style: TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () async {
                  final file = await FileUploadService.instance.pickAudioFile();
                  if (file != null) {
                    setDialogState(() {
                      urlCtrl.text = file.dataUrl;
                    });
                  }
                },
                icon: const Icon(Icons.audio_file, size: 18),
                label: Text(urlCtrl.text.isEmpty
                    ? '📁 डिभाइसबाट सिधै MP3 रोज्नुहोस् (Pick MP3)'
                    : 'अडियो लोड भयो ✅ (${urlCtrl.text.startsWith("data:") ? "Local File" : "URL"})'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'वा अडियो URL लिङ्क राख्नुहोस् (Optional URL)',
                  hintText: 'https://hrd.go.kr/audio/word.mp3',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () {
              final newUrl = urlCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                final updated = VisualFlashcard(
                  id: card.id,
                  koreanWord: card.koreanWord,
                  pronunciation: card.pronunciation,
                  nepaliMeaning: card.nepaliMeaning,
                  chapterNo: card.chapterNo,
                  chapterTitle: card.chapterTitle,
                  topic: card.topic,
                  visualIcon: card.visualIcon,
                  exampleSentence: card.exampleSentence,
                  isMastered: card.isMastered,
                  audioUrl: newUrl,
                );
                StudyMaterialService.instance.deleteVisualFlashcard(card.id);
                StudyMaterialService.instance.addVisualFlashcard(updated);
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('अडियो सेभ गर्नुहोस्'),
          ),
        ],
      ),
    ),
  );
}

  // Visual Flashcard state
  int _selectedFlashcardChapter = 0; // 0 = all chapters
  String _selectedFlashcardTopic = 'सबै (All)';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flashcardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_special, size: 24),
            SizedBox(width: 10),
            Text(
              'EPS-TOPIK अध्ययन स्रोत (Resources Hub)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.amber,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'किताबहरू (Books)'),
            Tab(icon: Icon(Icons.auto_stories, size: 18), text: 'डिक्सनरी (Dictionary)'),
            Tab(icon: Icon(Icons.style, size: 18), text: 'चित्र फ्ल्यास कार्ड (Flashcards)'),
            Tab(icon: Icon(Icons.translate, size: 18), text: 'ग्रामर (Grammar)'),
            Tab(icon: Icon(Icons.play_circle_filled, size: 18), text: 'भिडियो कोर्स (Videos)'),
            Tab(icon: Icon(Icons.campaign, size: 18), text: 'सूचना (Notices)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: _buildBooksTab())),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: _buildDictionaryTab())),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _buildVisualFlashcardsTab())),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: _buildGrammarTab())),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: _buildVideoCourseTab())),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: _buildNoticesTab())),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: UNLIMITED BOOKS (नयाँ तथा पुराना असीमित किताबहरू)
  // -------------------------------------------------------------
  Widget _buildBooksTab() {
    final allBooks = StudyMaterialService.instance.getAllBooks();
    final editions = ['सबै (All)', 'नयाँ संस्करण (New Edition)', 'पुरानो संस्करण (Old Edition)', 'विशेष गाइड (Special Guide)'];

    final filtered = allBooks.where((b) {
      if (_selectedBookEdition == 'सबै (All)') return true;
      final key = _selectedBookEdition.split(' ')[0];
      return b.editionType.contains(key);
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
                final isSel = _selectedBookEdition == ed;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ed, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E3A8A),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) => setState(() => _selectedBookEdition = ed),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('कुनै किताब भेटिएन।', style: TextStyle(color: Colors.black54)))
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
                              b.editionType,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNew ? Colors.blue.shade900 : Colors.amber.shade900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${b.chaptersCount} वटा अध्याय', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(b.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(b.description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text('📌 मुख्य विशेषताहरू (Highlights):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 6),
            ...b.highlightTopics.map((topic) => Padding(
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
                final isDownloaded = OfflineDownloadService.instance.isBookDownloaded(b.id);
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
                        label: const Text('📖 अडियोसहितको पुस्तक खोल्नुहोस्'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDownloaded ? Colors.green.shade700 : const Color(0xFF0F766E),
                        side: BorderSide(color: isDownloaded ? Colors.green : const Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (isDownloaded) {
                          await OfflineDownloadService.instance.removeDownloadedBook(b.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('अफलाइन क्यासबाट पुस्तक हटाइयो।')),
                          );
                        } else {
                          await OfflineDownloadService.instance.downloadBook(b.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ पुस्तक इन-एप अफलाइन अध्ययनका लागि डाउनलोड भयो!'), backgroundColor: Colors.teal),
                          );
                        }
                        setState(() {});
                      },
                      icon: Icon(isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined, size: 18),
                      label: Text(isDownloaded ? '✅ अफलाइन सेभ' : '⬇️ अफलाइन सेभ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _openBookReaderModal(StudyBook b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Color(0xFF1E3A8A), size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(b.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(b.subtitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('कुल अध्याय संख्या: ${b.chaptersCount} • संस्करण: ${b.editionType}', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Text(b.description, style: const TextStyle(fontSize: 13, height: 1.5)),
              const SizedBox(height: 14),
              const Text('अध्यायगत मुख्य सूची:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...b.highlightTopics.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $h', style: const TextStyle(fontSize: 12)),
                  )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('बुझें (Close)'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: DICTIONARY (कोरियन-नेपाली स्मार्ट डिक्सनरी)
  // -------------------------------------------------------------
  Widget _buildDictionaryTab() {
    final allWords = StudyMaterialService.instance.getAllDictionaryWords();
    final parts = ['सबै (All)', 'संज्ञा (Noun)', 'क्रिया (Verb)', 'विशेषण (Adjective)'];

    final filtered = allWords.where((w) {
      if (_selectedPartOfSpeech != 'सबै (All)') {
        final key = _selectedPartOfSpeech.split(' ')[0];
        if (!w.partOfSpeech.contains(key)) return false;
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
                  hintText: 'शब्द खोज्नुहोस् (जस्तै: 안전모, हथौडा, 용접, safe...)',
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
                    final isSel = _selectedPartOfSpeech == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) => setState(() => _selectedPartOfSpeech = p),
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
              ? const Center(child: Text('डिक्सनरीमा कुनै शब्द भेटिएन।', style: TextStyle(color: Colors.black54)))
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
                                      tooltip: 'उच्चारण सुन्नुहोस्',
                                      onPressed: () => KoreanTtsService.instance.speakKorean(w.koreanWord),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('제${w.chapterNo}과 • ${w.partOfSpeech.split(' ')[0]}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
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
    final topics = ['सबै (All)', 'कारखाना औजार', 'सुरक्षा सामग्री', 'कृषि तथा पशुपालन', 'निर्माण तथा ढुवानी'];

    final filtered = allCards.where((c) {
      if (_selectedFlashcardChapter > 0 && c.chapterNo != _selectedFlashcardChapter) return false;
      if (_selectedFlashcardTopic != 'सबै (All)' && !c.topic.contains(_selectedFlashcardTopic)) return false;
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
                      const Text('अध्याय:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _selectedFlashcardChapter,
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('📚 सबै ६० अध्यायहरू (All Chapters)')),
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
                        'अटो TTS:',
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
                    final isSel = _selectedFlashcardTopic == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A8A),
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) {
                          setState(() {
                            _selectedFlashcardTopic = t;
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
              ? const Center(child: Text('छानिएको अध्याय वा टपिकमा कुनै फ्ल्यासकार्ड भेटिएन।', style: TextStyle(color: Colors.black54)))
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    // Progress & Counter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'कार्ड ${_currentFlashcardIndex + 1} / ${filtered.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                          ),
                          Text(
                            'कण्ठ भएका: ${filtered.where((c) => c.isMastered).length}/${filtered.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

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
                                      // Header tags
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                            child: Text('제${card.chapterNo}과 • ${card.topic}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                          ),
                                          Text(
                                            isFlipped ? '🇳🇵 पछाडिको भाग (अर्थ)' : '🇰🇷 अगाडिको भाग (शब्द)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isFlipped ? Colors.green.shade800 : const Color(0xFF1E3A8A)),
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
                                            // 1. Korean TTS Button
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E3A8A),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                              onPressed: () => KoreanTtsService.instance.speakKorean(card.koreanWord),
                                              icon: const Icon(Icons.volume_up, size: 18),
                                              label: const Text('🔊 TTS उच्चारण'),
                                            ),
                                            // 2. Uploaded Custom Audio Button
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                                                    ? Colors.teal.shade700
                                                    : Colors.blueGrey.shade700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                              onPressed: () {
                                                if (card.audioUrl != null && card.audioUrl!.isNotEmpty) {
                                                  AudioPlaybackService.instance.playAudioUrl(card.audioUrl!);
                                                } else {
                                                  _showAttachAudioDialog(card);
                                                }
                                              },
                                              icon: Icon(
                                                (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                                                    ? Icons.play_circle_filled
                                                    : Icons.upload_file,
                                                size: 18,
                                              ),
                                              label: Text(
                                                (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                                                    ? '🎵 आफ्नै अडियो'
                                                    : '🎵 अडियो जोड्नुहोस्',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text('👆 कार्ड थिचेर नेपाली अर्थ हेर्नुहोस् (Tap to Flip)', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
                                                  const Text('कार्यस्थल उदाहरण वाक्य:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
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
                                          label: Text(card.isMastered ? '✓ कण्ठ भयो (Mastered)' : 'कण्ठ भयो भनी चिन्ह लगाउनुहोस्'),
                                        ),
                                      ],

                                      // Swipe indicator
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_back, size: 12, color: Colors.black38),
                                          SizedBox(width: 6),
                                          Text('स्वाइप गर्नुहोस् (Swipe to Next)', style: TextStyle(fontSize: 11, color: Colors.black45)),
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

                    // Bottom Navigation Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                            label: const Text('अघिल्लो'),
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
                            label: const Text('अर्को कार्ड'),
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
                          child: Text('संरचना: ${g.structure}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFFF8FAFC),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('नेपालीमा नियम र व्याख्या:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text(g.nepaliExplanation, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                                const SizedBox(height: 14),
                                const Text('कार्यस्थल तथा परीक्षा उदाहरण वाक्यहरू:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final v = videos[i];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1E3A8A), size: 34),
                        ),
                        const SizedBox(height: 8),
                        Text('भिडियो कक्षा (${v.duration})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(v.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                    ),
                    Text('⏱️ ${v.duration}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(v.description, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
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
