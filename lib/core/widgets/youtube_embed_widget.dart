import 'package:flutter/material.dart';
import 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart' as player_impl;

class YouTubeEmbedPlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final double? aspectRatio;
  final VoidCallback? onVideoEnded;

  const YouTubeEmbedPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = true,
    this.aspectRatio = 16 / 9,
    this.onVideoEnded,
  });

  @override
  State<YouTubeEmbedPlayer> createState() => _YouTubeEmbedPlayerState();
}

class _YouTubeEmbedPlayerState extends State<YouTubeEmbedPlayer> {
  late String _viewKey;

  @override
  void initState() {
    super.initState();
    _updateViewKey();
  }

  @override
  void didUpdateWidget(covariant YouTubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _updateViewKey();
    }
  }

  void _updateViewKey() {
    _viewKey = 'yt-view-${widget.videoId}-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) {
      return Container(
        color: const Color(0xFF0F172A),
        alignment: Alignment.center,
        child: const Text(
          'भिडियो फेला परेन वा लिङ्क अमान्य छ',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }

    Widget content = player_impl.buildYouTubeIFrame(
      videoId: widget.videoId,
      viewKey: _viewKey,
      autoPlay: widget.autoPlay,
    );

    if (widget.aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
