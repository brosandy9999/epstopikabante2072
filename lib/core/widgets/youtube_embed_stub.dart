import 'package:flutter/material.dart';

Widget buildYouTubeIFrame({
  required String videoId,
  required String viewKey,
  bool autoPlay = true,
}) {
  final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  return Container(
    color: Colors.black,
    alignment: Alignment.center,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.video_library, color: Colors.white54, size: 48),
          ),
        ),
        Container(color: Colors.black45),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 8),
            const Text(
              '▶ भिडियो प्ले गर्नुहोस्',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );
}
