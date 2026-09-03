import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/study_material_service.dart';

/// Interactive Textbook e-Book Reader supporting LARGE NUMBERS OF AUDIO BUTTONS
/// Designed specifically for EPS-TOPIK textbooks with dozens to hundreds of tracks per book.
class BookReaderScreen extends StatefulWidget {
  final StudyBook book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  int _selectedChapter = 1;
  String? _currentlyPlayingTrackId;
  BookAudioTrack? _currentlyPlayingTrack;
  double _audioSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    AudioPlaybackService.instance.currentAudioSourceNotifier.addListener(_onAudioSourceChanged);
  }

  void _onAudioSourceChanged() {
    if (!mounted) return;
    if (AudioPlaybackService.instance.currentSource == null) {
      if (_currentlyPlayingTrackId != null) {
        setState(() {
          _currentlyPlayingTrackId = null;
          _currentlyPlayingTrack = null;
        });
      }
    }
  }

  @override
  void dispose() {
    AudioPlaybackService.instance.currentAudioSourceNotifier.removeListener(_onAudioSourceChanged);
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  void _togglePlayTrack(BookAudioTrack track) {
    if (_currentlyPlayingTrackId == track.id) {
      AudioPlaybackService.instance.stop();
      setState(() {
        _currentlyPlayingTrackId = null;
        _currentlyPlayingTrack = null;
      });
    } else {
      // Strictly stop previous audio before starting new track
      AudioPlaybackService.instance.stop();
      setState(() {
        _currentlyPlayingTrackId = track.id;
        _currentlyPlayingTrack = track;
      });
      AudioPlaybackService.instance.playAudioUrl(track.audioUrl);
    }
  }

  void _openAddTrackDialog({String? initialSection}) {
    final chapterTracks = widget.book.audioTracks.where((t) => t.chapterNo == _selectedChapter).toList();
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
              const Icon(Icons.audio_file, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text('제$_selectedChapter과 नयाँ अडियो बटन थप्नुहोस्', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('एउटै पिडिएफ/किताबमा जतिवटा पनि अडियो बटनहरू थप्न सकिन्छ:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'बटनको नाम / लेबल (e.g. Track 15, Track 24 वा 01)*',
                    hintText: 'Track 01',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sectionType,
                  decoration: const InputDecoration(labelText: 'खण्ड / बटन रहने ठाउँ (Section)*', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'dialogue_1', child: Text('💬 대화 1 (संवाद १)')),
                    DropdownMenuItem(value: 'vocabulary', child: Text('📖 어휘 1 (शब्दावली १)')),
                    DropdownMenuItem(value: 'dialogue_2', child: Text('🗣️ 대화 2 (संवाद २)')),
                    DropdownMenuItem(value: 'vocabulary_2', child: Text('📚 어휘 2 (शब्दावली २)')),
                    DropdownMenuItem(value: 'pronunciation', child: Text('🔊 발음 (उच्चारण अभ्यास)')),
                    DropdownMenuItem(value: 'listening', child: Text('🎧 듣기 1~5번 (सुन्ने अभ्यास)')),
                    DropdownMenuItem(value: 'extended', child: Text('📝 확장 연습 (थप लिसनिङ अभ्यास)')),
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
                        audioUrlCtrl.text = file.dataUrl;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(audioUrlCtrl.text.isEmpty
                      ? '📁 कम्प्युटर/मोबाइलबाट MP3 रोज्नुहोस्'
                      : 'अडियो लोड भयो ✅ (${audioUrlCtrl.text.startsWith("data:") ? "Local File" : "URL"})'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: audioUrlCtrl,
                  decoration: InputDecoration(
                    labelText: 'वा अडियो URL लिङ्क (Optional)',
                    hintText: 'https://hrd.go.kr/audio/ch${_selectedChapter}_01.mp3',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty || audioUrlCtrl.text.trim().isEmpty) return;

                final newTrack = BookAudioTrack(
                  id: 'track_${DateTime.now().millisecondsSinceEpoch}_${labelCtrl.text.trim()}',
                  chapterNo: _selectedChapter,
                  label: labelCtrl.text.trim(),
                  sectionType: sectionType,
                  audioUrl: audioUrlCtrl.text.trim(),
                );

                // Add to book in service
                final allBooks = StudyMaterialService.instance.getAllBooks();
                final bIndex = allBooks.indexWhere((b) => b.id == widget.book.id);
                if (bIndex != -1) {
                  final updatedTracks = List<BookAudioTrack>.from(allBooks[bIndex].audioTracks)..add(newTrack);
                  final updatedBook = StudyBook(
                    id: widget.book.id,
                    title: widget.book.title,
                    subtitle: widget.book.subtitle,
                    editionType: widget.book.editionType,
                    level: widget.book.level,
                    chaptersCount: widget.book.chaptersCount,
                    description: widget.book.description,
                    pdfUrl: widget.book.pdfUrl,
                    highlightTopics: widget.book.highlightTopics,
                    audioTracks: updatedTracks,
                    createdAt: widget.book.createdAt,
                  );
                  StudyMaterialService.instance.addBook(updatedBook);
                }

                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('बटन थप्नुहोस् (Save Track Button)'),
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
        title: const Text('अडियो बटन मेटाउने?'),
        content: Text('के तपाईं "${track.label}" अडियो बटन यस पुस्तकबाट हटाउन निश्चित हुनुहुन्छ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final allBooks = StudyMaterialService.instance.getAllBooks();
              final bIndex = allBooks.indexWhere((b) => b.id == widget.book.id);
              if (bIndex != -1) {
                final updatedTracks = List<BookAudioTrack>.from(allBooks[bIndex].audioTracks)
                  ..removeWhere((t) => t.id == track.id);
                final updatedBook = StudyBook(
                  id: widget.book.id,
                  title: widget.book.title,
                  subtitle: widget.book.subtitle,
                  editionType: widget.book.editionType,
                  level: widget.book.level,
                  chaptersCount: widget.book.chaptersCount,
                  description: widget.book.description,
                  pdfUrl: widget.book.pdfUrl,
                  highlightTopics: widget.book.highlightTopics,
                  audioTracks: updatedTracks,
                  createdAt: widget.book.createdAt,
                );
                StudyMaterialService.instance.addBook(updatedBook);
              }
              Navigator.pop(ctx);
              setState(() {
                if (_currentlyPlayingTrackId == track.id) {
                  AudioPlaybackService.instance.stop();
                  _currentlyPlayingTrackId = null;
                  _currentlyPlayingTrack = null;
                }
              });
            },
            child: const Text('मेटाउनुहोस् (Delete)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterTracks = widget.book.audioTracks.where((t) => t.chapterNo == _selectedChapter).toList();

    // Default tracks if none added yet for this chapter
    if (chapterTracks.isEmpty) {
      chapterTracks.addAll([
        BookAudioTrack(
          id: 'def_d1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 01 (대화 1)',
          sectionType: 'dialogue_1',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=안녕하세요저는투안입니다',
        ),
        BookAudioTrack(
          id: 'def_v1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 02 (어휘 1)',
          sectionType: 'vocabulary',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=네팔한국베트남미얀마',
        ),
        BookAudioTrack(
          id: 'def_d2_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 03 (대화 2)',
          sectionType: 'dialogue_2',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=저는회사원입니다',
        ),
        BookAudioTrack(
          id: 'def_p1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 04 (발음)',
          sectionType: 'pronunciation',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=국적직업인사말',
        ),
        BookAudioTrack(
          id: 'def_l1_$_selectedChapter',
          chapterNo: _selectedChapter,
          label: 'Track 05 (듣기 1~5번)',
          sectionType: 'listening',
          audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=들은것을고르십시오नेपाल사람입니다',
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.book.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${widget.book.editionType} • 제$_selectedChapter과 (${chapterTracks.length} वटा अडियो बटनहरू)', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _openAddTrackDialog(),
            icon: const Icon(Icons.add_circle, size: 16),
            label: const Text('➕ नयाँ अडियो बटन थप्नुहोस्', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _currentlyPlayingTrack != null ? _buildNowPlayingBottomBar() : null,
      body: Column(
        children: [
          // 1. Chapter Selector & Prev/Next Ribbon
          _buildChapterNavRibbon(),

          // 2. All Chapter Audio Quick Ribbon (बटन धेरै भएको बेला एकै ठाउँबाट सजिलै चलाउन)
          _buildAllTracksQuickRibbon(chapterTracks),

          // 3. Main Textbook Page with multiple inline audio buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChapterHeader(chapterTracks.length),
                        const Divider(height: 28, thickness: 1.5),

                        // Section: 대화 1 (Dialogue 1) - Can have multiple buttons
                        _buildDynamicSection(
                          title: '대화 1 (संवाद १)',
                          icon: Icons.forum,
                          sectionType: 'dialogue_1',
                          themeColor: const Color(0xFF1E3A8A),
                          bgColor: const Color(0xFFF8FAFC),
                          borderColor: const Color(0xFFE2E8F0),
                          tracks: chapterTracks.where((t) => t.sectionType == 'dialogue_1').toList(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogueBubble('투안', '안녕하세요? 저는 투안입니다.', 'नमस्ते? म थुवान हुँ।'),
                              const SizedBox(height: 8),
                              _buildDialogueBubble('민수', '안녕하세요? 저는 이민수입니다.', 'नमस्ते? म इ-मिन्सु हुँ।'),
                              const SizedBox(height: 8),
                              _buildDialogueBubble('투안', '어느 나라 사람입니까?', 'कुन देशको मान्छे हुनुहुन्छ?'),
                              const SizedBox(height: 8),
                              _buildDialogueBubble('민수', '한국 사람입니다. 만나서 반갑습니다.', 'म कोरियन नागरिक हुँ। भेटेर खुसी लाग्यो।'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Section: 어휘 1 (Vocabulary 1) - Can have multiple buttons
                        _buildDynamicSection(
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
                        const SizedBox(height: 22),

                        // Section: 대화 2 (Dialogue 2) - Can have multiple buttons
                        _buildDynamicSection(
                          title: '대화 2 (संवाद २)',
                          icon: Icons.record_voice_over,
                          sectionType: 'dialogue_2',
                          themeColor: const Color(0xFF15803D),
                          bgColor: const Color(0xFFF0FDF4),
                          borderColor: const Color(0xFFBBF7D0),
                          tracks: chapterTracks.where((t) => t.sectionType == 'dialogue_2').toList(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogueBubble('투안', '저는 회사원입니다.', 'म कम्पनी कर्मचारी हुँ।'),
                              const SizedBox(height: 8),
                              _buildDialogueBubble('준석', '당신은 학생입니까?', 'तपाईं विद्यार्थी हुनुहुन्छ?'),
                              const SizedBox(height: 8),
                              _buildDialogueBubble('투안', '아니요, 저는 학생이 아닙니다.', 'होइन, म विद्यार्थी होइन।'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Section: 발음 (Pronunciation) - Can have multiple buttons
                        _buildDynamicSection(
                          title: '발음 (उच्चारण अभ्यास & Pronunciation)',
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
                        const SizedBox(height: 22),

                        // Section: 듣기 평가 (Listening Exercises) - Can have multiple buttons
                        _buildDynamicSection(
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
                        const SizedBox(height: 22),

                        // Section: 확장 연습 (Extended Listening) - Can have multiple buttons
                        _buildDynamicSection(
                          title: '확장 연습 (थप सुन्ने अभ्यास - Extended Practice)',
                          icon: Icons.library_music,
                          sectionType: 'extended',
                          themeColor: const Color(0xFF0F766E),
                          bgColor: const Color(0xFFF0FDFA),
                          borderColor: const Color(0xFF99F6E4),
                          tracks: chapterTracks.where((t) => t.sectionType == 'extended').toList(),
                          child: const Text('थप अडियो सुनेर वास्तविक परीक्षा प्रश्नहरूको अभ्यास गर्नुहोस्।', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Chapter Nav Ribbon
  Widget _buildChapterNavRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('अध्याय (Chapter):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedChapter,
                isDense: true,
                items: List.generate(widget.book.chaptersCount, (i) {
                  final ch = i + 1;
                  final count = widget.book.audioTracks.where((t) => t.chapterNo == ch).length;
                  return DropdownMenuItem(
                    value: ch,
                    child: Text('제${ch}과: अध्याय $ch ${count > 0 ? "($count अडियो बटन)" : ""}'),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    AudioPlaybackService.instance.stop();
                    setState(() {
                      _selectedChapter = val;
                      _currentlyPlayingTrackId = null;
                      _currentlyPlayingTrack = null;
                    });
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'अघिल्लो अध्याय',
                onPressed: _selectedChapter > 1
                    ? () => setState(() {
                          _selectedChapter--;
                          AudioPlaybackService.instance.stop();
                          _currentlyPlayingTrackId = null;
                          _currentlyPlayingTrack = null;
                        })
                    : null,
              ),
              Text('$_selectedChapter / ${widget.book.chaptersCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'अर्को अध्याय',
                onPressed: _selectedChapter < widget.book.chaptersCount
                    ? () => setState(() {
                          _selectedChapter++;
                          AudioPlaybackService.instance.stop();
                          _currentlyPlayingTrackId = null;
                          _currentlyPlayingTrack = null;
                        })
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. All Chapter Audio Quick Ribbon (Displays all buttons horizontally scrollable)
  Widget _buildAllTracksQuickRibbon(List<BookAudioTrack> tracks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            Text('यस पाठका सबै ${tracks.length} वटा बटनहरू:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
            const SizedBox(width: 8),
            ...tracks.map((track) {
              final isPlaying = _currentlyPlayingTrackId == track.id;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InlineBookAudioButton(
                  label: track.label,
                  audioUrl: track.audioUrl,
                  isPlaying: isPlaying,
                  onTap: () => _togglePlayTrack(track),
                  onLongPress: () => _deleteTrack(track),
                ),
              );
            }),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFEA580C), size: 20),
              tooltip: 'नयाँ बटन थप्नुहोस्',
              onPressed: () => _openAddTrackDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Chapter Top Header
  Widget _buildChapterHeader(int trackCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: Text('🎧 $trackCount वटा अडियो बटनहरू उपलब्ध', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedChapter == 1
              ? '안녕하세요 (नमस्ते / Hello)'
              : (_selectedChapter == 6
                  ? '저는 투안입니다 (म थुवान हुँ)'
                  : '제$_selectedChapter과: 한국어 표준교재'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '학습 목표 (सिकाइ उद्देश्य): 인삿말 및 기본 어휘 익히기 • 직업과 국적 묻고 대답하기',
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // Dynamic Section that can contain ANY NUMBER of audio buttons
  Widget _buildDynamicSection({
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: themeColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: themeColor)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                color: themeColor,
                tooltip: 'यस खण्डमा थप अडियो बटन थप्नुहोस्',
                onPressed: () => _openAddTrackDialog(initialSection: sectionType),
              ),
            ],
          ),

          // Render ALL audio buttons belonging to this section as small matching inline buttons
          if (tracks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tracks.map((track) {
                final isPlaying = _currentlyPlayingTrackId == track.id;
                return InlineBookAudioButton(
                  label: track.label,
                  audioUrl: track.audioUrl,
                  isPlaying: isPlaying,
                  onTap: () => _togglePlayTrack(track),
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

  Widget _buildDialogueBubble(String speaker, String korean, String nepali) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(speaker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(korean, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text(nepali, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  // Floating Now-Playing Mini-Bar at the bottom
  Widget _buildNowPlayingBottomBar() {
    final track = _currentlyPlayingTrack!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xFFEA580C), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(track.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(4)),
                        child: const Text('बजिरहेको छ 🔊', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Text('अध्याय $_selectedChapter • बटन थिचेर बन्द गर्न वा गति परिवर्तन गर्न सकिन्छ', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 28),
              tooltip: 'अडियो रोक्नुहोस्',
              onPressed: () {
                AudioPlaybackService.instance.stop();
                setState(() {
                  _currentlyPlayingTrackId = null;
                  _currentlyPlayingTrack = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, elegant inline audio play button matching textbook typography
/// Fits directly within lines of text or beside headings
class InlineBookAudioButton extends StatelessWidget {
  final String label;
  final String audioUrl;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const InlineBookAudioButton({
    super.key,
    required this.label,
    required this.audioUrl,
    required this.isPlaying,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'थिचेर अडियो सुन्नुहोस् (हटाउन लङ-प्रेस गर्नुहोस्)',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: isPlaying ? const Color(0xFFEA580C) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPlaying ? const Color(0xFFEA580C) : const Color(0xFF1E3A8A).withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: isPlaying
                ? [BoxShadow(color: const Color(0xFFEA580C).withOpacity(0.35), blurRadius: 5, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 14,
                color: isPlaying ? Colors.white : const Color(0xFF1E3A8A),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: isPlaying ? Colors.white : const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
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
