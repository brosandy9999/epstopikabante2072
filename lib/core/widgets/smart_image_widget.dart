import 'dart:convert';
import 'package:flutter/material.dart';

class SmartImageWidget extends StatelessWidget {
  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const SmartImageWidget({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallback,
  });

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

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
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
