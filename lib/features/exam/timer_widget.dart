import 'dart:async';
import 'package:flutter/material.dart';

/// Phase 7: Timer Engine (५० मिनेटको उल्टो टाइमर)
class ExamTimerWidget extends StatefulWidget {
  final int durationSeconds; // जस्तै: ५० मिनेट = ३००० सेकेन्ड
  final VoidCallback onTimerFinished; // समय सकिएपछि कल हुने फङ्सन (Auto-submit)
  final bool isCompact;

  const ExamTimerWidget({
    Key? key,
    required this.durationSeconds,
    required this.onTimerFinished,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<ExamTimerWidget> createState() => _ExamTimerWidgetState();
}

class _ExamTimerWidgetState extends State<ExamTimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        // समय 00:00 भएपछि आफैं सबमिट गर्ने लजिक कल हुन्छ
        widget.onTimerFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// सेकेन्डलाई MM:SS फर्म्याटमा बदल्ने
  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = seconds.toString().padLeft(2, '0');
    return "$minStr:$secStr";
  }

  @override
  Widget build(BuildContext context) {
    // समय थोरै बाँकी हुँदा (जस्तै ५ मिनेट) रातो रङ देखाउने
    Color timerColor = _remainingSeconds < 300 ? Colors.red : Colors.green.shade700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 8 : 16,
        vertical: widget.isCompact ? 3 : 8,
      ),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        border: Border.all(color: timerColor, width: widget.isCompact ? 1.0 : 2.0),
        borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: timerColor, size: widget.isCompact ? 14 : 20),
          SizedBox(width: widget.isCompact ? 4 : 8),
          Text(
            _formattedTime,
            style: TextStyle(
              fontSize: widget.isCompact ? 13 : 24,
              fontWeight: FontWeight.bold,
              color: timerColor,
              letterSpacing: widget.isCompact ? 1.0 : 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
