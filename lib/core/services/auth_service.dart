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
  final AppUser _superAdmin = AppUser(
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

  AppUser get admin => _admin;
  List<AppUser> get students => List.unmodifiable(_students);

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  void loadFromStorage(List<AppUser> users) {
    if (users.isNotEmpty) {
      _students.clear();
      _students.addAll(users);
      notifyListeners();
    }
  }

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
      }
      final adminJson = StorageService.instance.getString('auth_admin_user');
      if (adminJson != null && adminJson.isNotEmpty) {
        _admin = AppUser.fromJson(jsonDecode(adminJson));
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
      final list = _students.map((e) => e.toJson()).toList();
      StorageService.instance.setString('auth_students_list', jsonEncode(list));
    } catch (_) {}
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
  /// Automatically detects whether the user is Admin or Student.
  AppUser? login(String identifier, String password) {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    // 1. Check Platform Super Admin
    if ((_superAdmin.username.toLowerCase() == cleanId || (_superAdmin.mobileNumber != null && _superAdmin.mobileNumber == cleanId)) &&
        _superAdmin.password == cleanPass) {
      _currentUser = _superAdmin;
      notifyListeners();
      return _superAdmin;
    }

    // 2. Check Institute Admin
    if ((_admin.username.toLowerCase() == cleanId || (_admin.mobileNumber != null && _admin.mobileNumber == cleanId)) &&
        _admin.password == cleanPass) {
      _currentUser = _admin;
      notifyListeners();
      return _admin;
    }

    // Check additional registered institute admins
    final instAdminIdx = _instituteAdmins.indexWhere((u) =>
        (u.username.toLowerCase() == cleanId || (u.mobileNumber != null && u.mobileNumber == cleanId)) &&
        u.password == cleanPass);
    if (instAdminIdx != -1) {
      _currentUser = _instituteAdmins[instAdminIdx];
      notifyListeners();
      return _currentUser;
    }

    // 2. Check Students by Username, Registration No, or Mobile Number
    final studentIndex = _students.indexWhere((u) {
      final matchesUser = u.username.toLowerCase() == cleanId;
      final matchesReg = u.registrationNo?.toLowerCase() == cleanId;
      final matchesMobile = u.mobileNumber != null && u.mobileNumber == cleanId;
      return (matchesUser || matchesReg || matchesMobile) && u.password == cleanPass;
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
    final newAdmin = AppUser(
      id: 'ADMIN_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      password: password,
      name: name,
      mobileNumber: mobileNumber,
      role: UserRole.admin,
      instituteId: instituteId,
      instituteName: instituteName,
    );
    _instituteAdmins.add(newAdmin);
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

  /// Reset password for the Super Admin (manual admin‑only UI)
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
      final newId = 'STU_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newStudent = AppUser(
        id: newId,
        username: cleanUser,
        password: 'google_oauth_user',
        name: displayName.isNotEmpty ? displayName : 'Google परीक्षार्थी',
        registrationNo: 'REG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        mobileNumber: '98${(DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}',
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
      final newId = 'STU_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newStudent = AppUser(
        id: newId,
        username: 'user_${cleanMobile.substring(cleanMobile.length - 4)}',
        password: 'mobile_otp_user',
        name: 'मोबाइल परीक्षार्थी ($cleanMobile)',
        registrationNo: 'REG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
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
    final cleanUser = username.trim().toLowerCase();
    final cleanMobile = mobileNumber.trim();

    final exists = _students.any((s) =>
      s.username.toLowerCase() == cleanUser ||
      (s.mobileNumber != null && s.mobileNumber == cleanMobile)
    );
    if (exists) return false;

    final newId = 'STU_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final regNo = registrationNo != null && registrationNo.trim().isNotEmpty
        ? registrationNo.trim()
        : 'REG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final instId = _currentUser?.instituteId ?? 'inst_01';
    final instName = _currentUser?.instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
    final instLogo = _currentUser?.instituteLogo ?? 'assets/images/institute_logo_default.png';

    final newStudent = AppUser(
      id: newId,
      username: username.trim(),
      password: password.trim(),
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
      _saveCustomUsers(); // though super admin not saved in storage, keep for consistency
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
    if (_admin.password != oldPassword) {
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
    final cleanUser = username.trim().toLowerCase();
    final cleanMobile = mobileNumber?.trim();

    final exists = _students.any((s) =>
      s.username.toLowerCase() == cleanUser ||
      (cleanMobile != null && cleanMobile.isNotEmpty && s.mobileNumber == cleanMobile)
    );
    if (exists) return false;

    final instId = _currentUser?.instituteId ?? 'inst_01';
    final instName = _currentUser?.instituteName ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट';
    final instLogo = _currentUser?.instituteLogo ?? 'assets/images/institute_logo_default.png';

    final newId = 'STU_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _students.add(AppUser(
      id: newId,
      username: username.trim(),
      password: password.trim(),
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
    String? newPassword,
    String? newName,
    String? newMobile,
    String? profilePhoto,
  }) {
    bool updated = false;

    // Super Admin check
    if (_superAdmin.id == userId || (_currentUser != null && _currentUser!.role == UserRole.superAdmin)) {
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

    // Institute Admin check
    if (_admin.id == userId || (_currentUser != null && _currentUser!.role == UserRole.admin && _currentUser!.id == _admin.id)) {
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

    // Students list check
    final idx = _students.indexWhere((s) => s.id == userId);
    if (idx != -1) {
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        _students[idx].password = newPassword.trim();
      }
      if (newName != null && newName.trim().isNotEmpty) {
        _students[idx].name = newName.trim();
      }
      if (newMobile != null && newMobile.trim().isNotEmpty) {
        _students[idx].mobileNumber = newMobile.trim();
      }
      if (profilePhoto != null) {
        _students[idx].profilePhoto = profilePhoto;
      }
      updated = true;
    }

    // Keep _currentUser synchronized
    if (_currentUser != null) {
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
    final idx = _students.indexWhere((s) => s.id == studentId);
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
