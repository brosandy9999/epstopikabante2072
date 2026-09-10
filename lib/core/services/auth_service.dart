import 'firebase_rtdb_sync_service.dart';
import 'cloud_sync_service.dart';
import 'language_service.dart';
import 'exam_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

enum UserRole { superAdmin, admin, student }

class AppUser {
  final String id;
  String username;
  String password;
  String name;
  String? registrationNo;
  String? mobileNumber;
  String batch;
  String sector;
  String status;
  final UserRole role;
  String instituteId;
  String instituteName;
  String instituteLogo;
  String? profilePhoto;
  int allowedSetsQuota; // -1 for unlimited, or 1, 5, 10, 20, 50 etc.
  DateTime? validityExpiry; // Expiry date (Calendar-selectable)
  List<String> unlockedSetIds;
  int setsUsedCount;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    this.registrationNo,
    this.mobileNumber,
    this.batch = '2026 Batch A (बिहानी सत्र)',
    this.sector = '제조업 (Manufacturing)',
    this.status = 'सक्रिय (Active)',
    required this.role,
    this.instituteId = 'inst_01',
    this.instituteName = 'ग्लोबल कोरियन भाषा इन्स्टिच्युट',
    this.instituteLogo = 'assets/images/institute_logo_default.png',
    this.profilePhoto,
    this.allowedSetsQuota = 10,
    DateTime? validityExpiry,
    List<String>? unlockedSetIds,
    this.setsUsedCount = 0,
  })  : validityExpiry = validityExpiry ?? DateTime.now().add(const Duration(days: 60)),
        unlockedSetIds = unlockedSetIds ?? const [];

  bool get isExpired {
    if (role != UserRole.student) return false;
    if (validityExpiry == null) return false;
    return DateTime.now().isAfter(validityExpiry!);
  }

  bool get isPendingApproval =>
      status.contains('प्रतीक्षारत') ||
      status.toLowerCase().contains('pending') ||
      status.contains('स्वीकृति पर्खिरहेको');

  int get daysRemaining {
    if (validityExpiry == null) return 999;
    final diff = validityExpiry!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isUnlimitedQuota => allowedSetsQuota <= 0 || allowedSetsQuota >= 999;

  String get quotaSummaryText {
    if (isUnlimitedQuota) {
      return LanguageService.instance.trText(ne: 'असीमित सेट', en: 'Unlimited Sets', ko: '무제한 세트');
    }
    return '$allowedSetsQuota ' + LanguageService.instance.trText(ne: 'सेट', en: 'Sets', ko: '세트');
  }

  String get validitySummaryText {
    if (validityExpiry == null) {
      return LanguageService.instance.trText(ne: 'असीमित म्याद', en: 'No Expiry', ko: '무제한 기간');
    }
    final d = validityExpiry!;
    final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    if (isExpired) {
      return LanguageService.instance.trText(ne: '$dateStr (म्याद सकियो)', en: '$dateStr (Expired)', ko: '$dateStr (만료됨)');
    }
    return "$dateStr (${daysRemaining} " + LanguageService.instance.trText(ne: 'दिन बाँकी', en: 'days left', ko: '일 남음') + ")";
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'password': password,
    'name': name,
    'registrationNo': registrationNo,
    'mobileNumber': mobileNumber,
    'batch': batch,
    'sector': sector,
    'status': status,
    'role': role == UserRole.superAdmin ? 'superAdmin' : (role == UserRole.admin ? 'admin' : 'student'),
    'instituteId': instituteId,
    'instituteName': instituteName,
    'instituteLogo': instituteLogo,
    'profilePhoto': profilePhoto,
    'allowedSetsQuota': allowedSetsQuota,
    'validityExpiry': validityExpiry?.toIso8601String(),
    'unlockedSetIds': unlockedSetIds,
    'setsUsedCount': setsUsedCount,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rStr = json['role'] as String?;
    final role = rStr == 'superAdmin'
        ? UserRole.superAdmin
        : (rStr == 'admin' ? UserRole.admin : UserRole.student);

    DateTime? validity;
    if (json['validityExpiry'] != null) {
      validity = DateTime.tryParse(json['validityExpiry'] as String);
    }
    validity ??= DateTime.now().add(const Duration(days: 60));

    return AppUser(
      id: json['id'] as String? ?? 'STU_001',
      username: json['username'] as String? ?? 'student',
      password: json['password'] as String? ?? 'student123',
      name: json['name'] as String? ?? 'विद्यार्थी',
      registrationNo: json['registrationNo'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      batch: json['batch'] as String? ?? '2026 Batch A (बिहानी सत्र)',
      sector: json['sector'] as String? ?? '제조업 (Manufacturing)',
      status: json['status'] as String? ?? 'सक्रिय (Active)',
      role: role,
      instituteId: json['instituteId'] as String? ?? 'inst_01',
      instituteName: json['instituteName'] as String? ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट',
      instituteLogo: json['instituteLogo'] as String? ?? 'assets/images/institute_logo_default.png',
      profilePhoto: json['profilePhoto'] as String?,
      allowedSetsQuota: json['allowedSetsQuota'] as int? ?? 10,
      validityExpiry: validity,
      unlockedSetIds: (json['unlockedSetIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      setsUsedCount: json['setsUsedCount'] as int? ?? 0,
    );
  }
}

/// Dynamic Authentication, Student Batch & Mobile Login Service
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Platform Super Admin
  AppUser _superAdmin = AppUser(
    id: 'SUPER_ADMIN_001',
    username: 'superadmin',
    password: 'admin123',
    name: 'मुख्य सुपर एडमिन (Super Admin)',
    mobileNumber: '9851000000',
    batch: 'Platform Headquarters',
    sector: 'Platform Owner',
    role: UserRole.superAdmin,
    instituteId: 'platform_master',
    instituteName: 'EPS-TOPIK Master Platform',
    allowedSetsQuota: -1,
  );

  // Default Institute Admin User
  AppUser _admin = AppUser(
    id: 'ADMIN_001',
    username: 'admin',
    password: 'admin123',
    name: 'इन्स्टिच्युट एडमिन (Institute Admin)',
    mobileNumber: '9851234567',
    batch: 'Management',
    sector: 'Administration',
    role: UserRole.admin,
    instituteId: 'inst_01',
    instituteName: 'ग्लोबल कोरियन भाषा इन्स्टिच्युट',
    allowedSetsQuota: -1,
  );

  // Dynamic Institute Admins List
  final List<AppUser> _instituteAdmins = [];

  // Registered Students List with Batches, Sectors, Quotas, and Calendar Expiry
  final List<AppUser> _students = [];

  void clearAllStudents() {
    _students.clear();
    _saveCustomUsers();
    notifyListeners();
  }

  void deleteStudent(String studentId) {
    _students.removeWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    _saveCustomUsers();
    notifyListeners();
  }

  AppUser get superAdmin => _superAdmin;
  AppUser get admin => _admin;
  List<AppUser> get instituteAdmins => List.unmodifiable(_instituteAdmins);
  List<AppUser> get students => List.unmodifiable(_students);

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isSuperAdmin => _currentUser?.role == UserRole.superAdmin;

  void init() {
    _loadCustomUsers();
  }

  void _loadCustomUsers() {
    try {
      final superAdminJson = StorageService.instance.getString('auth_super_admin_user') ??
          StorageService.instance.getString('auth_super_admin_user_backup');
      if (superAdminJson != null && superAdminJson.isNotEmpty) {
        final parsed = AppUser.fromJson(jsonDecode(superAdminJson));
        _superAdmin.username = parsed.username;
        _superAdmin.password = parsed.password;
        _superAdmin.name = parsed.name;
        _superAdmin.mobileNumber = parsed.mobileNumber;
        if (parsed.profilePhoto != null) _superAdmin.profilePhoto = parsed.profilePhoto;
      }
      final adminJson = StorageService.instance.getString('auth_admin_user') ??
          StorageService.instance.getString('auth_admin_user_backup');
      if (adminJson != null && adminJson.isNotEmpty) {
        _admin = AppUser.fromJson(jsonDecode(adminJson));
      }
      final instAdminsJson = StorageService.instance.getString('auth_institute_admins_list') ??
          StorageService.instance.getString('auth_institute_admins_list_backup');
      if (instAdminsJson != null && instAdminsJson.isNotEmpty) {
        final List list = jsonDecode(instAdminsJson);
        _instituteAdmins.clear();
        _instituteAdmins.addAll(list.map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))));
      }
      final studentsJson = StorageService.instance.getString('auth_students_list') ??
          StorageService.instance.getString('auth_students_list_backup');
      if (studentsJson != null && studentsJson.isNotEmpty) {
        final List list = jsonDecode(studentsJson);
        if (list.isNotEmpty) {
          _students.clear();
          _students.addAll(list.map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))));
        }
      }
    } catch (_) {}
  }

  void _saveCustomUsers() {
    try {
      final superAdminStr = jsonEncode(_superAdmin.toJson());
      final adminStr = jsonEncode(_admin.toJson());
      final instAdminsStr = jsonEncode(_instituteAdmins.map((e) => e.toJson()).toList());
      final studentsList = _students.map((e) => e.toJson()).toList();
      final studentsStr = jsonEncode(studentsList);

      // Save to primary storage
      StorageService.instance.setString('auth_super_admin_user', superAdminStr);
      StorageService.instance.setString('auth_admin_user', adminStr);
      StorageService.instance.setString('auth_institute_admins_list', instAdminsStr);
      StorageService.instance.setString('auth_students_list', studentsStr);
      StorageService.instance.saveUsers(_students);

      // Redundant immutable backup layer to prevent loss on cache flush / code redeploy
      StorageService.instance.setString('auth_super_admin_user_backup', superAdminStr);
      StorageService.instance.setString('auth_admin_user_backup', adminStr);
      StorageService.instance.setString('auth_institute_admins_list_backup', instAdminsStr);
      StorageService.instance.setString('auth_students_list_backup', studentsStr);

      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    } catch (_) {}
  }

  void loadFromStorage(List<AppUser> users) {
    if (users.isNotEmpty) {
      mergeUsersFromCloud(users);
    }
  }

  /// Intelligent Non-Destructive Cloud Merge:
  /// NEVER deletes or resets local admin/superadmin credentials or registered students!
  void mergeUsersFromCloud(List<AppUser> remoteUsers) {
    bool hasChanges = false;
    for (final rUser in remoteUsers) {
      if (rUser.role == UserRole.student) {
        final localIdx = _students.indexWhere((s) =>
            s.id == rUser.id ||
            s.username.toLowerCase() == rUser.username.toLowerCase() ||
            (s.mobileNumber != null && s.mobileNumber!.isNotEmpty && s.mobileNumber == rUser.mobileNumber));
        if (localIdx == -1) {
          _students.add(rUser);
          hasChanges = true;
        } else {
          final localStudent = _students[localIdx];
          // Always sync status, quota, batch, validity if remote updated
          if (localStudent.status != rUser.status ||
              localStudent.allowedSetsQuota != rUser.allowedSetsQuota ||
              localStudent.batch != rUser.batch ||
              localStudent.validityExpiry != rUser.validityExpiry) {
            _students[localIdx].status = rUser.status;
            _students[localIdx].allowedSetsQuota = rUser.allowedSetsQuota;
            _students[localIdx].batch = rUser.batch;
            _students[localIdx].validityExpiry = rUser.validityExpiry;
            if (_currentUser?.id == localStudent.id) {
              _currentUser!.status = rUser.status;
              _currentUser!.allowedSetsQuota = rUser.allowedSetsQuota;
              _currentUser!.batch = rUser.batch;
              _currentUser!.validityExpiry = rUser.validityExpiry;
            }
            hasChanges = true;
          }
          if (localStudent.password.isEmpty && rUser.password.isNotEmpty) {
            _students[localIdx].password = rUser.password;
            hasChanges = true;
          }
        }
      } else if (rUser.role == UserRole.admin) {
        // Protect local admin against being reset to default initial credentials
        final isLocalAdminDefault = _admin.password == 'admin123' && _admin.username == 'admin';
        if (isLocalAdminDefault) {
          if (_admin.id == rUser.id || _admin.username.toLowerCase() == rUser.username.toLowerCase()) {
            _admin = rUser;
            hasChanges = true;
          }
        }
        // Additional institute admins
        final instIdx = _instituteAdmins.indexWhere((a) => a.id == rUser.id || a.username.toLowerCase() == rUser.username.toLowerCase());
        if (instIdx == -1 && rUser.id != 'ADMIN_001') {
          _instituteAdmins.add(rUser);
          hasChanges = true;
        }
      } else if (rUser.role == UserRole.superAdmin) {
        // Protect local superAdmin against being reset to default initial credentials
        final isLocalSuperDefault = _superAdmin.password == 'admin123' && _superAdmin.username == 'superadmin';
        if (isLocalSuperDefault) {
          if (_superAdmin.id == rUser.id || _superAdmin.username.toLowerCase() == rUser.username.toLowerCase()) {
            _superAdmin = rUser;
            hasChanges = true;
          }
        }
      }
    }

    if (hasChanges) {
      _saveCustomUsers();
      notifyListeners();
    }
  }

  AppUser? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<AppUser> getStudentsByBatch(String batch) {
    if (batch == 'all' || batch.isEmpty || batch.contains('सबै')) {
      return List.unmodifiable(_students);
    }
    return _students.where((s) => s.batch == batch).toList();
  }

  bool updateUserCredentials({
    required String userId,
    String? newName,
    String? newPassword,
    String? newMobile,
    String? profilePhoto,
  }) {
    bool updated = false;

    if (_superAdmin.id == userId) {
      if (newName != null && newName.isNotEmpty) _superAdmin.name = newName;
      if (newPassword != null && newPassword.isNotEmpty) _superAdmin.password = newPassword;
      if (newMobile != null) _superAdmin.mobileNumber = newMobile;
      if (profilePhoto != null) _superAdmin.profilePhoto = profilePhoto;
      updated = true;
    } else if (_admin.id == userId) {
      if (newName != null && newName.isNotEmpty) _admin.name = newName;
      if (newPassword != null && newPassword.isNotEmpty) _admin.password = newPassword;
      if (newMobile != null) _admin.mobileNumber = newMobile;
      if (profilePhoto != null) _admin.profilePhoto = profilePhoto;
      updated = true;
    } else {
      final instIdx = _instituteAdmins.indexWhere((u) => u.id == userId);
      if (instIdx != -1) {
        final u = _instituteAdmins[instIdx];
        if (newName != null && newName.isNotEmpty) u.name = newName;
        if (newPassword != null && newPassword.isNotEmpty) u.password = newPassword;
        if (newMobile != null) u.mobileNumber = newMobile;
        if (profilePhoto != null) u.profilePhoto = profilePhoto;
        updated = true;
      } else {
        final stuIdx = _students.indexWhere((u) => u.id == userId);
        if (stuIdx != -1) {
          final u = _students[stuIdx];
          if (newName != null && newName.isNotEmpty) u.name = newName;
          if (newPassword != null && newPassword.isNotEmpty) u.password = newPassword;
          if (newMobile != null) u.mobileNumber = newMobile;
          if (profilePhoto != null) u.profilePhoto = profilePhoto;
          updated = true;
        }
      }
    }

    if (updated) {
      if (_currentUser?.id == userId) {
        if (newName != null && newName.isNotEmpty) _currentUser!.name = newName;
        if (newPassword != null && newPassword.isNotEmpty) _currentUser!.password = newPassword;
        if (newMobile != null) _currentUser!.mobileNumber = newMobile;
        if (profilePhoto != null) _currentUser!.profilePhoto = profilePhoto;
      }
      _saveCustomUsers();
      notifyListeners();
    }

    return updated;
  }

  /// Unified Auto-Detecting Login:
  /// Authenticates using Username, Registration Number, or Mobile Number!
  /// Case-insensitive username check, exact trimmed password match.
  AppUser? login(String identifier, String password) {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) return null;

    // 1. Check Platform Super Admin
    final superUserMatch = _superAdmin.username.trim().toLowerCase() == cleanId;
    final superMobileMatch = _superAdmin.mobileNumber != null && _superAdmin.mobileNumber!.trim() == cleanId;
    if ((superUserMatch || superMobileMatch) && _superAdmin.password.trim() == cleanPass) {
      _currentUser = _superAdmin;
      notifyListeners();
      return _superAdmin;
    }

    // 2. Check Default Institute Admin
    final adminUserMatch = _admin.username.trim().toLowerCase() == cleanId;
    final adminMobileMatch = _admin.mobileNumber != null && _admin.mobileNumber!.trim() == cleanId;
    if ((adminUserMatch || adminMobileMatch) && _admin.password.trim() == cleanPass) {
      _currentUser = _admin;
      notifyListeners();
      return _admin;
    }

    // 3. Check Additional Registered Institute Admins
    final instAdminIdx = _instituteAdmins.indexWhere((u) {
      final uMatch = u.username.trim().toLowerCase() == cleanId;
      final mMatch = u.mobileNumber != null && u.mobileNumber!.trim() == cleanId;
      return (uMatch || mMatch) && u.password.trim() == cleanPass;
    });
    if (instAdminIdx != -1) {
      _currentUser = _instituteAdmins[instAdminIdx];
      notifyListeners();
      return _currentUser;
    }

    // 4. Check Registered Students
    final studentIndex = _students.indexWhere((u) {
      final matchesUser = u.username.trim().toLowerCase() == cleanId;
      final matchesReg = u.registrationNo != null && u.registrationNo!.trim().toLowerCase() == cleanId;
      final matchesMobile = u.mobileNumber != null && u.mobileNumber!.trim() == cleanId;
      return (matchesUser || matchesReg || matchesMobile) && u.password.trim() == cleanPass;
    });

    if (studentIndex != -1) {
      _currentUser = _students[studentIndex];
      notifyListeners();
      return _currentUser;
    }

    return null;
  }

  void registerInstituteAdmin({
    required String username,
    required String password,
    required String name,
    required String mobileNumber,
    required String instituteId,
    required String instituteName,
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final cleanMob = mobileNumber.trim();

    // Update if already exists or create new
    final idx = _instituteAdmins.indexWhere((a) => a.username.toLowerCase() == cleanUser.toLowerCase() || a.instituteId == instituteId);
    if (idx != -1) {
      _instituteAdmins[idx].username = cleanUser;
      _instituteAdmins[idx].password = cleanPass;
      _instituteAdmins[idx].name = name.trim();
      _instituteAdmins[idx].mobileNumber = cleanMob;
      _instituteAdmins[idx].instituteName = instituteName.trim();
    } else {
      final newAdmin = AppUser(
        id: 'ADMIN_${DateTime.now().millisecondsSinceEpoch}',
        username: cleanUser,
        password: cleanPass,
        name: name.trim(),
        mobileNumber: cleanMob,
        role: UserRole.admin,
        instituteId: instituteId,
        instituteName: instituteName.trim(),
      );
      _instituteAdmins.add(newAdmin);
    }
    _saveCustomUsers();
    notifyListeners();
  }

  void updateInstituteBranding({
    required String instituteId,
    required String instituteName,
    required String instituteLogo,
  }) {
    if (_admin.instituteId == instituteId) {
      _admin.instituteName = instituteName;
      _admin.instituteLogo = instituteLogo;
    }
    for (final a in _instituteAdmins) {
      if (a.instituteId == instituteId) {
        a.instituteName = instituteName;
        a.instituteLogo = instituteLogo;
      }
    }
    for (final s in _students) {
      if (s.instituteId == instituteId) {
        s.instituteName = instituteName;
        s.instituteLogo = instituteLogo;
      }
    }
    if (_currentUser != null && _currentUser!.instituteId == instituteId) {
      _currentUser!.instituteName = instituteName;
      _currentUser!.instituteLogo = instituteLogo;
    }
    _saveCustomUsers();
    notifyListeners();
  }

  /// Reset password for the Super Admin
  bool resetSuperAdminPassword(String newPassword) {
    final cleanPass = newPassword.trim();
    if (cleanPass.isEmpty) return false;
    _superAdmin.password = cleanPass;
    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  /// Log out current user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Universal Logout Confirmation Dialog for ALL User Roles
  static void confirmAndLogout(BuildContext context, {VoidCallback? onAfterLogout}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              LanguageService.instance.trText(
                ne: 'लगआउट पुष्टि गर्नुहोस्',
                en: 'Confirm Logout',
                ko: '로그아웃 확인',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          LanguageService.instance.trText(
            ne: 'के तपाईं आफ्नो खाताबाट लगआउट गर्न निश्चित हुनुहुन्छ?',
            en: 'Are you sure you want to log out of your account?',
            ko: '정말 계정에서 로그아웃하시겠습니까?',
          ),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              LanguageService.instance.trText(
                ne: 'रद्द गर्नुहोस्',
                en: 'Cancel',
                ko: '취소',
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.instance.logout();
              if (onAfterLogout != null) {
                onAfterLogout();
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: Text(
              LanguageService.instance.trText(
                ne: 'हो, लगआउट गर्नुहोस्',
                en: 'Yes, Log Out',
                ko: '예, 로그아웃',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Direct Official Google Sign-In & Registration
  AppUser loginWithGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    String? googleUid,
    String? instituteId,
    String? instituteName,
    String? mobileNumber,
    String? batch,
    String? sector,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUser = cleanEmail.split('@')[0];

    final idx = _students.indexWhere((u) =>
      u.username.toLowerCase() == cleanUser ||
      (u.registrationNo?.toLowerCase() == cleanEmail) ||
      (googleUid != null && u.id == googleUid)
    );

    if (idx != -1) {
      final existing = _students[idx];
      if (displayName.isNotEmpty && (existing.name.isEmpty || existing.name.contains('परीक्षार्थी'))) {
        existing.name = displayName;
      }
      if (photoUrl != null && photoUrl.isNotEmpty && (existing.profilePhoto == null || existing.profilePhoto!.isEmpty)) {
        existing.profilePhoto = photoUrl;
      }
      if (mobileNumber != null && mobileNumber.isNotEmpty && (existing.mobileNumber == null || existing.mobileNumber!.isEmpty)) {
        existing.mobileNumber = mobileNumber;
      }
      if (instituteId != null && instituteId.isNotEmpty) {
        existing.instituteId = instituteId;
        existing.instituteName = instituteName ?? existing.instituteName;
      }
      _currentUser = existing;
      _saveCustomUsers();
    } else {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newId = googleUid ?? 'STU_$nowMs';
      final effectiveInstId = instituteId ?? 'inst_01';
      final effectiveInstName = instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
      final newStudent = AppUser(
        id: newId,
        username: cleanUser,
        password: 'google_oauth_user',
        name: displayName.isNotEmpty ? displayName : 'Google परीक्षार्थी',
        registrationNo: 'REG-${nowMs.toString().substring(7)}',
        mobileNumber: mobileNumber,
        batch: batch ?? '2026 Batch A (बिहानी सत्र)',
        sector: sector ?? '제조업 (Manufacturing)',
        status: 'प्रतीक्षारत (Pending Approval)', // Google registered student requires Institute Admin approval
        role: UserRole.student,
        instituteId: effectiveInstId,
        instituteName: effectiveInstName,
        profilePhoto: photoUrl,
        allowedSetsQuota: 10,
        validityExpiry: DateTime.now().add(const Duration(days: 60)),
      );
      _students.add(newStudent);
      _currentUser = newStudent;
      _saveCustomUsers();
    }

    CloudSyncService.instance.pushToCloud();
    CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    notifyListeners();
    return _currentUser!;
  }

  /// Direct Mobile OTP Sign-In & Verification
  AppUser? loginWithMobileOtp({
    required String mobileNumber,
    String? name,
    String? instituteId,
    String? instituteName,
    String? batch,
    String? sector,
  }) {
    final cleanMobile = mobileNumber.trim();
    if (cleanMobile.length < 8) return null;

    final idx = _students.indexWhere((u) => u.mobileNumber == cleanMobile || (cleanMobile.length == 10 && u.mobileNumber != null && u.mobileNumber!.endsWith(cleanMobile)));
    if (idx != -1) {
      _currentUser = _students[idx];
    } else {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newId = 'STU_$nowMs';
      final effectiveInstId = instituteId ?? 'inst_01';
      final effectiveInstName = instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
      final newStudent = AppUser(
        id: newId,
        username: 'user_${nowMs.toString().substring(7)}',
        password: 'mobile_otp_user',
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : 'मोबाइल परीक्षार्थी ($cleanMobile)',
        registrationNo: 'REG-${nowMs.toString().substring(7)}',
        mobileNumber: cleanMobile,
        batch: batch ?? '2026 Batch A (बिहानी सत्र)',
        sector: sector ?? '제조업 (Manufacturing)',
        status: (instituteId != null && instituteId.isNotEmpty) ? 'प्रतीक्षारत (Pending Approval)' : 'सक्रिय (Active)',
        role: UserRole.student,
        instituteId: effectiveInstId,
        instituteName: effectiveInstName,
        allowedSetsQuota: 10,
        validityExpiry: DateTime.now().add(const Duration(days: 60)),
      );
      _students.add(newStudent);
      _currentUser = newStudent;
      _saveCustomUsers();
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    }

    notifyListeners();
    return _currentUser;
  }

  /// Self-Registration for new candidates
  bool registerStudent({
    required String name,
    required String username,
    required String password,
    required String mobileNumber,
    String? registrationNo,
    String batch = '2026 Batch A (बिहानी सत्र)',
    String sector = '제조업 (Manufacturing)',
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final cleanMobile = mobileNumber.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) return false;

    final existsInStudents = _students.any((s) =>
      s.username.toLowerCase() == cleanUser.toLowerCase() ||
      (cleanMobile.isNotEmpty && s.mobileNumber == cleanMobile)
    );
    final existsInAdmins = _admin.username.toLowerCase() == cleanUser.toLowerCase() ||
      _superAdmin.username.toLowerCase() == cleanUser.toLowerCase() ||
      _instituteAdmins.any((a) => a.username.toLowerCase() == cleanUser.toLowerCase());

    if (existsInStudents || existsInAdmins) return false;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final newId = 'STU_$nowMs';
    final regNo = registrationNo != null && registrationNo.trim().isNotEmpty
        ? registrationNo.trim()
        : 'REG-${nowMs.toString().substring(7)}';

    final instId = _currentUser?.instituteId ?? 'inst_01';
    final instName = _currentUser?.instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
    final instLogo = _currentUser?.instituteLogo ?? 'assets/images/institute_logo_default.png';

    final newStudent = AppUser(
      id: newId,
      username: cleanUser,
      password: cleanPass,
      name: name.trim(),
      registrationNo: regNo,
      mobileNumber: cleanMobile,
      batch: batch,
      sector: sector,
      status: 'सक्रिय (Active)',
      role: UserRole.student,
      instituteId: instId,
      instituteName: instName,
      instituteLogo: instLogo,
    );

    _students.add(newStudent);
    _currentUser = newStudent;
    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  /// Self-Registration with Institute Selection (Status: Pending Approval)
  AppUser? registerStudentWithInstitute({
    required String name,
    required String username,
    required String password,
    required String mobileNumber,
    required String instituteId,
    required String instituteName,
    String? instituteLogo,
    String? registrationNo,
    String batch = '2026 Batch A (बिहानी सत्र)',
    String sector = '제조업 (Manufacturing)',
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final cleanMobile = mobileNumber.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) return null;

    final existsInStudents = _students.any((s) =>
      s.username.toLowerCase() == cleanUser.toLowerCase() ||
      (cleanMobile.isNotEmpty && s.mobileNumber == cleanMobile)
    );
    final existsInAdmins = _admin.username.toLowerCase() == cleanUser.toLowerCase() ||
      _superAdmin.username.toLowerCase() == cleanUser.toLowerCase() ||
      _instituteAdmins.any((a) => a.username.toLowerCase() == cleanUser.toLowerCase());

    if (existsInStudents || existsInAdmins) return null;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final newId = 'STU_$nowMs';
    final regNo = registrationNo != null && registrationNo.trim().isNotEmpty
        ? registrationNo.trim()
        : 'REG-${nowMs.toString().substring(7)}';

    final newStudent = AppUser(
      id: newId,
      username: cleanUser,
      password: cleanPass,
      name: name.trim(),
      registrationNo: regNo,
      mobileNumber: cleanMobile,
      batch: batch,
      sector: sector,
      status: 'प्रतीक्षारत (Pending Approval)',
      role: UserRole.student,
      instituteId: instituteId,
      instituteName: instituteName,
      instituteLogo: instituteLogo ?? 'assets/images/institute_logo_default.png',
      allowedSetsQuota: 10,
      validityExpiry: DateTime.now().add(const Duration(days: 60)),
    );

    _students.add(newStudent);
    _currentUser = newStudent;
    _saveCustomUsers();
    notifyListeners();
    return newStudent;
  }

  /// Approve a student from the Institute Admin
  bool approveStudent({
    required String studentId,
    String? batch,
    int? allowedSetsQuota,
    DateTime? validityExpiry,
  }) {
    final idx = _students.indexWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    if (idx == -1) return false;

    _students[idx].status = 'सक्रिय (Active)';
    if (batch != null && batch.trim().isNotEmpty) {
      _students[idx].batch = batch.trim();
    }
    if (allowedSetsQuota != null) {
      _students[idx].allowedSetsQuota = allowedSetsQuota;
    }
    if (validityExpiry != null) {
      _students[idx].validityExpiry = validityExpiry;
    }

    if (_currentUser != null && (_currentUser!.id == studentId || _currentUser!.username.toLowerCase() == studentId.toLowerCase())) {
      _currentUser!.status = 'सक्रिय (Active)';
      if (batch != null && batch.trim().isNotEmpty) _currentUser!.batch = batch.trim();
      if (allowedSetsQuota != null) _currentUser!.allowedSetsQuota = allowedSetsQuota;
      if (validityExpiry != null) _currentUser!.validityExpiry = validityExpiry;
    }

    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  /// Reject / Delete a pending registration
  bool rejectStudent(String studentId) {
    final idx = _students.indexWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    if (idx == -1) return false;

    _students.removeAt(idx);
    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  /// Forgot Password Recovery via Mobile Number or Username
  bool resetPassword({
    required String mobileOrUsername,
    required String newPassword,
  }) {
    final cleanId = mobileOrUsername.trim().toLowerCase();
    final cleanPass = newPassword.trim();
    if (cleanPass.isEmpty) return false;

    // Super Admin reset
    if (_superAdmin.username.toLowerCase() == cleanId || (_superAdmin.mobileNumber != null && _superAdmin.mobileNumber == cleanId)) {
      _superAdmin.password = cleanPass;
      _saveCustomUsers();
      notifyListeners();
      return true;
    }
    // Admin reset
    if (_admin.username.toLowerCase() == cleanId || _admin.mobileNumber == cleanId) {
      _admin.password = cleanPass;
      _saveCustomUsers();
      notifyListeners();
      return true;
    }
    // Institute Admins reset
    final aIdx = _instituteAdmins.indexWhere((u) => u.username.toLowerCase() == cleanId || (u.mobileNumber != null && u.mobileNumber == cleanId));
    if (aIdx != -1) {
      _instituteAdmins[aIdx].password = cleanPass;
      _saveCustomUsers();
      notifyListeners();
      return true;
    }

    // Student reset
    final idx = _students.indexWhere((u) =>
      u.username.toLowerCase() == cleanId ||
      (u.mobileNumber != null && u.mobileNumber == cleanId) ||
      (u.registrationNo?.toLowerCase() == cleanId)
    );

    if (idx != -1) {
      _students[idx].password = cleanPass;
      _saveCustomUsers();
      notifyListeners();
      return true;
    }

    return false;
  }

  bool changeAdminCredentials({
    required String oldPassword,
    required String newUsername,
    required String newPassword,
  }) {
    if (_admin.password != oldPassword.trim()) {
      return false;
    }
    _admin.username = newUsername.trim();
    _admin.password = newPassword.trim();
    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  bool addStudent({
    required String username,
    required String password,
    required String name,
    String? registrationNo,
    String? mobileNumber,
    String batch = '2026 Batch A (बिहानी सत्र)',
    String sector = '제조업 (Manufacturing)',
    String status = 'सक्रिय (Active)',
    int allowedSetsQuota = 10,
    DateTime? validityExpiry,
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final cleanMobile = mobileNumber?.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) return false;

    final exists = _students.any((s) =>
      s.username.toLowerCase() == cleanUser.toLowerCase() ||
      (cleanMobile != null && cleanMobile.isNotEmpty && s.mobileNumber == cleanMobile)
    );
    if (exists) return false;

    final instId = _currentUser?.instituteId ?? 'inst_01';
    final instName = _currentUser?.instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
    final instLogo = _currentUser?.instituteLogo ?? 'assets/images/institute_logo_default.png';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final newId = 'STU_$nowMs';
    final regNo = registrationNo != null && registrationNo.trim().isNotEmpty
        ? registrationNo.trim()
        : 'REG-${nowMs.toString().substring(7)}';
    _students.add(AppUser(
      id: newId,
      username: cleanUser,
      password: cleanPass,
      name: name.trim(),
      registrationNo: regNo,
      mobileNumber: cleanMobile,
      batch: batch,
      sector: sector,
      status: status,
      role: UserRole.student,
      instituteId: instId,
      instituteName: instName,
      instituteLogo: instLogo,
      allowedSetsQuota: allowedSetsQuota,
      validityExpiry: validityExpiry ?? DateTime.now().add(const Duration(days: 60)),
    ));
    _saveCustomUsers();
    CloudSyncService.instance.pushToCloud();
    notifyListeners();
    return true;
  }

  bool updateStudentCredentials({
    required String studentId,
    String? newName,
    String? newUsername,
    String? newPassword,
    String? newMobile,
    String? newBatch,
    String? newSector,
    String? newStatus,
    int? newAllowedSetsQuota,
    DateTime? newValidityExpiry,
    bool clearExpiry = false,
  }) {
    final idx = _students.indexWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    if (idx == -1) return false;

    if (newName != null && newName.trim().isNotEmpty) {
      _students[idx].name = newName.trim();
    }
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      _students[idx].username = newUsername.trim();
    }
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      _students[idx].password = newPassword.trim();
    }
    if (newMobile != null && newMobile.trim().isNotEmpty) {
      _students[idx].mobileNumber = newMobile.trim();
    }
    if (newBatch != null && newBatch.trim().isNotEmpty) {
      _students[idx].batch = newBatch.trim();
    }
    if (newSector != null && newSector.trim().isNotEmpty) {
      _students[idx].sector = newSector.trim();
    }
    if (newStatus != null && newStatus.trim().isNotEmpty) {
      _students[idx].status = newStatus.trim();
    }
    if (newAllowedSetsQuota != null) {
      _students[idx].allowedSetsQuota = newAllowedSetsQuota;
    }
    if (clearExpiry) {
      _students[idx].validityExpiry = null;
    } else if (newValidityExpiry != null) {
      _students[idx].validityExpiry = newValidityExpiry;
    }

    if (_currentUser != null && (_currentUser!.id == studentId || _currentUser!.username.toLowerCase() == studentId.toLowerCase())) {
      if (newName != null && newName.trim().isNotEmpty) _currentUser!.name = newName.trim();
      if (newUsername != null && newUsername.trim().isNotEmpty) _currentUser!.username = newUsername.trim();
      if (newPassword != null && newPassword.trim().isNotEmpty) _currentUser!.password = newPassword.trim();
      if (newMobile != null && newMobile.trim().isNotEmpty) _currentUser!.mobileNumber = newMobile.trim();
      if (newBatch != null && newBatch.trim().isNotEmpty) _currentUser!.batch = newBatch.trim();
      if (newSector != null && newSector.trim().isNotEmpty) _currentUser!.sector = newSector.trim();
      if (newStatus != null && newStatus.trim().isNotEmpty) _currentUser!.status = newStatus.trim();
      if (newAllowedSetsQuota != null) _currentUser!.allowedSetsQuota = newAllowedSetsQuota;
      if (clearExpiry) {
        _currentUser!.validityExpiry = null;
      } else if (newValidityExpiry != null) {
        _currentUser!.validityExpiry = newValidityExpiry;
      }
    }

    _saveCustomUsers();
    CloudSyncService.instance.pushToCloud();
    notifyListeners();
    return true;
  }

  bool updateStudentQuotaAndValidity({
    required String studentId,
    required int allowedSetsQuota,
    required DateTime? validityExpiry,
    List<String>? unlockedSetIds,
  }) {
    final idx = _students.indexWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    if (idx == -1) return false;

    _students[idx].allowedSetsQuota = allowedSetsQuota;
    _students[idx].validityExpiry = validityExpiry;
    if (unlockedSetIds != null) {
      _students[idx].unlockedSetIds = unlockedSetIds;
    }

    if (_currentUser != null && (_currentUser!.id == studentId || _currentUser!.username.toLowerCase() == studentId.toLowerCase())) {
      _currentUser!.allowedSetsQuota = allowedSetsQuota;
      _currentUser!.validityExpiry = validityExpiry;
      if (unlockedSetIds != null) {
        _currentUser!.unlockedSetIds = unlockedSetIds;
      }
    }

    _saveCustomUsers();
    CloudSyncService.instance.pushToCloud();
    notifyListeners();
    return true;
  }

  /// Universal Student Quota and Expiration Access Guard with alert dialog
  static bool checkStudentAccessWithDialog(BuildContext context, {String? setId}) {
    final u = AuthService.instance.currentUser;
    if (u == null || u.role != UserRole.student) {
      return true; // Admins & Super Admins have unrestricted preview & test access
    }

    // 1. Check validity expiry
    if (u.isExpired) {
      final expStr = u.validityExpiry != null
          ? "${u.validityExpiry!.year}-${u.validityExpiry!.month.toString().padLeft(2, '0')}-${u.validityExpiry!.day.toString().padLeft(2, '0')}"
          : LanguageService.instance.trText(ne: 'समाप्त', en: 'Expired', ko: '만료');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.timer_off_rounded, color: Colors.red, size: 26),
              const SizedBox(width: 8),
              Text(
                LanguageService.instance.trText(ne: "म्याद समाप्त भएको छ!", en: "Account Expired!", ko: "이용 기간 만료!"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  LanguageService.instance.trText(
                    ne: "⚠️ तपाईंको अध्ययन तथा परीक्षाको म्याद ($expStr) मा समाप्त भइसकेको छ।",
                    en: "⚠️ Your study and exam access expired on $expStr.",
                    ko: "⚠️ 학습 및 모의고사 이용 기간이 $expStr 일자로 만료되었습니다.",
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LanguageService.instance.trText(
                  ne: "नयाँ समय सीमा (Validity) थप गर्न वा नवीकरण गर्न कृपया आफ्नो इन्स्टिच्युट (${u.instituteName}) प्रशासनसँग सम्पर्क गर्नुहोस्।",
                  en: "Please contact your Institute (${u.instituteName}) admin to extend or renew your validity.",
                  ko: "기간 연장 및 갱신을 위해 소속 학원(${u.instituteName}) 관리자에게 문의해 주세요.",
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: "बुझें (Understood)", en: "Understood", ko: "확인")),
            ),
          ],
        ),
      );
      return false;
    }

    // 2. Check Set Specific Unlock Permission (Admin-Assigned Sets)
    if (setId != null && setId.isNotEmpty && u.unlockedSetIds.isNotEmpty && !u.unlockedSetIds.contains(setId)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.orange, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService.instance.trText(
                    ne: "यो सेट तपाईंलाई तोकिएको छैन!",
                    en: "Set Not Assigned!",
                    ko: "미배정 모의고사 세트!",
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  LanguageService.instance.trText(
                    ne: "🔒 यो प्रश्न सेट तपाईंको इन्स्टिच्युट (${u.instituteName}) का एडमिनले तपाईंलाई तोक्नुभएको छैन।",
                    en: "🔒 This question set has not been assigned to you by your institute (${u.instituteName}) admin.",
                    ko: "🔒 본 모의고사 세트는 소속 학원(${u.instituteName}) 관리자에 의해 배정되지 않았습니다.",
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LanguageService.instance.trText(
                  ne: "यो प्रश्न सेट अनलक गराउन कृपया आफ्नो इन्स्टिच्युट एडमिनसँग सम्पर्क गरी पहुँच अनुमति लिनुहोस्।",
                  en: "Please contact your Institute admin to unlock and assign this question set to your account.",
                  ko: "해당 세트를 응시하시려면 학원 관리자에게 세트 배정을 요청해 주세요.",
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: "बुझें (Understood)", en: "Understood", ko: "확인")),
            ),
          ],
        ),
      );
      return false;
    }

    // 3. Check Set Quota
    if (!u.isUnlimitedQuota) {
      final completed = ExamHistoryService.instance.getCompletedSetsCountForStudent(u.username);
      if (completed >= u.allowedSetsQuota) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 26),
                const SizedBox(width: 8),
                Text(
                  LanguageService.instance.trText(ne: "सेट कोटा समाप्त भयो!", en: "Set Quota Exhausted!", ko: "세트 할당량 소진!"),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB45309)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    LanguageService.instance.trText(
                      ne: "📊 तपाईंलाई तोकिएको ${u.allowedSetsQuota} वटा सेटको कोटा प्रयोग भइसकेको छ (हालसम्म $completed सेट पूरा गरियो)।",
                      en: "📊 You have used all ${u.allowedSetsQuota} allocated question sets ($completed sets completed).",
                      ko: "📊 배정된 ${u.allowedSetsQuota}개 세트 할당량을 모두 사용하셨습니다(현재까지 $completed개 완료).",
                    ),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  LanguageService.instance.trText(
                    ne: "थप नयाँ प्रश्न सेटहरू खोल्न कृपया आफ्नो इन्स्टिच्युट (${u.instituteName}) मा सम्पर्क गरी कोटा वृद्धि गर्नुहोस्।",
                    en: "Please contact your Institute (${u.instituteName}) to increase your question set quota.",
                    ko: "추가 문제 세트를 응시하시려면 소속 학원(${u.instituteName})에 문의하여 할당량을 추가해 주세요.",
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(LanguageService.instance.trText(ne: "बुझें (Understood)", en: "Understood", ko: "확인")),
              ),
            ],
          ),
        );
        return false;
      }
    }

    return true;
  }

  

  void updateStudentUnlockedSets(String studentId, List<String> setIds) {
    final idx = _students.indexWhere((s) => s.id == studentId || s.username.toLowerCase() == studentId.toLowerCase());
    if (idx != -1) {
      _students[idx].unlockedSetIds = setIds;
      if (_currentUser != null && (_currentUser!.id == studentId || _currentUser!.username.toLowerCase() == studentId.toLowerCase())) {
        _currentUser!.unlockedSetIds = setIds;
      }
      _saveCustomUsers();
      CloudSyncService.instance.pushToCloud();
      notifyListeners();
    }
  }

}
