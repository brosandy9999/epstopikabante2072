import 'package:flutter/material.dart';
import 'dart:async';
import '../question_engine/question_template.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/language_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/widgets/sequence_option_widget.dart';

enum AudioState { ready, playingFirst, firstComplete, playingSecond, locked }

/// EPS-TOPIK Official Listening (듣기) Widget
class ListeningQuestionWidget extends StatefulWidget {
  final dynamic question;
  final int? selectedOption;
  final int? selectedOptionIndex;
  final Function(int) onOptionSelected;

  const ListeningQuestionWidget({
    super.key,
    required this.question,
    this.selectedOption,
    this.selectedOptionIndex,
    required this.onOptionSelected,
  });

  @override
  State<ListeningQuestionWidget> createState() => _ListeningQuestionWidgetState();
}

class _ListeningQuestionWidgetState extends State<ListeningQuestionWidget> {
  AudioState _audioState = AudioState.ready;
  Timer? _intermissionTimer;

  int? get _currentSelected => widget.selectedOptionIndex ?? widget.selectedOption;

  @override
  void dispose() {
    _intermissionTimer?.cancel();
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  Future<void> _startContinuousAudioLoop() async {
    if (_audioState == AudioState.locked ||
        _audioState == AudioState.playingFirst ||
        _audioState == AudioState.playingSecond) {
      return;
    }

    String speechText = '';
    String? audioPath;
    if (widget.question is UniversalQuestion) {
      speechText = (widget.question as UniversalQuestion).audioScript ?? widget.question.questionText;
      audioPath = (widget.question as UniversalQuestion).questionAudioUrl;
    } else if (widget.question is ListeningAudioQuestion) {
      speechText = (widget.question as ListeningAudioQuestion).audioScript ?? widget.question.questionText;
      audioPath = (widget.question as ListeningAudioQuestion).audioAssetPath;
    }


    Future<void> playTrack() async {
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        await AudioPlaybackService.instance.playAudioUrlAndWait(
          audioPath.trim(),
        );
      }
    }

    // ROUND 1
    if (!mounted) return;
    setState(() {
      _audioState = AudioState.playingFirst;
    });

    await playTrack();

    if (!mounted) return;
    setState(() {
      _audioState = AudioState.firstComplete;
    });

    // 2-3 sec Intermission
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // ROUND 2
    setState(() {
      _audioState = AudioState.playingSecond;
    });

    await playTrack();

    if (!mounted) return;
    setState(() {
      _audioState = AudioState.locked;
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
      rawOptions = List.generate(4, (i) => '${i + 1}번');
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isLocked = _audioState == AudioState.locked;
    final isPlaying = _audioState == AudioState.playingFirst || _audioState == AudioState.playingSecond;
    final isIntermission = _audioState == AudioState.firstComplete;

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT PANE: Listening Audio Player & Prompt (50% split)
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: _buildAudioPromptPane(context, true, isLocked, isPlaying, isIntermission),
                ),
              ),
              const SizedBox(width: 12),
              // RIGHT PANE: 4 Options (50% split)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: _buildOptions(rawOptions, isLandscape),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAudioPromptPane(context, false, isLocked, isPlaying, isIntermission),
          const SizedBox(height: 12),
          _buildOptions(rawOptions, isLandscape),
        ],
      ),
    );
  }

  Widget _buildAudioPromptPane(
    BuildContext context,
    bool isLandscape,
    bool isLocked,
    bool isPlaying,
    bool isIntermission,
  ) {
    final cleanPrompt = widget.question.questionText.split('\n').first.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Text(
            cleanPrompt,
            style: TextStyle(
              fontSize: isLandscape ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          // Question Image (if any)
          if (widget.question is UniversalQuestion &&
              (widget.question as UniversalQuestion).hasQuestionImage) ...[
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: isLandscape ? 140 : 180,
                maxHeight: isLandscape ? 220 : 280,
              ),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: SmartImageWidget(
                imageSource: (widget.question as UniversalQuestion).questionImageUrl!,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Audio Player Banner
          Center(
            child: Column(
              children: [
                Text(
                  isLocked
                      ? LanguageService.instance.trText(
                          ne: 'अडियो समाप्त (२/२ सकियो)',
                          en: 'Audio Completed (Locked)',
                          ko: '재생 완료 (오디오 잠금)',
                        )
                      : (isPlaying
                          ? LanguageService.instance.trText(
                              ne: 'अडियो बजिरहेको छ...',
                              en: 'Audio playing...',
                              ko: '오디오 재생 중...',
                            )
                          : LanguageService.instance.trText(
                              ne: 'अडियो सुन्नुहोस् (यहाँ थिच्नुहोस्)',
                              en: 'Listen to Audio (Click to Play)',
                              ko: '오디오 듣기 (클릭하여 재생)',
                            )),
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Colors.grey.shade600
                        : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: isLocked
                      ? Colors.grey.shade200
                      : (isPlaying ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isLocked ? null : _startContinuousAudioLoop,
                    child: Container(
                      padding: EdgeInsets.all(isLandscape ? 14 : 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLocked
                              ? Colors.grey.shade400
                              : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF3B82F6)),
                          width: isPlaying ? 2.5 : 1.5,
                        ),
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.volume_off
                            : (isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
                        size: isLandscape ? 32 : 36,
                        color: isLocked
                            ? Colors.grey.shade500
                            : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(List<String> rawOptions, bool isLandscape) {
    final circledNums = ['①', '②', '③', '④'];

    return Column(
      children: [
        ...List.generate(rawOptions.length, (index) {
          final isSelected = _currentSelected == index;
          final numLabel = index < circledNums.length ? circledNums[index] : '${index + 1}';
          final optionText = rawOptions[index].trim();

          String? imageOptionUrl;
          if (widget.question is UniversalQuestion) {
            final uq = widget.question as UniversalQuestion;
            if (index < uq.imageOptions.length &&
                uq.imageOptions[index] != null &&
                uq.imageOptions[index]!.trim().isNotEmpty) {
              imageOptionUrl = uq.imageOptions[index]!.trim();
            }
          }

          final displayText = optionText.isNotEmpty
              ? optionText
              : (imageOptionUrl == null ? '${index + 1}번' : '');

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
