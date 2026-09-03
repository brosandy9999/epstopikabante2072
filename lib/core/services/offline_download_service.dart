import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../models/mock_test_model.dart';
import 'question_bank_service.dart';
import 'study_material_service.dart';

/// In-App Offline Content & Exam Download Service
/// Enables 100% offline exam taking and offline study resources viewing
/// strictly within the app (no external exports, protected local storage).
class OfflineDownloadService extends ChangeNotifier {
  static final OfflineDownloadService instance = OfflineDownloadService._internal();
  OfflineDownloadService._internal();

  static const String _keyDownloadedSets = 'eps_offline_downloaded_sets_v1';
  static const String _keyDownloadedBooks = 'eps_offline_downloaded_books_v1';

  final Set<String> _downloadedSetIds = {};
  final Set<String> _downloadedBookIds = {};
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
    } catch (_) {}
  }

  void _saveState() {
    try {
      StorageService.instance.setString(_keyDownloadedSets, jsonEncode(_downloadedSetIds.toList()));
      StorageService.instance.setString(_keyDownloadedBooks, jsonEncode(_downloadedBookIds.toList()));
    } catch (_) {}
  }

  // --- Mock Test Exam Downloads ---
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

  // --- Study Book / Material Downloads ---
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

  // --- Metrics ---
  int get downloadedSetsCount {
    init();
    return _downloadedSetIds.length;
  }

  int get downloadedBooksCount {
    init();
    return _downloadedBookIds.length;
  }

  double get estimatedStorageMb {
    init();
    final setMb = _downloadedSetIds.length * 2.5;
    final bookMb = _downloadedBookIds.length * 4.0;
    return double.parse((setMb + bookMb).toStringAsFixed(1));
  }

  Future<void> clearAllOfflineCache() async {
    init();
    _downloadedSetIds.clear();
    _downloadedBookIds.clear();
    _saveState();
    notifyListeners();
  }
}
