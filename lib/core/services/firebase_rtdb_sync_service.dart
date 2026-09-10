import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// Firebase Realtime Database Sync Service (No Token Required)
///
/// Architecture:
///   - Public READ  → GET  `/eps_sync.json`         (no auth)
///   - Authed WRITE → PUT  `/eps_sync.json?auth=TOKEN`
///   - Anonymous sign-in via Firebase Auth REST API (invisible to user)
///
/// Developer setup (one-time, in Firebase Console → topik-abante):
///   1. Realtime Database → Create database
///   2. Rules:
///      `{ "rules": { "eps_sync": { ".read": true, ".write": "auth != null" } } }`
///   3. Authentication → Sign-in method → Anonymous → Enable
class FirebaseRtdbSyncService {
  static final FirebaseRtdbSyncService instance =
      FirebaseRtdbSyncService._internal();
  FirebaseRtdbSyncService._internal();

  // ── Firebase project config (embedded — apiKey is safe to expose) ──
  static const String _apiKey = 'AIzaSyCwHKCw4W_zM__zGLyPrkQTRIrA6B7Racw'; // Real Web API key from topik-abante project
  static const String _databaseUrl =
      'https://topik-abante-default-rtdb.firebaseio.com';
  static const String _syncPath = 'eps_sync';

  static const String _keyAnonToken = 'eps_firebase_anon_token';
  static const String _keyAnonTokenExpiry = 'eps_firebase_anon_token_expiry';

  String? _anonIdToken;
  DateTime? _tokenExpiry;
  Timer? _pushDebounceTimer;

  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // Restore cached token
    _anonIdToken = StorageService.instance.getString(_keyAnonToken);
    final expiryStr = StorageService.instance.getString(_keyAnonTokenExpiry);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.tryParse(expiryStr);
    }
    // Pre-fetch token in background so first push is instant
    _ensureToken().catchError((_) => null);
  }

  // ── Anonymous Auth ──────────────────────────────────────────────────

  /// Returns a valid Firebase ID token, refreshing if expired.
  Future<String?> _ensureToken() async {
    // Token valid for >5 minutes remaining — reuse it
    if (_anonIdToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      return _anonIdToken;
    }
    return _refreshAnonToken();
  }

  Future<String?> _refreshAnonToken() async {
    try {
      final uri = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'returnSecureToken': true}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _anonIdToken = data['idToken'] as String?;
        // Firebase anon tokens last 1 hour
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        StorageService.instance.setString(_keyAnonToken, _anonIdToken ?? '');
        StorageService.instance.setString(
            _keyAnonTokenExpiry, _tokenExpiry!.toIso8601String());
        debugPrint('[FirebaseRTDB] Anonymous token refreshed ✅');
        return _anonIdToken;
      } else {
        debugPrint('[FirebaseRTDB] Auth failed: ${resp.statusCode} ${resp.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[FirebaseRTDB] Auth error: $e');
      return null;
    }
  }

  // ── PULL (public read — no auth needed) ────────────────────────────

  /// Fetches the full sync payload from Firebase RTDB.
  /// Returns null if offline or no data.
  Future<Map<String, dynamic>?> pullData() async {
    try {
      final uri = Uri.parse(
          '$_databaseUrl/$_syncPath.json?_t=${DateTime.now().millisecondsSinceEpoch}');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200 && resp.body.trim() != 'null') {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          debugPrint('[FirebaseRTDB] Pull successful ✅');
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('[FirebaseRTDB] Pull error: $e');
    }
    return null;
  }

  // ── PUSH (requires anonymous auth token) ───────────────────────────

  /// Pushes the full sync payload to Firebase RTDB.
  Future<bool> pushData(Map<String, dynamic> payload) async {
    try {
      final token = await _ensureToken();
      if (token == null) {
        debugPrint('[FirebaseRTDB] Push skipped — no auth token');
        return false;
      }
      final uri =
          Uri.parse('$_databaseUrl/$_syncPath.json?auth=$token');
      final resp = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        debugPrint('[FirebaseRTDB] Push successful ✅');
        return true;
      } else {
        debugPrint('[FirebaseRTDB] Push failed: ${resp.statusCode}');
        // Token may have been revoked — refresh on next attempt
        if (resp.statusCode == 401) {
          _anonIdToken = null;
          _tokenExpiry = null;
        }
        return false;
      }
    } catch (e) {
      debugPrint('[FirebaseRTDB] Push error: $e');
      return false;
    }
  }

  // ── Debounced Push ──────────────────────────────────────────────────

  /// Schedules a push after [delay] (default 3 seconds).
  /// Multiple calls within the delay window collapse into one push.
  void schedulePush(Map<String, dynamic> Function() payloadBuilder,
      {Duration delay = const Duration(seconds: 3)}) {
    _pushDebounceTimer?.cancel();
    _pushDebounceTimer = Timer(delay, () {
      pushData(payloadBuilder()).catchError((_) => false);
    });
  }

  void dispose() {
    _pushDebounceTimer?.cancel();
  }
}
