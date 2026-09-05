import 'package:flutter/material.dart';
import '../../core/services/language_service.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../study/book_reader_screen.dart';

/// Admin Resources, Books, Dictionary & Notice Manager Screen
/// Allows administrators to upload unlimited books (new/old editions),
/// add dictionary words, manage visual chapter/topic flashcards, grammar, and videos.
class AdminStudyManagerScreen extends StatefulWidget {
  const AdminStudyManagerScreen({super.key});

  @override
  State<AdminStudyManagerScreen> createState() => _AdminStudyManagerScreenState();
}

class _AdminStudyManagerScreenState extends State<AdminStudyManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LanguageService.instance, StudyMaterialService.instance]),
      builder: (context, _) {
        final lang = LanguageService.instance;
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            title: Text(lang.trText(ne: 'रिसोर्स तथा अध्ययन सामग्री व्यवस्थापन', en: 'Study Resources & Content Hub', ko: '학습 자료 및 교재 관리'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.amber,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(icon: const Icon(Icons.menu_book, size: 18), text: lang.tr('books')),
                Tab(icon: const Icon(Icons.auto_stories, size: 18), text: lang.tr('dictionary')),
                Tab(icon: const Icon(Icons.style, size: 18), text: lang.tr('flashcards')),
                Tab(icon: const Icon(Icons.campaign, size: 18), text: lang.tr('notices')),
                Tab(icon: const Icon(Icons.translate, size: 18), text: lang.tr('grammar')),
                Tab(icon: const Icon(Icons.play_circle_filled, size: 18), text: lang.tr('videos')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBookManager(),
              _buildDictionaryManager(),
              _buildFlashcardManager(),
              _buildNoticeManager(),
              _buildGrammarManager(),
              _buildVideoManager(),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 1. UNLIMITED BOOKS MANAGER (असीमित किताबहरू)
  // -------------------------------------------------------------
  Widget _buildBookManager() {
    final books = StudyMaterialService.instance.getAllBooks();
    final lang = LanguageService.instance;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_photos),
        label: Text(lang.trText(ne: 'नयाँ किताब अपलोड गर्नुहोस्', en: 'Upload New Book', ko: '새 교재 업로드')),
        onPressed: _openAddBookDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final b = books[i];
          final isNew = b.editionType.contains('नयाँ') || b.id.contains('new');

          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: isNew ? Colors.blue.shade50 : Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(b.localizedEditionType(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNew ? Colors.blue.shade900 : Colors.amber.shade900)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          StudyMaterialService.instance.deleteBook(b.id);
                          setState(() {});
                          CloudSyncService.instance.pushToCloud();
                        },
                      ),
                    ],
                  ),
                  Text(b.localizedTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(b.localizedSubtitle(), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    lang.trText(
                      ne: 'अध्याय:  वटा • लिङ्क: ',
                      en: 'Chapters:  • Link: ',
                      ko: '단원: 개 • 링크: ',
                    ),
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookReaderScreen(book: b)),
                      );
                    },
                    icon: const Icon(Icons.menu_book, size: 16),
                    label: Text(lang.trText(ne: 'अडियोसहित पुस्तक खोल्नुहोस्', en: 'Open Book with Audio', ko: '오디오 포함 교재 열기')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddBookDialog() {
    final lang = LanguageService.instance;
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final chapCtrl = TextEditingController(text: '30');
    final pdfCtrl = TextEditingController(text: 'https://hrdkorea.or.kr/book.pdf');
    final descCtrl = TextEditingController();
    String editionType = 'नयाँ संस्करण';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(lang.trText(ne: '📘 नयाँ किताब वा गाइड थप्नुहोस्', en: '📘 Add New Book or Guide', ko: '📘 새 교재 또는 가이드 추가'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: lang.trText(ne: 'किताबको शीर्षक*', en: 'Book Title*', ko: '교재 제목*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: subtitleCtrl, decoration: InputDecoration(labelText: lang.trText(ne: 'उपशीर्षक', en: 'Subtitle', ko: '부제목'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editionType,
                  decoration: InputDecoration(labelText: lang.trText(ne: 'संस्करण', en: 'Edition', ko: '판본'), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'नयाँ संस्करण', child: Text(lang.trText(ne: 'नयाँ संस्करण', en: 'New Edition', ko: '신규 개정판'))),
                    DropdownMenuItem(value: 'पुरानो संस्करण', child: Text(lang.trText(ne: 'पुरानो संस्करण', en: 'Old Edition', ko: '클래식 구판'))),
                    DropdownMenuItem(value: 'विशेष गाइड', child: Text(lang.trText(ne: 'विशेष गाइड', en: 'Special Guide', ko: '특수 가이드'))),
                  ],
                  onChanged: (val) => setDialogState(() => editionType = val!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: chapCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.trText(ne: 'अध्याय संख्या', en: 'Chapters Count', ko: '단원 수'), border: const OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: pdfCtrl, decoration: InputDecoration(labelText: lang.trText(ne: 'PDF वा फाइल लिङ्क', en: 'PDF or File Link', ko: 'PDF 또는 파일 링크'), border: const OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: lang.trText(ne: 'विवरण', en: 'Description', ko: '설명'), border: const OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newBook = StudyBook(
                  id: 'book_',
                  title: titleCtrl.text.trim(),
                  subtitle: subtitleCtrl.text.trim(),
                  editionType: editionType,
                  level: 'All Levels',
                  chaptersCount: int.tryParse(chapCtrl.text.trim()) ?? 30,
                  pdfUrl: pdfCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? 'EPS-TOPIK अध्ययन सामग्री' : descCtrl.text.trim(),
                  highlightTopics: ['अध्यायगत अभ्यास तथा शब्दावली'],
                  createdAt: DateTime.now(),
                );
                StudyMaterialService.instance.addBook(newBook);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(lang.trText(ne: 'किताब सेभ गर्नुहोस्', en: 'Save Book', ko: '교재 저장')),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. DICTIONARY MANAGER
  // -------------------------------------------------------------
  Widget _buildDictionaryManager() {
    final words = StudyMaterialService.instance.getAllDictionaryWords();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.post_add),
        label: const Text('नयाँ डिक्सनरी शब्द थप्नुहोस्'),
        onPressed: _openAddDictionaryWordDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final w = words[i];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              title: Text('${w.koreanWord} [ ${w.pronunciation} ]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text('${w.nepaliMeaning} • 제${w.chapterNo}과 • ${w.partOfSpeech}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  StudyMaterialService.instance.deleteDictionaryWord(w.id);
                  setState(() {});
                  CloudSyncService.instance.pushToCloud();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddDictionaryWordDialog() {
    final korCtrl = TextEditingController();
    final pronCtrl = TextEditingController();
    final nepCtrl = TextEditingController();
    final chapCtrl = TextEditingController(text: '41');
    final exKorCtrl = TextEditingController();
    final exNepCtrl = TextEditingController();
    String pos = 'संज्ञा';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('📖 नयाँ डिक्सनरी शब्द थप्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: korCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'कोरियाली शब्द*', en: 'Korean Word*', ko: '한국어 단어*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: pronCtrl, decoration: const InputDecoration(labelText: 'उच्चारण*', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: nepCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'नेपाली अर्थ*', en: 'Meaning / Translation*', ko: '의미/번역*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: pos,
                        decoration: const InputDecoration(labelText: 'व्याकरण विधा', border: OutlineInputBorder()),
                        items: ['संज्ञा', 'क्रिया', 'विशेषण', 'क्रियाविशेषण'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) => setDialogState(() => pos = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: chapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अध्याय (१-६०)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: exKorCtrl, decoration: const InputDecoration(labelText: 'उदाहरण वाक्य (कोरियन)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: exNepCtrl, decoration: const InputDecoration(labelText: 'नेपाली अनुवाद', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                if (korCtrl.text.trim().isEmpty || nepCtrl.text.trim().isEmpty) return;
                final newWord = DictionaryWord(
                  id: 'dict_${DateTime.now().millisecondsSinceEpoch}',
                  koreanWord: korCtrl.text.trim(),
                  pronunciation: pronCtrl.text.trim(),
                  nepaliMeaning: nepCtrl.text.trim(),
                  partOfSpeech: pos,
                  chapterNo: int.tryParse(chapCtrl.text.trim()) ?? 1,
                  category: pos.split(' ')[0],
                  exampleKorean: exKorCtrl.text.trim(),
                  exampleNepali: exNepCtrl.text.trim(),
                );
                StudyMaterialService.instance.addDictionaryWord(newWord);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: const Text('डिक्सनरीमा थप्नुहोस्'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. VISUAL FLASHCARD MANAGER
  // -------------------------------------------------------------
  Widget _buildFlashcardManager() {
    final list = StudyMaterialService.instance.getAllVisualFlashcards();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.style),
        label: const Text('नयाँ चित्र फ्ल्यास कार्ड थप्नुहोस्'),
        onPressed: _openAddFlashcardDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = list[i];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(c.visualIcon, style: const TextStyle(fontSize: 22)),
              ),
              title: Text('${c.koreanWord} [ ${c.pronunciation} ]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${c.nepaliMeaning} • 제${c.chapterNo}과 • ${c.topic}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  StudyMaterialService.instance.deleteVisualFlashcard(c.id);
                  setState(() {});
                  CloudSyncService.instance.pushToCloud();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddFlashcardDialog() {
    final korCtrl = TextEditingController();
    final pronCtrl = TextEditingController();
    final nepCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: '📦');
    final chapCtrl = TextEditingController(text: '1');
    final chapTitleCtrl = TextEditingController(text: '한글 익히기 (वर्णमाला तथा आधारभूत)');
    final exCtrl = TextEditingController();
    final audioUrlCtrl = TextEditingController();
    bool useCustomAudio = false;
    String topic = 'अभिवादन';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.style, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('🗂️ नयाँ च्याप्टर फ्ल्यासकार्ड थप्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: chapCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'अध्याय नं (१ देखि ६०)*', en: 'Chapter No (1 to 60)*', ko: '과 번호 (1~60)*'), border: const OutlineInputBorder()),
                          onChanged: (val) {
                            final c = int.tryParse(val.trim()) ?? 1;
                            setDialogState(() {
                              chapTitleCtrl.text = '제${c}과: 표준교재 단어장';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: chapTitleCtrl,
                          decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'अध्याय शीर्षक', en: 'Chapter Title', ko: '과 제목'), border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: korCtrl,
                          decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'कोरियाली शब्द*', en: 'Korean Word*', ko: '한국어 단어*'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: iconCtrl,
                                decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'इमोजी / प्रतीक', en: 'Emoji / Icon', ko: '이모지/아이콘'), border: const OutlineInputBorder()),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF1E3A8A)),
                              tooltip: 'डिभाइसबाट फोटो छान्नुहोस्',
                              onPressed: () async {
                                final file = await FileUploadService.instance.pickImageFile();
                                if (file != null) {
                                  setDialogState(() {
                                    iconCtrl.text = file.bestUrl;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pronCtrl,
                          decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'नेपाली उच्चारण*', en: 'Pronunciation / Reading*', ko: '발음 표기*'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nepCtrl,
                          decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'नेपाली अर्थ*', en: 'Meaning / Translation*', ko: '의미/번역*'), border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: topic,
                    decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'विषय (टपिक)', en: 'Category / Topic', ko: '주제/분류'), border: const OutlineInputBorder()),
                    items: ['अभिवादन', 'आत्मपरिचय', 'दैनिक स्थान', 'किनमेल', 'कारखाना औजार', 'सुरक्षा सामग्री', 'कृषि तथा पशुपालन', 'निर्माण तथा ढुवानी', 'श्रम कानुन', 'कार्यस्थल संवाद'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => topic = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: exCtrl,
                    decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'कार्यस्थल उदाहरण वाक्य', en: 'Workplace Example Sentence', ko: '직장 예문'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),

                  // Audio Selection: TTS vs Uploaded Audio
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LanguageService.instance.trText(ne: '🔊 उच्चारण अडियो छनोट (Audio Source):', en: '🔊 Audio Source Selection:', ko: '🔊 발음 오디오 선택:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: useCustomAudio,
                              onChanged: (v) => setDialogState(() => useCustomAudio = v!),
                            ),
                            Text(LanguageService.instance.trText(ne: 'स्वचालित कोरियन TTS', en: 'Automatic Korean TTS', ko: '자동 한국어 TTS'), style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 14),
                            Radio<bool>(
                              value: true,
                              groupValue: useCustomAudio,
                              onChanged: (v) => setDialogState(() => useCustomAudio = v!),
                            ),
                            Text(LanguageService.instance.trText(ne: 'अपलोड अडियो URL/MP3', en: 'Upload Audio URL/MP3', ko: '오디오 URL/MP3 업로드'), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (useCustomAudio) ...[
                          const SizedBox(height: 8),
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
                                  audioUrlCtrl.text = file.bestUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.audio_file, size: 18),
                            label: Text(audioUrlCtrl.text.isEmpty
                                ? LanguageService.instance.trText(ne: '📁 कम्प्युटर/मोबाइलबाट अडियो रोज्नुहोस्', en: '📁 Pick Audio File', ko: '📁 기기에서 오디오 선택')
                                : (audioUrlCtrl.text.startsWith('https://firebasestorage')
                                    ? 'अडियो Firebase मा अपलोड भयो ✅'
                                    : 'अडियो लोड भयो ✅ (${audioUrlCtrl.text.startsWith("data:") ? "Local File" : "URL"})')),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: audioUrlCtrl,
                            decoration: InputDecoration(
                              labelText: LanguageService.instance.trText(ne: 'वा अडियो URL लिङ्क राख्नुहोस्', en: 'Or enter audio URL link', ko: '또는 오디오 URL 링크'),
                              hintText: 'https://hrd.go.kr/audio/ch1_01.mp3',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixIcon: audioUrlCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                                      onPressed: () => setDialogState(() => audioUrlCtrl.clear()),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                if (korCtrl.text.trim().isNotEmpty) {
                                  KoreanTtsService.instance.speakKorean(korCtrl.text.trim());
                                }
                              },
                              icon: const Icon(Icons.volume_up, size: 16),
                              label: Text(LanguageService.instance.trText(ne: 'TTS टेस्ट सुन्नुहोस्', en: 'Test TTS', ko: 'TTS 테스트 듣기'), style: const TextStyle(fontSize: 11)),
                            ),
                            if (useCustomAudio && audioUrlCtrl.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  AudioPlaybackService.instance.playAudioUrl(audioUrlCtrl.text.trim());
                                },
                                icon: const Icon(Icons.play_circle_filled, size: 16, color: Colors.teal),
                                label: Text(LanguageService.instance.trText(ne: 'अपलोड अडियो सुन्नुहोस्', en: 'Listen Uploaded Audio', ko: '업로드된 오디오 듣기'), style: const TextStyle(fontSize: 11, color: Colors.teal)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (korCtrl.text.trim().isEmpty || nepCtrl.text.trim().isEmpty) return;
                final newCard = VisualFlashcard(
                  id: 'vfc_${DateTime.now().millisecondsSinceEpoch}',
                  koreanWord: korCtrl.text.trim(),
                  pronunciation: pronCtrl.text.trim().isEmpty ? korCtrl.text.trim() : pronCtrl.text.trim(),
                  nepaliMeaning: nepCtrl.text.trim(),
                  chapterNo: int.tryParse(chapCtrl.text.trim()) ?? 1,
                  chapterTitle: chapTitleCtrl.text.trim().isEmpty ? '제${chapCtrl.text.trim()}과' : chapTitleCtrl.text.trim(),
                  topic: topic,
                  visualIcon: iconCtrl.text.trim().isEmpty ? '📦' : iconCtrl.text.trim(),
                  exampleSentence: exCtrl.text.trim(),
                  audioUrl: useCustomAudio && audioUrlCtrl.text.trim().isNotEmpty ? audioUrlCtrl.text.trim() : null,
                );
                StudyMaterialService.instance.addVisualFlashcard(newCard);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(LanguageService.instance.trText(ne: 'कार्ड सुरक्षित गर्नुहोस्', en: 'Save Flashcard', ko: '카드 저장')),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. NOTICE, GRAMMAR & VIDEO MANAGERS
  // -------------------------------------------------------------
  Widget _buildNoticeManager() {
    final notices = StudyMaterialService.instance.getAllNotices();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: Text(LanguageService.instance.trText(ne: 'नयाँ सूचना जारी गर्नुहोस्', en: 'Publish Notice', ko: '공지사항 등록')),
        onPressed: _openAddNoticeDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final n = notices[i];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.priority.contains('जरुरी') ? Colors.red.shade100 : const Color(0xFF1E3A8A).withOpacity(0.1),
                child: Icon(Icons.campaign, color: n.priority.contains('जरुरी') ? Colors.red : const Color(0xFF1E3A8A)),
              ),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${n.category} • ${n.date.year}.${n.date.month}.${n.date.day} • ${n.author}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  StudyMaterialService.instance.deleteNotice(n.id);
                  setState(() {});
                  CloudSyncService.instance.pushToCloud();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddNoticeDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final authorCtrl = TextEditingController(text: 'परीक्षा शाखा / प्रशासन');
    String priority = 'सामान्य';
    String category = 'परीक्षा तालिका';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(LanguageService.instance.trText(ne: '📢 नयाँ सूचना जारी गर्नुहोस्', en: '📢 Post New Notice', ko: '📢 새 공지사항 등록'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'सूचना शीर्षक*', en: 'Notice Title*', ko: '공지 제목*'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: contentCtrl, maxLines: 3, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'व्यहोरा*', en: 'Content*', ko: '내용*'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: authorCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'जारीकर्ता', en: 'Author / Department', ko: '작성자/부서'), border: const OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                final newNotice = InstituteNotice(
                  id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                  author: authorCtrl.text.trim(),
                  priority: priority,
                  category: category,
                  date: DateTime.now(),
                  isPinned: true,
                );
                StudyMaterialService.instance.addNotice(newNotice);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(LanguageService.instance.trText(ne: 'सूचना प्रकाशित गर्नुहोस्', en: 'Publish Notice', ko: '공지 게시')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarManager() {
    final list = StudyMaterialService.instance.getAllGrammar();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(LanguageService.instance.trText(ne: 'नयाँ व्याकरण थप्नुहोस्', en: 'Add Grammar', ko: '문법 추가')),
        onPressed: _openAddGrammarDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final g = list[i];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E))),
              subtitle: Text('${g.structure} • ${g.category}\n${g.nepaliExplanation}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  StudyMaterialService.instance.deleteGrammar(g.id);
                  setState(() {});
                  CloudSyncService.instance.pushToCloud();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddGrammarDialog() {
    final titleCtrl = TextEditingController();
    final structCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'आधारभूत व्याकरण');
    final descCtrl = TextEditingController();
    final korExCtrl = TextEditingController();
    final nepExCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(LanguageService.instance.trText(ne: '📝 नयाँ व्याकरण नियम थप्नुहोस्', en: '📝 Add New Grammar Rule', ko: '📝 새 문법 규칙 추가'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'व्याकरण शीर्षक (जस्तै: -(으)ㄹ 수 있다)*', en: 'Grammar Title (e.g., -(으)ㄹ 수 있다)*', ko: '문법 제목 (예: -(으)ㄹ 수 있다)*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: structCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'संरचना / सूत्र*', en: 'Structure / Formula*', ko: '문법 구조/공식*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: catCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'वर्ग / श्रेणी', en: 'Category', ko: '분류/카테고리'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'नियम व्याख्या*', en: 'Explanation of Rule*', ko: '문법 규칙 설명*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: korExCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'कोरियन उदाहरण वाक्य', en: 'Korean Example Sentence', ko: '한국어 예문'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: nepExCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'अनुवाद उदाहरण', en: 'Translated Example', ko: '번역 예문'), border: const OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || structCtrl.text.trim().isEmpty) return;
                final newGrammar = GrammarTopic(
                  id: 'g_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  structure: structCtrl.text.trim(),
                  category: catCtrl.text.trim().isEmpty ? 'सामान्य व्याकरण' : catCtrl.text.trim(),
                  nepaliExplanation: descCtrl.text.trim(),
                  examples: korExCtrl.text.trim().isNotEmpty
                      ? [GrammarExample(korean: korExCtrl.text.trim(), nepali: nepExCtrl.text.trim())]
                      : [],
                  createdAt: DateTime.now(),
                );
                StudyMaterialService.instance.addGrammar(newGrammar);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(LanguageService.instance.trText(ne: 'व्याकरण सेभ गर्नुहोस्', en: 'Save Grammar', ko: '문법 저장')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoManager() {
    final list = StudyMaterialService.instance.getAllVideos();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call),
        label: Text(LanguageService.instance.trText(ne: 'नयाँ भिडियो पाठ थप्नुहोस्', en: 'Add Video Lesson', ko: '동영상 강의 추가')),
        onPressed: _openAddVideoDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final v = list[i];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: Icon(Icons.play_arrow, color: Colors.teal.shade900)),
              title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${v.category} • ${v.duration} • ${v.instructor}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  StudyMaterialService.instance.deleteVideo(v.id);
                  setState(() {});
                  CloudSyncService.instance.pushToCloud();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddVideoDialog() {
    final titleCtrl = TextEditingController();
    final instCtrl = TextEditingController(text: 'कोरियन भाषा मुख्य प्रशिक्षक');
    final durCtrl = TextEditingController(text: '३० मिनेट');
    final urlCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'पाठ्यपुस्तक भिडियो');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(LanguageService.instance.trText(ne: '🎥 नयाँ भिडियो क्लास थप्नुहोस्', en: '🎥 Add Video Class', ko: '🎥 새 동영상 강의 추가'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'भिडियो शीर्षक*', en: 'Video Title*', ko: '동영상 제목*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: urlCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'भिडियो लिङ्क / YouTube URL*', en: 'Video Link / YouTube URL*', ko: '동영상 링크 / YouTube URL*'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: instCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'प्रशिक्षकको नाम', en: 'Instructor Name', ko: '강사명'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: durCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'अवधि (जस्तै: २५ मिनेट)', en: 'Duration (e.g., 25 mins)', ko: '재생 시간 (예: 25분)'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: catCtrl, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'वर्ग / श्रेणी', en: 'Category', ko: '분류/카테고리'), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'संक्षिप्त विवरण', en: 'Short Description', ko: '간단 설명'), border: const OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
                final newVideo = VideoCourse(
                  id: 'vid_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  instructor: instCtrl.text.trim(),
                  duration: durCtrl.text.trim(),
                  videoUrl: urlCtrl.text.trim(),
                  category: catCtrl.text.trim().isEmpty ? 'पाठ्यपुस्तक भिडियो' : catCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? 'EPS-TOPIK अनलाइन भिडियो क्लास' : descCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                StudyMaterialService.instance.addVideo(newVideo);
                Navigator.pop(ctx);
                setState(() {});
                CloudSyncService.instance.pushToCloud();
              },
              child: Text(LanguageService.instance.trText(ne: 'भिडियो क्लास सेभ गर्नुहोस्', en: 'Save Video Class', ko: '강의 저장')),
            ),
          ],
        ),
      ),
    );
  }
}
