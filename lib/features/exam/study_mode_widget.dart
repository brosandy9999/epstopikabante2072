import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/widgets/sequence_option_widget.dart';
import '../../core/services/language_service.dart';

enum StudyAudioState { ready, playingFirst, firstComplete, playingSecond, locked }

/// Responsive Study Mode Interactive Question Widget
/// - Tablet/Desktop/Landscape: Left Question & Audio/Visual | Right Options & Feedback
/// - Mobile/Portrait: Top Question | Middle Options | Bottom Feedback & Explanation
class StudyModeQuestionWidget extends StatefulWidget {
  final QuestionTemplate question;
  final QuestionAnswerInfo? answerInfo;
  final int? selectedOption;
  final Function(int) onOptionSelected;
  final VoidCallback onRetry;

  const StudyModeQuestionWidget({
    super.key,
    required this.question,
    required this.answerInfo,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onRetry,
  });

  @override
  State<StudyModeQuestionWidget> createState() => _StudyModeQuestionWidgetState();
}

class _StudyModeQuestionWidgetState extends State<StudyModeQuestionWidget> {
  StudyAudioState _audioState = StudyAudioState.ready;
  bool _showScript = false;
  int _loopRunId = 0;

  @override
  void dispose() {
    _loopRunId++;
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  /// Continuous 2-Repeat loop matching EPS-TOPIK examination format
  Future<void> _startContinuousAudioLoop() async {
    if (_audioState == StudyAudioState.locked ||
        _audioState == StudyAudioState.playingFirst ||
        _audioState == StudyAudioState.playingSecond) {
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

    Future<void> playTrack() async {
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        await AudioPlaybackService.instance.playAudioUrlAndWait(
          audioPath.trim(),
        );
      }
    }

    // ROUND 1
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = StudyAudioState.playingFirst;
    });

    await playTrack();

    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = StudyAudioState.firstComplete;
    });

    // 3.0s intermission gap between round 1 and round 2
    await Future.delayed(const Duration(seconds: 3));

    // ROUND 2
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = StudyAudioState.playingSecond;
    });

    await playTrack();

    // FINISHED / LOCKED
    if (!mounted || _loopRunId != currentRun) return;
    setState(() {
      _audioState = StudyAudioState.locked;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final isAnswered = widget.selectedOption != null;
    final isCorrect = widget.answerInfo != null && widget.selectedOption == widget.answerInfo!.correctIndex;

    final isListening = (widget.question is UniversalQuestion)
        ? (widget.question as UniversalQuestion).isListening
        : (widget.question is ListeningAudioQuestion || widget.question is ListeningImageOptionsQuestion);

    List<String> rawOptions = [];
    if (widget.question is UniversalQuestion) {
      rawOptions = (widget.question as UniversalQuestion).textOptions;
    } else if (widget.question is ReadingTextQuestion) {
      rawOptions = (widget.question as ReadingTextQuestion).textOptions;
    } else if (widget.question is ReadingImageQuestion) {
      rawOptions = (widget.question as ReadingImageQuestion).textOptions;
    } else if (widget.question is ListeningAudioQuestion) {
      rawOptions = (widget.question as ListeningAudioQuestion).textOptions;
    } else if (widget.question is ListeningImageOptionsQuestion) {
      rawOptions = (widget.question as ListeningImageOptionsQuestion).imageOptionPaths;
    }

    final options = List.generate(4, (index) => (index < rawOptions.length) ? rawOptions[index] : '');

    final isPlaying = _audioState == StudyAudioState.playingFirst || _audioState == StudyAudioState.playingSecond;
    final isIntermission = _audioState == StudyAudioState.firstComplete;
    final isLocked = _audioState == StudyAudioState.locked;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth >= 720;

        if (isLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane (Question Prompt + Visual Material / Audio Button)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: _buildQuestionContent(isListening, isPlaying, isIntermission, isLocked),
                ),
              ),

              const SizedBox(width: 16),

              // Right Pane (Options + Feedback)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: _buildOptionsAndFeedback(options, isAnswered, isCorrect),
                ),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Question Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: _buildQuestionContent(isListening, isPlaying, isIntermission, isLocked),
              ),

              const SizedBox(height: 16),

              // Middle/Bottom: Options and Feedback
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: _buildOptionsAndFeedback(options, isAnswered, isCorrect),
              ),
            ],
          );
        }
      },
    );
  }

  /// Builds question prompt, illustrations (Reading) or centered speaker icon (Listening)
  Widget _buildQuestionContent(bool isListening, bool isPlaying, bool isIntermission, bool isLocked) {
    String? questionImageUrl;
    if (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).hasQuestionImage) {
      questionImageUrl = (widget.question as UniversalQuestion).questionImageUrl;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Text
        Text(
          widget.question.questionText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
        ),

        if (questionImageUrl != null && questionImageUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
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

        const SizedBox(height: 16),

        // If Listening: Centered Speaker Icon Button
        if (isListening) ...[
          Center(
            child: Tooltip(
              message: isLocked
                  ? '재생 완료 (Audio Locked)'
                  : (isPlaying ? '오디오 재생 중...' : '오디오 듣기 (Click to Play Audio)'),
              child: Material(
                color: isLocked
                    ? Colors.grey.shade200
                    : (isPlaying ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF)),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isLocked ? null : _startContinuousAudioLoop,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLocked
                            ? Colors.grey.shade400
                            : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF2563EB)),
                        width: isPlaying ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.volume_off
                          : (isPlaying ? Icons.volume_up : Icons.volume_up_outlined),
                      size: 34,
                      color: isLocked
                          ? Colors.grey.shade500
                          : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              String statusText;
              if (isLocked) {
                statusText = LanguageService.instance.trText(ne: 'अडियो समाप्त (२/२ पटक सकियो)', en: 'Audio Finished (Played 2/2)', ko: '재생 완료 (2/2회 완료)');
              } else if (isPlaying) {
                statusText = (_audioState == StudyAudioState.playingFirst)
                    ? LanguageService.instance.trText(ne: 'पहिलो पटक बज्दैछ... (१/२)', en: 'Playing Round 1... (1/2)', ko: '1회차 재생 중... (1/2)')
                    : LanguageService.instance.trText(ne: 'दोस्रो पटक दोहोरिँदैछ... (२/२)', en: 'Playing Round 2... (2/2)', ko: '2회차 반복 재생 중... (2/2)');
              } else if (isIntermission) {
                statusText = LanguageService.instance.trText(ne: 'केही क्षणमा दोस्रो पटक सुरु हुनेछ...', en: 'Playing second round shortly...', ko: '잠시 후, 2회차 재생 시작...');
              } else {
                statusText = LanguageService.instance.trText(ne: '🔊 अडियो सुन्नुहोस् (२ पटक बज्नेछ)', en: '🔊 Play Audio (Plays 2 times)', ko: '🔊 오디오 듣기 (2회 연속 재생)');
              }
              return Center(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Colors.grey.shade600
                        : (isPlaying ? const Color(0xFFB45309) : const Color(0xFF1E3A8A)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showScript = !_showScript),
              icon: Icon(_showScript ? Icons.visibility_off : Icons.subtitles, size: 16),
              label: Text(_showScript ? 'स्क्रिप्ट लुकाउनुहोस् (Hide Script)' : '📜 अडियो स्क्रिप्ट हेर्नुहोस् (Audio Script)'),
            ),
          ),
          if (_showScript) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over, size: 16, color: Color(0xFFB45309)),
                      SizedBox(width: 6),
                      Text('듣기 대본 (Listening Dialogue):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (widget.question is UniversalQuestion)
                        ? ((widget.question as UniversalQuestion).audioScript ?? widget.question.questionText)
                        : ((widget.question is ListeningAudioQuestion)
                            ? ((widget.question as ListeningAudioQuestion).audioScript ?? widget.question.questionText)
                            : widget.question.questionText),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).audioScriptNepali != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🇳🇵 ',
                      style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ] else if (widget.question is ListeningAudioQuestion && (widget.question as ListeningAudioQuestion).audioScriptNepali != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🇳🇵 ',
                      style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ] else ...[
          // If Reading: Visual Material
          _buildVisualMaterial(widget.question.questionId),
        ],
      ],
    );
  }

  Widget _buildOptionsAndFeedback(List<String> options, bool isAnswered, bool isCorrect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Options
        ...List.generate(options.length, (index) {
          final circledNumbers = ['①', '②', '③', '④'];
          final label = index < circledNumbers.length ? circledNumbers[index] : '';
          final optionText = options[index].trim();

          String? imageOptionUrl;
          if (widget.question is UniversalQuestion) {
            final uq = widget.question as UniversalQuestion;
            if (index < uq.imageOptions.length && uq.imageOptions[index] != null && uq.imageOptions[index]!.trim().isNotEmpty) {
              imageOptionUrl = uq.imageOptions[index]!.trim();
            }
          }

          final isThisSelected = widget.selectedOption == index;
          final isThisCorrect = widget.answerInfo != null && index == widget.answerInfo!.correctIndex;

          Color bgColor = Colors.white;
          Color borderColor = Colors.grey.shade300;
          Color textColor = Colors.black87;
          Widget? badge;

          if (isAnswered) {
            if (isThisCorrect) {
              bgColor = const Color(0xFFDCFCE7);
              borderColor = Colors.green;
              textColor = Colors.green.shade900;
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                child: Text(LanguageService.instance.trText(ne: '✅ सही उत्तर', en: '✅ Correct Answer', ko: '✅ 정답'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              );
            } else if (isThisSelected && !isThisCorrect) {
              bgColor = const Color(0xFFFEE2E2);
              borderColor = Colors.red;
              textColor = Colors.red.shade900;
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: Text(LanguageService.instance.trText(ne: '❌ तपाईंको छनोट (गलत)', en: '❌ My Choice (Incorrect)', ko: '❌ 내 선택 (오답)'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              );
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: isAnswered ? null : () => widget.onOptionSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: (isThisCorrect || isThisSelected) ? 2 : 1.2),
                  ),
                  child: Row(
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (optionText.isNotEmpty)
                              SequenceOptionWidget(
                                text: optionText,
                                isSelected: isThisSelected,
                                baseStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: (isThisCorrect || isThisSelected) ? FontWeight.bold : FontWeight.normal,
                                  color: textColor,
                                ),
                              ),
                            if (imageOptionUrl != null && imageOptionUrl.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 90),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SmartImageWidget(imageSource: imageOptionUrl, fit: BoxFit.contain),
                              ),
                            ],
                            
                          ],
                        ),
                      ),
                      if (badge != null) badge,
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Instant Explanation & Retry Card
        if (isAnswered) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect
                          ? LanguageService.instance.trText(ne: 'उत्कृष्ट! सही उत्तर रोज्नुभयो 🎉', en: 'Great Job! Correct Answer 🎉', ko: '정답입니다! 참 잘했어요 🎉')
                          : LanguageService.instance.trText(ne: 'गलत भयो! फेरि प्रयास गर्नुहोस् 💪', en: 'Incorrect! Try Again 💪', ko: '오답입니다! 다시 시도해 보세요 💪'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.answerInfo != null) ...[
                  Text(
                    '💡 ' + LanguageService.instance.trText(ne: 'व्याख्या (Explanation):', en: 'Explanation:', ko: '해설:'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.answerInfo!.explanation,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(LanguageService.instance.trText(ne: 'फेरि प्रयास गर्नुहोस् (Retry)', en: 'Try Again', ko: '다시 풀기')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect ? Colors.green.shade700 : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisualMaterial(String qId) {
    String? customImage;
    if (widget.question is UniversalQuestion) {
      customImage = (widget.question as UniversalQuestion).questionImageUrl;
    } else if (widget.question is ReadingImageQuestion) {
      customImage = (widget.question as ReadingImageQuestion).imageAssetPath;
    }

    if (customImage != null && customImage.trim().isNotEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: SmartImageWidget(imageSource: customImage.trim(), fit: BoxFit.contain),
      );
    }
    return const SizedBox.shrink();
  }
}
