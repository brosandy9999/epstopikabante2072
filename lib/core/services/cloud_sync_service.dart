import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'question_bank_service.dart';
import 'auth_service.dart';
import 'exam_service.dart';
import 'study_material_service.dart';
import '../models/mock_test_model.dart';
import '../models/study_material_model.dart';

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

  // Free default cloud sync repository (supports Firebase Realtime Database REST or custom API)
  String _cloudEndpoint = 'https://eps-topik-hub-default-rtdb.firebaseio.com/sync_channel.json';
  String get cloudEndpoint => _cloudEndpoint;

  String formatFirebaseUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://';
    }
    if (!trimmed.endsWith('.json')) {
      if (trimmed.endsWith('/')) {
        trimmed = '\eps_topik_sync.json';
      } else {
        trimmed = '\/eps_topik_sync.json';
      }
    }
    return trimmed;
  }

  void setCloudEndpoint(String url) {
    final formatted = formatFirebaseUrl(url);
    if (formatted.isNotEmpty) {
      _cloudEndpoint = formatted;
      StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
      notifyListeners();
    }
  }

  bool get hasConfiguredCloud {
    final saved = StorageService.instance.getString('eps_cloud_endpoint');
    return saved != null && saved.isNotEmpty;
  }

  Future<bool> testConnection() async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(_cloudEndpoint);
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _state = SyncState.synced;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Firebase सर्भर स्थिति: ';
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

  void init() {
    final savedUrl = StorageService.instance.getString('eps_cloud_endpoint');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _cloudEndpoint = savedUrl;
    }
    final lastTimeStr = StorageService.instance.getString('eps_last_sync_time');
    if (lastTimeStr != null && lastTimeStr.isNotEmpty) {
      _lastSyncTime = DateTime.tryParse(lastTimeStr);
    }
  }

  /// Exports complete application state into a unified Sync Payload
  Map<String, dynamic> generateFullSyncPayload({String? channelId}) {
    final allSets = QuestionBankService.instance.getAllMockSets();
    final allUsers = AuthService.instance.students;
    final allAttempts = ExamHistoryService.instance.getAllAttempts();
    final allCards = StudyMaterialService.instance.getAllVisualFlashcards();
    final allBooks = StudyMaterialService.instance.getAllBooks();

    return {
      'version': '2.0',
      'channelId': channelId ?? 'default_hub',
      'timestamp': DateTime.now().toIso8601String(),
      'deviceType': kIsWeb ? 'desktop_web' : 'mobile_app',
      'sets': allSets.map((s) => s.toJson()).toList(),
      'users': allUsers.map((u) => u.toJson()).toList(),
      'attempts': allAttempts.map((a) => a.toJson()).toList(),
      'flashcards': allCards.map((c) => c.toJson()).toList(),
      'books': allBooks.map((b) => b.toJson()).toList(),
    };
  }

  /// Ingests a received Sync Payload into all local stores
  bool ingestSyncPayload(Map<String, dynamic> payload) {
    try {
      // 1. Ingest Question Sets
      if (payload['sets'] is List) {
        final List rawSets = payload['sets'];
        for (final item in rawSets) {
          if (item is Map) {
            final setObj = MockTestSet.fromJson(Map<String, dynamic>.from(item));
            QuestionBankService.instance.addOrUpdateMockSet(setObj);
          }
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
          AuthService.instance.loadFromStorage(users);
          StorageService.instance.saveUsers(AuthService.instance.students);
        }
      }

      // 3. Ingest Attempts
      if (payload['attempts'] is List) {
        final List rawAttempts = payload['attempts'];
        final List<ExamAttemptRecord> attempts = [];
        for (final item in rawAttempts) {
          if (item is Map) {
            attempts.add(ExamAttemptRecord.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (attempts.isNotEmpty) {
          ExamHistoryService.instance.loadFromStorage(attempts);
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

      _lastSyncTime = DateTime.now();
      StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
      _state = SyncState.synced;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _state = SyncState.error;
      notifyListeners();
      return false;
    }
  }

  /// Push local updates to Cloud endpoint
  Future<bool> pushToCloud() async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final payload = generateFullSyncPayload();
      final response = await http.put(
        Uri.parse(_cloudEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastSyncTime = DateTime.now();
        StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
        _state = SyncState.synced;
        notifyListeners();
        return true;
      } else {
        _lastError = 'सर्भर प्रतिक्रिया: ';
        _state = SyncState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'क्लाउड सिङ्क असफल: इन्टरनेट वा URL जाँच गर्नुहोस्।';
      _state = SyncState.offline;
      notifyListeners();
      return false;
    }
  }

  /// Pull latest updates from Cloud endpoint into local app
  Future<bool> pullFromCloud() async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(_cloudEndpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final success = ingestSyncPayload(Map<String, dynamic>.from(decoded));
          return success;
        } else {
          _lastError = 'क्लाउडमा कुनै डेटा फेला परेन।';
          _state = SyncState.error;
          notifyListeners();
          return false;
        }
      } else {
        _lastError = 'सर्भर त्रुटि: ';
        _state = SyncState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'डेटा ल्याउन सकिएन: इन्टरनेट छैन वा सर्भर बन्द छ।';
      _state = SyncState.offline;
      notifyListeners();
      return false;
    }
  }

  /// Exports raw JSON backup string for manual transfer or sharing
  String exportBackupJson() {
    final payload = generateFullSyncPayload();
    return jsonEncode(payload);
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
      _lastError = 'अवैध ब्याकअप फाइल।';
      return false;
    }
  }
}
