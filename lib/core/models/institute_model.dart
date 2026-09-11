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
  int? maxFileSizeMb;
  int customSetQuota;
  int customSetDurationDays;
  int mainSetQuota;
  int mainSetDurationDays;
  final DateTime createdAt;

  InstituteProfile({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl = 'assets/images/institute_logo_default.png',
    required this.phone,
    required this.email,
    required this.address,
    this.aboutUs = '',
    this.allowedSetsQuota = 48,
    required this.validityExpiry,
    this.maxStudentsQuota = 500,
    this.isActive = true,
    List<String>? assignedSetIds,
    int? customSetQuota,
    int? customSetDurationDays,
    int? mainSetQuota,
    int? mainSetDurationDays,
    DateTime? createdAt,
  })  : assignedSetIds = assignedSetIds ?? List.generate(48, (i) => 'set_${(i + 1).toString().padLeft(2, '0')}'),
        customSetQuota = customSetQuota ?? 48,
        customSetDurationDays = customSetDurationDays ?? 3650,
        mainSetQuota = mainSetQuota ?? 48,
        mainSetDurationDays = mainSetDurationDays ?? 3650,
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
        id: json['id'] as String? ?? 'inst_abante_ktm',
        name: json['name'] as String? ?? 'Abante Korean Language (Abante Academy)',
        code: json['code'] as String? ?? 'ABANTE_KTM',
        logoUrl: json['logoUrl'] as String? ?? 'assets/images/institute_logo_default.png',
        phone: json['phone'] as String? ?? '014168102',
        email: json['email'] as String? ?? 'info@abante.edu.np',
        address: json['address'] as String? ?? 'Putalisadak, Kathmandu',
        aboutUs: json['aboutUs'] as String? ?? '',
        allowedSetsQuota: json['allowedSetsQuota'] as int? ?? 48,
        validityExpiry: json['validityExpiry'] != null
            ? DateTime.tryParse(json['validityExpiry'] as String) ?? DateTime.now().add(const Duration(days: 3650))
            : DateTime.now().add(const Duration(days: 3650)),
        maxStudentsQuota: json['maxStudentsQuota'] as int? ?? 500,
        isActive: json['isActive'] as bool? ?? true,
        customSetQuota: json['customSetQuota'] as int? ?? 48,
        customSetDurationDays: json['customSetDurationDays'] as int? ?? 3650,
        mainSetQuota: json['mainSetQuota'] as int? ?? 48,
        mainSetDurationDays: json['mainSetDurationDays'] as int? ?? 3650,
        assignedSetIds: (json['assignedSetIds'] as List?)?.map((e) => e.toString()).toList() ??
            List.generate(48, (i) => 'set_${(i + 1).toString().padLeft(2, '0')}'),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}