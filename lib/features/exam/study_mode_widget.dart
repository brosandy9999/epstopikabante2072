import '../../core/services/language_service.dart';
import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/audio_playback_service.dart';

enum StudyAudioState { ready, playingFirst, firstComplete, playingSecond, locked }

/// Phase 10: Responsive Study Mode Interactive Question Widget
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
  double _playbackProgress = 0.0;
  bool _showScript = false;

  @override
  void dispose() {
    AudioPlaybackService.instance.stop();
    super.dispose();
  }

  /// Continuous 2-Repeat loop just like the strict exam mode
  void _startContinuousAudioLoop() {
    if (_audioState == StudyAudioState.locked ||
        _audioState == StudyAudioState.playingFirst ||
        _audioState == StudyAudioState.playingSecond) {
      return;
    }

    String speechText = widget.question.questionText;
    if (widget.question is UniversalQuestion) {
      speechText = (widget.question as UniversalQuestion).audioScript ?? widget.question.questionText;
    } else if (widget.question is ListeningAudioQuestion) {
      speechText = (widget.question as ListeningAudioQuestion).audioScript ?? widget.question.questionText;
    }

    // ROUND 1
    setState(() {
      _audioState = StudyAudioState.playingFirst;
      _playbackProgress = 0.0;
    });

    AudioPlaybackService.instance.playKoreanSpeech(speechText);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _audioState == StudyAudioState.playingFirst) {
        setState(() => _playbackProgress = 0.45);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _audioState == StudyAudioState.playingFirst) {
        setState(() => _playbackProgress = 0.85);
      }
    });

    // 1.5s intermission
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _audioState = StudyAudioState.firstComplete;
        _playbackProgress = 1.0;
      });

      // ROUND 2
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _audioState = StudyAudioState.playingSecond;
          _playbackProgress = 0.0;
        });

        AudioPlaybackService.instance.playKoreanSpeech(speechText);

        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && _audioState == StudyAudioState.playingSecond) {
            setState(() => _playbackProgress = 0.45);
          }
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _audioState == StudyAudioState.playingSecond) {
            setState(() => _playbackProgress = 0.85);
          }
        });

        // Round 2 finishes -> Locked
        Future.delayed(const Duration(milliseconds: 2400), () {
          if (!mounted) return;
          setState(() {
            _audioState = StudyAudioState.locked;
            _playbackProgress = 1.0;
          });
        });
      });
    });
  }

  @override
  void didUpdateWidget(covariant StudyModeQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      AudioPlaybackService.instance.stop();
      _audioState = StudyAudioState.ready;
      _playbackProgress = 0.0;
      _showScript = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = (widget.question is ListeningAudioQuestion) ||
        (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).isListening);
    final options = (widget.question is UniversalQuestion)
        ? (widget.question as UniversalQuestion).textOptions
        : ((widget.question is ReadingTextQuestion)
            ? (widget.question as ReadingTextQuestion).textOptions
            : ((widget.question is ListeningAudioQuestion)
                ? (widget.question as ListeningAudioQuestion).textOptions
                : <String>[]));

    final isAnswered = widget.selectedOption != null;
    final isCorrect = isAnswered &&
        widget.answerInfo != null &&
        widget.selectedOption == widget.answerInfo!.correctIndex;

    final isPlaying = _audioState == StudyAudioState.playingFirst || _audioState == StudyAudioState.playingSecond;
    final isIntermission = _audioState == StudyAudioState.firstComplete;
    final isLocked = _audioState == StudyAudioState.locked;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLandscapeOrWide = constraints.maxWidth > 750;

        if (isLandscapeOrWide) {
          // ==========================================
          // TABLET / DESKTOP / LANDSCAPE (SPLIT VIEW)
          // ==========================================
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane (Question Prompt + Visual Material / Audio Button)
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: _buildQuestionContent(isListening, isPlaying, isIntermission, isLocked),
                ),
              ),

              const SizedBox(width: 24),

              // Right Pane (4 Multiple-Choice Options + Instant Feedback)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: _buildOptionsAndFeedback(options, isAnswered, isCorrect),
                ),
              ),
            ],
          );
        } else {
          // ==========================================
          // MOBILE / PORTRAIT (TOP-TO-BOTTOM COLUMN)
          // ==========================================
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Text
        Text(
          widget.question.questionText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
        ),

        const SizedBox(height: 20),

        // If Listening: Centered Speaker Icon Button (Identical to Exam Mode)
        if (isListening) ...[
          const SizedBox(height: 10),
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
                  onTap: (isLocked || isPlaying || isIntermission) ? null : _startContinuousAudioLoop,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isLocked
                              ? Icons.volume_off
                              : (isPlaying ? Icons.volume_up : Icons.volume_up_outlined),
                          size: 34,
                          color: isLocked
                              ? Colors.grey.shade500
                              : (isPlaying ? const Color(0xFFD97706) : const Color(0xFF1E3A8A)),
                        ),
                        if (isPlaying)
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(
                              value: _playbackProgress,
                              strokeWidth: 2.5,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              isLocked
                  ? LanguageService.instance.trText(ne: 'अडियो समाप्त (२/२ बजिसक्यो)', en: 'Audio Finished (Played 2/2)', ko: '재생 종료 (2/2회 완료)')
                  : (isPlaying
                      ? (_audioState == StudyAudioState.playingFirst ? LanguageService.instance.trText(ne: 'पहिलो पटक बज्दैछ... (१/२)', en: 'Playing Round 1... (1/2)', ko: '1회차 재생 중... (1/2)') : LanguageService.instance.trText(ne: 'दोस्रो पटक बज्दैछ... (२/२)', en: 'Playing Round 2... (2/2)', ko: '2회차 자동 반복 중... (2/2)'))
                      : (isIntermission
                          ? LanguageService.instance.trText(ne: 'केही क्षणमा दोस्रो पटक स्वतः बज्नेछ...', en: 'Playing second round shortly...', ko: '잠시 후 2회차 자동 반복...')
                          : LanguageService.instance.trText(ne: '🔊 अडियो बजाउनुहोस् (२ पटक बज्नेछ)', en: '🔊 Play Audio (Plays 2 times)', ko: '🔊 오디오 재생 (2회 연속 재생)'))),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isLocked
                    ? Colors.grey.shade600
                    : (isPlaying ? const Color(0xFFB45309) : const Color(0xFF1E3A8A)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showScript = !_showScript),
              icon: Icon(_showScript ? Icons.visibility_off : Icons.subtitles, size: 16),
              label: Text(_showScript ? "대본 숨기기 (Hide Script)" : "🎧 대본 보기 (Audio Script)"),
            ),
          ),
          if (_showScript && widget.question is ListeningAudioQuestion) ...[
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
                      Text("듣기 대본 (Listening Dialogue):",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (widget.question as ListeningAudioQuestion).audioScript ?? widget.question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if ((widget.question as ListeningAudioQuestion).audioScriptNepali != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "🇳🇵 ${(widget.question as ListeningAudioQuestion).audioScriptNepali}",
                      style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ] else ...[
          // If Reading: Authentic Illustration / Visual material
          _buildVisualMaterial(widget.question.questionId),
        ],
      ],
    );
  }

  /// Builds options list and instant feedback card with Nepali explanation
  Widget _buildOptionsAndFeedback(List<String> options, bool isAnswered, bool isCorrect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageService.instance.trText(ne: '[विकल्प छनोट] सहि उत्तर रोज्नुहोस्:', en: '[Options] Choose the correct answer:', ko: '[보기 선택] 정답을 고르십시오:'),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 14),

        // 4 Options
        ...List.generate(options.length, (index) {
          final circledNumbers = ['①', '②', '③', '④'];
          final label = index < circledNumbers.length ? circledNumbers[index] : '';

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
                child: Text(LanguageService.instance.trText(ne: '✓ सहि उत्तर', en: '✓ Correct Answer', ko: '✓ 정답'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              );
            } else if (isThisSelected && !isThisCorrect) {
              bgColor = const Color(0xFFFEE2E2);
              borderColor = Colors.red;
              textColor = Colors.red.shade900;
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: Text(LanguageService.instance.trText(ne: '✗ मेरो रोजाइ (गलत)', en: '✗ My Choice (Incorrect)', ko: '✗ 내 선택 (오답)'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: (isThisCorrect || isThisSelected) ? 2 : 1.2),
                  ),
                  child: Row(
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: (isThisCorrect || isThisSelected) ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isCorrect ? Colors.green.shade300 : Colors.red.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          isCorrect ? LanguageService.instance.trText(ne: 'सहि उत्तर! बधाई छ 🎉', en: 'Correct Answer! Congratulations 🎉', ko: '맞았습니다! 정답입니다 🎉') : LanguageService.instance.trText(ne: 'गलत उत्तर! फेरि प्रयास गर्नुहोस् ❌', en: 'Incorrect! Try again ❌', ko: '틀렸습니다! 다시 시도해보세요 ❌'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.onRetry();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(LanguageService.instance.trText(ne: 'पुनः प्रयास गर्नुहोस्', en: 'Try Again', ko: '다시 풀기')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                        side: BorderSide(color: isCorrect ? Colors.green : Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (widget.answerInfo != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LanguageService.instance.trText(ne: 'सहि उत्तर व्याख्या:', en: 'Answer Explanation:', ko: '정답 해설:'),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.answerInfo!.explanation,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Authentic illustrations / visuals for reading items
  Widget _buildVisualMaterial(String qId) {
    if (qId == 'Q01') {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 65, color: Colors.blueGrey.shade700),
            const SizedBox(height: 8),
            const Text('[ 공 책 (Notebook) ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );
    } else if (qId == 'Q02') {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 65, color: Colors.deepOrange.shade600),
            const SizedBox(height: 8),
            const Text('[ 소방관 (Firefighter) ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );
    } else if (qId == 'Q03') {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.not_interested, size: 65, color: Colors.red.shade700),
            const SizedBox(height: 8),
            const Text('[ 주차금지 (NO PARKING) ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          ],
        ),
      );
    } else if (qId == 'Q09') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade400)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📄 [행복마트 영수증]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown)),
            Text(
              '• 사과 2개: 4,000원\n• 우유 1팩: 2,500원\n• 합계: 6,500원\n• 결제방법: 신용카드 (Card)',
              style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: const Row(
        children: [
          Icon(Icons.article, color: Colors.blueGrey, size: 24),
          SizedBox(width: 10),
          Expanded(child: Text('다음을 읽고 내용과 같은 것을 고르십시오.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
