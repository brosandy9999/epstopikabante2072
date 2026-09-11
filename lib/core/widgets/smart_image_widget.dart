import 'dart:convert';
import 'package:flutter/material.dart';

class SmartImageWidget extends StatelessWidget {
  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final bool enableZoom;
  final bool showZoomHint;

  const SmartImageWidget({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallback,
    this.enableZoom = true,
    this.showZoomHint = true,
  });

  void _showZoomDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => _ImageZoomDialog(imageSource: imageSource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clean = imageSource.trim();
    if (clean.isEmpty) {
      return fallback ?? _buildPlaceholder();
    }

    Widget img;
    if (clean.startsWith('data:image')) {
      try {
        final base64Part = clean.contains(',') ? clean.split(',')[1] : clean;
        final bytes = base64Decode(base64Part);
        img = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback ?? _buildPlaceholder(),
        );
      } catch (_) {
        img = fallback ?? _buildPlaceholder();
      }
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      img = Image.network(
        clean,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? _buildPlaceholder(),
      );
    } else {
      img = Image.asset(
        clean,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback ?? _buildPlaceholder(),
      );
    }

    Widget result = img;
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }

    if (enableZoom) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onTap: () => _showZoomDialog(context),
            onDoubleTap: () => _showZoomDialog(context),
            child: MouseRegion(
              cursor: SystemMouseCursors.zoomIn,
              child: result,
            ),
          ),
          if (showZoomHint)
            Positioned(
              right: 6,
              bottom: 6,
              child: GestureDetector(
                onTap: () => _showZoomDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text(
                        '확대',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return result;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

/// Fullscreen Interactive Zoom Dialog with Double-Tap, Pinch & Pan Controls
class _ImageZoomDialog extends StatefulWidget {
  final String imageSource;

  const _ImageZoomDialog({required this.imageSource});

  @override
  State<_ImageZoomDialog> createState() => _ImageZoomDialogState();
}

class _ImageZoomDialogState extends State<_ImageZoomDialog> {
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformController.value = Matrix4.identity()
        ..translate(-position.dx * 1.2, -position.dy * 1.2)
        ..scale(2.2);
    }
  }

  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 4.5) {
      _transformController.value = _transformController.value.scaled(1.3, 1.3, 1.0);
    }
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _transformController.value = _transformController.value.scaled(0.75, 0.75, 1.0);
    } else {
      _transformController.value = Matrix4.identity();
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Zoomable image surface
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: Center(
                child: SmartImageWidget(
                  imageSource: widget.imageSource,
                  fit: BoxFit.contain,
                  enableZoom: false,
                  showZoomHint: false,
                ),
              ),
            ),
          ),

          // Top Header Bar: Close button & Zoom Hint
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Double Click / Pinch to Zoom (더블클릭 확대)',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.75),
                    padding: const EdgeInsets.all(8),
                  ),
                  tooltip: 'Close (닫기)',
                ),
              ],
            ),
          ),

          // Bottom Floating Controls: Zoom In, Zoom Out, Reset
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white30),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 22),
                    tooltip: 'Zoom Out (축소)',
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.amberAccent, size: 18),
                    label: const Text('100%', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 22),
                    tooltip: 'Zoom In (확대)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}