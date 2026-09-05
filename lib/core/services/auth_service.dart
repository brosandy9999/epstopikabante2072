import 'cloud_sync_service.dart';
import 'language_service.dart';
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
  });

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
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rStr = json['role'] as String?;
    final role = rStr == 'superAdmin'
        ? UserRole.superAdmin
        : (rStr == 'admin' ? UserRole.admin : UserRole.student);

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
  );

  // Dynamic Institute Admins List
  final List<AppUser> _instituteAdmins = [];

  // Registered Students List with Batches, Sectors, and Mobile Numbers
  final List<AppUser> _students = [
    AppUser(
      id: 'STU_001',
      username: 'student',
      password: 'student123',
      name: 'राम बहादुर (Ram Bahadur)',
      registrationNo: '01234567',
      mobileNumber: '9841234567',
      batch: '2026 Batch A (बिहानी सत्र)',
      sector: '제조업 (Manufacturing)',
      status: 'सक्रिय (Active)',
      role: UserRole.student,
    ),
    AppUser(
      id: 'STU_002',
      username: 'sita',
      password: 'student123',
      name: 'सीता शर्मा (Sita Sharma)',
      registrationNo: '01234568',
      mobileNumber: '9841234568',
      batch: '2026 Batch A (बिहानी सत्र)',
      sector: '농축산 (Agriculture)',
      status: 'सक्रिय (Active)',
      role: UserRole.student,
    ),
    AppUser(
      id: 'STU_003',
      username: 'kiran',
      password: 'student123',
      name: 'किरण गुरुङ (Kiran Gurung)',
      registrationNo: '01234569',
      mobileNumber: '9841234569',
      batch: '2026 Batch B (दिवा सत्र)',
      sector: '제조업 (Manufacturing)',
      status: 'सक्रिय (Active)',
      role: UserRole.student,
    ),
    AppUser(
      id: 'STU_004',
      username: 'anita',
      password: 'student123',
      name: 'अनिता तामाङ (Anita Tamang)',
      registrationNo: '01234570',
      mobileNumber: '9841234570',
      batch: '2026 Batch C (साँझ सत्र)',
      sector: '건설업 (Construction)',
      status: 'सक्रिय (Active)',
      role: UserRole.student,
    ),
  ];

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
      final superAdminJson = StorageService.instance.getString('auth_super_admin_user');
      if (superAdminJson != null && superAdminJson.isNotEmpty) {
        final parsed = AppUser.fromJson(jsonDecode(superAdminJson));
        _superAdmin.username = parsed.username;
        _superAdmin.password = parsed.password;
        _superAdmin.name = parsed.name;
        _superAdmin.mobileNumber = parsed.mobileNumber;
        if (parsed.profilePhoto != null) _superAdmin.profilePhoto = parsed.profilePhoto;
      }
      final adminJson = StorageService.instance.getString('auth_admin_user');
      if (adminJson != null && adminJson.isNotEmpty) {
        _admin = AppUser.fromJson(jsonDecode(adminJson));
      }
      final instAdminsJson = StorageService.instance.getString('auth_institute_admins_list');
      if (instAdminsJson != null && instAdminsJson.isNotEmpty) {
        final List list = jsonDecode(instAdminsJson);
        _instituteAdmins.clear();
        _instituteAdmins.addAll(list.map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))));
      }
      final studentsJson = StorageService.instance.getString('auth_students_list');
      if (studentsJson != null && studentsJson.isNotEmpty) {
        final List list = jsonDecode(studentsJson);
        _students.clear();
        _students.addAll(list.map((e) => AppUser.fromJson(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
  }

  void _saveCustomUsers() {
    try {
      StorageService.instance.setString('auth_super_admin_user', jsonEncode(_superAdmin.toJson()));
      StorageService.instance.setString('auth_admin_user', jsonEncode(_admin.toJson()));
      StorageService.instance.setString('auth_institute_admins_list', jsonEncode(_instituteAdmins.map((e) => e.toJson()).toList()));
      final list = _students.map((e) => e.toJson()).toList();
      StorageService.instance.setString('auth_students_list', jsonEncode(list));
      StorageService.instance.saveUsers(_students);
      CloudSyncService.instance.pushToCloud(silent: true).catchError((_) => false);
    } catch (_) {}
  }

  void loadFromStorage(List<AppUser> users) {
    if (users.isNotEmpty) {
      mergeUsersFromCloud(users);
    }
  }

  /// Intelligent Non-Destructive Cloud Merge:
  /// Preserves locally registered / updated candidates and adds new ones (Never Deletes Local Users)
  void mergeUsersFromCloud(List<AppUser> remoteUsers) {
    bool hasChanges = false;
    for (final rUser in remoteUsers) {
      if (rUser.role == UserRole.student) {
        final localIdx = _students.indexWhere((s) => s.id == rUser.id || s.username.toLowerCase() == rUser.username.toLowerCase());
        if (localIdx == -1) {
          _students.add(rUser);
          hasChanges = true;
        } else {
          // Preserve local student credentials, update metadata if newer
          final localStudent = _students[localIdx];
          if (localStudent.password == rUser.password || localStudent.password.isEmpty) {
            _students[localIdx] = rUser;
            hasChanges = true;
          }
        }
      } else if (rUser.role == UserRole.admin) {
        if (_admin.id == rUser.id || _admin.username.toLowerCase() == rUser.username.toLowerCase()) {
          _admin = rUser;
          hasChanges = true;
        } else {
          final instIdx = _instituteAdmins.indexWhere((a) => a.id == rUser.id || a.username.toLowerCase() == rUser.username.toLowerCase());
          if (instIdx == -1) {
            _instituteAdmins.add(rUser);
            hasChanges = true;
          } else {
            _instituteAdmins[instIdx] = rUser;
            hasChanges = true;
          }
        }
      } else if (rUser.role == UserRole.superAdmin) {
        if (_superAdmin.id == rUser.id || _superAdmin.username.toLowerCase() == rUser.username.toLowerCase()) {
          _superAdmin = rUser;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      try {
        StorageService.instance.setString('auth_super_admin_user', jsonEncode(_superAdmin.toJson()));
        StorageService.instance.setString('auth_admin_user', jsonEncode(_admin.toJson()));
        StorageService.instance.setString('auth_institute_admins_list', jsonEncode(_instituteAdmins.map((e) => e.toJson()).toList()));
        final list = _students.map((e) => e.toJson()).toList();
        StorageService.instance.setString('auth_students_list', jsonEncode(list));
        StorageService.instance.saveUsers(_students);
      } catch (_) {}
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
        id: 'ADMIN_',
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

  /// Direct 1-Click Google Sign-In
  AppUser loginWithGoogle({required String email, required String displayName}) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUser = cleanEmail.split('@')[0];

    final idx = _students.indexWhere((u) =>
      u.username.toLowerCase() == cleanUser ||
      (u.registrationNo?.toLowerCase() == cleanEmail)
    );

    if (idx != -1) {
      _currentUser = _students[idx];
    } else {
      final newId = 'STU_';
      final newStudent = AppUser(
        id: newId,
        username: cleanUser,
        password: 'google_oauth_user',
        name: displayName.isNotEmpty ? displayName : 'Google परीक्षार्थी',
        registrationNo: 'REG-',
        mobileNumber: '98',
        batch: '2026 Batch A (बिहानी सत्र)',
        sector: '제조업 (Manufacturing)',
        status: 'सक्रिय (Active)',
        role: UserRole.student,
      );
      _students.add(newStudent);
      _currentUser = newStudent;
      _saveCustomUsers();
    }

    notifyListeners();
    return _currentUser!;
  }

  /// Direct Mobile OTP Sign-In
  AppUser? loginWithMobileOtp({required String mobileNumber}) {
    final cleanMobile = mobileNumber.trim();
    if (cleanMobile.length < 8) return null;

    final idx = _students.indexWhere((u) => u.mobileNumber == cleanMobile);
    if (idx != -1) {
      _currentUser = _students[idx];
    } else {
      final newId = 'STU_';
      final newStudent = AppUser(
        id: newId,
        username: 'user_',
        password: 'mobile_otp_user',
        name: 'मोबाइल परीक्षार्थी ()',
        registrationNo: 'REG-',
        mobileNumber: cleanMobile,
        batch: '2026 Batch A (बिहानी सत्र)',
        sector: '제조업 (Manufacturing)',
        status: 'सक्रिय (Active)',
        role: UserRole.student,
      );
      _students.add(newStudent);
      _currentUser = newStudent;
      _saveCustomUsers();
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

    final newId = 'STU_';
    final regNo = registrationNo != null && registrationNo.trim().isNotEmpty
        ? registrationNo.trim()
        : 'REG-';

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

    final newId = 'STU_';
    _students.add(AppUser(
      id: newId,
      username: cleanUser,
      password: cleanPass,
      name: name.trim(),
      registrationNo: registrationNo?.trim(),
      mobileNumber: cleanMobile,
      batch: batch,
      sector: sector,
      status: status,
      role: UserRole.student,
      instituteId: instId,
      instituteName: instName,
      instituteLogo: instLogo,
    ));
    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  bool updateUserCredentials({
    required String userId,
    String? newUsername,
    String? newPassword,
    String? newName,
    String? newMobile,
    String? profilePhoto,
  }) {
    bool updated = false;

    // 1. Super Admin target
    if (_superAdmin.id == userId || _superAdmin.username.toLowerCase() == userId.toLowerCase()) {
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        _superAdmin.username = newUsername.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _superAdmin.password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _superAdmin.name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _superAdmin.mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _superAdmin.profilePhoto = profilePhoto;
      }
      updated = true;
    }

    // 2. Default Institute Admin target
    if (_admin.id == userId || _admin.username.toLowerCase() == userId.toLowerCase()) {
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        _admin.username = newUsername.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _admin.password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _admin.name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _admin.mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _admin.profilePhoto = profilePhoto;
      }
      updated = true;
    }

    // 3. Institute Admins list target
    final aIdx = _instituteAdmins.indexWhere((a) => a.id == userId || a.username.toLowerCase() == userId.toLowerCase());
    if (aIdx != -1) {
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        _instituteAdmins[aIdx].username = newUsername.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _instituteAdmins[aIdx].password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _instituteAdmins[aIdx].name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _instituteAdmins[aIdx].mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _instituteAdmins[aIdx].profilePhoto = profilePhoto;
      }
      updated = true;
    }

    // 4. Students list target
    final stuIdx = _students.indexWhere((s) => s.id == userId || s.username.toLowerCase() == userId.toLowerCase());
    if (stuIdx != -1) {
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        _students[stuIdx].username = newUsername.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _students[stuIdx].password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _students[stuIdx].name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _students[stuIdx].mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _students[stuIdx].profilePhoto = profilePhoto;
      }
      updated = true;
    }

    // 5. Keep current user session synchronized if matching target
    if (_currentUser != null && (_currentUser!.id == userId || _currentUser!.username.toLowerCase() == userId.toLowerCase())) {
      if (newUsername != null && newUsername.trim().isNotEmpty) {
        _currentUser!.username = newUsername.trim();
      }
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _currentUser!.password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _currentUser!.name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _currentUser!.mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _currentUser!.profilePhoto = profilePhoto;
      }
      updated = true;
    }

    if (updated) {
      _saveCustomUsers();
      notifyListeners();
    }
    return updated;
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

    if (_currentUser != null && (_currentUser!.id == studentId || _currentUser!.username.toLowerCase() == studentId.toLowerCase())) {
      if (newName != null && newName.trim().isNotEmpty) _currentUser!.name = newName.trim();
      if (newUsername != null && newUsername.trim().isNotEmpty) _currentUser!.username = newUsername.trim();
      if (newPassword != null && newPassword.trim().isNotEmpty) _currentUser!.password = newPassword.trim();
      if (newMobile != null && newMobile.trim().isNotEmpty) _currentUser!.mobileNumber = newMobile.trim();
      if (newBatch != null && newBatch.trim().isNotEmpty) _currentUser!.batch = newBatch.trim();
      if (newSector != null && newSector.trim().isNotEmpty) _currentUser!.sector = newSector.trim();
      if (newStatus != null && newStatus.trim().isNotEmpty) _currentUser!.status = newStatus.trim();
    }

    _saveCustomUsers();
    notifyListeners();
    return true;
  }

  void deleteStudent(String studentId) {
    _students.removeWhere((s) => s.id == studentId);
    _saveCustomUsers();
    notifyListeners();
  }
}
