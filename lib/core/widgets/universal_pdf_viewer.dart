import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/language_service.dart';

/// Universal Cross-Platform PDF & Textbook Page Viewer
/// Works reliably on Web, Windows, Android, iOS, macOS, and Linux without iframe blocks!
class UniversalPdfViewerWidget extends StatefulWidget {
  final String url;
  final String viewId;

  const UniversalPdfViewerWidget({
    super.key,
    required this.url,
    required this.viewId,
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
    if (oldWidget.url != widget.url) {
      _loadPdfBytes();
    }
  }

  Future<void> _loadPdfBytes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rawUrl = widget.url.trim();

    try {
      // Case 0: Flutter Local Asset PDF
      if (rawUrl.startsWith('assets/') || rawUrl.startsWith('data/')) {
        final byteData = await rootBundle.load(rawUrl);
        if (mounted) {
          setState(() {
            _pdfBytes = byteData.buffer.asUint8List();
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
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Case 2: Raw Base64 string without data: prefix
      if (rawUrl.length > 200 && !rawUrl.startsWith('http') && !rawUrl.startsWith('blob:')) {
        try {
          final bytes = base64Decode(rawUrl.replaceAll(RegExp(r'\s+'), ''));
          if (bytes.length > 10 && mounted) {
            setState(() {
              _pdfBytes = bytes;
              _isLoading = false;
            });
            return;
          }
        } catch (_) {}
      }

      // Case 3: HTTP / HTTPS Network URL
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _pdfBytes = response.bodyBytes;
              _isLoading = false;
            });
          }
          return;
        } else {
          throw Exception('HTTP Status ${response.statusCode}');
        }
      }

      throw Exception('Invalid PDF source');
    } catch (e) {
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
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 12),
            Text(
              LanguageService.instance.trText(
                ne: 'PDF लोड हुँदैछ, कृपया प्रतीक्षा गर्नुहोस्...',
                en: 'Loading PDF document, please wait...',
                ko: 'PDF 문서를 불러오는 중입니다...',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 56, color: Colors.blueGrey),
              const SizedBox(height: 12),
              Text(
                LanguageService.instance.trText(
                  ne: 'PDF सिधै खोल्न सकिएन। बाह्य लिङ्कमा खोल्नुहोस्:',
                  en: 'Could not render PDF directly. Open external link:',
                  ko: 'PDF를 직접 불러올 수 없습니다. 외부 링크로 열기:',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_pdfBytes != null) {
                    Printing.sharePdf(bytes: _pdfBytes!, filename: 'book.pdf');
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(LanguageService.instance.trText(ne: 'PDF डाउनलोड / सेयर गर्नुहोस्', en: 'Open / Download PDF', ko: 'PDF 열기 / 다운로드')),
              ),
            ],
          ),
        ),
      );
    }

    // High-performance PDF Document Viewer using Printing Package (Works on Web, Windows, Android, iOS)
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      child: PdfPreview(
        build: (PdfPageFormat format) async => _pdfBytes!,
        useActions: false, // Clean embedding inside textbook canvas
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
          child: Text('PDF render error: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
        dynamicLayout: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}
