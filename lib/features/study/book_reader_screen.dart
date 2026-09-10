import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/offline_download_service.dart';
import '../../core/widgets/pdf_viewer.dart';

/// Comprehensive Textbook & Interactive PDF Reader
/// Features:
/// 1. Book & Chapter Management: Add, Edit, Delete Book, Chapter Name, Chapter Number, PDF.
/// 2. Interactive Audio Player Buttons: Add, Edit, Delete, Pin/Move audio buttons with live seekable timeline slider.
/// 3. Uploaded PDF Viewer: Works 100% across Web & Mobile with native Blob viewer, image viewer, and digital reader fallback.
class BookReaderScreen extends StatefulWidget {
  final StudyBook book;
  final int initialChapter;

  const BookReaderScreen({super.key, required this.book, this.initialChapter = 1});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late StudyBook _currentBook;
  int _selectedChapter = 1;
  bool _isPdfMode = true; // Default to PDF / Textbook canvas view
  bool _isPinningMode = false; // Mode to tap and place audio buttons directly on headphone icons

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _selectedChapter = widget.initialChapter.clamp(1, widget.book.chaptersCount > 0 ? widget.book.chaptersCount : 1);
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
    CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
  }

  List<BookAudioTrack> get _chapterTracks {
    return _currentBook.audioTracks.where((t) => t.chapterNo == _selectedChapter).toList();
  }

  void _addDefaultTracksForChapter() {
    final newTracks = [
      BookAudioTrack(
        id: 'track_${DateTime.now().millisecondsSinceEpoch}_1',
        chapterNo: _selectedChapter,
        label: 'Track 01 (대화 1)',
        sectionType: 'dialogue_1',
        audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=안녕하세요저는투안입니다',
        posX: 0.15,
        posY: 0.28,
      ),
      BookAudioTrack(
        id: 'track_${DateTime.now().millisecondsSinceEpoch}_2',
        chapterNo: _selectedChapter,
        label: 'Track 02 (어휘 1)',
        sectionType: 'vocabulary',
        audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=네팔한국베트남미얀마',
        posX: 0.15,
        posY: 0.44,
      ),
      BookAudioTrack(
        id: 'track_${DateTime.now().millisecondsSinceEpoch}_3',
        chapterNo: _selectedChapter,
        label: 'Track 03 (대화 2)',
        sectionType: 'dialogue_2',
        audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=저는회사원입니다',
        posX: 0.15,
        posY: 0.60,
      ),
      BookAudioTrack(
        id: 'track_${DateTime.now().millisecondsSinceEpoch}_4',
        chapterNo: _selectedChapter,
        label: 'Track 04 (듣기 1~5)',
        sectionType: 'listening',
        audioUrl: 'https://translate.google.com/translate_tts?ie=UTF-8&tl=ko&client=tw-ob&q=들은것을고르십시오네팔사람입니다',
        posX: 0.15,
        posY: 0.78,
      ),
    ];
    final updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks)..addAll(newTracks);
    _saveUpdatedBook(_currentBook.copyWith(audioTracks: updatedTracks));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageService.instance.trText(
          ne: 'अध्याय $_selectedChapter का लागि डिफल्ट अडियो बटनहरू थपियो ✅',
          en: 'Default audio tracks added for Chapter $_selectedChapter ✅',
          ko: '제${_selectedChapter}과 기본 오디오 버튼 추가됨 ✅',
        )),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. BOOK MANAGEMENT (किताब सम्पादन तथा व्यवस्थापन)
  // -------------------------------------------------------------
  void _openEditBookDialog() {
    final titleCtrl = TextEditingController(text: _currentBook.title);
    final subtitleCtrl = TextEditingController(text: _currentBook.subtitle);
    final chapCtrl = TextEditingController(text: '${_currentBook.chaptersCount}');
    final pdfCtrl = TextEditingController(text: _currentBook.pdfUrl);
    final descCtrl = TextEditingController(text: _currentBook.description);
    String editionType = _currentBook.editionType;
    String _uploadStatus = '';
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: 'किताबको जानकारी सम्पादन गर्नुहोस्',
                    en: 'Edit Book Details',
                    ko: '교재 정보 수정',
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'किताबको नाम / शीर्षक*', en: 'Book Title*', ko: '교재 이름*'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'उपशीर्षक / विवरण', en: 'Subtitle', ko: '부제목'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: editionType,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'संस्करण (Edition)', en: 'Edition', ko: '판본'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: _currentBook.editionType, child: Text(_currentBook.editionType)),
                    DropdownMenuItem(value: 'नयाँ संस्करण (New 2024)', child: Text(LanguageService.instance.trText(ne: 'नयाँ संस्करण (New 2024)', en: 'New Edition (2024)', ko: '신규 개정판 (2024)'))),
                    DropdownMenuItem(value: 'पुरानो संस्करण (Old 2013)', child: Text(LanguageService.instance.trText(ne: 'पुरानो संस्करण (Old 2013)', en: 'Old Edition (2013)', ko: '클래식 구판 (2013)'))),
                    DropdownMenuItem(value: 'विशेष गाइड', child: Text(LanguageService.instance.trText(ne: 'विशेष गाइड', en: 'Special Guide', ko: '특수 가이드'))),
                  ].toSet().toList(),
                  onChanged: (v) => setDialogState(() => editionType = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: chapCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'जम्मा अध्याय संख्या', en: 'Total Chapters', ko: '총 단원 수'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Book PDF Upload & Management
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onPressed: _isUploading
                        ? null
                        : () async {
                            setDialogState(() {
                              _isUploading = true;
                              _uploadStatus = '⏳ PDF अपलोड हुँदैछ...';
                            });
                            final file = await FileUploadService.instance.pickPdfFile();
                            if (file != null) {
                              setDialogState(() {
                                pdfCtrl.text = file.bestUrl;
                                _uploadStatus = '✅ PDF सुरक्षित भयो (${file.formattedSize})';
                                _isUploading = false;
                              });
                            } else {
                              setDialogState(() {
                                _isUploading = false;
                                _uploadStatus = '';
                              });
                            }
                          },
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(LanguageService.instance.trText(ne: '📄 नयाँ PDF फाइल डिभाइसबाट रोज्नुहोस्', en: '📄 Pick PDF from Device', ko: '📄 기기에서 PDF 선택'), style: const TextStyle(fontSize: 11)),
                  ),
                ),
                if (_uploadStatus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_uploadStatus, style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pdfCtrl,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(ne: 'पुस्तक PDF लिङ्क', en: 'Book PDF Link', ko: '교재 PDF 링크'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (pdfCtrl.text.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'PDF हटाउनुहोस् (Remove PDF)',
                        onPressed: () {
                          setDialogState(() {
                            pdfCtrl.clear();
                            _uploadStatus = 'PDF हटाइयो';
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'विवरण', en: 'Description', ko: '설명'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                _confirmDeleteBookFromReader(ctx);
              },
              child: Text(LanguageService.instance.trText(ne: 'किताब मेटाउनुहोस्', en: 'Delete Book', ko: '교재 삭제')),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                final newTitle = titleCtrl.text.trim();
                if (newTitle.isEmpty) return;

                final updated = _currentBook.copyWith(
                  title: newTitle,
                  subtitle: subtitleCtrl.text.trim(),
                  editionType: editionType,
                  chaptersCount: int.tryParse(chapCtrl.text.trim()) ?? _currentBook.chaptersCount,
                  pdfUrl: pdfCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                _saveUpdatedBook(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'किताबको जानकारी अपडेट भयो ✅',
                      en: 'Book details updated ✅',
                      ko: '교재 정보가 수정되었습니다 ✅',
                    )),
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

  void _confirmDeleteBookFromReader(BuildContext dialogCtx) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LanguageService.instance.trText(ne: 'किताब मेटाउने?', en: 'Delete Book?', ko: '교재 삭제?')),
        content: Text(LanguageService.instance.trText(
          ne: 'के तपाईं "${_currentBook.title}" पुस्तक र यसका सबै च्याप्टर तथा अडियोहरू हटाउन निश्चित हुनुहुन्छ?',
          en: 'Are you sure you want to delete "${_currentBook.title}"?',
          ko: '정말 "${_currentBook.title}" 교재를 삭제하시겠습니까?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmCtx), child: Text(LanguageService.instance.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              StudyMaterialService.instance.deleteBook(_currentBook.id);
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogCtx);
              Navigator.pop(context); // Exit BookReaderScreen
            },
            child: Text(LanguageService.instance.tr('delete')),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. CHAPTER MANAGEMENT (च्याप्टर थप्ने, सम्पादन गर्ने, मेटाउने)
  // -------------------------------------------------------------
  void _openChapterManagerDialog({int? chapterToEdit}) {
    final targetCh = chapterToEdit ?? _selectedChapter;
    final currentTitle = _currentBook.getChapterTitle(targetCh);
    final chNumCtrl = TextEditingController(text: '$targetCh');
    final chTitleCtrl = TextEditingController(text: currentTitle);
    final chPdfCtrl = TextEditingController(text: _currentBook.chapterPdfs['$targetCh'] ?? '');
    String _uploadStatus = '';
    bool _isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.menu_book, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapterToEdit != null
                      ? LanguageService.instance.trText(
                          ne: 'अध्याय $targetCh सम्पादन गर्नुहोस्',
                          en: 'Edit Chapter $targetCh',
                          ko: '제${targetCh}과 수정',
                        )
                      : LanguageService.instance.trText(
                          ne: '➕ नयाँ अध्याय थप्नुहोस् / सम्पादन',
                          en: '➕ Add / Edit Chapter',
                          ko: '➕ 새 단원 추가 / 수정',
                        ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: chNumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(ne: 'च्याप्टर नं.*', en: 'Chapter No.*', ko: '단원 번호*'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: chTitleCtrl,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.trText(ne: 'च्याप्टरको नाम / शीर्षक*', en: 'Chapter Title / Name*', ko: '단원 제목 / 이름*'),
                          hintText: '안녕하세요 / 직장 생활',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Upload PDF or Image button
                Text(
                  LanguageService.instance.trText(
                    ne: 'यस च्याप्टरको PDF वा पृष्ठ फोटो:',
                    en: 'Chapter PDF or Page Image:',
                    ko: '이 단원의 PDF 또는 페이지 이미지:',
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onPressed: _isUploading
                            ? null
                            : () async {
                                setDialogState(() {
                                  _isUploading = true;
                                  _uploadStatus = '⏳ PDF अपलोड हुँदैछ...';
                                });
                                final file = await FileUploadService.instance.pickPdfFile();
                                if (file != null) {
                                  setDialogState(() {
                                    chPdfCtrl.text = file.bestUrl;
                                    _uploadStatus = '✅ PDF लोड भयो (${file.formattedSize})';
                                    _isUploading = false;
                                  });
                                } else {
                                  setDialogState(() {
                                    _isUploading = false;
                                    _uploadStatus = '';
                                  });
                                }
                              },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: Text(LanguageService.instance.trText(ne: '📄 PDF छान्नुहोस्', en: '📄 Pick PDF', ko: '📄 PDF 선택'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onPressed: _isUploading
                            ? null
                            : () async {
                                setDialogState(() {
                                  _isUploading = true;
                                  _uploadStatus = '⏳ फोटो अपलोड हुँदैछ...';
                                });
                                final file = await FileUploadService.instance.pickImageFile();
                                if (file != null) {
                                  setDialogState(() {
                                    chPdfCtrl.text = file.bestUrl;
                                    _uploadStatus = '✅ फोटो लोड भयो (${file.formattedSize})';
                                    _isUploading = false;
                                  });
                                } else {
                                  setDialogState(() {
                                    _isUploading = false;
                                    _uploadStatus = '';
                                  });
                                }
                              },
                        icon: const Icon(Icons.image, size: 16),
                        label: Text(LanguageService.instance.trText(ne: '🖼️ पृष्ठ फोटो', en: '🖼️ Page Image', ko: '🖼️ 페이지 사진'), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                if (_uploadStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_uploadStatus, style: TextStyle(fontSize: 11, color: _uploadStatus.startsWith('✅') ? Colors.green.shade800 : Colors.blue.shade800)),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: chPdfCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'वा PDF / Image URL लिङ्क', en: 'Or PDF / Image URL', ko: '또는 PDF / 이미지 URL'),
                    hintText: 'https://example.com/chapter.pdf',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (chPdfCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(LanguageService.instance.trText(ne: 'यस च्याप्टरको PDF हटाउनुहोस्', en: 'Remove Chapter PDF', ko: '이 단원 PDF 삭제'), style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setDialogState(() {
                          chPdfCtrl.clear();
                          _uploadStatus = '🗑️ PDF हटाइयो';
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (chapterToEdit != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  _confirmDeleteChapter(targetCh, ctx);
                },
                child: Text(LanguageService.instance.tr('delete')),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                final chNum = int.tryParse(chNumCtrl.text.trim()) ?? targetCh;
                final chTitle = chTitleCtrl.text.trim();
                final chPdf = chPdfCtrl.text.trim();

                final updatedTitles = Map<String, String>.from(_currentBook.chapterTitles);
                final updatedPdfs = Map<String, String>.from(_currentBook.chapterPdfs);

                if (chTitle.isNotEmpty) {
                  updatedTitles['$chNum'] = chTitle;
                }
                if (chPdf.isNotEmpty) {
                  updatedPdfs['$chNum'] = chPdf;
                } else {
                  updatedPdfs.remove('$chNum');
                }

                int newCount = _currentBook.chaptersCount;
                if (chNum > newCount) {
                  newCount = chNum;
                }

                final updated = _currentBook.copyWith(
                  chaptersCount: newCount,
                  chapterTitles: updatedTitles,
                  chapterPdfs: updatedPdfs,
                );

                _saveUpdatedBook(updated);
                setState(() {
                  _selectedChapter = chNum;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'अध्याय $chNum सुरक्षित भयो ✅',
                      en: 'Chapter $chNum saved ✅',
                      ko: '제${chNum}과가 저장되었습니다 ✅',
                    )),
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

  void _confirmDeleteChapter(int ch, BuildContext dialogCtx) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LanguageService.instance.trText(ne: 'अध्याय $ch मेटाउने?', en: 'Delete Chapter $ch?', ko: '제${ch}과 삭제?')),
        content: Text(LanguageService.instance.trText(
          ne: 'के तपाईं अध्याय $ch र यसका सबै अडियो ट्र्याकहरू हटाउन निश्चित हुनुहुन्छ?',
          en: 'Are you sure you want to delete Chapter $ch and its audio tracks?',
          ko: '제${ch}과 및 모든 오디오를 삭제하시겠습니까?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmCtx), child: Text(LanguageService.instance.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final updatedTitles = Map<String, String>.from(_currentBook.chapterTitles)..remove('$ch');
              final updatedPdfs = Map<String, String>.from(_currentBook.chapterPdfs)..remove('$ch');
              final updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks)..removeWhere((t) => t.chapterNo == ch);

              final updated = _currentBook.copyWith(
                chapterTitles: updatedTitles,
                chapterPdfs: updatedPdfs,
                audioTracks: updatedTracks,
              );
              _saveUpdatedBook(updated);
              Navigator.pop(confirmCtx);
              Navigator.pop(dialogCtx);
              setState(() {
                if (_selectedChapter == ch) {
                  _selectedChapter = 1;
                }
              });
            },
            child: Text(LanguageService.instance.tr('delete')),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. INTERACTIVE AUDIO BUTTON MANAGEMENT (थप्ने, सम्पादन, मेटाउने)
  // -------------------------------------------------------------
  void _openAddOrEditTrackDialog({BookAudioTrack? trackToEdit, String? initialSection, double? posX, double? posY}) {
    final isEditing = trackToEdit != null;
    final nextTrackNum = _chapterTracks.length + 1;
    final labelCtrl = TextEditingController(text: isEditing ? trackToEdit.label : 'Track ${nextTrackNum.toString().padLeft(2, '0')}');
    final audioUrlCtrl = TextEditingController(text: isEditing ? trackToEdit.audioUrl : '');
    String sectionType = isEditing ? trackToEdit.sectionType : (initialSection ?? 'dialogue_1');
    double? currentPosX = isEditing ? trackToEdit.posX : posX;
    double? currentPosY = isEditing ? trackToEdit.posY : posY;
    String _uploadStatus = '';
    bool _isUploading = false;

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
                  isEditing
                      ? LanguageService.instance.trText(ne: '✏️ अडियो बटन सम्पादन गर्नुहोस्', en: '✏️ Edit Audio Button', ko: '✏️ 오디오 버튼 수정')
                      : (posX != null
                          ? LanguageService.instance.trText(ne: '📌 हेडफोन आइकनमा अडियो बटन पिन गर्नुहोस्', en: '📌 Pin Audio Button', ko: '📌 오디오 버튼 핀 고정')
                          : LanguageService.instance.trText(ne: '➕ नयाँ अडियो बटन थप्नुहोस् (अध्याय $_selectedChapter)', en: '➕ Add Audio Button (Ch $_selectedChapter)', ko: '➕ 새 오디오 버튼 추가 (제$_selectedChapter과)')),
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
                if (currentPosX != null && currentPosY != null)
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
                          'पिन गरिएको स्थान: X: ${(currentPosX * 100).toStringAsFixed(1)}%, Y: ${(currentPosY * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.instance.trText(ne: 'बटनको नाम / लेबल (e.g. Track 01, 대화 1)*', en: 'Button Label (e.g. Track 01)*', ko: '버튼 라벨 (예: Track 01)*'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sectionType,
                  decoration: InputDecoration(labelText: LanguageService.instance.trText(ne: 'खण्ड (Section)*', en: 'Section*', ko: '섹션*'), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'dialogue_1', child: Text(LanguageService.instance.trText(ne: '💬 संवाद १ (Dialogue 1)', en: '💬 Dialogue 1', ko: '💬 대화 1'))),
                    DropdownMenuItem(value: 'vocabulary', child: Text(LanguageService.instance.trText(ne: '📖 शब्दावली १ (Vocabulary 1)', en: '📖 Vocabulary 1', ko: '📖 어휘 1'))),
                    DropdownMenuItem(value: 'dialogue_2', child: Text(LanguageService.instance.trText(ne: '🗣️ संवाद २ (Dialogue 2)', en: '🗣️ Dialogue 2', ko: '🗣️ 대화 2'))),
                    DropdownMenuItem(value: 'vocabulary_2', child: Text(LanguageService.instance.trText(ne: '📚 शब्दावली २ (Vocabulary 2)', en: '📚 Vocabulary 2', ko: '📚 어휘 2'))),
                    DropdownMenuItem(value: 'pronunciation', child: Text(LanguageService.instance.trText(ne: '🔊 उच्चारण अभ्यास (Pronunciation)', en: '🔊 Pronunciation', ko: '🔊 발음 연습'))),
                    DropdownMenuItem(value: 'listening', child: Text(LanguageService.instance.trText(ne: '🎧 सुन्ने अभ्यास १~५ (Listening)', en: '🎧 Listening 1~5', ko: '🎧 듣기 1~5'))),
                    DropdownMenuItem(value: 'extended', child: Text(LanguageService.instance.trText(ne: '📝 थप अभ्यास (Extended)', en: '📝 Extended Practice', ko: '📝 확장 연습'))),
                    DropdownMenuItem(value: 'custom', child: Text(LanguageService.instance.trText(ne: '✨ अन्य विशेष अडियो', en: '✨ Custom Audio', ko: '✨ 기타 오디오'))),
                  ],
                  onChanged: (v) => setDialogState(() => sectionType = v!),
                ),
                const SizedBox(height: 14),

                // Direct MP3 upload
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onPressed: _isUploading
                        ? null
                        : () async {
                            setDialogState(() {
                              _isUploading = true;
                              _uploadStatus = '⏳ अडियो अपलोड हुँदैछ...';
                            });
                            final file = await FileUploadService.instance.pickAudioFile();
                            if (file != null) {
                              setDialogState(() {
                                audioUrlCtrl.text = file.bestUrl;
                                _uploadStatus = '✅ MP3 अडियो लोड भयो (${file.formattedSize})';
                                _isUploading = false;
                              });
                            } else {
                              setDialogState(() {
                                _isUploading = false;
                                _uploadStatus = '';
                              });
                            }
                          },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      audioUrlCtrl.text.isEmpty
                          ? LanguageService.instance.trText(ne: '📁 डिभाइसबाट MP3 अडियो रोज्नुहोस्', en: '📁 Pick MP3 Audio File', ko: '📁 MP3 오디오 파일 선택')
                          : LanguageService.instance.trText(ne: '📁 अर्को MP3 रोज्नुहोस्', en: '📁 Change MP3 File', ko: '📁 다른 MP3 선택'),
                    ),
                  ),
                ),
                if (_uploadStatus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_uploadStatus, style: TextStyle(fontSize: 11, color: _uploadStatus.startsWith('✅') ? Colors.green.shade800 : Colors.orange.shade800)),
                ],
                const SizedBox(height: 10),
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
            if (isEditing)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteTrack(trackToEdit);
                },
                child: Text(LanguageService.instance.tr('delete')),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                final label = labelCtrl.text.trim();
                final audioUrl = audioUrlCtrl.text.trim();
                if (label.isEmpty || audioUrl.isEmpty) return;

                List<BookAudioTrack> updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks);

                if (isEditing) {
                  final idx = updatedTracks.indexWhere((t) => t.id == trackToEdit.id);
                  final updatedTrack = trackToEdit.copyWith(
                    label: label,
                    sectionType: sectionType,
                    audioUrl: audioUrl,
                    posX: currentPosX,
                    posY: currentPosY,
                  );
                  if (idx != -1) {
                    updatedTracks[idx] = updatedTrack;
                  } else {
                    updatedTracks.add(updatedTrack);
                  }
                } else {
                  final newTrack = BookAudioTrack(
                    id: 'track_${DateTime.now().millisecondsSinceEpoch}_${label.hashCode.abs()}',
                    chapterNo: _selectedChapter,
                    label: label,
                    sectionType: sectionType,
                    audioUrl: audioUrl,
                    posX: currentPosX,
                    posY: currentPosY,
                  );
                  updatedTracks.add(newTrack);
                }

                final updatedBook = _currentBook.copyWith(audioTracks: updatedTracks);
                _saveUpdatedBook(updatedBook);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'अडियो बटन "$label" सुरक्षित भयो ✅',
                      en: 'Audio button "$label" saved ✅',
                      ko: '오디오 버튼 "$label" 저장됨 ✅',
                    )),
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

  void _deleteTrack(BookAudioTrack track) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LanguageService.instance.trText(ne: 'अडियो बटन मेटाउने?', en: 'Delete Audio Button?', ko: '오디오 버튼 삭제?')),
        content: Text(LanguageService.instance.trText(
          ne: 'के तपाईं "${track.label}" अडियो बटन यस पुस्तकबाट हटाउन निश्चित हुनुहुन्छ?',
          en: 'Are you sure you want to remove audio button "${track.label}"?',
          ko: '정말 "${track.label}" 오디오 버튼을 삭제하시겠습니까?',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LanguageService.instance.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              final updatedTracks = List<BookAudioTrack>.from(_currentBook.audioTracks)..removeWhere((t) => t.id == track.id);
              final updatedBook = _currentBook.copyWith(audioTracks: updatedTracks);
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

  void _showAllChaptersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, color: Color(0xFF1E3A8A), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        LanguageService.instance.trText(ne: 'अध्यायगत सूची तथा व्यवस्थापन', en: 'Chapters & Management', ko: '단원 목록 및 관리'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
                        tooltip: LanguageService.instance.trText(ne: 'नयाँ अध्याय थप्नुहोस्', en: 'Add Chapter', ko: '새 단원 추가'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openChapterManagerDialog();
                        },
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ],
              ),
              Text(
                LanguageService.instance.trText(
                  ne: 'अध्याय छान्नुहोस् वा ✏️ थिचेर नाम/PDF सम्पादन गर्नुहोस्:',
                  en: 'Select a chapter or tap ✏️ to edit title/PDF:',
                  ko: '단원을 선택하거나 ✏️를 눌러 제목/PDF를 수정하세요:',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: _currentBook.chaptersCount,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ch = i + 1;
                    final isDownloaded = OfflineDownloadService.instance.isChapterDownloaded(_currentBook.id, ch);
                    final isSelected = _selectedChapter == ch;
                    final tracksCount = _currentBook.audioTracks.where((t) => t.chapterNo == ch).length;
                    final chTitle = _currentBook.getChapterTitle(ch);
                    final hasPdf = _currentBook.chapterPdfs.containsKey('$ch') || _currentBook.pdfUrl.isNotEmpty;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? const Color(0xFF1E3A8A) : (isDownloaded ? Colors.teal.shade50 : Colors.grey.shade200),
                        child: Text('$ch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDownloaded ? Colors.teal.shade900 : Colors.black87))),
                      ),
                      title: Text(
                        '제${ch}과: $chTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87),
                      ),
                      subtitle: Text(
                        LanguageService.instance.trText(
                          ne: '$tracksCount वटा अडियो • ${hasPdf ? "📄 PDF उपलब्ध" : "टेक्स्टबुक"}',
                          en: '$tracksCount Audio • ${hasPdf ? "📄 PDF Available" : "Standard"}',
                          ko: '$tracksCount개 오디오 • ${hasPdf ? "📄 PDF 제공" : "기본 교재"}',
                        ),
                        style: TextStyle(fontSize: 11, color: isDownloaded ? Colors.teal.shade700 : Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                            tooltip: LanguageService.instance.trText(ne: 'च्याप्टर सम्पादन गर्नुहोस्', en: 'Edit Chapter', ko: '단원 수정'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openChapterManagerDialog(chapterToEdit: ch);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isDownloaded ? Icons.offline_pin : Icons.download_for_offline_outlined,
                              color: isDownloaded ? Colors.green.shade700 : const Color(0xFF0F766E),
                              size: 20,
                            ),
                            tooltip: isDownloaded
                                ? LanguageService.instance.trText(ne: 'अफलाइन सुरक्षित', en: 'Saved offline', ko: '오프라인 저장됨')
                                : LanguageService.instance.trText(ne: 'अफलाइन डाउनलोड', en: 'Download offline', ko: '오프라인 다운로드'),
                            onPressed: () async {
                              await OfflineDownloadService.instance.toggleChapterDownload(_currentBook.id, ch);
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          if (!isSelected)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(60, 32),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                AudioPlaybackService.instance.stop();
                                setState(() {
                                  _selectedChapter = ch;
                                });
                              },
                              child: Text(LanguageService.instance.trText(ne: 'खोल्नुहोस्', en: 'Open', ko: '열기'), style: const TextStyle(fontSize: 11)),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final chapterTracks = _chapterTracks;
        final currentChapterTitle = _currentBook.getChapterTitle(_selectedChapter);

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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentBook.localizedTitle(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF1E3A8A)),
                      tooltip: LanguageService.instance.trText(ne: 'किताबको विवरण सम्पादन गर्नुहोस्', en: 'Edit Book Details', ko: '교재 정보 수정'),
                      onPressed: _openEditBookDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  '제${_selectedChapter}과: $currentChapterTitle • ${chapterTracks.length} ' + LanguageService.instance.trText(ne: 'अडियो बटनहरू', en: 'Audio Buttons', ko: '오디오 버튼'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              // Edit Chapter Button
              IconButton(
                icon: const Icon(Icons.edit, size: 19, color: Color(0xFF1E3A8A)),
                tooltip: LanguageService.instance.trText(ne: 'यस च्याप्टरको नाम र PDF सम्पादन गर्नुहोस्', en: 'Edit this chapter name & PDF', ko: '이 단원 이름 및 PDF 수정'),
                onPressed: () => _openChapterManagerDialog(chapterToEdit: _selectedChapter),
              ),
              // Add Audio Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _openAddOrEditTrackDialog(),
                icon: const Icon(Icons.add_circle, size: 15),
                label: Text(
                  LanguageService.instance.trText(ne: '➕ अडियो बटन', en: '➕ Audio Button', ko: '➕ 오디오 버튼'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
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
          // Chapter Dropdown & Quick Edit
          Row(
            children: [
              Text(
                LanguageService.instance.trText(ne: 'पाठ:', en: 'Lesson:', ko: '과:'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedChapter,
                isDense: true,
                items: List.generate(_currentBook.chaptersCount, (i) {
                  final ch = i + 1;
                  final title = _currentBook.getChapterTitle(ch);
                  final count = _currentBook.audioTracks.where((t) => t.chapterNo == ch).length;
                  return DropdownMenuItem(
                    value: ch,
                    child: Text(
                      '제$ch과: ${title.length > 20 ? "${title.substring(0, 18)}..." : title} ${count > 0 ? "($count🎧)" : ""}',
                      style: const TextStyle(fontSize: 12),
                    ),
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
              const SizedBox(width: 6),
              // Chapter Manager Modal Button
              IconButton(
                icon: const Icon(Icons.format_list_bulleted, size: 18, color: Color(0xFF1E3A8A)),
                tooltip: LanguageService.instance.trText(ne: 'सबै अध्यायहरूको सूची तथा डाउनलोड', en: 'All Chapters List', ko: '모든 단원 목록'),
                onPressed: _showAllChaptersModal,
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
              'अडियो बटनहरू (${tracks.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            if (tracks.isEmpty) ...[
              Text(
                LanguageService.instance.trText(
                  ne: '(यस पाठमा अडियो बटन छैन)',
                  en: '(No audio buttons in this chapter)',
                  ko: '(이 단원에 등록된 오디오 버튼 없음)',
                ),
                style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(60, 26),
                ),
                onPressed: _addDefaultTracksForChapter,
                icon: const Icon(Icons.flash_on, size: 13),
                label: Text(
                  LanguageService.instance.trText(ne: '⚡ डिफल्ट अडियो राख्नुहोस्', en: '⚡ Add Default Audio', ko: '⚡ 기본 오디오 추가'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],
            ...tracks.map((track) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ExpandableAudioTimelineButton(
                  track: track,
                  onLongPress: () => _openAddOrEditTrackDialog(trackToEdit: track),
                  onEditRequested: () => _openAddOrEditTrackDialog(trackToEdit: track),
                ),
              );
            }),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFEA580C), size: 18),
              tooltip: LanguageService.instance.trText(ne: 'नयाँ बटन थप्नुहोस्', en: 'Add New Button', ko: '새 버튼 추가'),
              onPressed: () => _openAddOrEditTrackDialog(),
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
                      ? LanguageService.instance.trText(
                          ne: '📌 पिन मोड सक्रिय: पृष्ठमा जहाँ हेडफोनको आइकन छ, त्यहीँ ट्याप गरेर नयाँ बटन राख्नुहोस्!',
                          en: '📌 Pin mode active: Tap where the headphone icon is on the page to place button!',
                          ko: '📌 핀 모드 활성화: 페이지 내 헤드폰 아이콘 위치를 탭하여 버튼을 배치하세요!',
                        )
                      : LanguageService.instance.trText(
                          ne: '💡 हेडफोन आइकनमा ट्याप गरेर सिधै अडियो सुन्नुहोस्। नयाँ बटन राख्न "पिन मोड" थिच्नुहोस्।',
                          en: '💡 Tap headphone icons to listen audio. Tap "Pin Mode" to add new buttons.',
                          ko: '💡 헤드폰 아이콘을 탭하여 오디오를 재생하세요. 우측 "핀 모드"로 새 버튼을 추가할 수 있습니다.',
                        ),
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
                  _isPinningMode
                      ? LanguageService.instance.trText(ne: 'पिनिङ पूरा भयो ✅', en: 'Pinning Done ✅', ko: '핀 고정 완료 ✅')
                      : LanguageService.instance.trText(ne: '📌 हेडफोनमा बटन पिन गर्नुहोस्', en: '📌 Pin Button', ko: '📌 버튼 핀 고정'),
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
                    const double canvasWidth = 840.0;
                    const double canvasHeight = 1180.0;

                    return GestureDetector(
                      onTapUp: _isPinningMode
                          ? (details) {
                              final posX = (details.localPosition.dx / canvasWidth).clamp(0.02, 0.90);
                              final posY = (details.localPosition.dy / canvasHeight).clamp(0.02, 0.95);
                              _openAddOrEditTrackDialog(posX: posX, posY: posY);
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
                                  onLongPress: () => _openAddOrEditTrackDialog(trackToEdit: track),
                                  onEditRequested: () => _openAddOrEditTrackDialog(trackToEdit: track),
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
    final bool isImage = url.startsWith('data:image') ||
        (url.startsWith('http') &&
            RegExp(r'\.(jpe?g|png|webp|gif|svg)(\?.*)?$', caseSensitive: false).hasMatch(url));

    // ── Image (data:image base64 or network image URL) ────────────────
    if (isImage) {
      if (url.startsWith('data:image')) {
        try {
          final bytes = base64Decode(url.split(',')[1]);
          return Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {}
      }
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => _buildDefaultTextbookCanvas(),
      );
    }

    // ── PDF (web: iframe via native blob/object URL; mobile: placeholder) ──
    final viewId = 'pdf_ch${_currentBook.id}_${_selectedChapter}_${url.hashCode.abs()}';
    return SizedBox.expand(
      child: buildPdfViewerWidget(url, viewId),
    );
  }

  /// Official Korean EPS-TOPIK Textbook Aesthetic Template
  Widget _buildDefaultTextbookCanvas() {
    final chTitle = _currentBook.getChapterTitle(_selectedChapter);

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
                    chTitle,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _openChapterManagerDialog(chapterToEdit: _selectedChapter),
                icon: const Icon(Icons.upload, size: 14),
                label: Text(
                  LanguageService.instance.trText(ne: '📄 यस पृष्ठको PDF/फोटो अपलोड', en: '📄 Upload PDF/Page', ko: '📄 이 페이지 PDF 업로드'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.5),

          // Dialogue 1 Section with printed Headphone Icon
          _buildCanvasSectionBox(
            title: LanguageService.instance.trText(ne: 'संवाद १ (Dialogue 1)', en: 'Dialogue 1', ko: '대화 1'),
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
                children: [
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
            title: LanguageService.instance.trText(ne: 'संवाद २ (Dialogue 2)', en: 'Dialogue 2', ko: '대화 2'),
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
            title: LanguageService.instance.trText(ne: 'सुन्ने अभ्यास १~५ (Listening 1~5)', en: 'Listening Practice 1~5', ko: '듣기 연습 1~5'),
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
    final chTitle = _currentBook.getChapterTitle(_selectedChapter);

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
                      child: Text(
                        LanguageService.instance.trText(ne: '🎧 ${chapterTracks.length} वटा अडियो बटनहरू उपलब्ध', en: '🎧 ${chapterTracks.length} Audio Buttons', ko: '🎧 ${chapterTracks.length}개 오디오 버튼'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  chTitle,
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
                    children: [
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
                tooltip: LanguageService.instance.trText(ne: 'यस खण्डमा अडियो बटन थप्नुहोस्', en: 'Add audio button', ko: '이 섹션에 오디오 버튼 추가'),
                onPressed: () => _openAddOrEditTrackDialog(initialSection: sectionType),
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
                  onLongPress: () => _openAddOrEditTrackDialog(trackToEdit: track),
                  onEditRequested: () => _openAddOrEditTrackDialog(trackToEdit: track),
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
                    LanguageService.instance.trText(
                      ne: 'अडियो बजिरहेको छ 🔊 (टाइमलाइन हेर्न अडियो बटन थिच्नुहोस्)',
                      en: 'Audio playing 🔊 (Tap audio button to view timeline)',
                      ko: '오디오 재생 중 🔊 (타임라인을 보려면 오디오 버튼을 누르세요)',
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

/// Expandable Audio Timeline Button with Live Scrubber and Edit/Delete Capabilities:
/// 1. Compact button with headphone icon 🎧 and track label.
/// 2. Clicking expands smoothly into live audio timeline slider with progress, elapsed/total time and seek control.
/// 3. Clicking again or stop button collapses back to compact headphone button.
/// 4. Options to edit or delete the button.
class ExpandableAudioTimelineButton extends StatefulWidget {
  final BookAudioTrack track;
  final VoidCallback? onLongPress;
  final VoidCallback? onEditRequested;
  final bool isPinned;

  const ExpandableAudioTimelineButton({
    super.key,
    required this.track,
    this.onLongPress,
    this.onEditRequested,
    this.isPinned = false,
  });

  @override
  State<ExpandableAudioTimelineButton> createState() => _ExpandableAudioTimelineButtonState();
}

class _ExpandableAudioTimelineButtonState extends State<ExpandableAudioTimelineButton> {
  double _playbackSpeed = 1.0;

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 0.8;
      } else if (_playbackSpeed == 0.8) {
        _playbackSpeed = 1.2;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    AudioPlaybackService.instance.setPlaybackRate(_playbackSpeed);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AudioPlaybackService.instance.currentAudioSourceNotifier,
      builder: (context, currentSource, _) {
        final isPlayingThis = currentSource == widget.track.audioUrl;

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: isPlayingThis
              ? _buildExpandedTimeline(context)
              : _buildCompactTextbookBadge(context),
        );
      },
    );
  }

  /// 1. Authentic Official Korean Textbook In-Print Badge Button
  /// Matches standard EPS-TOPIK Korean textbook print typography and aesthetic
  Widget _buildCompactTextbookBadge(BuildContext context) {
    return Tooltip(
      message: LanguageService.instance.trText(
        ne: 'अडियो सुन्न थिच्नुहोस् (स्लाइडर खुल्नेछ) • सम्पादन गर्न लङ-प्रेस',
        en: 'Tap to listen audio (slider expands) • Long-press to edit',
        ko: '오디오 듣기 (슬라이더 열림) • 길게 눌러 수정',
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioPlaybackService.instance.playAudioUrl(widget.track.audioUrl);
          },
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0F766E),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // In-print Headphone Badge Icon
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F766E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headphones_rounded, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 6),
                // Authentic Textbook Typography Label
                Text(
                  widget.track.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFFEA580C)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Expanded Floating Audio Slider with Live Scrubber & Speed Control
  Widget _buildExpandedTimeline(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      color: const Color(0xFF0F172A),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF14B8A6), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stop / Collapse Button
            InkWell(
              onTap: () => AudioPlaybackService.instance.stop(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),

            // Track Name
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 85),
              child: Text(
                widget.track.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Live Seek Slider
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
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: const Color(0xFF14B8A6),
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
                                Text(_formatTime(pos), style: const TextStyle(fontSize: 9, color: Color(0xFF5EEAD4), fontWeight: FontWeight.bold)),
                                Text(_formatTime(dur), style: const TextStyle(fontSize: 9, color: Colors.white60)),
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

            const SizedBox(width: 4),

            // Speed cycle button
            InkWell(
              onTap: _cycleSpeed,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${_playbackSpeed}x',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Close / Minimize Button
            InkWell(
              onTap: () => AudioPlaybackService.instance.stop(),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white70),
              ),
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

  const _VocabChip({
    super.key,
    required this.word,
    required this.nepali,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 4),
          Text('($nepali)', style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }
}
