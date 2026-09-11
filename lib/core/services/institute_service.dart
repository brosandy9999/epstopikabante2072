import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/institute_model.dart';
import 'storage_service.dart';
import 'cloud_sync_service.dart';

class InstituteService extends ChangeNotifier {
  static final InstituteService instance = InstituteService._internal();
  InstituteService._internal();

  static const String _keyInstitutes = 'eps_institutes_list_v2';
  static const String platformCopyright = '© 2026 Abante Korean Language (Abante Academy). All rights reserved.';
  List<InstituteProfile>? _institutes;

  List<InstituteProfile> getAllInstitutes() {
    if (_institutes == null) {
      _institutes = _loadInstitutesFromStorage() ?? _getDefaultInstitutes();
      _saveInstitutes();
    }
    return _institutes!;
  }

  InstituteProfile getDefaultInstitute() {
    final list = getAllInstitutes();
    return list.isNotEmpty ? list.first : _getDefaultInstitutes().first;
  }

  InstituteProfile? getInstituteById(String id) {
    if (id.trim().isEmpty) return null;
    getAllInstitutes();
    final cleanId = id.trim();
    final idx = _institutes!.indexWhere((i) => i.id == cleanId);
    if (idx != -1) return _institutes![idx];
    final idxCode = _institutes!.indexWhere((i) => i.code.trim().toUpperCase() == cleanId.toUpperCase());
    if (idxCode != -1) return _institutes![idxCode];
    final idxName = _institutes!.indexWhere((i) => i.name.trim().toLowerCase() == cleanId.toLowerCase());
    if (idxName != -1) return _institutes![idxName];
    return null;
  }

  InstituteProfile? getInstituteByCode(String code) {
    getAllInstitutes();
    final cleanCode = code.trim().toUpperCase();
    final idx = _institutes!.indexWhere((i) => i.code.trim().toUpperCase() == cleanCode);
    return idx != -1 ? _institutes![idx] : null;
  }

  void createInstitute({
    String? id,
    required String name,
    required String code,
    String logoUrl = 'assets/images/institute_logo_default.png',
    required String phone,
    required String email,
    required String address,
    String aboutUs = '',
    int allowedSetsQuota = 48,
    required DateTime validityExpiry,
    int maxStudentsQuota = 500,
    bool isActive = true,
  }) {
    getAllInstitutes();
    final profile = InstituteProfile(
      id: id ?? 'inst_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: code,
      logoUrl: logoUrl,
      phone: phone,
      email: email,
      address: address,
      aboutUs: aboutUs,
      allowedSetsQuota: allowedSetsQuota,
      validityExpiry: validityExpiry,
      maxStudentsQuota: maxStudentsQuota,
      isActive: isActive,
    );
    final idx = _institutes!.indexWhere((i) => i.id == profile.id || i.code.trim().toUpperCase() == profile.code.trim().toUpperCase());
    if (idx != -1) {
      _institutes![idx] = profile;
    } else {
      _institutes!.add(profile);
    }
    _saveInstitutes();
    notifyListeners();
  }

  void addInstituteProfile(InstituteProfile profile) {
    getAllInstitutes();
    _institutes!.add(profile);
    _saveInstitutes();
    notifyListeners();
  }

  void updateInstitute(InstituteProfile profile) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == profile.id);
    if (idx != -1) {
      _institutes![idx] = profile;
    } else {
      _institutes!.add(profile);
    }
    _saveInstitutes();
    notifyListeners();
  }

  void updateInstituteDetails({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? aboutUs,
    String? code,
  }) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final inst = _institutes![idx];
      if (name != null && name.trim().isNotEmpty) inst.name = name.trim();
      if (address != null) inst.address = address.trim();
      if (phone != null) inst.phone = phone.trim();
      if (email != null) inst.email = email.trim();
      if (logoUrl != null) inst.logoUrl = logoUrl.trim();
      if (aboutUs != null) inst.aboutUs = aboutUs.trim();
      if (code != null && code.trim().isNotEmpty) inst.code = code.trim().toUpperCase();
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

  bool canUploadCustomSet(String instituteId) {
    final institute = getInstituteById(instituteId);
    if (institute == null) return true;
    return institute.customSetQuota > 0;
  }

  bool canAccessMainSet(String instituteId) {
    final institute = getInstituteById(instituteId);
    if (institute == null) return true;
    return institute.mainSetQuota > 0;
  }

  void updateCustomSetQuota(String id, int quota) {
    getAllInstitutes();
    final idx = _institutes!.indexWhere((i) => i.id == id);
    if (idx != -1) {
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
      final list = decoded.map((e) => InstituteProfile.fromJson(Map<String, dynamic>.from(e))).toList();
      if (list.isNotEmpty) {
        return list;
      }
      return null;
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
    return <InstituteProfile>[];
  }
}