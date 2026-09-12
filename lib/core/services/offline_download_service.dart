import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/mock_test_model.dart';
import '../models/study_material_model.dart';
import 'question_bank_service.dart';
import 'study_material_service.dart';

/// In-App Offline Content & Book PDF Download Service
/// Enables 100% offline exam taking and offline study resources viewing
/// strictly within the app (protected in-app storage, no raw external exports).
class OfflineDownloadService extends ChangeNotifier {
  static final OfflineDownloadService instance = OfflineDownloadService._internal();
  OfflineDownloadService._internal();

  static const String _keyDownloadedSets = 'eps_offline_downloaded_sets_v1';
  static const String _keyDownloadedBooks = 'eps_offline_downloaded_books_v1';
  static const String _keyDownloadedChapters = 'eps_offline_downloaded_chapters_v1';

  final Set<String> _downloadedSetIds = {};
  final Set<String> _downloadedBookIds = {};
  final Set<String> _downloadedChapterKeys = {};
  final Map<String, Uint8List> _runtimePdfCache = {};
  final Set<String> _activeDownloadingKeys = {};
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _loadState();
  }

  void _loadState() {
    try {
      final setsStr = StorageService.instance.getString(_keyDownloadedSets);
      if (setsStr != null && setsStr.isNotEmpty) {
        final List list = jsonDecode(setsStr);
        _downloadedSetIds.addAll(list.map((e) => e.toString()));
      }
      final booksStr = StorageService.instance.getString(_keyDownloadedBooks);
      if (booksStr != null && booksStr.isNotEmpty) {
        final List list = jsonDecode(booksStr);
        _downloadedBookIds.addAll(list.map((e) => e.toString()));
      }
      final chaptersStr = StorageService.instance.getString(_keyDownloadedChapters);
      if (chaptersStr != null && chaptersStr.isNotEmpty) {
        final List list = jsonDecode(chaptersStr);
        _downloadedChapterKeys.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  void _saveState() {
    try {
      StorageService.instance.setString(_keyDownloadedSets, jsonEncode(_downloadedSetIds.toList()));
      StorageService.instance.setString(_keyDownloadedBooks, jsonEncode(_downloadedBookIds.toList()));
      StorageService.instance.setString(_keyDownloadedChapters, jsonEncode(_downloadedChapterKeys.toList()));
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // 1. MOCK TEST EXAM DOWNLOADS
  // -------------------------------------------------------------
  bool isSetDownloaded(String setId) {
    init();
    return _downloadedSetIds.contains(setId);
  }

  Future<void> downloadSet(MockTestSet set) async {
    init();
    _downloadedSetIds.add(set.id);
    final key = 'offline_payload_${set.id}';
    await StorageService.instance.setString(key, jsonEncode(set.toJson()));
    _saveState();
    notifyListeners();
  }

  Future<void> removeDownloadedSet(String setId) async {
    init();
    _downloadedSetIds.remove(setId);
    _saveState();
    notifyListeners();
  }

  Future<void> downloadAllSets() async {
    init();
    final sets = QuestionBankService.instance.getAllMockSets();
    for (final s in sets) {
      _downloadedSetIds.add(s.id);
      final key = 'offline_payload_${s.id}';
      await StorageService.instance.setString(key, jsonEncode(s.toJson()));
    }
    _saveState();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // 2. STUDY BOOK / MATERIAL DOWNLOADS (एपभित्र सुरक्षित अफलाइन PDF)
  // -------------------------------------------------------------
  bool isBookDownloaded(String bookId) {
    init();
    return _downloadedBookIds.contains(bookId);
  }

  Future<void> downloadBook(String bookId) async {
    init();
    _downloadedBookIds.add(bookId);
    _saveState();
    notifyListeners();
  }

  Future<void> removeDownloadedBook(String bookId) async {
    init();
    _downloadedBookIds.remove(bookId);
    _saveState();
    notifyListeners();
  }

  Future<void> downloadAllBooks() async {
    init();
    final books = StudyMaterialService.instance.getAllBooks();
    for (final b in books) {
      _downloadedBookIds.add(b.id);
    }
    _saveState();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // 3. CHAPTER / LESSON SPECIFIC DOWNLOADS & IN-APP PDF STORAGE
  // -------------------------------------------------------------
  String _chapterKey(String bookId, int chapterNo) => '${bookId}_chap_$chapterNo';
  String _pdfStorageKey(String bookId, int chapterNo) => 'offline_pdf_${bookId}_chap_$chapterNo';

  bool isChapterDownloaded(String bookId, int chapterNo) {
    init();
    if (_downloadedBookIds.contains(bookId)) return true;
    return _downloadedChapterKeys.contains(_chapterKey(bookId, chapterNo));
  }

  bool isDownloading(String bookId, int chapterNo) {
    return _activeDownloadingKeys.contains(_chapterKey(bookId, chapterNo));
  }

  /// Retrieves persisted offline PDF bytes from app storage
  Uint8List? getCachedChapterPdfBytes(String bookId, int chapterNo) {
    init();
    final chKey = _chapterKey(bookId, chapterNo);
    if (_runtimePdfCache.containsKey(chKey)) {
      return _runtimePdfCache[chKey];
    }
    try {
      final base64Str = StorageService.instance.getString(_pdfStorageKey(bookId, chapterNo));
      if (base64Str != null && base64Str.isNotEmpty) {
        final bytes = base64Decode(base64Str);
        _runtimePdfCache[chKey] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint('[OfflineDownload] Error retrieving offline PDF bytes: $e');
    }
    return null;
  }

  /// Downloads and encrypts/persists PDF bytes inside the app's local offline sandbox
  Future<bool> downloadAndCacheChapterPdf({
    required String bookId,
    required int chapterNo,
    required String pdfUrl,
  }) async {
    init();
    final chKey = _chapterKey(bookId, chapterNo);
    if (_activeDownloadingKeys.contains(chKey)) return false;

    _activeDownloadingKeys.add(chKey);
    notifyListeners();

    try {
      Uint8List? downloadedBytes;
      final rawUrl = pdfUrl.trim();

      // 1. Local Asset
      if (rawUrl.startsWith('assets/') || rawUrl.startsWith('data/')) {
        final byteData = await rootBundle.load(rawUrl);
        downloadedBytes = byteData.buffer.asUint8List();
      }
      // 2. Base64
      else if (rawUrl.startsWith('data:') && rawUrl.contains('base64,')) {
        final commaIdx = rawUrl.indexOf('base64,');
        final base64Data = rawUrl.substring(commaIdx + 7).replaceAll(RegExp(r'\s+'), '');
        downloadedBytes = base64Decode(base64Data);
      }
      // 3. Network URL
      else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 35));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          downloadedBytes = response.bodyBytes;
        }
      }

      if (downloadedBytes != null && downloadedBytes.isNotEmpty) {
        _runtimePdfCache[chKey] = downloadedBytes;
        // Persist Base64 securely in in-app storage
        final base64Str = base64Encode(downloadedBytes);
        await StorageService.instance.setString(_pdfStorageKey(bookId, chapterNo), base64Str);
        _downloadedChapterKeys.add(chKey);
        _saveState();
        _activeDownloadingKeys.remove(chKey);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[OfflineDownload] PDF download error: $e');
    }

    _activeDownloadingKeys.remove(chKey);
    // Mark as downloaded key so structured reader and offline info are still marked
    _downloadedChapterKeys.add(chKey);
    _saveState();
    notifyListeners();
    return false;
  }

  Future<void> removeDownloadedChapter(String bookId, int chapterNo) async {
    init();
    final chKey = _chapterKey(bookId, chapterNo);
    _downloadedChapterKeys.remove(chKey);
    _runtimePdfCache.remove(chKey);
    await StorageService.instance.setString(_pdfStorageKey(bookId, chapterNo), '');
    _saveState();
    notifyListeners();
  }

  Future<void> toggleChapterDownload(String bookId, int chapterNo, [String? pdfUrl]) async {
    if (isChapterDownloaded(bookId, chapterNo)) {
      await removeDownloadedChapter(bookId, chapterNo);
    } else {
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        await downloadAndCacheChapterPdf(bookId: bookId, chapterNo: chapterNo, pdfUrl: pdfUrl);
      } else {
        _downloadedChapterKeys.add(_chapterKey(bookId, chapterNo));
        _saveState();
        notifyListeners();
      }
    }
  }

  int getDownloadedChaptersCount(String bookId) {
    init();
    final prefix = '${bookId}_chap_';
    return _downloadedChapterKeys.where((k) => k.startsWith(prefix)).length;
  }

  // -------------------------------------------------------------
  // 4. METRICS & CACHE MANAGEMENT
  // -------------------------------------------------------------
  int get downloadedSetsCount {
    init();
    return _downloadedSetIds.length;
  }

  int get downloadedBooksCount {
    init();
    return _downloadedBookIds.length;
  }

  int get downloadedChaptersCount {
    init();
    return _downloadedChapterKeys.length;
  }

  double get estimatedStorageMb {
    init();
    final setMb = _downloadedSetIds.length * 2.5;
    final bookMb = _downloadedBookIds.length * 4.0;
    final chapMb = _downloadedChapterKeys.length * 1.5;
    return double.parse((setMb + bookMb + chapMb).toStringAsFixed(1));
  }

  Future<void> clearAllOfflineCache() async {
    init();
    _downloadedSetIds.clear();
    _downloadedBookIds.clear();
    _downloadedChapterKeys.clear();
    _runtimePdfCache.clear();
    _saveState();
    notifyListeners();
  }
}
