import 'package:flutter/material.dart';
import 'interactive_chapter_embed_stub.dart'
    if (dart.library.html) 'interactive_chapter_embed_web.dart' as chapter_impl;

class InteractiveChapterViewer extends StatefulWidget {
  final String chapterUrl;
  final String? bookId;
  final int? chapterNo;

  const InteractiveChapterViewer({
    super.key,
    required this.chapterUrl,
    this.bookId,
    this.chapterNo,
  });

  @override
  State<InteractiveChapterViewer> createState() => _InteractiveChapterViewerState();
}

class _InteractiveChapterViewerState extends State<InteractiveChapterViewer> {
  late String _viewKey;

  @override
  void initState() {
    super.initState();
    _updateViewKey();
  }

  @override
  void didUpdateWidget(covariant InteractiveChapterViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterUrl != widget.chapterUrl ||
        oldWidget.bookId != widget.bookId ||
        oldWidget.chapterNo != widget.chapterNo) {
      _updateViewKey();
    }
  }

  void _updateViewKey() {
    final clean = widget.chapterUrl.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    _viewKey = 'ch-view-${widget.bookId ?? "b"}-${widget.chapterNo ?? 0}-$clean';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chapterUrl.isEmpty) {
      return Container(
        color: const Color(0xFF202124),
        alignment: Alignment.center,
        child: const Text(
          'पाठ्यपुस्तक फेला परेन (No chapter found)',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }

    return chapter_impl.buildInteractiveChapterIFrame(
      chapterUrl: widget.chapterUrl,
      viewKey: _viewKey,
    );
  }
}
