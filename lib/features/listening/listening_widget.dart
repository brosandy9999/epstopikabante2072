import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/models/exam_session_model.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/widgets/sequence_option_widget.dart';
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
  int _loopRunId = 0;

  @override
  void dispose() {
    _loopRunId++;
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  /// Plays audio continuously for 2 iterations waiting for actual track duration
  Future<void> _startContinuousAudioLoop() async {
    if (_audioState == AudioState.locked ||
        _audioState == AudioState.playingFirst ||
        _audioState == AudioState.playingSecond) {
      return;
    }

    final currentRun = ++_loopRunId;

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

    Future<void> playTrack() async {
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        await AudioPlaybackService.instance.playAudioUrlAndWait(
          audioPath.trim(),
          fallbackKoreanText: isAudioOnly ? null : speechText,
        );
      } else if (!isAudioOnly && speechText.trim().isNotEmpty) {
        await AudioPlaybackService.instance.playKoreanSpeechAndWait(speechText.trim());
      }
    }

    // ----------------------------------------
    // ROUND 1: 1st Audio Playback
    // ----------------------------------------
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = AudioState.playingFirst;
    });

    await playTrack();

    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = AudioState.firstComplete; // Intermission state
    });

    // ----------------------------------------
    // 1.5s intermission before round 2
    // ----------------------------------------
    await Future.delayed(const Duration(seconds: 3));

    // ----------------------------------------
    // ROUND 2: Auto Repeat 2nd Playback
    // ----------------------------------------
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = AudioState.playingSecond;
    });

    await playTrack();

    // Round 2 finishes -> Permanently Locked!
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = AudioState.locked;
    });
  }

  void _playOptionAudio(int index, String? audioUrl, String optionText) {
    final cleanUrl = audioUrl?.trim() ?? '';
    final cleanText = optionText.trim();

    final isPlayingThis = AudioPlaybackService.instance.isPlaying &&
        ((cleanUrl.isNotEmpty && AudioPlaybackService.instance.currentSource == cleanUrl) ||
            (AudioPlaybackService.instance.currentSource == 'tts:$cleanText'));

    if (isPlayingThis) {
      AudioPlaybackService.instance.stop();
      return;
    }

    if (cleanUrl.isNotEmpty) {
      AudioPlaybackService.instance.playAudioUrl(cleanUrl, fallbackKoreanText: cleanText);
    } else if (cleanText.isNotEmpty) {
      AudioPlaybackService.instance.playKoreanSpeech(cleanText);
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth >= 640;

        if (!isLandscape) {
          // ==========================================
          // MOBILE / PORTRAIT: VERTICAL STACK
          // ==========================================
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Card: Audio Player & Prompt
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: _buildAudioPromptPane(context, false, isLocked, isPlaying, isIntermission),
                ),
                const SizedBox(height: 10),
                // Bottom Card: 4 Multiple Choice Options
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: _buildOptionsPane(context, options, false),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }

        // ==========================================
        // LANDSCAPE / TABLET / DESKTOP: 2-COLUMN SPLIT
        // ==========================================
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT PANE: Listening Audio Player & Prompt
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
                  child: _buildAudioPromptPane(context, true, isLocked, isPlaying, isIntermission),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // RIGHT PANE: 4 Multiple-Choice Options
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
                  child: _buildOptionsPane(context, options, true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioPromptPane(BuildContext context, bool isLandscape, bool isLocked, bool isPlaying, bool isIntermission) {
    String? questionImageUrl;
    if (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).hasQuestionImage) {
      questionImageUrl = (widget.question as UniversalQuestion).questionImageUrl;
    }

    return Column(
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
                        ne: 'अडियो मात्र (Audio Only)',
                        en: 'Strict Audio Only',
                        ko: '오디오 전용',
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
          style: TextStyle(
            fontSize: isLandscape ? 14 : 16,
            fontWeight: FontWeight.bold,
            height: 1.35,
            color: const Color(0xFF0F172A),
          ),
        ),
        if (questionImageUrl != null && questionImageUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              constraints: BoxConstraints(maxHeight: isLandscape ? 150 : 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: SmartImageWidget(
                imageSource: questionImageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
        SizedBox(height: isLandscape ? 8 : 14),

        // Speaker Icon centered below the question
        Center(
          child: Tooltip(
            message: isLocked
                ? LanguageService.instance.trText(ne: 'अडियो समाप्त (२/२ सकियो)', en: 'Audio Completed (Locked)', ko: '재생 완료 (오디오 잠금)')
                : (isPlaying
                    ? LanguageService.instance.trText(ne: 'अडियो बजिरहेको छ...', en: 'Audio playing...', ko: '오디오 재생 중...')
                    : LanguageService.instance.trText(ne: 'अडियो सुन्नुहोस् (यहाँ थिच्नुहोस्)', en: 'Listen to Audio (Click to Play)', ko: '오디오 듣기 (클릭하여 재생)')),
            child: Material(
              color: isLocked
                  ? Colors.grey.shade200
                  : (isPlaying ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLocked ? null : _startContinuousAudioLoop,
                child: Container(
                  padding: EdgeInsets.all(isLandscape ? 10 : 16),
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
                    size: isLandscape ? 28 : 36,
                    color: isLocked
                        ? Colors.grey.shade500
                        : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsPane(BuildContext context, List<String> options, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Options Stacked Vertically
        ...List.generate(4, (index) {
          final isSelected = widget.selectedOptionIndex == index;
          const circledNumbers = ['①', '②', '③', '④'];
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
              : (imageOptionUrl == null ? '${index + 1}번' : '');

          final hasAudioCapability = (audioOptionUrl != null && audioOptionUrl.isNotEmpty) || optionText.isNotEmpty;

          return Container(
            margin: EdgeInsets.only(bottom: isLandscape ? 6 : 8),
            child: Material(
              color: isSelected ? const Color(0xFFFFFBEB) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => widget.onOptionSelected(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 8 : 12,
                    vertical: isLandscape ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Circled Number
                      Container(
                        width: isLandscape ? 24 : 28,
                        height: isLandscape ? 24 : 28,
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
                            fontSize: isLandscape ? 13 : 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: isLandscape ? 8 : 12),

                      // Option Text & Media
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayText.isNotEmpty)
                              SequenceOptionWidget(
                                text: displayText,
                                isSelected: isSelected,
                                baseStyle: TextStyle(
                                  fontSize: isLandscape ? 13 : 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF92400E) : Colors.black87,
                                ),
                              ),
                            if (imageOptionUrl != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                constraints: BoxConstraints(maxHeight: isLandscape ? 75 : 100),
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
                            if (hasAudioCapability) ...[
                              const SizedBox(height: 4),
                              ValueListenableBuilder<String?>(
                                valueListenable: AudioPlaybackService.instance.currentAudioSourceNotifier,
                                builder: (context, currentSource, _) {
                                  final isPlayingThis = AudioPlaybackService.instance.isPlaying &&
                                      ((audioOptionUrl != null && currentSource == audioOptionUrl) ||
                                          (optionText.isNotEmpty && currentSource == 'tts:$optionText'));

                                  return InkWell(
                                    onTap: () => _playOptionAudio(index, audioOptionUrl, optionText),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPlayingThis ? const Color(0xFFFDE68A) : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isPlayingThis ? const Color(0xFFD97706) : Colors.amber.shade300,
                                          width: isPlayingThis ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPlayingThis ? Icons.volume_up : Icons.play_circle_fill,
                                            size: 14,
                                            color: const Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            isPlayingThis
                                                ? LanguageService.instance.trText(
                                                    ne: 'बज्दैछ...',
                                                    en: 'Playing...',
                                                    ko: '재생 중...',
                                                  )
                                                : LanguageService.instance.trText(
                                                    ne: 'अडियो सुन्नुहोस्',
                                                    en: 'Play Audio',
                                                    ko: '음성 듣기',
                                                  ),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
    );
  }
}