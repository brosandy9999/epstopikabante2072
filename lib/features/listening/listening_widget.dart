import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/models/exam_session_model.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/services/language_service.dart';

/// Authentic HRDK EPS-TOPIK UBT Listening Question Widget
/// Single Click Continuous Playback Engine: Plays Round 1 -> Brief Intermission -> Auto Repeats Round 2 -> Locks!
class ListeningQuestionWidget extends StatefulWidget {
  final QuestionTemplate question;
  final int? selectedOptionIndex;
  final Function(int) onOptionSelected;

  const ListeningQuestionWidget({
    super.key,
    required this.question,
    this.selectedOptionIndex,
    required this.onOptionSelected,
  });

  @override
  State<ListeningQuestionWidget> createState() => _ListeningQuestionWidgetState();
}

class _ListeningQuestionWidgetState extends State<ListeningQuestionWidget> {
  AudioState _audioState = AudioState.ready;

  @override
  void dispose() {
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  /// Plays audio continuously for 2 iterations without requiring manual 2nd tap
  void _startContinuousAudioLoop() {
    if (_audioState == AudioState.locked || _audioState == AudioState.playingFirst || _audioState == AudioState.playingSecond) {
      return;
    }

    String speechText = widget.question.questionText;
    String? audioPath;
    if (widget.question is UniversalQuestion) {
      speechText = (widget.question as UniversalQuestion).audioScript ?? widget.question.questionText;
      audioPath = (widget.question as UniversalQuestion).questionAudioUrl;
    } else if (widget.question is ListeningAudioQuestion) {
      speechText = (widget.question as ListeningAudioQuestion).audioScript ?? widget.question.questionText;
      audioPath = (widget.question as ListeningAudioQuestion).audioAssetPath;
    }

    final isAudioOnly = (widget.question is UniversalQuestion)
        ? (widget.question as UniversalQuestion).isAudioOnly
        : false;

    void playCurrentTrack() {
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        AudioPlaybackService.instance.playAudioUrl(audioPath.trim());
      } else if (!isAudioOnly) {
        AudioPlaybackService.instance.playKoreanSpeech(speechText);
      }
    }

    // ----------------------------------------
    // ROUND 1: 1st Audio Playback
    // ----------------------------------------
    setState(() {
      _audioState = AudioState.playingFirst;
    });

    playCurrentTrack();

    // Round 1 ends after 2.4s -> 1.5s brief pause before auto repeating
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _audioState = AudioState.firstComplete; // Intermission state
      });

      // ----------------------------------------
      // ROUND 2: Auto Repeat 2nd Playback
      // ----------------------------------------
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _audioState = AudioState.playingSecond;
        });

        playCurrentTrack();

        // Round 2 finishes -> Permanently Locked!
        Future.delayed(const Duration(milliseconds: 2400), () {
          if (!mounted) return;
          setState(() {
            _audioState = AudioState.locked;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> rawOptions = [];
    if (widget.question is UniversalQuestion) {
      rawOptions = (widget.question as UniversalQuestion).textOptions;
    } else if (widget.question is ListeningAudioQuestion) {
      rawOptions = (widget.question as ListeningAudioQuestion).textOptions;
    } else if (widget.question is ListeningImageOptionsQuestion) {
      rawOptions = (widget.question as ListeningImageOptionsQuestion).imageOptionPaths;
    } else if (widget.question is ReadingTextQuestion) {
      rawOptions = (widget.question as ReadingTextQuestion).textOptions;
    } else if (widget.question is ReadingImageQuestion) {
      rawOptions = (widget.question as ReadingImageQuestion).textOptions;
    }

    final List<String> options = List.generate(4, (index) {
      if (index < rawOptions.length) {
        return rawOptions[index];
      }
      return '';
    });

    final isLocked = _audioState == AudioState.locked;
    final isPlaying = _audioState == AudioState.playingFirst || _audioState == AudioState.playingSecond;
    final isIntermission = _audioState == AudioState.firstComplete;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // LEFT PANE: Listening Audio Player & Prompt
        // ==========================================
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LanguageService.instance.listeningSectionText(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).isAudioOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC2410C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.audiotrack, color: Colors.white, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  LanguageService.instance.trText(
                                    ne: 'केवल अडियो ट्र्याक',
                                    en: 'Strict Audio Only',
                                    ko: '오디오 전용 문항',
                                  ),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Question Instruction Text
                    Text(
                      widget.question.questionText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.35, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),

                    // Speaker Icon centered below the question
                    Center(
                      child: Tooltip(
                        message: isLocked
                            ? LanguageService.instance.trText(ne: "अडियो समाप्त (लक भयो)", en: "Audio Completed (Locked)", ko: "재생 완료 (오디오 잠김)")
                            : (isPlaying
                                ? LanguageService.instance.trText(ne: "अडियो बजिरहेको छ...", en: "Audio playing...", ko: "오디오 재생 중...")
                                : LanguageService.instance.trText(ne: "अडियो सुन्नुहोस् (यहाँ थिच्नुहोस्)", en: "Listen to Audio (Click to Play)", ko: "오디오 듣기 (클릭하여 재생)")),
                        child: Material(
                          color: isLocked
                              ? Colors.grey.shade200
                              : (isPlaying ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isLocked ? null : _startContinuousAudioLoop,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isLocked
                                      ? Colors.grey.shade400
                                      : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF3B82F6)),
                                  width: 2.0,
                                ),
                              ),
                              child: Icon(
                                isLocked
                                    ? Icons.lock_rounded
                                    : (isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
                                size: 28,
                                color: isLocked
                                    ? Colors.grey.shade500
                                    : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Playback status text
                    Center(
                      child: Text(
                        isLocked
                            ? LanguageService.instance.trText(
                                ne: "अडियो २ पटक बजिसक्यो (सम्पन्न)",
                                en: "Audio Played 2 Times (Completed)",
                                ko: "재생 완료 (2회 청취 완료)",
                              )
                            : (isPlaying
                                ? (_audioState == AudioState.playingFirst
                                    ? LanguageService.instance.trText(
                                        ne: "🔊 पहिलो पटक अडियो बज्दैछ... (Round 1)",
                                        en: "🔊 Playing Round 1 Audio...",
                                        ko: "🔊 1회차 오디오 재생 중...",
                                      )
                                    : LanguageService.instance.trText(
                                        ne: "🔊 दोस्रो पटक अडियो दोहोरिँदै... (Round 2)",
                                        en: "🔊 Repeating Round 2 Audio...",
                                        ko: "🔊 2회차 오디오 반복 중...",
                                      ))
                                : (isIntermission
                                    ? LanguageService.instance.trText(
                                        ne: "⏳ केही क्षणमा दोस्रो पटक स्वतः बज्नेछ...",
                                        en: "⏳ Round 2 will auto-play in a moment...",
                                        ko: "⏳ 잠시 후 2회차가 자동 재생됩니다...",
                                      )
                                    : LanguageService.instance.trText(
                                        ne: "🔊 अडियो सुन्नुहोस् (यहाँ थिचेपछि २ पटक बज्नेछ)",
                                        en: "🔊 Play Audio (Korean voice will play 2 times)",
                                        ko: "🔊 오디오 듣기 (클릭 시 2회 연속 재생)",
                                      ))),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? Colors.grey.shade600
                              : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ==========================================
        // RIGHT PANE: 4 Multiple-Choice Options
        // ==========================================
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.selectedOptionIndex != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            "선택: ${widget.selectedOptionIndex! + 1}번",
                            style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // 4 Options Stacked Vertically
                    ...List.generate(4, (index) {
                      final isSelected = widget.selectedOptionIndex == index;
                      const circledNumbers = ["①", "②", "③", "④"];
                      final numLabel = circledNumbers[index];
                      final optionText = options[index].trim();

                      // Check if image option exists
                      String? imageOptionUrl;
                      if (widget.question is UniversalQuestion) {
                        final uq = widget.question as UniversalQuestion;
                        if (index < uq.imageOptions.length && uq.imageOptions[index] != null && uq.imageOptions[index]!.trim().isNotEmpty) {
                          imageOptionUrl = uq.imageOptions[index]!.trim();
                        }
                      } else if (widget.question is ListeningImageOptionsQuestion) {
                        final lio = widget.question as ListeningImageOptionsQuestion;
                        if (index < lio.imageOptionPaths.length && lio.imageOptionPaths[index].trim().isNotEmpty) {
                          imageOptionUrl = lio.imageOptionPaths[index].trim();
                        }
                      }

                      // Check if audio option exists
                      String? audioOptionUrl;
                      if (widget.question is UniversalQuestion) {
                        final uq = widget.question as UniversalQuestion;
                        if (index < uq.audioOptions.length && uq.audioOptions[index] != null && uq.audioOptions[index]!.trim().isNotEmpty) {
                          audioOptionUrl = uq.audioOptions[index]!.trim();
                        }
                      }

                      // Fallback text if text is blank and no image is attached:
                      final displayText = optionText.isNotEmpty 
                          ? optionText 
                          : (imageOptionUrl == null ? "${index + 1}번" : "");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSelected ? const Color(0xFFFFFBEB) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () => widget.onOptionSelected(index),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Circled Number
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFFD97706) : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade400,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Text(
                                      numLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Option Text & Media
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (displayText.isNotEmpty)
                                          Text(
                                            displayText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? const Color(0xFF92400E) : Colors.black87,
                                            ),
                                          ),
                                        if (imageOptionUrl != null) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            constraints: const BoxConstraints(maxHeight: 85),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: SmartImageWidget(
                                              imageSource: imageOptionUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                        if (audioOptionUrl != null) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => AudioPlaybackService.instance.playAudioUrl(audioOptionUrl!),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.amber.shade300),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.play_circle_fill, size: 14, color: Color(0xFFD97706)),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    LanguageService.instance.trText(
                                                      ne: 'अडियो सुन्नुहोस्',
                                                      en: 'Play Audio',
                                                      ko: '오디오 듣기',
                                                    ),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFFD97706), size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
