import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('रिसोर्स तथा सामग्री व्यवस्थापन (Admin Resource Hub)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          tabs: const [
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'किताबहरू (Books)'),
            Tab(icon: Icon(Icons.auto_stories, size: 18), text: 'डिक्सनरी (Dictionary)'),
            Tab(icon: Icon(Icons.style, size: 18), text: 'चित्र फ्ल्यास कार्ड (Flashcards)'),
            Tab(icon: Icon(Icons.campaign, size: 18), text: 'सूचना (Notices)'),
            Tab(icon: Icon(Icons.translate, size: 18), text: 'ग्रामर (Grammar)'),
            Tab(icon: Icon(Icons.play_circle_filled, size: 18), text: 'भिडियो कोर्स (Videos)'),
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
  }

  // -------------------------------------------------------------
  // 1. UNLIMITED BOOKS MANAGER (असीमित किताबहरू)
  // -------------------------------------------------------------
  Widget _buildBookManager() {
    final books = StudyMaterialService.instance.getAllBooks();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_to_photos),
        label: const Text('नयाँ किताब अपलोड गर्नुहोस्'),
        onPressed: _openAddBookDialog,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final b = books[i];
          final isNew = b.editionType.contains('नयाँ');

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
                        child: Text(b.editionType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isNew ? Colors.blue.shade900 : Colors.amber.shade900)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          StudyMaterialService.instance.deleteBook(b.id);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(b.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('अध्याय: ${b.chaptersCount} वटा • लिंक: ${b.pdfUrl.isEmpty ? 'इन-एप गाइड' : b.pdfUrl}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
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
                    label: const Text('📖 अडियोसहित पुस्तक खोल्नुहोस् (Inline Audio Reader)'),
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
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final chapCtrl = TextEditingController(text: '30');
    final pdfCtrl = TextEditingController(text: 'https://hrdkorea.or.kr/book.pdf');
    final descCtrl = TextEditingController();
    String editionType = 'नयाँ संस्करण (New Edition)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('📘 नयाँ किताब वा गाइड थप्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'किताबको शीर्षक (Title)*', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'उपशीर्षक (Subtitle)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editionType,
                  decoration: const InputDecoration(labelText: 'संस्करण (Edition Type)', border: OutlineInputBorder()),
                  items: ['नयाँ संस्करण (New Edition)', 'पुरानो संस्करण (Old Edition)', 'विशेष गाइड (Special Guide)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => editionType = val!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: chapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अध्याय संख्या', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: pdfCtrl, decoration: const InputDecoration(labelText: 'PDF वा फाइल लिंक', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'विवरण (Description)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newBook = StudyBook(
                  id: 'book_${DateTime.now().millisecondsSinceEpoch}',
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
              },
              child: const Text('किताब सेभ गर्नुहोस्'),
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
    String pos = 'संज्ञा (Noun)';

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
                TextField(controller: korCtrl, decoration: const InputDecoration(labelText: 'कोरियाली शब्द (Korean Word)*', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: pronCtrl, decoration: const InputDecoration(labelText: 'उच्चारण (Pronunciation)*', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: nepCtrl, decoration: const InputDecoration(labelText: 'नेपाली अर्थ (Nepali Meaning)*', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: pos,
                        decoration: const InputDecoration(labelText: 'व्याकरण विधा', border: OutlineInputBorder()),
                        items: ['संज्ञा (Noun)', 'क्रिया (Verb)', 'विशेषण (Adjective)', 'क्रियाविशेषण'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) => setDialogState(() => pos = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: chapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अध्याय (१-६०)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: exKorCtrl, decoration: const InputDecoration(labelText: 'उदाहरण वाक्य (Korean)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: exNepCtrl, decoration: const InputDecoration(labelText: 'नेपाली अनुवाद (Nepali)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
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
                          decoration: const InputDecoration(labelText: 'अध्याय नं (१ देखि ६०)*', border: OutlineInputBorder()),
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
                          decoration: const InputDecoration(labelText: 'अध्याय शीर्षक (Chapter Title)', border: OutlineInputBorder()),
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
                          decoration: const InputDecoration(labelText: 'कोरियाली शब्द (Korean Word)*', border: OutlineInputBorder()),
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
                                decoration: const InputDecoration(labelText: 'इमोजी/प्रतीक (Icon)', border: OutlineInputBorder()),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF1E3A8A)),
                              tooltip: 'डिभाइसबाट फोटो छान्नुहोस्',
                              onPressed: () async {
                                final file = await FileUploadService.instance.pickImageFile();
                                if (file != null) {
                                  setDialogState(() {
                                    iconCtrl.text = file.dataUrl;
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
                          decoration: const InputDecoration(labelText: 'नेपाली उच्चारण (Pronunciation)*', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nepCtrl,
                          decoration: const InputDecoration(labelText: 'नेपाली अर्थ (Nepali Meaning)*', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: topic,
                    decoration: const InputDecoration(labelText: 'टपिक (Topic)', border: OutlineInputBorder()),
                    items: ['अभिवादन', 'आत्मपरिचय', 'दैनिक स्थान', 'किनमेल', 'कारखाना औजार', 'सुरक्षा सामग्री', 'कृषि तथा पशुपालन', 'निर्माण तथा ढुवानी', 'श्रम कानुन', 'कार्यस्थल संवाद'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => topic = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: exCtrl,
                    decoration: const InputDecoration(labelText: 'कार्यस्थल उदाहरण वाक्य (Example Sentence)', border: OutlineInputBorder()),
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
                        const Text('🔊 उच्चारण अडियो छनोट (Audio Source):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: useCustomAudio,
                              onChanged: (v) => setDialogState(() => useCustomAudio = v!),
                            ),
                            const Text('स्वचालित कोरियन TTS', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 14),
                            Radio<bool>(
                              value: true,
                              groupValue: useCustomAudio,
                              onChanged: (v) => setDialogState(() => useCustomAudio = v!),
                            ),
                            const Text('अपलोड अडियो URL/MP3', style: TextStyle(fontSize: 12)),
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
                                  audioUrlCtrl.text = file.dataUrl;
                                });
                              }
                            },
                            icon: const Icon(Icons.audio_file, size: 18),
                            label: Text(audioUrlCtrl.text.isEmpty
                                ? '📁 कम्प्युटर/मोबाइलबाट अडियो रोज्नुहोस् (Pick MP3)'
                                : 'अडियो लोड भयो ✅ (${audioUrlCtrl.text.startsWith("data:") ? "Local File" : "URL"})'),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: audioUrlCtrl,
                            decoration: InputDecoration(
                              labelText: 'वा अडियो URL लिङ्क राख्नुहोस् (Optional URL)',
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
                              label: const Text('TTS टेस्ट सुन्नुहोस्', style: TextStyle(fontSize: 11)),
                            ),
                            if (useCustomAudio && audioUrlCtrl.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  AudioPlaybackService.instance.playAudioUrl(audioUrlCtrl.text.trim());
                                },
                                icon: const Icon(Icons.play_circle_filled, size: 16, color: Colors.teal),
                                label: const Text('अपलोड अडियो सुन्नुहोस्', style: TextStyle(fontSize: 11, color: Colors.teal)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
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
              },
              child: const Text('कार्ड सुरक्षित गर्नुहोस्'),
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
        label: const Text('नयाँ सूचना जारी गर्नुहोस्'),
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
    final authorCtrl = TextEditingController(text: 'इन्स्टिच्युट प्रशासन');
    String priority = 'सामान्य';
    String category = 'परीक्षा';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('📢 नयाँ सूचना जारी गर्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'सूचना शीर्षक*', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'व्यहोरा*', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'जारीकर्ता', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द गर्नुहोस्')),
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
              },
              child: const Text('सूचना प्रकाशित गर्नुहोस्'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarManager() {
    final list = StudyMaterialService.instance.getAllGrammar();
    return ListView.separated(
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
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoManager() {
    final list = StudyMaterialService.instance.getAllVideos();
    return ListView.separated(
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
              },
            ),
          ),
        );
      },
    );
  }
}
