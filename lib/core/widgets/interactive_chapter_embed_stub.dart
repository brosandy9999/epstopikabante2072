import 'package:flutter/material.dart';

Widget buildInteractiveChapterIFrame({
  required String chapterUrl,
  required String viewKey,
}) {
  return Container(
    color: const Color(0xFF202124),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        const Text(
          'स्मार्ट इन्टरएक्टिभ अडियो बुक (Smart Interactive Book)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          chapterUrl,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
