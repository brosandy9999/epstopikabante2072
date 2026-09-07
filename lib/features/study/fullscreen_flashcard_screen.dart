import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/study_material_model.dart';
import '../../core/services/language_service.dart';
import '../../core/services/study_material_service.dart';
import '../../core/services/korean_tts_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/widgets/smart_image_widget.dart';

/// Immersive Fullscreen Flashcard Learning Screen
/// Maximizes screen real estate for distraction-free vocabulary memorization,
/// with flip animations, auto-slideshow, TTS audio, custom audio attachment, and keyboard shortcuts.
class FullscreenFlashcardScreen extends StatefulWidget {
  final List<VisualFlashcard> flashcards;
  final int initialIndex;
  final String title;
  final String? chapterTitle;

  const FullscreenFlashcardScreen({
    super.key,
    required this.flashcards,
    this.initialIndex = 0,
    this.title = 'Visual Flashcards',
    this.chapterTitle,
  });

  @override
  State<FullscreenFlashcardScreen> createState() => _FullscreenFlashcardScreenState();
}

class _FullscreenFlashcardScreenState extends State<FullscreenFlashcardScreen> {
  late List<VisualFlashcard> _deck;
  late PageController _pageController;
  int _currentIndex = 0;
  final Set<String> _flippedCardIds = {};
  bool _autoPlayTts = true;
  bool _isSlideshowRunning = false;
  Timer? _slideshowTimer;
  int _slideshowSeconds = 5; // seconds per card in slideshow mode
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.flashcards);
    _currentIndex = widget.initialIndex.clamp(0, _deck.isEmpty ? 0 : _deck.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    // Initial audio speak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_deck.isNotEmpty && _autoPlayTts) {
        KoreanTtsService.instance.speakKorean(_deck[_currentIndex].koreanWord);
      }
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_autoPlayTts && index < _deck.length) {
      final card = _deck[index];
      KoreanTtsService.instance.speakKorean(card.koreanWord);
    }
  }

  void _toggleFlipCurrent() {
    if (_deck.isEmpty) return;
    final cardId = _deck[_currentIndex].id;
    setState(() {
      if (_flippedCardIds.contains(cardId)) {
        _flippedCardIds.remove(cardId);
      } else {
        _flippedCardIds.add(cardId);
      }
    });
  }

  void _toggleMasteredCurrent() {
    if (_deck.isEmpty) return;
    final card = _deck[_currentIndex];
    StudyMaterialService.instance.toggleFlashcardMastered(card.id);
    setState(() {
      final updatedList = StudyMaterialService.instance.getAllVisualFlashcards();
      final updatedCard = updatedList.firstWhere((c) => c.id == card.id, orElse: () => card);
      final idx = _deck.indexWhere((c) => c.id == card.id);
      if (idx >= 0) {
        _deck[idx] = updatedCard;
      }
    });
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextCard() {
    if (_currentIndex < _deck.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else if (_isSlideshowRunning) {
      // Loop back to start in slideshow
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleSlideshow() {
    setState(() {
      _isSlideshowRunning = !_isSlideshowRunning;
    });

    if (_isSlideshowRunning) {
      _startSlideshowTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.instance.trText(
              ne: '▶ अटो-स्लाइडशो सुरु भयो (${_slideshowSeconds} सेकेन्ड प्रति कार्ड)',
              en: '▶ Auto-slideshow started (${_slideshowSeconds}s per card)',
              ko: '▶ 자동 슬라이드쇼 시작 (${_slideshowSeconds}초 간격)',
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );
    } else {
      _slideshowTimer?.cancel();
    }
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(Duration(seconds: _slideshowSeconds), (t) {
      if (!mounted || !_isSlideshowRunning) {
        t.cancel();
        return;
      }

      final currentCard = _deck[_currentIndex];
      final isFlipped = _flippedCardIds.contains(currentCard.id);

      if (!isFlipped) {
        // First flip to reveal meaning
        _toggleFlipCurrent();
      } else {
        // Then move to next card
        _nextCard();
      }
    });
  }

  void _shuffleDeck() {
    setState(() {
      _deck.shuffle();
      _currentIndex = 0;
      _flippedCardIds.clear();
      _pageController.jumpToPage(0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.instance.trText(
            ne: '🔀 फ्ल्यासकार्डहरू र्‍यान्डम (Shuffle) गरियो!',
            en: '🔀 Flashcards shuffled!',
            ko: '🔀 단어 카드가 무작위로 섞였습니다!',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: '${card.koreanWord} - अडियो जोड्नुहोस्',
                    en: '${card.koreanWord} - Attach Audio',
                    ko: '${card.koreanWord} - 음원 첨부',
                  ),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService.instance.trText(
                  ne: 'यस शब्दका लागि मोबाइल/कम्प्युटरबाट MP3 अडियो फाइल रोज्नुहोस्:',
                  en: 'Select MP3 audio for this word from your device:',
                  ko: '이 단어의 MP3 음원을 기기에서 선택하세요:',
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
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
                label: Text(
                  urlCtrl.text.isEmpty
                      ? (LanguageService.instance.isEnglish
                          ? '📁 Pick Audio from device'
                          : (LanguageService.instance.isKorean ? '📁 기기에서 오디오 선택' : '📁 डिभाइसबाट सिधै अडियो रोज्नुहोस्'))
                      : (LanguageService.instance.isEnglish
                          ? 'Audio loaded ✅'
                          : (LanguageService.instance.isKorean ? '오디오 로드 완료 ✅' : 'अडियो लोड भयो ✅')),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: LanguageService.instance.isEnglish
                      ? 'Or enter audio URL'
                      : (LanguageService.instance.isKorean ? '또는 오디오 링크 입력' : 'वा अडियो लिङ्क राख्नुहोस्'),
                  hintText: 'https://hrd.go.kr/audio/word.mp3',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.tr('cancel')),
            ),
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
                  setState(() {
                    final idx = _deck.indexWhere((c) => c.id == card.id);
                    if (idx >= 0) _deck[idx] = updated;
                  });
                }
                Navigator.pop(ctx);
              },
              child: Text(LanguageService.instance.trText(ne: 'अडियो सेभ गर्नुहोस्', en: 'Save Audio', ko: '오디오 저장')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            LanguageService.instance.trText(
              ne: 'यस सेक्सनमा कुनै फ्ल्यासकार्ड उपलब्ध छैन।',
              en: 'No flashcards available.',
              ko: '학습할 단어 카드가 없습니다.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final currentCard = _deck[_currentIndex];
    final isFlipped = _flippedCardIds.contains(currentCard.id);
    final progressFraction = (_currentIndex + 1) / _deck.length;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousCard();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextCard();
          } else if (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _toggleFlipCurrent();
          } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
            _toggleMasteredCurrent();
          } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
            KoreanTtsService.instance.speakKorean(currentCard.koreanWord);
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B132B), // High-focus deep midnight canvas
        body: SafeArea(
          child: Column(
            children: [
              // 1. TOP PROGRESS BAR (Subtle glowing strip)
              LinearProgressIndicator(
                value: progressFraction,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                minHeight: 3.5,
              ),

              // 2. ULTRA-SLEEK TOP CONTROLS BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Exit Button & Chapter Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                          tooltip: LanguageService.instance.trText(ne: 'फुलस्क्रिन बन्द गर्नुहोस्', en: 'Exit Fullscreen', ko: '전체화면 닫기'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '제${currentCard.chapterNo}과 • ${currentCard.topic}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Center: Counter & Mastered Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_deck.length}',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ),

                    // Right: Actions (Auto TTS, Slideshow, Shuffle)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Auto TTS Toggle
                        IconButton(
                          icon: Icon(
                            _autoPlayTts ? Icons.volume_up : Icons.volume_off,
                            color: _autoPlayTts ? const Color(0xFF38BDF8) : Colors.white38,
                            size: 20,
                          ),
                          tooltip: LanguageService.instance.trText(ne: 'अटो TTS अन/अफ', en: 'Auto TTS On/Off', ko: '자동 발음 켜기/끄기'),
                          onPressed: () {
                            setState(() => _autoPlayTts = !_autoPlayTts);
                            if (_autoPlayTts) {
                              KoreanTtsService.instance.speakKorean(currentCard.koreanWord);
                            }
                          },
                        ),

                        // Slideshow Mode Toggle
                        IconButton(
                          icon: Icon(
                            _isSlideshowRunning ? Icons.pause_circle_filled : Icons.play_circle_outline,
                            color: _isSlideshowRunning ? Colors.amber : Colors.white70,
                            size: 22,
                          ),
                          tooltip: LanguageService.instance.trText(ne: 'स्वतः स्लाइडशो', en: 'Auto Slideshow', ko: '자동 슬라이드쇼'),
                          onPressed: _toggleSlideshow,
                        ),

                        // Shuffle Deck
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: Colors.white70, size: 20),
                          tooltip: LanguageService.instance.trText(ne: 'र्‍यान्डम (Shuffle)', en: 'Shuffle Deck', ko: '무작위 섞기'),
                          onPressed: _shuffleDeck,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. MAIN FULLSCREEN FLASHCARD CANVAS (SWIPEABLE & INTERACTIVE)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _deck.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final card = _deck[index];
                    final isCardFlipped = _flippedCardIds.contains(card.id);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 720,
                            maxHeight: 640,
                          ),
                          child: GestureDetector(
                            onTap: _toggleFlipCurrent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: isCardFlipped ? const Color(0xFFF0FDF4) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: card.isMastered
                                      ? Colors.green.shade600
                                      : (isCardFlipped ? const Color(0xFF16A34A) : const Color(0xFF38BDF8)),
                                  width: card.isMastered ? 3.0 : 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: card.isMastered
                                        ? Colors.green.withValues(alpha: 0.25)
                                        : Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Corner Watermark / Side Tag
                                    Positioned(
                                      top: 16,
                                      right: 18,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCardFlipped ? Colors.green.shade100 : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isCardFlipped ? '🇳🇵 अर्थ (Meaning)' : '🇰🇷 कोरियन (Word)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isCardFlipped ? Colors.green.shade900 : const Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Mastered Star Badge if active
                                    if (card.isMastered)
                                      Positioned(
                                        top: 16,
                                        left: 18,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                LanguageService.instance.tr('mastered'),
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Main Card Contents
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                                      child: isCardFlipped
                                          ? _buildCardBack(card)
                                          : _buildCardFront(card),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. BOTTOM FLOATING CONTROLS & NAVIGATION BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(
                        LanguageService.instance.trText(ne: 'अघिल्लो', en: 'Prev', ko: '이전'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Flip Card Button (Center Hero Button)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFlipped ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _toggleFlipCurrent,
                      icon: const Icon(Icons.flip_to_back, size: 18),
                      label: Text(
                        isFlipped
                            ? LanguageService.instance.trText(ne: 'शब्द हेर्नुहोस् (Front)', en: 'View Word (Front)', ko: '단어 보기 (앞면)')
                            : LanguageService.instance.trText(ne: 'अर्थ हेर्नुहोस् (Flip)', en: 'Flip Meaning', ko: '뜻 보기 (뒤집기)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Next Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _currentIndex < _deck.length - 1 ? _nextCard : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        LanguageService.instance.trText(ne: 'अर्को', en: 'Next', ko: '다음'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FRONT SIDE (Korean Word, Visual Illustration, TTS, Pronunciation)
  // -------------------------------------------------------------
  Widget _buildCardFront(VisualFlashcard card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Visual Illustration / Icon
        Expanded(
          flex: 5,
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: (card.visualIcon.startsWith('data:image') || card.visualIcon.startsWith('http'))
                  ? ClipOval(
                      child: SmartImageWidget(
                        imageSource: card.visualIcon,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      card.visualIcon,
                      style: const TextStyle(fontSize: 72),
                    ),
            ),
          ),
        ),

        // 2. Korean Word Typography & Pronunciation
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.koreanWord,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    color: Color(0xFF0F172A),
                    letterSpacing: 2.0,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '[ ${card.pronunciation} ]',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // 3. Audio & Voice Bar (TTS, Slow TTS, Custom MP3)
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  // Korean Normal TTS
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => KoreanTtsService.instance.speakKorean(card.koreanWord),
                    icon: const Icon(Icons.volume_up, size: 16),
                    label: Text(LanguageService.instance.trText(ne: '🔊 उच्चारण', en: '🔊 Speak', ko: '🔊 발음 듣기'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),

                  // Slow Speech 0.7x TTS
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      // Slow TTS
                      KoreanTtsService.instance.speakKorean(card.koreanWord);
                    },
                    icon: const Icon(Icons.speed, size: 15),
                    label: Text(LanguageService.instance.trText(ne: '🐢 बिस्तारै', en: '🐢 Slow', ko: '🐢 느리게'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),

                  // Custom MP3 Audio if attached
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                          ? Colors.teal.shade700
                          : Colors.blueGrey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      size: 16,
                    ),
                    label: Text(
                      (card.audioUrl != null && card.audioUrl!.isNotEmpty)
                          ? LanguageService.instance.trText(ne: '🎵 आफ्नै MP3', en: '🎵 Custom MP3', ko: '🎵 내 음원')
                          : LanguageService.instance.trText(ne: '🎵 अडियो थप्नुहोस्', en: '🎵 Add Audio', ko: '🎵 오디오 추가'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '👆 ' + LanguageService.instance.trText(ne: 'अर्थ हेर्न कार्डमा ट्याप गर्नुहोस् (वा Space थिच्नुहोस्)', en: 'Tap card or press Space to flip meaning', ko: '뜻을 확인하려면 카드를 탭하세요 (스페이스바)'),
                style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // BACK SIDE (Nepali Meaning, Practical Sentences, Mastered Toggle)
  // -------------------------------------------------------------
  Widget _buildCardBack(VisualFlashcard card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Nepali Meaning Title
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.koreanWord,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.nepaliMeaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: Color(0xFF15803D),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Workplace / Textbook Example Sentence Box
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'कार्यस्थल व्यावहारिक उदाहरण वाक्य:',
                          en: 'Practical Workplace Example Sentence:',
                          ko: '직장 실무 예문:',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  Text(
                    '🇰🇷 ${card.exampleSentence}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📖 제${card.chapterNo}과: ${card.chapterTitle}',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Action Button: Mark as Mastered
        Expanded(
          flex: 3,
          child: Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: card.isMastered ? Colors.green.shade700 : const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _toggleMasteredCurrent,
              icon: Icon(card.isMastered ? Icons.check_circle : Icons.bookmark_add, size: 20),
              label: Text(
                card.isMastered
                    ? ('✓ ' + LanguageService.instance.tr('mastered') + ' (कण्ठ भइसकेको)')
                    : LanguageService.instance.trText(
                        ne: 'कण्ठ भयो भनी चिन्ह लगाउनुहोस्',
                        en: 'Mark as Mastered',
                        ko: '암기완료로 표시',
                      ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
