import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/models/exam_session_model.dart';
import '../../core/services/audio_playback_service.dart';

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
  double _playbackProgress = 0.0;

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
      _playbackProgress = 0.0;
    });

    playCurrentTrack();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _audioState == AudioState.playingFirst) {
        setState(() => _playbackProgress = 0.45);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _audioState == AudioState.playingFirst) {
        setState(() => _playbackProgress = 0.85);
      }
    });

    // Round 1 ends after 2.4s -> 1.5s brief pause before auto repeating
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _audioState = AudioState.firstComplete; // Intermission state
        _playbackProgress = 1.0;
      });

      // ----------------------------------------
      // ROUND 2: Auto Repeat 2nd Playback
      // ----------------------------------------
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _audioState = AudioState.playingSecond;
          _playbackProgress = 0.0;
        });

        playCurrentTrack();

        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && _audioState == AudioState.playingSecond) {
            setState(() => _playbackProgress = 0.45);
          }
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _audioState == AudioState.playingSecond) {
            setState(() => _playbackProgress = 0.85);
          }
        });

        // Round 2 finishes -> Permanently Locked!
        Future.delayed(const Duration(milliseconds: 2400), () {
          if (!mounted) return;
          setState(() {
            _audioState = AudioState.locked;
            _playbackProgress = 1.0;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = (widget.question is UniversalQuestion)
        ? (widget.question as UniversalQuestion).textOptions
        : ((widget.question is ListeningAudioQuestion)
            ? (widget.question as ListeningAudioQuestion).textOptions
            : <String>[]);
    final isLocked = _audioState == AudioState.locked;
    final isPlaying = _audioState == AudioState.playingFirst || _audioState == AudioState.playingSecond;
    final isIntermission = _audioState == AudioState.firstComplete;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // LEFT PANE: Listening Audio Player & Prompt
        // ==========================================
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "?? (Listening)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (widget.question is UniversalQuestion && (widget.question as UniversalQuestion).isAudioOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2410C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.audiotrack, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('केबल अडियो ट्र्याक (Pure Audio)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Instruction Text
                  Text(
                    widget.question.questionText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 30),

                  // Speaker Icon centered below the question
                  Center(
                    child: Tooltip(
                      message: isLocked
                          ? "재생 완료 (Audio Locked)"
                          : (isPlaying ? "오디오 재생 중..." : "오디오 듣기 (Click to Play Audio)"),
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
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      isLocked
                          ? "재생 완료 (Audio Locked - २ पटक बजिसक्यो)"
                          : (isPlaying
                              ? (_audioState == AudioState.playingFirst
                                  ? "🔊 1회차 오디오 재생 중... (Playing Round 1)"
                                  : "🔊 2회차 오디오 반복 중... (Playing Round 2)")
                              : (isIntermission
                                  ? "⏳ 잠시 후 2회차가 자동 재생됩니다..."
                                  : "🔊 오디오 듣기 (यहाँ थिचेपछि कोरियाली आवाज २ पटक बज्नेछ)")),
                      style: TextStyle(
                        fontSize: 13,
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

        const SizedBox(width: 25),

        // ==========================================
        // RIGHT PANE: 4 Multiple-Choice Options
        // ==========================================
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "[???] ?? ?? ?????",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    if (widget.selectedOptionIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          "??: ?",
                          style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                  ],
                ),
                const Divider(height: 24),

                // 4 Options Stacked Vertically
                ...List.generate(options.length, (index) {
                  final isSelected = widget.selectedOptionIndex == index;
                  final circledNumbers = ["?", "?", "?", "?"];
                  final numLabel = index < circledNumbers.length ? circledNumbers[index] : "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: isSelected ? const Color(0xFFFFFBEB) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => widget.onOptionSelected(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Circled Number or Radio
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFFD97706) : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  numLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Option Text
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF92400E) : Colors.black87,
                                  ),
                                ),
                              ),

                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFFD97706), size: 24),
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
      ],
    );
  }
}
