import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/language_service.dart';

/// Interactive Textbook & PDF Reader with Pin-to-Canvas and Expandable Timeline Audio Buttons
/// Allows admins and students to:
/// 1. Upload chapter PDF/Page image directly.
/// 2. Place small headphone audio buttons directly onto headphone icons in the PDF.
/// 3. Tap any audio button to smoothly expand an audio timeline slider with live time & seeking.
/// 4. Tap again to stop audio and collapse the timeline back into the small compact button.
class BookReaderScreen extends StatefulWidget {
  final StudyBook book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late StudyBook _currentBook;
  int _selectedChapter = 1;
  bool _isPdfMode = true; // Default to PDF / Textbook page view
  bool _isPinningMode = false; // Mode to tap and place audio buttons directly on headphone icons

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _refreshBookFromService();
  }

  void _refreshBookFromService() {
    final all = StudyMaterialService.instance.getAllBooks();
    final idx = all.indexWhere((b) => b.id == widget.book.id);
    if (idx != -1) {
      _currentBook = all[idx];
    }
  }

  @override
  void dispose() {
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  void _saveUpdatedBook(StudyBook updated) {
    setState(() {
      _currentBook = updated;
    });
    StudyMaterialService.instance.addBook(updated);
    CloudSyncService.instance.pushToCloud();
  }

  List<BookAudioTrack> get _chapterTracks {
    final tracks = _currentBook.audioTracks.where((t) => t.chapterNo == _selectedChapter).toList();
    if (tracks.isEmpty) {
      // Default tracks for demo if empty
      return [
        BookAudioTrack(
          id: 'def_d1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 01 (대화 1)',
          sectionType: 'dialogue_1',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=안녕하세요저는투안입니다',
          posX: 0.15,
          posY: 0.28,
        ),
        BookAudioTrack(
          id: 'def_v1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 02 (어휘 1)',
          sectionType: 'vocabulary',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=네팔한국베트남미얀마',
          posX: 0.15,
          posY: 0.44,
        ),
        BookAudioTrack(
          id: 'def_d2_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 03 (대화 2)',
          sectionType: 'dialogue_2',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=저는회사원입니다',
          posX: 0.15,
          posY: 0.60,
        ),
        BookAudioTrack(
          id: 'def_l1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 04 (듣기 1~5)',
          sectionType: 'listening',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=들은것을고르십시오네팔사람입니다',
          posX: 0.15,
          posY: 0.78,
        ),
      ];
    }
    return tracks;
  }

  /// Direct Upload PDF or Page Image for this chapter
  Future<void> _uploadChapterPageDialog() async {
    final urlCtrl = TextEditingController(text: _currentBook.chapterPdfs['$_selectedChapter'] ?? _currentBook.pdfUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(LanguageService.instance.trText(ne: 'अध्याय $_selectedChapter PDF / पृष्ठ अपलोड गर्नुहोस्', en: 'Upload Chapter $_selectedChapter PDF / Page', ko: '제$_selectedChapter과 PDF / 페이지 업로드'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.instance.trText(ne: 'यस अध्यायको लागि आधिकारिक पाठ्यपुस्तकको PDF वा पृष्ठ फोटो अपलोड गर्नुहोस्:', en: 'Upload textbook PDF or page image for this chapter:', ko: '이 단원의 공식 교재 PDF 또는 페이지 이미지를 업로드하세요:'),
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),

                // Pick from device
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () async {
                    final file = await FileUploadService.instance.pickImageFile() ??
                        await FileUploadService.instance.pickPdfFile();
                    if (file != null) {
                      setDialogState(() {
                        urlCtrl.text = file.bestUrl;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(urlCtrl.text.isEmpty
                      ? LanguageService.instance.trText(ne: '📁 कम्प्युटर/मोबाइलबाट PDF वा फोटो रोज्नुहोस्', en: '📁 Pick PDF or Image from Device', ko: '📁 기기에서 PDF 또는 이미지 선택')
                      : 'फाइल लोड भयो ✅ (${urlCtrl.text.startsWith("data:") ? "Local File" : "URL"})'),
                ),
                const SizedBox(height: 10),

                // Or URL
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'वा PDF / Image URL लिङ्क', en: 'Or enter PDF / Image URL', ko: '또는 PDF / 이미지 URL 링크'),
                    hintText: 'https://example.com/chapter1.pdf वा jpg',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                final url = urlCtrl.text.trim();
                final updatedPdfs = Map<String, String>.from(_currentBook.chapterPdfs);
                if (url.isNotEmpty) {
                  updatedPdfs['$_selectedChapter'] = url;
                } else {
                  updatedPdfs.remove('$_selectedChapter');
                }

                final updated = StudyBook(
                  id: _currentBook.id,
                  title: _currentBook.title,
                  subtitle: _currentBook.subtitle,
                  editionType: _currentBook.editionType,
                  level: _currentBook.level,
                  chaptersCount: _currentBook.chaptersCount,
                  description: _currentBook.description,
                  pdfUrl: _currentBook.pdfUrl,
                  chapterPdfs: updatedPdfs,
                  highlightTopics: _currentBook.highlightTopics,
                  audioTracks: _currentBook.audioTracks,
                  createdAt: _currentBook.createdAt,
                );

                _saveUpdatedBook(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(ne: 'अध्याय $_selectedChapter को PDF/पेज सुरक्षित भयो ✅', en: 'Chapter $_selectedChapter PDF/page saved ✅', ko: '제$_selectedChapter과 PDF/페이지가 저장되었습니다 ✅')),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              },
              child: Text(LanguageService.instance.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens dialog to add or place a track (optionally at a pinned position)
  void _openAddTrackDialog({String? initialSection, double? posX, double? posY}) {
    final chapterTracks = _chapterTracks;
    final nextTrackNum = chapterTracks.length + 1;
    final labelCtrl = TextEditingController(text: 'Track ${nextTrackNum.toString().padLeft(2, '0')}');
    final audioUrlCtrl = TextEditingController();
    String sectionType = initialSection ?? 'dialogue_1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.headphones, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  posX != null
                      ? LanguageService.instance.trText(ne: '📌 हेडफोन आइकनमा अडियो बटन पिन गर्नुहोस्', en: '📌 Pin audio button on headphone icon', ko: '📌 헤드폰 아이콘에 오디오 버튼 핀 고정')
                      : LanguageService.instance.trText(ne: 'अध्याय $_selectedChapter नयाँ अडियो बटन थप्नुहोस्', en: 'Add new audio button for Chapter $_selectedChapter', ko: '제$_selectedChapter과 새 오디오 버튼 추가'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posX != null && posY != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'पिन गरिएको स्थान: X: ${(posX * 100).toStringAsFixed(1)}%, Y: ${(posY * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                Text(LanguageService.instance.trText(ne: 'अडियो बटनको लेबल र MP3 अडियो रोज्नुहोस्:', en: 'Choose Audio Button Label & MP3:', ko: '오디오 버튼 라벨 및 MP3 선택:'), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'बटनको नाम / लेबल (e.g. Track 15 वा 01)*', en: 'Button Name / Label (e.g. Track 15 or 01)*', ko: '버튼 이름 / 라벨 (예: Track 15 또는 01)*'),
                    hintText: 'Track 01',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: sectionType,
                  decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'खण्ड*', en: 'Section*', ko: '섹션*'), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'dialogue_1', child: Text(LanguageService.instance.trText(ne: '💬 संवाद १', en: '💬 Dialogue 1', ko: '💬 대화 1'))),
                    DropdownMenuItem(value: 'vocabulary', child: Text(LanguageService.instance.trText(ne: '📖 शब्दावली १', en: '📖 Vocabulary 1', ko: '📖 어휘 1'))),
                    DropdownMenuItem(value: 'dialogue_2', child: Text(LanguageService.instance.trText(ne: '🗣️ संवाद २', en: '🗣️ Dialogue 2', ko: '🗣️ 대화 2'))),
                    DropdownMenuItem(value: 'vocabulary_2', child: Text(LanguageService.instance.trText(ne: '📚 शब्दावली २', en: '📚 Vocabulary 2', ko: '📚 어휘 2'))),
                    DropdownMenuItem(value: 'pronunciation', child: Text(LanguageService.instance.trText(ne: '🔊 उच्चारण अभ्यास', en: '🔊 Pronunciation', ko: '🔊 발음'))),
                    DropdownMenuItem(value: 'listening', child: Text(LanguageService.instance.trText(ne: '🎧 सुन्ने अभ्यास १~५', en: '🎧 Listening Practice 1~5', ko: '🎧 듣기 1~5번'))),
                    DropdownMenuItem(value: 'extended', child: Text(LanguageService.instance.trText(ne: '📝 थप लिसनिङ अभ्यास', en: '📝 Extended Practice', ko: '📝 확장 연습'))),
                  ],
                  onChanged: (v) => setDialogState(() => sectionType = v!),
                ),
                const SizedBox(height: 14),

                // Direct MP3 upload button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () async {
                    final file = await FileUploadService.instance.pickAudioFile();
                    if (file != null) {
                      setDialogState(() {
                        audioUrlCtrl.text = file.bestUrl;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(audioUrlCtrl.text.isEmpty
                      ? LanguageService.instance.trText(ne: '📁 कम्प्युटर/मोबाइलबाट MP3 रोज्नुहोस्', en: '📁 Pick MP3 Audio from Device', ko: '📁 기기에서 MP3 오디오 선택')
                      : 'अडियो लोड भयो ✅ (${audioUrlCtrl.text.startsWith("data:") ? "Local File" : "URL"})'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: audioUrlCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'वा अडियो URL लिङ्क', en: 'Or Audio URL link', ko: '또는 오디오 URL 링크'),
                    hintText: 'https://hrd.go.kr/audio/ch${_selectedChapter}_01.mp3',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty || audioUrlCtrl.text.trim().isEmpty) return;

                final newTrack = BookAudioTrack(
                  id: 'track_${DateTime.now().millisecondsSinceEpoch}_${labelCtrl.text.trim().hashCode}',
                  chapterNo: _selectedChapter,
                  label: labelCtrl.text.trim(),
                  sectionType: sectionType,
                  audioUrl: audioUrlCtrl.text.trim(),
                  posX: posX,
                  posY: posY,
                );

                final updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks)..add(newTrack);
                final updatedBook = StudyBook(
                  id: _currentBook.id,
                  title: _currentBook.title,
                  subtitle: _currentBook.subtitle,
                  editionType: _currentBook.editionType,
                  level: _currentBook.level,
                  chaptersCount: _currentBook.chaptersCount,
                  description: _currentBook.description,
                  pdfUrl: _currentBook.pdfUrl,
                  chapterPdfs: _currentBook.chapterPdfs,
                  highlightTopics: _currentBook.highlightTopics,
                  audioTracks: updatedTracks,
                  createdAt: _currentBook.createdAt,
                );

                _saveUpdatedBook(updatedBook);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(ne: 'अडियो बटन "${newTrack.label}" थपियो ✅', en: 'Audio button "${newTrack.label}" added ✅', ko: '오디오 버튼 "${newTrack.label}" 추가됨 ✅')),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'अडियो बटन सुरक्षित गर्नुहोस्', en: 'Save Audio Button', ko: '오디오 버튼 저장')),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTrack(BookAudioTrack track) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LanguageService.instance.trText(ne: 'अडियो बटन मेटाउने?', en: 'Delete Audio Button?', ko: '오디오 버튼 삭제?')),
        content: Text(LanguageService.instance.trText(ne: 'के तपाईं "${track.label}" अडियो बटन यस पुस्तकबाट हटाउन निश्चित हुनुहुन्छ?', en: 'Are you sure you want to remove audio button "${track.label}"?', ko: '정말 "${track.label}" 오디오 버튼을 삭제하시겠습니까?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks)
                ..removeWhere((t) => t.id == track.id);
              final updatedBook = StudyBook(
                id: _currentBook.id,
                title: _currentBook.title,
                subtitle: _currentBook.subtitle,
                editionType: _currentBook.editionType,
                level: _currentBook.level,
                chaptersCount: _currentBook.chaptersCount,
                description: _currentBook.description,
                pdfUrl: _currentBook.pdfUrl,
                chapterPdfs: _currentBook.chapterPdfs,
                highlightTopics: _currentBook.highlightTopics,
                audioTracks: updatedTracks,
                createdAt: _currentBook.createdAt,
              );
              _saveUpdatedBook(updatedBook);
              AudioPlaybackService.instance.stop();
              Navigator.pop(ctx);
            },
            child: Text(LanguageService.instance.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final chapterTracks = _chapterTracks;

        return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentBook.localizedTitle(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(
              '${_currentBook.editionType} • ' + LanguageService.instance.trText(ne: 'अध्याय $_selectedChapter (${chapterTracks.length} वटा अडियो बटन)', en: 'Chapter $_selectedChapter (${chapterTracks.length} Audio Buttons)', ko: '제$_selectedChapter과 (${chapterTracks.length}개 오디오 버튼)'),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          // Upload PDF/Page Button
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20),
            tooltip: LanguageService.instance.trText(ne: 'यस च्याप्टरको PDF वा पृष्ठ फोटो अपलोड गर्नुहोस्', en: 'Upload PDF or page photo for this chapter', ko: '이 과의 PDF 또는 페이지 사진 업로드'),
            onPressed: _uploadChapterPageDialog,
          ),
          // Add Audio Track Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () => _openAddTrackDialog(),
            icon: const Icon(Icons.add_circle, size: 15),
            label: Text(LanguageService.instance.trText(ne: '➕ अडियो बटन', en: '➕ Audio Button', ko: '➕ 오디오 버튼'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 6),
                    const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildGlobalNowPlayingBar(),
      body: Column(
        children: [
          // 1. Chapter Nav & Mode Toggle Ribbon
          _buildChapterNavRibbon(),

          // 2. All Chapter Audio Quick Ribbon (Displays all buttons horizontally)
          _buildAllTracksQuickRibbon(chapterTracks),

          // 3. Main View: PDF Canvas with Pinning OR Structured Reader View
          Expanded(
            child: _isPdfMode
                ? _buildPdfCanvasView(chapterTracks)
                : _buildStructuredReaderView(chapterTracks),
          ),
        ],
      ),
    );
      },
    );
  }

  // 1. Chapter Nav & Mode Toggle Ribbon
  Widget _buildChapterNavRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Chapter Dropdown
          Row(
            children: [
              Text(LanguageService.instance.trText(ne: 'पाठ:', en: 'Lesson:', ko: '과:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedChapter,
                isDense: true,
                items: List.generate(_currentBook.chaptersCount, (i) {
                  final ch = i + 1;
                  final count = _currentBook.audioTracks.where((t) => t.chapterNo == ch).length;
                  return DropdownMenuItem(
                    value: ch,
                    child: Text(LanguageService.instance.trText(ne: 'अध्याय $ch ${count > 0 ? "($count अडियो)" : ""}', en: 'Chapter $ch ${count > 0 ? "($count Audio)" : ""}', ko: '제$ch과 ${count > 0 ? "($count 오디오)" : ""}')),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    AudioPlaybackService.instance.stop();
                    setState(() {
                      _selectedChapter = val;
                    });
                  }
                },
              ),
            ],
          ),

          // View Mode Switcher: PDF Canvas vs Structured
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isPdfMode = true),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: _isPdfMode ? const Color(0xFF1E3A8A) : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 14, color: _isPdfMode ? Colors.white : Colors.black87),
                            const SizedBox(width: 4),
                            Text(
                              LanguageService.instance.trText(ne: '📄 PDF क्यानभास', en: '📄 PDF Canvas', ko: '📄 PDF 캔버스'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isPdfMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isPdfMode = false),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: !_isPdfMode ? const Color(0xFF1E3A8A) : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(Icons.menu_book, size: 14, color: !_isPdfMode ? Colors.white : Colors.black87),
                            const SizedBox(width: 4),
                            Text(
                              LanguageService.instance.trText(ne: '📖 डिजिटल पाठ', en: '📖 Digital Reader', ko: '📖 디지털 본문'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_isPdfMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Prev / Next Buttons
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: LanguageService.instance.trText(ne: 'अघिल्लो अध्याय', en: 'Previous Chapter', ko: '이전 과'),
                onPressed: _selectedChapter > 1
                    ? () => setState(() {
                          _selectedChapter--;
                          AudioPlaybackService.instance.stop();
                        })
                    : null,
              ),
              Text('$_selectedChapter / ${_currentBook.chaptersCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: LanguageService.instance.trText(ne: 'अर्को अध्याय', en: 'Next Chapter', ko: '다음 과'),
                onPressed: _selectedChapter < _currentBook.chaptersCount
                    ? () => setState(() {
                          _selectedChapter++;
                          AudioPlaybackService.instance.stop();
                        })
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. All Chapter Audio Quick Ribbon
  Widget _buildAllTracksQuickRibbon(List<BookAudioTrack> tracks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.queue_music, size: 16, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 6),
            Text(
              'यस पाठका ${tracks.length} वटा बटनहरू:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            ...tracks.map((track) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ExpandableAudioTimelineButton(
                  track: track,
                  onLongPress: () => _deleteTrack(track),
                ),
              );
            }),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFEA580C), size: 18),
              tooltip: LanguageService.instance.trText(ne: 'नयाँ बटन थप्नुहोस्', en: 'Add New Button', ko: '새 버튼 추가'),
              onPressed: () => _openAddTrackDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // VIEW MODE 1: PDF CANVAS WITH DIRECT AUDIO PINNING ON HEADPHONES
  // -------------------------------------------------------------
  Widget _buildPdfCanvasView(List<BookAudioTrack> tracks) {
    final chapterPdf = _currentBook.chapterPdfs['$_selectedChapter'] ??
        (_currentBook.pdfUrl.isNotEmpty ? _currentBook.pdfUrl : null);

    return Column(
      children: [
        // Pin Mode Control Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: _isPinningMode ? Colors.amber.shade100 : Colors.blue.shade50,
          child: Row(
            children: [
              Icon(
                _isPinningMode ? Icons.edit_location_alt : Icons.touch_app,
                size: 16,
                color: _isPinningMode ? Colors.amber.shade900 : const Color(0xFF1E3A8A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isPinningMode
                      ? LanguageService.instance.trText(ne: '📌 पिन मोड सक्रिय छ: पृष्ठमा जहाँ हेडफोनको आइकन छ, त्यहीँ ट्याप गरेर नयाँ बटन राख्नुहोस्!', en: '📌 Pin mode active: Tap where the headphone icon is on the page to place button!', ko: '📌 핀 모드 활성화: 페이지 내 헤드폰 아이콘 위치를 탭하여 버튼을 배치하세요!')
                      : LanguageService.instance.trText(ne: '💡 हेडफोन आइकनमा ट्याप गरेर सिधै अडियो सुन्नुहोस्। नयाँ बटन राख्न दायाँपट्टिको "पिन मोड" थिच्नुहोस्।', en: '💡 Tap headphone icons to listen audio. Tap "Pin Mode" on the right to add new buttons.', ko: '💡 헤드폰 아이콘을 탭하여 오디오를 재생하세요. 우측 "핀 모드"로 새 버튼을 추가할 수 있습니다.'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isPinningMode ? Colors.amber.shade900 : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPinningMode ? Colors.amber.shade800 : const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () {
                  setState(() {
                    _isPinningMode = !_isPinningMode;
                  });
                },
                icon: Icon(_isPinningMode ? Icons.check : Icons.push_pin, size: 14),
                label: Text(
                  _isPinningMode ? LanguageService.instance.trText(ne: 'पिनिङ पूरा भयो ✅', en: 'Pinning Complete ✅', ko: '핀 고정 완료 ✅') : LanguageService.instance.trText(ne: '📌 हेडफोनमा बटन पिन गर्नुहोस्', en: '📌 Pin Button on Headphone', ko: '📌 헤드폰에 버튼 핀 고정'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Interactive PDF / Canvas with Pinned Audio Buttons
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(40),
            minScale: 0.6,
            maxScale: 3.0,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double canvasWidth = 820.0;
                    const double canvasHeight = 1160.0;

                    return GestureDetector(
                      onTapUp: _isPinningMode
                          ? (details) {
                              final posX = (details.localPosition.dx / canvasWidth).clamp(0.02, 0.90);
                              final posY = (details.localPosition.dy / canvasHeight).clamp(0.02, 0.95);
                              _openAddTrackDialog(posX: posX, posY: posY);
                            }
                          : null,
                      child: Container(
                        width: canvasWidth,
                        height: canvasHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                          ],
                          border: Border.all(
                            color: _isPinningMode ? Colors.amber.shade600 : Colors.grey.shade300,
                            width: _isPinningMode ? 2.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 1. Background Content: Either uploaded PDF/Image or Official Textbook Template
                            Positioned.fill(
                              child: chapterPdf != null && chapterPdf.isNotEmpty
                                  ? _buildUploadedPdfBackground(chapterPdf)
                                  : _buildDefaultTextbookCanvas(),
                            ),

                            // 2. All Pinned Audio Buttons placed exactly at posX / posY on the PDF
                            ...tracks.where((t) => t.posX != null && t.posY != null).map((track) {
                              final left = track.posX! * canvasWidth;
                              final top = track.posY! * canvasHeight;

                              return Positioned(
                                left: left,
                                top: top,
                                child: ExpandableAudioTimelineButton(
                                  track: track,
                                  isPinned: true,
                                  onLongPress: () => _deleteTrack(track),
                                ),
                              );
                            }),

                            // 3. Pin Mode Helper Overlay
                            if (_isPinningMode)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade900,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '📌 क्लिक गरेर हेडफोन आइकनमा बटन राख्नुहोस्',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedPdfBackground(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64Part = url.contains(',') ? url.split(',')[1] : url;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildDefaultTextbookCanvas(),
      );
    }
    return _buildDefaultTextbookCanvas();
  }

  /// Official Korean EPS-TOPIK Textbook Aesthetic Template
  Widget _buildDefaultTextbookCanvas() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(4)),
                    child: Text('제$_selectedChapter과', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedChapter == 1
                        ? '안녕하세요'
                        : (_selectedChapter == 6 ? '저는 투안입니다' : '한국어 표준교재 제$_selectedChapter과'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _uploadChapterPageDialog,
                icon: const Icon(Icons.upload, size: 14),
                label: Text(LanguageService.instance.trText(ne: '📄 यस पृष्ठको PDF अपलोड गर्नुहोस्', en: '📄 Upload PDF for this page', ko: '📄 이 페이지 PDF 업로드'), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.5),

          // Dialogue 1 Section with printed Headphone Icon
          _buildCanvasSectionBox(
            title: LanguageService.instance.trText(ne: 'संवाद १', en: 'Dialogue 1', ko: '대화 1'),
            iconLabel: 'Track 01',
            color: const Color(0xFF1E3A8A),
            content: [
              _buildCanvasBubble('투안', '안녕하세요? 저는 투안입니다.', 'नमस्ते? म थुवान हुँ।'),
              _buildCanvasBubble('민수', '안녕하세요? 저는 이민수입니다.', 'नमस्ते? म इ-मिन्सु हुँ।'),
              _buildCanvasBubble('투안', '어느 나라 사람입니까?', 'तपाईं कुन देशको मान्छे हुनुहुन्छ?'),
              _buildCanvasBubble('민수', '한국 사람입니다. 만나서 반갑습니다.', 'म कोरियन नागरिक हुँ। भेटेर खुसी लाग्यो।'),
            ],
          ),
          const SizedBox(height: 18),

          // Vocabulary 1 Section with printed Headphone Icon
          _buildCanvasSectionBox(
            title: '어휘 1 (शब्दावली १) : 나라 (देशहरू)',
            iconLabel: 'Track 02',
            color: const Color(0xFFB45309),
            content: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  _VocabChip(word: '네팔', nepali: 'नेपाल', flag: '🇳🇵'),
                  _VocabChip(word: '한국', nepali: 'कोरिया', flag: '🇰🇷'),
                  _VocabChip(word: '베트남', nepali: 'भियतनाम', flag: '🇻🇳'),
                  _VocabChip(word: '미얀마', nepali: 'म्यानमार', flag: '🇲🇲'),
                  _VocabChip(word: '스리랑카', nepali: 'श्रीलंका', flag: '🇱🇰'),
                  _VocabChip(word: '태국', nepali: 'थाइल्यान्ड', flag: '🇹🇭'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Dialogue 2 Section with printed Headphone Icon
          _buildCanvasSectionBox(
            title: LanguageService.instance.trText(ne: 'संवाद २', en: 'Dialogue 2', ko: '대화 2'),
            iconLabel: 'Track 03',
            color: const Color(0xFF15803D),
            content: [
              _buildCanvasBubble('투안', '저는 회사원입니다.', 'म कम्पनी कर्मचारी हुँ।'),
              _buildCanvasBubble('준석', '당신은 학생입니까?', 'तपाईं विद्यार्थी हुनुहुन्छ?'),
              _buildCanvasBubble('투안', '아니요, 저는 학생이 아닙니다.', 'होइन, म विद्यार्थी होइन।'),
            ],
          ),
          const SizedBox(height: 18),

          // Listening Section with printed Headphone Icon
          _buildCanvasSectionBox(
            title: LanguageService.instance.trText(ne: 'सुन्ने अभ्यास १~५', en: 'Listening Practice 1~5', ko: '듣기 연습 1~5'),
            iconLabel: 'Track 04',
            color: const Color(0xFFC2410C),
            content: const [
              Text('[1~3] 들은 것을 고르십시오 (सुनेको कुरा छान्नुहोस्):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 4),
              Text('1. ① 한국   ② 네팔   ③ 베트남   ④ 미얀마', style: TextStyle(fontSize: 12)),
              Text('2. ① 교사   ② 의사   ③ 회사원   ④ 농부', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasSectionBox({
    required String title,
    required String iconLabel,
    required Color color,
    required List<Widget> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
              const Spacer(),
              // Printed headphone indicator on standard textbook
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headphones, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(iconLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...content,
        ],
      ),
    );
  }

  Widget _buildCanvasBubble(String speaker, String korean, String nepali) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(speaker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(korean, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text(nepali, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // VIEW MODE 2: STRUCTURED DIGITAL READER VIEW
  // -------------------------------------------------------------
  Widget _buildStructuredReaderView(List<BookAudioTrack> chapterTracks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(4)),
                      child: Text('제$_selectedChapter과', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                      child: Text(LanguageService.instance.trText(ne: '🎧 ${chapterTracks.length} वटा अडियो बटनहरू उपलब्ध', en: '🎧 ${chapterTracks.length} Audio Buttons Available', ko: '🎧 ${chapterTracks.length}개 오디오 버튼 사용 가능'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedChapter == 1
                      ? LanguageService.instance.isEnglish ? '안녕하세요 (Hello)' : (LanguageService.instance.isKorean ? '안녕하세요' : '안녕하세요 (नमस्ते)')
                      : (_selectedChapter == 6 ? '저는 투안입니다 (म थुवान हुँ)' : '제$_selectedChapter과: 한국어 표준교재'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  '학습 목표 (सिकाइ उद्देश्य): 인삿말 및 기본 어휘 익히기 • 직업과 국적 묻고 대답하기',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
                ),
                const Divider(height: 28, thickness: 1.5),

                // Section: Dialogue 1
                _buildStructuredSectionBox(
                  title: LanguageService.instance.trText(ne: 'संवाद १', en: 'Dialogue 1', ko: '대화 1'),
                  icon: Icons.forum,
                  sectionType: 'dialogue_1',
                  themeColor: const Color(0xFF1E3A8A),
                  bgColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  tracks: chapterTracks.where((t) => t.sectionType == 'dialogue_1').toList(),
                  child: Column(
                    children: [
                      _buildCanvasBubble('투안', '안녕하세요? 저는 투안입니다.', 'नमस्ते? म थुवान हुँ।'),
                      _buildCanvasBubble('민수', '안녕하세요? 저는 이민수입니다.', 'नमस्ते? म इ-मिन्सु हुँ।'),
                      _buildCanvasBubble('투안', '어느 나라 사람입니까?', 'कुन देशको मान्छे हुनुहुन्छ?'),
                      _buildCanvasBubble('민수', '한국 사람입니다. 만나서 반갑습니다.', 'म कोरियन नागरिक हुँ। भेटेर खुसी लाग्यो।'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Vocabulary 1
                _buildStructuredSectionBox(
                  title: '어휘 1 (शब्दावली १): 나라 (देशहरू)',
                  icon: Icons.translate,
                  sectionType: 'vocabulary',
                  themeColor: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  tracks: chapterTracks.where((t) => t.sectionType == 'vocabulary').toList(),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: const [
                      _VocabChip(word: '네팔', nepali: 'नेपाल', flag: '🇳🇵'),
                      _VocabChip(word: '한국', nepali: 'कोरिया', flag: '🇰🇷'),
                      _VocabChip(word: '베트남', nepali: 'भियतनाम', flag: '🇻🇳'),
                      _VocabChip(word: '미얀마', nepali: 'म्यानमार', flag: '🇲🇲'),
                      _VocabChip(word: '스리랑카', nepali: 'श्रीलंका', flag: '🇱🇰'),
                      _VocabChip(word: '태국', nepali: 'थाइल्यान्ड', flag: '🇹🇭'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Dialogue 2
                _buildStructuredSectionBox(
                  title: LanguageService.instance.trText(ne: 'संवाद २', en: 'Dialogue 2', ko: '대화 2'),
                  icon: Icons.record_voice_over,
                  sectionType: 'dialogue_2',
                  themeColor: const Color(0xFF15803D),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  tracks: chapterTracks.where((t) => t.sectionType == 'dialogue_2').toList(),
                  child: Column(
                    children: [
                      _buildCanvasBubble('투안', '저는 회사원입니다.', 'म कम्पनी कर्मचारी हुँ।'),
                      _buildCanvasBubble('준석', '당신은 학생입니까?', 'तपाईं विद्यार्थी हुनुहुन्छ?'),
                      _buildCanvasBubble('투안', '아니요, 저는 학생이 아닙니다.', 'होइन, म विद्यार्थी होइन।'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Pronunciation
                _buildStructuredSectionBox(
                  title: LanguageService.instance.isEnglish ? 'Pronunciation Practice' : (LanguageService.instance.isKorean ? '발음 연습' : 'उच्चारण अभ्यास'),
                  icon: Icons.graphic_eq,
                  sectionType: 'pronunciation',
                  themeColor: const Color(0xFF6D28D9),
                  bgColor: const Color(0xFFF5F3FF),
                  borderColor: const Color(0xFFDDD6FE),
                  tracks: chapterTracks.where((t) => t.sectionType == 'pronunciation').toList(),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• 받침 ध्वनि नियम: ㄱ, ㄷ, ㅂ पछाडि आउने व्यञ्जन वर्णको उच्चारण कडा हुन्छ।', style: TextStyle(fontSize: 13, height: 1.4)),
                      SizedBox(height: 4),
                      Text('• उदाहरण: 국적 [국쩍], 한국 사람 [한국 सा-राम]', style: TextStyle(fontSize: 13, color: Color(0xFF6D28D9), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Listening
                _buildStructuredSectionBox(
                  title: 'EPS-TOPIK 듣기 (Listening Practice 1~5)',
                  icon: Icons.headphones,
                  sectionType: 'listening',
                  themeColor: const Color(0xFFC2410C),
                  bgColor: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFED7AA),
                  tracks: chapterTracks.where((t) => t.sectionType == 'listening').toList(),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('[1~3] 들은 것을 고르십시오 (सुनेको कुरा छान्नुहोस्):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 6),
                      Text('1. ① 한국   ② 네팔   ③ 베트남   ④ 미얀마', style: TextStyle(fontSize: 13, height: 1.5)),
                      Text('2. ① 교사   ② 의사   ③ 회사원   ④ 농부', style: TextStyle(fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStructuredSectionBox({
    required String title,
    required IconData icon,
    required String sectionType,
    required Color themeColor,
    required Color bgColor,
    required Color borderColor,
    required List<BookAudioTrack> tracks,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: themeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: themeColor)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                color: themeColor,
                tooltip: LanguageService.instance.trText(ne: 'यस खण्डमा अडियो बटन थप्नुहोस्', en: 'Add audio button to this section', ko: '이 섹션에 오디오 버튼 추가'),
                onPressed: () => _openAddTrackDialog(initialSection: sectionType),
              ),
            ],
          ),

          // Render Expandable Audio Buttons for this section
          if (tracks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tracks.map((track) {
                return ExpandableAudioTimelineButton(
                  track: track,
                  onLongPress: () => _deleteTrack(track),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Floating Now-Playing Mini-Bar at bottom
  Widget? _buildGlobalNowPlayingBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: AudioPlaybackService.instance.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        if (!isPlaying) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0F172A),
          child: SafeArea(
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LanguageService.instance.trText(ne: 'अडियो बजिरहेको छ 🔊 (बटन थिचेर टाइमलाइन हेर्न वा रोक्न सक्नुहुन्छ)', en: 'Audio playing 🔊 (Tap button to view timeline or stop)', ko: '오디오 재생 중 🔊 (버튼을 눌러 타임라인을 확인하거나 정지)'),
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 24),
                  tooltip: LanguageService.instance.trText(ne: 'अडियो रोक्नुहोस्', en: 'Stop audio', ko: '오디오 중지'),
                  onPressed: () => AudioPlaybackService.instance.stop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Expandable Audio Timeline Button matching user's exact specification:
/// 1. Compact small button with headphone icon 🎧 and track label.
/// 2. Clicking expands smoothly into a live audio timeline with progress slider, elapsed/total time.
/// 3. Clicking again (or clicking stop) stops playback and collapses back to the compact headphone button.
class ExpandableAudioTimelineButton extends StatelessWidget {
  final BookAudioTrack track;
  final VoidCallback? onLongPress;
  final bool isPinned;

  const ExpandableAudioTimelineButton({
    super.key,
    required this.track,
    this.onLongPress,
    this.isPinned = false,
  });

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AudioPlaybackService.instance.currentAudioSourceNotifier,
      builder: (context, currentSource, _) {
        final isPlayingThis = currentSource == track.audioUrl;

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: isPlayingThis
              ? _buildExpandedTimeline(context)
              : _buildCompactButton(context),
        );
      },
    );
  }

  /// 1. Small Compact Headphone Button (सानो अडियो बटन)
  Widget _buildCompactButton(BuildContext context) {
    return Tooltip(
      message: LanguageService.instance.trText(ne: 'अडियो सुन्न थिच्नुहोस् (TimeLine खुल्नेछ) • हटाउन लङ-प्रेस', en: 'Tap to listen audio (Opens timeline) • Long press to delete', ko: '오디오 듣기 (타임라인 열림) • 길게 눌러 삭제'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioPlaybackService.instance.playAudioUrl(track.audioUrl);
          },
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.5), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1.5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.headphones, size: 13, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 4),
                Text(
                  track.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFFEA580C)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Expanded Timeline with Live Slider and Stop/Collapse Button (टाइमलाइन देखाउने)
  Widget _buildExpandedTimeline(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFF0F172A),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEA580C), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stop & Collapse Button (फेरि थिचेपछि रोकिने र बन्द हुने)
            InkWell(
              onTap: () => AudioPlaybackService.instance.stop(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop_rounded, size: 15, color: Colors.white),
              ),
            ),
            const SizedBox(width: 6),

            // Track Label
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 75),
              child: Text(
                track.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
              ),
            ),
            const SizedBox(width: 4),

            // Interactive Live Slider Timeline
            Expanded(
              child: ValueListenableBuilder<Duration>(
                valueListenable: AudioPlaybackService.instance.positionNotifier,
                builder: (context, pos, _) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: AudioPlaybackService.instance.durationNotifier,
                    builder: (context, dur, _) {
                      final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
                      final currentMs = pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2.5,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                              activeTrackColor: const Color(0xFFEA580C),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: currentMs,
                              min: 0.0,
                              max: maxMs,
                              onChanged: (val) {
                                AudioPlaybackService.instance.seek(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTime(pos), style: const TextStyle(fontSize: 8.5, color: Colors.white70)),
                                Text(_formatTime(dur), style: const TextStyle(fontSize: 8.5, color: Colors.white38)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Close Icon
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: LanguageService.instance.trText(ne: 'रोक्नुहोस् र बन्द गर्नुहोस्', en: 'Stop and close', ko: '중지 및 닫기'),
              onPressed: () => AudioPlaybackService.instance.stop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabChip extends StatelessWidget {
  final String word;
  final String nepali;
  final String flag;

  const _VocabChip({required this.word, required this.nepali, required this.flag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(nepali, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
