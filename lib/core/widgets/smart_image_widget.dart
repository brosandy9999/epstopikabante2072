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

  const SmartImageWidget({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallback,
    this.enableZoom = true,
  });

  void _showZoomDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: SmartImageWidget(
                imageSource: imageSource,
                fit: BoxFit.contain,
                enableZoom: false,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
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
      return GestureDetector(
        onTap: () => _showZoomDialog(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          child: result,
        ),
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