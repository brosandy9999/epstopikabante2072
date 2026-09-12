import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/language_service.dart';
import '../services/offline_download_service.dart';
import 'pdf_blob_helper.dart';

/// In-memory cache for fast, zero-delay switching between chapters and PDF documents
final Map<String, Uint8List> _pdfBytesCache = {};

/// Universal Cross-Platform PDF & Textbook Page Viewer
/// Protected strictly for in-app viewing (No raw external exporting/sharing).
class UniversalPdfViewerWidget extends StatefulWidget {
  final String url;
  final String viewId;
  final String? bookId;
  final int? chapterNo;
  final bool showActions;
  final VoidCallback? onReloadRequested;

  const UniversalPdfViewerWidget({
    super.key,
    required this.url,
    required this.viewId,
    this.bookId,
    this.chapterNo,
    this.showActions = false,
    this.onReloadRequested,
  });

  @override
  State<UniversalPdfViewerWidget> createState() => _UniversalPdfViewerWidgetState();
}

class _UniversalPdfViewerWidgetState extends State<UniversalPdfViewerWidget> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdfBytes();
  }

  @override
  void didUpdateWidget(covariant UniversalPdfViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.bookId != widget.bookId ||
        oldWidget.chapterNo != widget.chapterNo) {
      _loadPdfBytes();
    }
  }

  /// Converts various link formats (Google Drive, Dropbox, OneDrive) into direct downloadable PDF streams
  String _normalizePdfUrl(String rawUrl) {
    var url = rawUrl.trim();

    // Google Drive share links
    if (url.contains('drive.google.com')) {
      final fileIdMatch = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (fileIdMatch != null) {
        final id = fileIdMatch.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
      final idParamMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
      if (idParamMatch != null) {
        final id = idParamMatch.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }

    // Dropbox links
    if (url.contains('dropbox.com')) {
      if (url.contains('dl=0')) {
        return url.replaceAll('dl=0', 'dl=1');
      } else if (!url.contains('dl=1')) {
        return url.contains('?') ? '$url&dl=1' : '$url?dl=1';
      }
    }

    return url;
  }

  Future<void> _loadPdfBytes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 0. Check in-app offline storage first (100% offline support)
    if (widget.bookId != null && widget.chapterNo != null) {
      final offlineBytes = OfflineDownloadService.instance.getCachedChapterPdfBytes(
        widget.bookId!,
        widget.chapterNo!,
      );
      if (offlineBytes != null && offlineBytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _pdfBytes = offlineBytes;
            _isLoading = false;
          });
        }
        return;
      }
    }

    final rawUrl = widget.url.trim();

    if (rawUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PDF URL खाली छ (No PDF URL provided)';
        });
      }
      return;
    }

    // Check in-memory cache
    if (_pdfBytesCache.containsKey(rawUrl)) {
      if (mounted) {
        setState(() {
          _pdfBytes = _pdfBytesCache[rawUrl];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Case 0: Flutter Local Asset PDF
      if (rawUrl.startsWith('assets/') || rawUrl.startsWith('data/')) {
        final byteData = await rootBundle.load(rawUrl);
        final bytes = byteData.buffer.asUint8List();
        _pdfBytesCache[rawUrl] = bytes;
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Case 1: Base64 data URI (uploaded from local computer)
      if (rawUrl.startsWith('data:') && rawUrl.contains('base64,')) {
        final commaIdx = rawUrl.indexOf('base64,');
        final base64Data = rawUrl.substring(commaIdx + 7).replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(base64Data);
        _pdfBytesCache[rawUrl] = bytes;
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Case 2: Web Blob URL (e.g. blob:http://localhost:... or blob:https://...)
      if (rawUrl.startsWith('blob:')) {
        final blobBytes = await fetchWebBlobBytes(rawUrl);
        if (blobBytes != null && blobBytes.isNotEmpty) {
          _pdfBytesCache[rawUrl] = blobBytes;
          if (mounted) {
            setState(() {
              _pdfBytes = blobBytes;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Case 3: Raw Base64 string without data: prefix
      if (rawUrl.length > 200 && !rawUrl.startsWith('http') && !rawUrl.startsWith('blob:')) {
        try {
          final bytes = base64Decode(rawUrl.replaceAll(RegExp(r'\s+'), ''));
          if (bytes.length > 10) {
            _pdfBytesCache[rawUrl] = bytes;
            if (mounted) {
              setState(() {
                _pdfBytes = bytes;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (_) {}
      }

      // Case 4: HTTP / HTTPS Network URL
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        final targetUrl = _normalizePdfUrl(rawUrl);
        final response = await http.get(
          Uri.parse(targetUrl),
          headers: {
            'Accept': 'application/pdf,*/*',
          },
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final bytes = response.bodyBytes;
          _pdfBytesCache[rawUrl] = bytes;
          if (mounted) {
            setState(() {
              _pdfBytes = bytes;
              _isLoading = false;
            });
          }
          return;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Error"}');
        }
      }

      throw Exception('अमान्य PDF स्रोत (Invalid PDF source: $rawUrl)');
    } catch (e) {
      debugPrint('[UniversalPdfViewer] PDF Load Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 14),
            Text(
              LanguageService.instance.trText(
                ne: '📄 PDF पाठ्यपुस्तक लोड हुँदैछ, कृपया प्रतीक्षा गर्नुहोस्...',
                en: '📄 Loading PDF Textbook, please wait...',
                ko: '📄 교재 PDF 문서를 불러오는 중입니다...',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                LanguageService.instance.trText(
                  ne: 'PDF पृष्ठ सिधै देखाउन सकिएन',
                  en: 'Could not render PDF directly',
                  ko: 'PDF를 직접 불러올 수 없습니다',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                LanguageService.instance.trText(
                  ne: 'इन्टरनेट नभएको वा सर्भर समस्या हुन सक्छ। कृपया पुनः प्रयास गर्नुहोस् वा पहिले डाउनलोड गरिएको भए अफलाइनबाट लोड गर्नुहोस्।',
                  en: 'Network issue or offline. Please retry or verify in-app downloaded content.',
                  ko: '네트워크 연결 또는 오프라인 저장 상태를 확인 후 다시 시도해 주세요.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  _pdfBytesCache.remove(widget.url.trim());
                  _loadPdfBytes();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(LanguageService.instance.trText(ne: 'पुनः प्रयास गर्नुहोस्', en: 'Retry Loading', ko: '다시 시도')),
              ),
            ],
          ),
        ),
      );
    }

    // Protected, In-App Only PDF Viewer (Printing & Sharing Disabled for Protection)
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      child: PdfPreview(
        build: (PdfPageFormat format) async => _pdfBytes!,
        useActions: widget.showActions,
        scrollViewDecoration: const BoxDecoration(color: Colors.white),
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        loadingWidget: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E3A8A)),
          ),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'PDF render notice: $error',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 11),
            ),
          ),
        ),
        dynamicLayout: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false, // Protected: Strictly in-app viewing only
        allowSharing: false,  // Protected: Raw PDF export disabled
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}
