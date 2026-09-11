import 'package:flutter/material.dart';

/// Renders EPS-TOPIK Process & Sequence Options (e.g. 'D - B - A - C - F - E')
/// with elegant step badges and directional arrows. If not a sequence, renders regular text.
class SequenceOptionWidget extends StatelessWidget {
  final String text;
  final bool isSelected;
  final TextStyle? baseStyle;

  const SequenceOptionWidget({
    super.key,
    required this.text,
    this.isSelected = false,
    this.baseStyle,
  });

  static bool isSequenceText(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return false;
    final parts = clean.split(RegExp(r'\s*[-–—➔→>]\s*'));
    return parts.length >= 3 && parts.every((p) => p.trim().isNotEmpty && p.trim().length <= 8);
  }

  @override
  Widget build(BuildContext context) {
    final clean = text.trim();
    if (!isSequenceText(clean)) {
      return Text(
        clean,
        style: baseStyle ??
            TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF92400E) : Colors.black87,
            ),
      );
    }

    final parts = clean.split(RegExp(r'\s*[-–—➔→>]\s*'));

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(parts.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Icon(
            Icons.arrow_forward_rounded,
            size: 13,
            color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade500,
          );
        }

        final itemIndex = index ~/ 2;
        final stepLabel = parts[itemIndex].trim();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
              width: 1.0,
            ),
          ),
          child: Text(
            stepLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF92400E) : const Color(0xFF1E293B),
            ),
          ),
        );
      }),
    );
  }
}