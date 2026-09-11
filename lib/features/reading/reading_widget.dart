import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/widgets/sequence_option_widget.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/language_service.dart';

/// Phase 7: Authentic HRDK EPS-TOPIK UBT Reading Question Widget
/// Strict 1:1 replica of the official South Korea HRD EPS-TOPIK Computer Based Test (CBT/UBT) interface
class ReadingQuestionWidget extends StatelessWidget {
  final QuestionTemplate question;
  final int? selectedOptionIndex;
  final Function(int) onOptionSelected;

  const ReadingQuestionWidget({
    super.key,
    required this.question,
    this.selectedOptionIndex,
    required this.onOptionSelected,
  });

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
    if (question is UniversalQuestion) {
      rawOptions = (question as UniversalQuestion).textOptions;
    } else if (question is ReadingTextQuestion) {
      rawOptions = (question as ReadingTextQuestion).textOptions;
    } else if (question is ReadingImageQuestion) {
      rawOptions = (question as ReadingImageQuestion).textOptions;
    } else if (question is ListeningAudioQuestion) {
      rawOptions = (question as ListeningAudioQuestion).textOptions;
    } else if (question is ListeningImageOptionsQuestion) {
      rawOptions = (question as ListeningImageOptionsQuestion).imageOptionPaths;
    }

    final List<String> options = List.generate(4, (index) {
      if (index < rawOptions.length) {
        return rawOptions[index];
      }
      return '';
    });

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
                // Top Card: Prompt & Visual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: _buildPromptPane(context, false),
                ),
                const SizedBox(height: 10),
                // Bottom Card: Options
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
            // LEFT PANE: Question Text & Visual Material
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
                  child: _buildPromptPane(context, true),
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

  Widget _buildPromptPane(BuildContext context, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            LanguageService.instance.readingSectionText(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        const SizedBox(height: 8),

        // Question Instruction / Prompt
        Text(
          question.questionText,
          style: TextStyle(
            fontSize: isLandscape ? 14 : 16,
            fontWeight: FontWeight.bold,
            height: 1.35,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: isLandscape ? 8 : 12),

        // Visual Material / Reading Passage Box (ONLY if image or passage exists)
        _buildQuestionMaterial(question.questionId, question.questionText, isLandscape),
      ],
    );
  }

  Widget _buildOptionsPane(BuildContext context, List<String> options, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Options Stacked Vertically
        ...List.generate(4, (index) {
          final isSelected = selectedOptionIndex == index;
          const circledNumbers = ['①', '②', '③', '④'];
          final numLabel = circledNumbers[index];
          final optionText = options[index].trim();

          // Check if image option exists
          String? imageOptionUrl;
          if (question is UniversalQuestion) {
            final uq = question as UniversalQuestion;
            if (index < uq.imageOptions.length && uq.imageOptions[index] != null && uq.imageOptions[index]!.trim().isNotEmpty) {
              imageOptionUrl = uq.imageOptions[index]!.trim();
            }
          }

          // Check if audio option exists
          String? audioOptionUrl;
          if (question is UniversalQuestion) {
            final uq = question as UniversalQuestion;
            if (index < uq.audioOptions.length && uq.audioOptions[index] != null && uq.audioOptions[index]!.trim().isNotEmpty) {
              audioOptionUrl = uq.audioOptions[index]!.trim();
            }
          }

          final displayText = optionText.isNotEmpty
              ? optionText
              : (imageOptionUrl == null ? '${index + 1}번' : '');

          final hasAudioCapability = (audioOptionUrl != null && audioOptionUrl.isNotEmpty) || optionText.isNotEmpty;

          return Container(
            margin: EdgeInsets.only(bottom: isLandscape ? 6 : 8),
            child: Material(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onOptionSelected(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 8 : 12,
                    vertical: isLandscape ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
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
                          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade400,
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
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
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
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPlayingThis ? const Color(0xFFDBEAFE) : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isPlayingThis ? const Color(0xFF2563EB) : Colors.blue.shade200,
                                          width: isPlayingThis ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPlayingThis ? Icons.volume_up : Icons.play_circle_fill,
                                            size: 14,
                                            color: const Color(0xFF1E3A8A),
                                          ),
                                          const SizedBox(width: 4),
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
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
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
                        const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
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

  /// Builds authentic illustrations, signage, receipts, or dialog boxes for Korean test items
  Widget _buildQuestionMaterial(String qId, String text, [bool isLandscape = false]) {
    String? customImage;
    if (question is UniversalQuestion) {
      customImage = (question as UniversalQuestion).questionImageUrl;
    } else if (question is ReadingImageQuestion) {
      customImage = (question as ReadingImageQuestion).imageAssetPath;
    }

    final cleanImg = (customImage != null &&
            customImage.trim().isNotEmpty &&
            customImage.trim() != 'null' &&
            customImage.trim() != 'undefined' &&
            !customImage.trim().endsWith('/null') &&
            !customImage.trim().endsWith('/undefined'))
        ? customImage.trim()
        : null;

    final imgHeight = isLandscape ? 135.0 : 190.0;

    if (cleanImg != null) {
      return Container(
        height: imgHeight + 10,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SmartImageWidget(imageSource: cleanImg, height: imgHeight, fit: BoxFit.contain),
      );
    }

    if (text.contains('\n')) {
      final passageText = text.split('\n').skip(1).join('\n').trim();
      if (passageText.isNotEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            passageText,
            style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF334155)),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}