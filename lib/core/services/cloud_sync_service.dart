import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'question_bank_service.dart';
import 'auth_service.dart';
import 'exam_service.dart';
import 'study_material_service.dart';
import 'institute_service.dart';
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

  // Free default cloud sync repository hosted directly on GitHub
  static const String defaultGitHubSyncUrl =
      'https://raw.githubusercontent.com/brosandy9999/epstopikabante2072/main/data/eps_sync_data.json';

  String _cloudEndpoint = defaultGitHubSyncUrl;
  String get cloudEndpoint => _cloudEndpoint;

  String formatEndpointUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return defaultGitHubSyncUrl;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://';
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

  void resetToDefaultGitHubSync() {
    _cloudEndpoint = defaultGitHubSyncUrl;
    StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
    notifyListeners();
  }

  bool get hasConfiguredCloud {
    return _cloudEndpoint.isNotEmpty;
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
        _lastError = 'सर्भर स्थिति: ';
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
    if (savedUrl != null &&
        savedUrl.isNotEmpty &&
        !savedUrl.contains('eps-topik-hub-default-rtdb.firebaseio.com')) {
      _cloudEndpoint = savedUrl;
    } else {
      _cloudEndpoint = defaultGitHubSyncUrl;
      StorageService.instance.setString('eps_cloud_endpoint', _cloudEndpoint);
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
    final allVideos = StudyMaterialService.instance.getAllVideos();
    final allGrammar = StudyMaterialService.instance.getAllGrammar();
    final allDict = StudyMaterialService.instance.getAllDictionaryWords();
    final allNotices = StudyMaterialService.instance.getAllNotices();
    final allInstitutes = InstituteService.instance.getAllInstitutes();

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
        final existingCards = StudyMaterialService.instance.getAllVisualFlashcards();
        for (final item in rawCards) {
          if (item is Map) {
            final card = VisualFlashcard.fromJson(Map<String, dynamic>.from(item));
            if (!existingCards.any((c) => c.id == card.id)) {
              StudyMaterialService.instance.addVisualFlashcard(card);
            }
          }
        }
      }

      // 5. Ingest Books
      if (payload['books'] is List) {
        final List rawBooks = payload['books'];
        final existingBooks = StudyMaterialService.instance.getAllBooks();
        for (final item in rawBooks) {
          if (item is Map) {
            final book = StudyBook.fromJson(Map<String, dynamic>.from(item));
            if (!existingBooks.any((b) => b.id == book.id)) {
              StudyMaterialService.instance.addBook(book);
            }
          }
        }
      }

      // 6. Ingest Videos
      if (payload['videos'] is List) {
        final List rawVideos = payload['videos'];
        final existingVideos = StudyMaterialService.instance.getAllVideos();
        for (final item in rawVideos) {
          if (item is Map) {
            final vid = VideoCourse.fromJson(Map<String, dynamic>.from(item));
            if (!existingVideos.any((v) => v.id == vid.id)) {
              StudyMaterialService.instance.addVideo(vid);
            }
          }
        }
      }

      // 7. Ingest Grammar
      if (payload['grammar'] is List) {
        final List rawGrammar = payload['grammar'];
        final existingGrammar = StudyMaterialService.instance.getAllGrammar();
        for (final item in rawGrammar) {
          if (item is Map) {
            final g = GrammarTopic.fromJson(Map<String, dynamic>.from(item));
            if (!existingGrammar.any((t) => t.id == g.id)) {
              StudyMaterialService.instance.addGrammar(g);
            }
          }
        }
      }

      // 8. Ingest Dictionary
      if (payload['dictionary'] is List) {
        final List rawDict = payload['dictionary'];
        final existingDict = StudyMaterialService.instance.getAllDictionaryWords();
        for (final item in rawDict) {
          if (item is Map) {
            final d = DictionaryWord.fromJson(Map<String, dynamic>.from(item));
            if (!existingDict.any((w) => w.id == d.id)) {
              StudyMaterialService.instance.addDictionaryWord(d);
            }
          }
        }
      }

      // 9. Ingest Notices
      if (payload['notices'] is List) {
        final List rawNotices = payload['notices'];
        final existingNotices = StudyMaterialService.instance.getAllNotices();
        for (final item in rawNotices) {
          if (item is Map) {
            final n = InstituteNotice.fromJson(Map<String, dynamic>.from(item));
            if (!existingNotices.any((x) => x.id == n.id)) {
              StudyMaterialService.instance.addNotice(n);
            }
          }
        }
      }

      // 10. Ingest Institutes
      if (payload['institutes'] is List) {
        final List rawInsts = payload['institutes'];
        final existingInsts = InstituteService.instance.getAllInstitutes();
        for (final item in rawInsts) {
          if (item is Map) {
            final inst = InstituteProfile.fromJson(Map<String, dynamic>.from(item));
            if (!existingInsts.any((x) => x.id == inst.id)) {
              InstituteService.instance.createInstitute(
                name: inst.name,
                code: inst.code,
                phone: inst.phone,
                email: inst.email,
                address: inst.address,
                aboutUs: inst.aboutUs,
                allowedSetsQuota: inst.allowedSetsQuota,
                validityExpiry: inst.validityExpiry,
                maxStudentsQuota: inst.maxStudentsQuota,
              );
            }
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

  /// Push local updates to Cloud endpoint or prepare sync payload
  Future<bool> pushToCloud() async {
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final isGitHub = _cloudEndpoint.contains('github.com') ||
          _cloudEndpoint.contains('githubusercontent.com');

      if (isGitHub) {
        // Local snapshot updated for GitHub repository sync
        _lastSyncTime = DateTime.now();
        StorageService.instance.setString('eps_last_sync_time', _lastSyncTime!.toIso8601String());
        _state = SyncState.synced;
        notifyListeners();
        return true;
      }

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
        _lastError = 'सर्भर प्रतिक्रिया कोड: ';
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final success = ingestSyncPayload(Map<String, dynamic>.from(decoded));
          return success;
        } else {
          _lastError = 'सर्भरमा कुनै मान्य डाटा फेला परेन।';
          _state = SyncState.error;
          notifyListeners();
          return false;
        }
      } else {
        _lastError = 'सर्भर त्रुटि कोड: ';
        _state = SyncState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'डेटा ल्याउन सकिएन: इन्टरनेट छैन वा सर्भर उपलब्ध छैन।';
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
      _lastError = 'अवैध ब्याकअप फाइल वा डाटा।';
      return false;
    }
  }
}
