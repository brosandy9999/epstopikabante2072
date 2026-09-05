import 'cloud_sync_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/institute_model.dart';
import 'storage_service.dart';

/// Multi-Tenant Institute & Platform Copyright Management Service
class InstituteService extends ChangeNotifier {
  static final InstituteService instance = InstituteService._internal();
  InstituteService._internal();

  static const String _keyInstitutes = 'eps_institutes_v1';
  static const String platformCopyright =
      '© 2026 EPS-TOPIK CBT & UBT Examination Management System. All Rights Reserved. Master Platform Owned by Super Admin.';

  List<InstituteProfile>? _institutes;

  List<InstituteProfile> getAllInstitutes() {
    _institutes ??= _loadInstitutesFromStorage() ?? _getDefaultInstitutes();
    return List.unmodifiable(_institutes!);
  }

  InstituteProfile? getInstituteById(String id) {
    getAllInstitutes();
    try {
      return _institutes!.firstWhere((inst) => inst.id == id);
    } catch (_) {
      return null;
    }
  }

  InstituteProfile getDefaultInstitute() {
    getAllInstitutes();
    return _institutes!.first;
  }

  void createInstitute({
    required String name,
    required String code,
    required String phone,
    required String email,
    required String address,
    String? aboutUs,
    int allowedSetsQuota = 5,
    required DateTime validityExpiry,
    int maxStudentsQuota = 100,
  }) {
    getAllInstitutes();
    final newInst = InstituteProfile(
      id: 'inst_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: code,
      phone: phone,
      email: email,
      address: address,
      aboutUs: aboutUs ?? 'हाम्रो इन्स्टिच्युटमा दक्षिण कोरियाको EPS-TOPIK UBT परीक्षाको उच्चस्तरीय तयारी गराइन्छ।',
      allowedSetsQuota: allowedSetsQuota,
      validityExpiry: validityExpiry,
      maxStudentsQuota: maxStudentsQuota,
      isActive: true,
      assignedSetIds: ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'].take(allowedSetsQuota).toList(),
    );
    _institutes!.add(newInst);
    _saveInstitutes();
    notifyListeners();
  }

  void updateInstitute(InstituteProfile updated) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _institutes![idx] = updated;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void toggleInstituteActive(String id) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].isActive = !_institutes![idx].isActive;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void updateAllowedSetsQuota(String id, int quota) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].allowedSetsQuota = quota;
      // Adjust assigned sets if needed
      final currentSets = _institutes![idx].assignedSetIds;
      if (currentSets.length > quota) {
        _institutes![idx].assignedSetIds = currentSets.take(quota).toList();
      }
      _saveInstitutes();
      notifyListeners();
    }
  }

  void extendValidity(String id, int days) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final current = _institutes![idx].validityExpiry;
      final base = current.isAfter(DateTime.now()) ? current : DateTime.now();
      _institutes![idx].validityExpiry = base.add(Duration(days: days));
      _saveInstitutes();
      notifyListeners();
    }
  }

  // ----- Quota Helper Methods -----
  bool canUploadCustomSet(String instituteId) {
    final institute = getInstituteById(instituteId);
    if (institute == null) return false;
    // Placeholder logic: check if quota is > 0. Real implementation should track uploads and durations.
    return institute.customSetQuota > 0;
  }

  bool canAccessMainSet(String instituteId) {
    final institute = getInstituteById(instituteId);
    if (institute == null) return false;
    // Placeholder logic: check if quota is > 0.
    return institute.mainSetQuota > 0;
  }

  void updateCustomSetQuota(String id, int quota) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      // Enforce quota limits: must be between 1 and 100 inclusive.
      int validatedQuota = quota.clamp(1, 100);
      _institutes![idx].customSetQuota = validatedQuota;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void updateCustomSetDuration(String id, int days) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].customSetDurationDays = days;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void updateMainSetQuota(String id, int quota) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      // Enforce quota limits: must be between 1 and 100 inclusive.
      int validatedQuota = quota.clamp(1, 100);
      _institutes![idx].mainSetQuota = validatedQuota;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void updateMainSetDuration(String id, int days) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].mainSetDurationDays = days;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void updateMaxStudentsQuota(String id, int quota) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].maxStudentsQuota = quota;
      _saveInstitutes();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // Audit Logging (local + remote)
  // -------------------------------------------------------------
  static const String _keyAuditLog = 'eps_audit_log_v1';
  static const String _remoteAuditEndpoint = 'https://example.com/api/audit'; // TODO: replace with real endpoint

  /// Logs an admin action.
  /// Writes to local storage.
  Future<void> logAdminAction(String adminId, String action, Map<String, dynamic> details) async {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'adminId': adminId,
      'action': action,
      'details': details,
    };
    // ---- Local persistence ----
    try {
      final existing = StorageService.instance.getString(_keyAuditLog);
      List<dynamic> logs = [];
      if (existing != null && existing.isNotEmpty) {
        logs = jsonDecode(existing) as List<dynamic>;
      }
      logs.add(entry);
      await StorageService.instance.setString(_keyAuditLog, jsonEncode(logs));
    } catch (e) {
      debugPrint('[InstituteService] Failed to write local audit log: $e');
    }
  }

  void assignSetsToInstitute(String id, List<String> setIds) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _institutes![idx].assignedSetIds = setIds;
      _saveInstitutes();
      notifyListeners();
    }
  }

  void deleteInstitute(String id) {
    getAllInstitutes();
    _institutes!.removeWhere((i) => i.id == id);
    _saveInstitutes();
    notifyListeners();
  }

  List<InstituteProfile>? _loadInstitutesFromStorage() {
    try {
      final jsonStr = StorageService.instance.getString(_keyInstitutes);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => InstituteProfile.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveInstitutes() {
    if (_institutes == null) return;
    try {
      final list = _institutes!.map((e) => e.toJson()).toList();
      StorageService.instance.setString(_keyInstitutes, jsonEncode(list));
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    } catch (e) {
      debugPrint('[InstituteService] Failed to save institutes: $e');
    }
  }

  List<InstituteProfile> _getDefaultInstitutes() {
    return [
      InstituteProfile(
        id: 'inst_01',
        name: 'ग्लोबल कोरियन भाषा इन्स्टिच्युट (Global Korean Institute)',
        code: 'GLOBAL_KTM',
        logoUrl: 'assets/images/institute_logo_default.png',
        phone: '9851234567',
        email: 'contact@globalinstitute.edu.np',
        address: 'बागबजार, काठमाडौं (Bagbazar, Kathmandu)',
        aboutUs: 'नेपालकै अग्रणी कोरियन भाषा शिक्षण तथा EPS-TOPIK UBT परीक्षा तयारी केन्द्र। १० वर्षभन्दा बढीको अनुभव र हजारौं सफल विद्यार्थीहरू।',
        allowedSetsQuota: 5,
        validityExpiry: DateTime.now().add(const Duration(days: 365)), // 1 year active
        maxStudentsQuota: 200,
        isActive: true,
        assignedSetIds: ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'],
      ),
      InstituteProfile(
        id: 'inst_02',
        name: 'एभरेष्ट कोरियन एकेडेमी (Everest Korean Academy)',
        code: 'EVEREST_POK',
        logoUrl: 'assets/images/institute_logo_default.png',
        phone: '9846001122',
        email: 'info@everestkorean.com',
        address: 'महेन्द्रपुल, पोखरा (Mahendrapool, Pokhara)',
        aboutUs: 'गण्डकी प्रदेशको भरपर्दो कोरियन भाषा इन्स्टिच्युट। उच्चस्तरीय कम्प्युटर UBT ल्याब तथा दक्ष भाषा प्रशिक्षक।',
        allowedSetsQuota: 3,
        validityExpiry: DateTime.now().add(const Duration(days: 90)), // 3 months active
        maxStudentsQuota: 100,
        isActive: true,
        assignedSetIds: ['set_01', 'set_02', 'set_03'],
      ),
    ];
  }
}
