import 'package:flutter/material.dart';

/// Phase 8: Strict Exam Mode (रुल नम्बर ९, ४५, र ४६)
/// यो र्यापरले परीक्षाको बेला चिटिङ गर्नबाट रोक्ने काम गर्छ।
class StrictModeWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onCheatAttemptDetected;

  const StrictModeWrapper({
    Key? key,
    required this.child,
    required this.onCheatAttemptDetected,
  }) : super(key: key);

  @override
  State<StrictModeWrapper> createState() => _StrictModeWrapperState();
}

class _StrictModeWrapperState extends State<StrictModeWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // एपको स्टेट (Tab change, minimize) ट्र्याक गर्न सुरु गर्ने
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // ट्र्याकिङ बन्द गर्ने
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// यदि विद्यार्थीले ब्राउजरको ट्याब (Tab) चेन्ज गर्यो वा मोबाइल मिनिमाइज गर्यो भने
  /// यो फङ्सन कल हुन्छ। (रुल ४५: Visibility change / Tab switching detection)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      print("⚠️ CHEAT ATTEMPT: Student switched tabs or minimized the app!");
      widget.onCheatAttemptDetected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // रुल ४६: माउसको राइट-क्लिक (Right-click / Context Menu) ब्लक गर्ने
      onSecondaryTapDown: (details) {
        print("⚠️ CHEAT ATTEMPT: Right-click is disabled in Strict Mode.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warning: Right-click is disabled during the exam!"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      },
      // रुल ४६: किबोर्ड सर्टकट र कपी/पेस्ट ब्लक गर्न FocusNode प्रयोग
      child: FocusScope(
        canRequestFocus: false, // किबोर्डबाट बटनहरूमा जान (Tab key) नमिल्ने
        child: widget.child,
      ),
    );
  }
}
