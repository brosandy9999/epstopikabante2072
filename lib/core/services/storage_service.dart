import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exam_service.dart';
import 'auth_service.dart';

/// Central Cross-Platform Offline Persistence Storage Service (Step 3)
/// Automatically manages local key-value JSON persistence for:
/// 1. Exam Attempts & Mistake Reviews (विद्यार्थी परीक्षा इतिहास)
/// 2. Custom & Imported Question Bank (प्रश्न बैंक भण्डारण)
/// 3. Registered Candidate Users & Passwords (विद्यार्थी तथा पासवर्ड)
class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  static const String _keyExamAttempts = 'eps_exam_attempts_v1';
  static const String _keyCustomQuestions = 'eps_custom_questions_v1';
  static const String _keyUsers = 'eps_users_v1';
  static const String _keyLanguage = 'eps_language_v1';

  SharedPreferences? _prefs;

  /// Initialize local storage engine
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('[StorageService] SharedPreferences initialized successfully.');
    } catch (e) {
      debugPrint('[StorageService] Error initializing SharedPreferences: ');
    }
  }

  // -------------------------------------------------------------
  // 1. EXAM ATTEMPTS (परीक्षा इतिहास तथा नतिजा)
  // -------------------------------------------------------------
  Future<bool> saveExamAttempts(List<ExamAttemptRecord> attempts) async {
    if (_prefs == null) await init();
    try {
      final List<Map<String, dynamic>> list = attempts.map((a) => a.toJson()).toList();
      final String jsonStr = jsonEncode(list);
      return await _prefs?.setString(_keyExamAttempts, jsonStr) ?? false;
    } catch (e) {
      debugPrint('[StorageService] Failed to save exam attempts: ');
      return false;
    }
  }

  List<ExamAttemptRecord>? loadExamAttempts() {
    try {
      final String? jsonStr = _prefs?.getString(_keyExamAttempts);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map((item) => ExamAttemptRecord.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[StorageService] Failed to load exam attempts: ');
    }
    return null;
  }

  // -------------------------------------------------------------
  // 2. CUSTOM / IMPORTED QUESTIONS (नयाँ वा आयातित प्रश्नहरू)
  // -------------------------------------------------------------
  Future<bool> saveCustomQuestions(List<Map<String, dynamic>> questions) async {
    if (_prefs == null) await init();
    try {
      final String jsonStr = jsonEncode(questions);
      return await _prefs?.setString(_keyCustomQuestions, jsonStr) ?? false;
    } catch (e) {
      debugPrint('[StorageService] Failed to save custom questions: ');
      return false;
    }
  }

  List<Map<String, dynamic>>? loadCustomQuestions() {
    try {
      final String? jsonStr = _prefs?.getString(_keyCustomQuestions);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      debugPrint('[StorageService] Failed to load custom questions: ');
    }
    return null;
  }

  // -------------------------------------------------------------
  // 3. USERS & PASSWORDS (विद्यार्थी तथा लगइन विवरण)
  // -------------------------------------------------------------
  Future<bool> saveUsers(List<AppUser> users) async {
    if (_prefs == null) await init();
    try {
      final List<Map<String, dynamic>> list = users.map((u) => u.toJson()).toList();
      final String jsonStr = jsonEncode(list);
      return await _prefs?.setString(_keyUsers, jsonStr) ?? false;
    } catch (e) {
      debugPrint('[StorageService] Failed to save users: ');
      return false;
    }
  }

  List<AppUser>? loadUsers() {
    try {
      final String? jsonStr = _prefs?.getString(_keyUsers);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[StorageService] Failed to load users: ');
    }
    return null;
  }

  // -------------------------------------------------------------
  // 4. APP LANGUAGE (भाषा छनौट)
  // -------------------------------------------------------------
  Future<bool> saveLanguage(String langCode) async {
    if (_prefs == null) await init();
    return await _prefs?.setString(_keyLanguage, langCode) ?? false;
  }

  String? loadLanguage() {
    return _prefs?.getString(_keyLanguage);
  }

  // -------------------------------------------------------------
  // GENERIC KEY-VALUE HELPERS
  // -------------------------------------------------------------
  String? getString(String key) => _prefs?.getString(key);

  Future<bool> setString(String key, String value) async {
    if (_prefs == null) await init();
    return await _prefs?.setString(key, value) ?? false;
  }

  // -------------------------------------------------------------
  // RESET / CLEAR ALL
  // -------------------------------------------------------------
  Future<void> clearAll() async {
    await _prefs?.remove(_keyExamAttempts);
    await _prefs?.remove(_keyCustomQuestions);
    await _prefs?.remove(_keyUsers);
    await _prefs?.remove(_keyLanguage);
  }
}
