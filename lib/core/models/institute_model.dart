class InstituteProfile {
  final String id;
  String name;
  String code;
  String logoUrl;
  String phone;
  String email;
  String address;
  String aboutUs;
  int allowedSetsQuota;
  DateTime validityExpiry;
  int maxStudentsQuota;
  bool isActive;
  List<String> assignedSetIds;
  // Maximum allowed file size for uploads (in MB). Null means unlimited.
  int? maxFileSizeMb;
  // New fields for dual quota
  int customSetQuota; // number of custom sets institute can upload
  int customSetDurationDays; // active days for each custom set after upload
  int mainSetQuota; // number of main sets students can access
  int mainSetDurationDays; // duration for main set access
  final DateTime createdAt;

  InstituteProfile({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl = 'assets/images/institute_logo_default.png',
    required this.phone,
    required this.email,
    required this.address,
    this.aboutUs = 'हाम्रो इन्स्टिच्युटमा दक्षिण कोरियाको EPS-TOPIK UBT परीक्षाको उच्चस्तरीय तयारी गराइन्छ। अनुभवी प्रशिक्षक, नवीनतम प्रश्न बैंक र रियल टाइम UBT ल्याब सुविधा।',
    this.allowedSetsQuota = 5,
    required this.validityExpiry,
    this.maxStudentsQuota = 100,
    this.isActive = true,
    List<String>? assignedSetIds,
    int? customSetQuota,
    int? customSetDurationDays,
    int? mainSetQuota,
    int? mainSetDurationDays,
    DateTime? createdAt,
  })  : assignedSetIds = assignedSetIds ?? ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'],
        customSetQuota = customSetQuota ?? 1,
        customSetDurationDays = customSetDurationDays ?? 365,
        mainSetQuota = mainSetQuota ?? 5,
        mainSetDurationDays = mainSetDurationDays ?? 365,
        createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(validityExpiry);

  int get daysRemaining {
    final diff = validityExpiry.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'logoUrl': logoUrl,
        'phone': phone,
        'email': email,
        'address': address,
        'aboutUs': aboutUs,
        'allowedSetsQuota': allowedSetsQuota,
        'validityExpiry': validityExpiry.toIso8601String(),
        'maxStudentsQuota': maxStudentsQuota,
        'isActive': isActive,
        'customSetQuota': customSetQuota,
        'customSetDurationDays': customSetDurationDays,
        'mainSetQuota': mainSetQuota,
        'mainSetDurationDays': mainSetDurationDays,
        'assignedSetIds': assignedSetIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InstituteProfile.fromJson(Map<String, dynamic> json) => InstituteProfile(
        id: json['id'] as String? ?? 'inst_01',
        name: json['name'] as String? ?? 'ग्लोबल कोरियन भाषा इन्स्टिच्युट',
        code: json['code'] as String? ?? 'GLOBAL_01',
        logoUrl: json['logoUrl'] as String? ?? 'assets/images/institute_logo_default.png',
        phone: json['phone'] as String? ?? '9851234567',
        email: json['email'] as String? ?? 'info@globalinstitute.edu.np',
        address: json['address'] as String? ?? 'बागबजार, काठमाडौं (Bagbazar, Kathmandu)',
        aboutUs: json['aboutUs'] as String? ?? 'हाम्रो इन्स्टिच्युटमा दक्षिण कोरियाको EPS-TOPIK UBT परीक्षाको उच्चस्तरीय तयारी गराइन्छ। अनुभवी प्रशिक्षक, नवीनतम प्रश्न बैंक र रियल टाइम UBT ल्याब सुविधा।',
        allowedSetsQuota: json['allowedSetsQuota'] as int? ?? 5,
        validityExpiry: json['validityExpiry'] != null
            ? DateTime.tryParse(json['validityExpiry'] as String) ?? DateTime.now().add(const Duration(days: 180))
            : DateTime.now().add(const Duration(days: 180)),
        maxStudentsQuota: json['maxStudentsQuota'] as int? ?? 100,
        isActive: json['isActive'] as bool? ?? true,
        customSetQuota: json['customSetQuota'] as int? ?? 1,
        customSetDurationDays: json['customSetDurationDays'] as int? ?? 7,
        mainSetQuota: json['mainSetQuota'] as int? ?? 5,
        mainSetDurationDays: json['mainSetDurationDays'] as int? ?? 30,
        assignedSetIds: (json['assignedSetIds'] as List?)?.map((e) => e.toString()).toList() ?? ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
