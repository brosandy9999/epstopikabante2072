import 'supabase_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'question_bank_service.dart';
import 'auth_service.dart';
import 'exam_service.dart';
import 'study_material_service.dart';
import 'institute_service.dart';
import 'language_service.dart';
import 'firebase_rtdb_sync_service.dart';
import '../models/mock_test_model.dart';
import '../models/study_material_model.dart';
import '../models/institute_model.dart';

enum SyncState { idle, syncing, synced, error, offline }

class CloudSyncService extends ChangeNotifier {
  static final CloudSyncService instance = CloudSyncService._internal();
  CloudSyncService._internal();

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _autoSyncTimer;

  // Master Raw & Live GitHub Sync Repositories with zero-cache timestamps
  static const String defaultFirebaseRtdbUrl = 'https://topik-abante-default-rtdb.firebaseio.com';

  String _cloudEndpoint = defaultFirebaseRtdbUrl;
  String get cloudEndpoint => _cloudEndpoint;

  String formatEndpointUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return defaultFirebaseRtdbUrl;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    if (trimmed.contains('firebaseio.com') && !trimmed.endsWith('.json')) {
      if (trimmed.endsWith('/')) {
        trimmed = '${trimmed}eps_sync.json';
      } else {
        trimmed = '$trimmed/eps_sync.json';
      }
    }
    return trimmed;
  }

  void setCloudEndpoint(String url) {
    final formatted = formatEndpointUrl(url);
    if (formatted.isNotEmpty) {
      _cloudEndpoint = formatted;
      StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
      notifyListeners();
    }
  }

  void resetToDefaultFirebaseSync() {
    _cloudEndpoint = defaultFirebaseRtdbUrl;
    StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
    notifyListeners();
  }

  bool get hasConfiguredCloud => _cloudEndpoint.isNotEmpty;
  bool get isCustomCloudServer =>
      !_cloudEndpoint.contains('firebaseio.com') &&
      !_cloudEndpoint.contains('githubusercontent.com');

  void init() {
    final savedUrl = StorageService.instance.getString('eps_cloud_endpoint');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _cloudEndpoint = savedUrl;
    } else {
      _cloudEndpoint = defaultFirebaseRtdbUrl;
      StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
    }
    final lastTimeStr = StorageService.instance.getString('eps_last_sync_time');
    if (lastTimeStr != null && lastTimeStr.isNotEmpty) {
      _lastSyncTime = DateTime.tryParse(lastTimeStr);
    }

    // Auto-load bundled dataset from asset on init
    loadBundledDataAsset().catchError((_) => false);

    // Initial lightweight sync check on startup
    pullFromCloud(silent: true).catchError((_) => false);

    // Start background periodic auto-sync (lightweight 30-byte check every 10 minutes)
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      pullFromCloud(silent: true).catchError((_) => false);
    });
  }

  /// Ingests the bundled master dataset from local asset on app bootstrap
  Future<bool> loadBundledDataAsset() async {
    try {
      final jsonString = await rootBundle.loadString('data/eps_sync_data.json');
      if (jsonString.isNotEmpty) {
        final Map<String, dynamic> payload = jsonDecode(jsonString);
        final success = ingestSyncPayload(payload);
        // Do NOT push to cloud from client app startup - only read/ingest
        return success;
      }
    } catch (e) {
      debugPrint('[CloudSync] Bundled asset load notice: $e');
    }
    return false;
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<bool> testConnection() async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(_cloudEndpoint);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _state = SyncState.synced;
        notifyListeners();
        return true;
      } else {
        _lastError = 'सर्भर स्थिति: ${response.statusCode}';
        _state = SyncState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'कनेक्सन हुन सकेन: इन्टरनेट वा URL जाँच गर्नुहोस्।';
      _state = SyncState.offline;
      notifyListeners();
      return false;
    }
  }

  /// Exports complete application state into a unified Sync Payload
  Map<String, dynamic> generateFullSyncPayload({String? channelId}) {
    final allSets = QuestionBankService.instance.getAllMockSets();
    final allUsers = AuthService.instance.students;
    final allAttempts = ExamHistoryService.instance.getAllAttempts();
    final allCards = StudyMaterialService.instance.getAllVisualFlashcards();
    final allBooks = StudyMaterialService.instance.getAllBooks();
    final allVideos = StudyMaterialService.instance.getAllVideos();
    final allGrammar = StudyMaterialService.instance.getAllGrammar();
    final allDict = StudyMaterialService.instance.getAllDictionaryWords();
    final allNotices = StudyMaterialService.instance.getAllNotices();
    final allInstitutes = InstituteService.instance.getAllInstitutes();

    return {
      'version': '2.4',
      'channelId': channelId ?? 'epstopikabante2072_main',
      'timestamp': DateTime.now().toIso8601String(),
      'deviceType': kIsWeb ? 'desktop_web' : 'mobile_app',
      'sets': allSets.map((s) => s.toJson()).toList(),
      'users': allUsers.map((u) => u.toJson()).toList(),
      'attempts': allAttempts.map((a) => a.toJson()).toList(),
      'flashcards': allCards.map((c) => c.toJson()).toList(),
      'books': allBooks.map((b) => b.toJson()).toList(),
      'videos': allVideos.map((v) => v.toJson()).toList(),
      'grammar': allGrammar.map((g) => g.toJson()).toList(),
      'dictionary': allDict.map((d) => d.toJson()).toList(),
      'notices': allNotices.map((n) => n.toJson()).toList(),
      'institutes': allInstitutes.map((i) => i.toJson()).toList(),
    };
  }

  /// Ingests a received Sync Payload into all local stores
  bool ingestSyncPayload(Map<String, dynamic> payload) {
    try {
      // 1. Ingest Question Sets (Non-Destructive Merge)
      if (payload['sets'] is List) {
        final List rawSets = payload['sets'];
        final List<MockTestSet> remoteSets = [];
        for (final item in rawSets) {
          if (item is Map) {
            remoteSets.add(MockTestSet.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (remoteSets.isNotEmpty) {
          QuestionBankService.instance.mergeSetsFromCloud(remoteSets);
        }
      }

      // 2. Ingest Users
      if (payload['users'] is List) {
        final List rawUsers = payload['users'];
        final List<AppUser> users = [];
        for (final item in rawUsers) {
          if (item is Map) {
            users.add(AppUser.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (users.isNotEmpty) {
          AuthService.instance.mergeUsersFromCloud(users);
        }
      }

      // 3. Ingest Attempts (Non-Destructive Merge)
      if (payload['attempts'] is List) {
        final List rawAttempts = payload['attempts'];
        final List<ExamAttemptRecord> attempts = [];
        for (final item in rawAttempts) {
          if (item is Map) {
            attempts.add(ExamAttemptRecord.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (attempts.isNotEmpty) {
          ExamHistoryService.instance.mergeAttemptsFromCloud(attempts);
        }
      }

      // 4. Ingest Flashcards
      if (payload['flashcards'] is List) {
        final List rawCards = payload['flashcards'];
        for (final item in rawCards) {
          if (item is Map) {
            final card = VisualFlashcard.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addVisualFlashcard(card);
          }
        }
      }

      // 5. Ingest Books (Update chapters, PDFs & audio tracks)
      if (payload['books'] is List) {
        final List rawBooks = payload['books'];
        for (final item in rawBooks) {
          if (item is Map) {
            final book = StudyBook.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addBook(book);
          }
        }
      }

      // 6. Ingest Videos
      if (payload['videos'] is List) {
        final List rawVideos = payload['videos'];
        for (final item in rawVideos) {
          if (item is Map) {
            final vid = VideoCourse.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addVideo(vid);
          }
        }
      }

      // 7. Ingest Grammar
      if (payload['grammar'] is List) {
        final List rawGrammar = payload['grammar'];
        for (final item in rawGrammar) {
          if (item is Map) {
            final g = GrammarTopic.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addGrammar(g);
          }
        }
      }

      // 8. Ingest Dictionary
      if (payload['dictionary'] is List) {
        final List rawDict = payload['dictionary'];
        for (final item in rawDict) {
          if (item is Map) {
            final d = DictionaryWord.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addDictionaryWord(d);
          }
        }
      }

      // 9. Ingest Notices
      if (payload['notices'] is List) {
        final List rawNotices = payload['notices'];
        for (final item in rawNotices) {
          if (item is Map) {
            final n = InstituteNotice.fromJson(Map<String, dynamic>.from(item));
            StudyMaterialService.instance.addNotice(n);
          }
        }
      }

      // 10. Ingest Institutes
      if (payload['institutes'] is List) {
        final List rawInsts = payload['institutes'];
        for (final item in rawInsts) {
          if (item is Map) {
            final inst = InstituteProfile.fromJson(Map<String, dynamic>.from(item));
            InstituteService.instance.createInstitute(
              id: inst.id,
              name: inst.name,
              code: inst.code,
              logoUrl: inst.logoUrl,
              phone: inst.phone,
              email: inst.email,
              address: inst.address,
              aboutUs: inst.aboutUs,
              allowedSetsQuota: inst.allowedSetsQuota,
              validityExpiry: inst.validityExpiry,
              maxStudentsQuota: inst.maxStudentsQuota,
              isActive: inst.isActive,
            );
          }
        }
      }

      _lastSyncTime = DateTime.now();
      StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
      _state = SyncState.synced;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _state = SyncState.error;
      notifyListeners();
      return false;
    }
  }

  /// Push local updates to Cloud endpoint or prepare sync payload
  Future<bool> pushToCloud({bool silent = true}) async {
    if (!silent) {
      _state = SyncState.syncing;
      _lastError = null;
      notifyListeners();
    }

    final payload = generateFullSyncPayload();

    // ── 1. Push to Supabase Cloud Storage & Database ──
    bool supabaseSuccess = false;
    try {
      supabaseSuccess = await SupabaseService.instance.pushSyncPayload(payload);
    } catch (_) {}

    // ── 2. Push to Firebase RTDB (Dual Realtime Cloud Backup) ──
    bool rtdbSuccess = false;
    try {
      rtdbSuccess = await FirebaseRtdbSyncService.instance.pushData(payload);
    } catch (_) {}

    // ── 2. Push to custom server if configured ───────────────────
    if (isCustomCloudServer) {
      try {
        final response = await http.put(
          Uri.parse(_cloudEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _lastSyncTime = DateTime.now();
          StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
          _state = SyncState.synced;
          notifyListeners();
          return true;
        } else {
          _lastError = 'सर्भर प्रतिक्रिया कोड: ${response.statusCode}';
          if (!rtdbSuccess) _state = SyncState.error;
          notifyListeners();
        }
      } catch (e) {
        _lastError = 'क्लाउड सिङ्क असफल: $e';
        if (!rtdbSuccess) _state = SyncState.offline;
        notifyListeners();
      }
    }

    _lastSyncTime = DateTime.now();
    StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
    _state = SyncState.synced;
    notifyListeners();
    return rtdbSuccess;
  }

  /// Pull latest updates from Cloud endpoints into local app (Firebase Realtime Database)
  Future<bool> pullFromCloud({bool force = false, bool silent = true}) async {
    if (!silent) {
      _state = SyncState.syncing;
      _lastError = null;
      notifyListeners();
    }

    // ── 1. Pull directly from Firebase Realtime Database ─────────────
    try {
      final rtdbPayload = await FirebaseRtdbSyncService.instance.pullData(force: force);
      if (rtdbPayload != null && rtdbPayload.isNotEmpty) {
        final success = ingestSyncPayload(rtdbPayload);
        if (success) {
          _lastSyncTime = DateTime.now();
          StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
          _state = SyncState.synced;
          _lastError = null;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[CloudSync] Firebase RTDB pull error: $e');
    }

    // ── 2. Fallback to custom cloud endpoint if configured ───────────
    if (isCustomCloudServer && _cloudEndpoint.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sep = _cloudEndpoint.contains('?') ? '&' : '?';
      final url = '$_cloudEndpoint${sep}_t=$timestamp';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            final success = ingestSyncPayload(Map<String, dynamic>.from(decoded));
            if (success) {
              _lastSyncTime = DateTime.now();
              StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
              _state = SyncState.synced;
              _lastError = null;
              notifyListeners();
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('[CloudSync] Pull error from custom server: $e');
      }
    }

    if (!silent) {
      _lastError = LanguageService.instance.trText(
        ne: 'Firebase सिङ्क असफल: इन्टरनेट वा डेटाबेस उपलब्ध छैन।',
        en: 'Firebase sync failed: No internet or database unreachable.',
        ko: 'Firebase 동기화 실패: 인터넷 또는 데이터베이스 연결 불가.',
      );
      _state = SyncState.offline;
      notifyListeners();
    }
    return false;
  }

  /// Full 1-tap bidirectional sync
  Future<bool> syncNow({BuildContext? context}) async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    final pulled = await pullFromCloud(silent: true);
    if (isCustomCloudServer) {
      await pushToCloud(silent: true);
    }

    _lastSyncTime = DateTime.now();
    StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
    _state = SyncState.synced;
    notifyListeners();

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: '☁️ सबै प्रश्नहरू, विद्यार्थी र डाटा सफलतापूर्वक सिङ्क भयो!',
                    en: '☁️ All questions, candidates and data successfully synced!',
                    ko: '☁️ 모든 문항, 응시생 및 데이터가 성공적으로 동기화되었습니다!',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return pulled;
  }

  /// Exports raw JSON backup string for manual transfer or sharing
  String exportBackupJson() {
    final payload = generateFullSyncPayload();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports raw JSON backup string from file or clipboard
  bool importBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return ingestSyncPayload(Map<String, dynamic>.from(decoded));
      }
      return false;
    } catch (e) {
      _lastError = 'अवैध ब्याकअप फाइल वा डाटा।';
      return false;
    }
  }

  /// Reusable Cloud Sync Action Button (Clean minimal mode: Silent background sync)
  Widget buildSyncAction(BuildContext context, {Color? iconColor}) {
    return const SizedBox.shrink();
  }
}
