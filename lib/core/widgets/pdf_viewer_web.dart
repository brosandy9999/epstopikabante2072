// Web-only PDF viewer using HtmlElementView + iframe + Blob Object URL
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Map<String, String> _blobUrlCache = {};

/// Registers a platform view factory (once per unique dynamic safe key) and
/// returns an [HtmlElementView] that renders the PDF inside an iframe.
Widget buildPdfViewerWidget(String url, String viewId) {
  final cleanUrl = url.trim();
  String displayUrl = cleanUrl;

  // 1. If base64 data URL: convert to Blob URL so browser PDF viewer renders it cleanly
  if (cleanUrl.startsWith('data:application/pdf') ||
      cleanUrl.startsWith('data:;base64,') ||
      (cleanUrl.startsWith('data:') && cleanUrl.contains('base64,'))) {
    if (_blobUrlCache.containsKey(cleanUrl)) {
      displayUrl = _blobUrlCache[cleanUrl]!;
    } else {
      try {
        final commaIdx = cleanUrl.indexOf(',');
        final base64Part =
            commaIdx != -1 ? cleanUrl.substring(commaIdx + 1) : cleanUrl;
        final Uint8List bytes =
            base64Decode(base64Part.replaceAll(RegExp(r'\s+'), ''));
        final blob = html.Blob([bytes], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        _blobUrlCache[cleanUrl] = blobUrl;
        displayUrl = blobUrl;
      } catch (e) {
        debugPrint('[PdfViewerWeb] Error converting base64 PDF to blob: $e');
      }
    }
  }

  // 2. Safe unique viewType key for dynamic instantiation
  final safeKey = 'pdf_${viewId}_${cleanUrl.hashCode.abs()}';

  try {
    ui_web.platformViewRegistry.registerViewFactory(
      safeKey,
      (int id) {
        final iframe = html.IFrameElement()
          ..src = displayUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#f8fafc'
          ..allow = 'fullscreen'
          ..setAttribute('type', 'application/pdf');
        return iframe;
      },
      isVisible: true,
    );
  } catch (_) {
    // Already registered — safe to ignore
  }

  return Stack(
    children: [
      Positioned.fill(
        child: HtmlElementView(viewType: safeKey),
      ),
      // Overlay Quick Action Buttons (Open in New Tab, Refresh)
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                tooltip: 'नयाँ ट्याबमा PDF खोल्नुहोस् (Open in New Tab)',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: const BoxConstraints(),
                onPressed: () {
                  html.window.open(displayUrl, '_blank');
                },
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  'PDF Viewer',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
