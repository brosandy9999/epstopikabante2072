// Stub for non-web platforms
import 'package:flutter/material.dart';

/// Returns a widget that renders a PDF/URL on the current platform.
/// On non-web platforms, shows a placeholder.
Widget buildPdfViewerWidget(String url, String viewId) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.picture_as_pdf, size: 64, color: Color(0xFF1E3A8A)),
        SizedBox(height: 12),
        Text(
          'PDF uploaded.\nOpen with a PDF viewer on mobile.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A)),
        ),
      ],
    ),
  );
}
