import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';

/// Admin Student Batch Management & Credential Screen
/// Allows teachers and administrators to organize students by batch,
/// assign sectors, set passwords, and manage active status.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _adminOldPassController = TextEditingController();
  final _adminNewUsernameController = TextEditingController();
  final _adminNewPassController = TextEditingController();
  final _adminConfirmPassController = TextEditingController();

  String _adminStatusMsg = '';
  bool _isAdminSuccess = false;

  String _selectedBatchFilter = 'सबै ब्याचहरू';
  final TextEditingController _studentSearchController = TextEditingController();

  final List<String> _batchesList = [
    'सबै ब्याचहरू',
    '2026 Batch A (बिहानी सत्र)',
    '2026 Batch B (दिवा सत्र)',
    '2026 Batch C (साँझ सत्र)',
    'विशेष UBT बुटक्याम्प',
  ];

  final List<String> _sectorsList = [
    '제조업 (Manufacturing)',
    '농축산 (Agriculture)',
    '건설업 (Construction)',
    '어업 (Fishery)',
  ];

  @override
  void initState() {
    super.initState();
    _adminNewUsernameController.text = AuthService.instance.admin.username;
  }

  @override
  void dispose() {
    _adminOldPassController.dispose();
    _adminNewUsernameController.dispose();
    _adminNewPassController.dispose();
    _adminConfirmPassController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  void _handleChangeAdminCredentials() {
    final oldPass = _adminOldPassController.text.trim();
    final newUsername = _adminNewUsernameController.text.trim();
    final newPass = _adminNewPassController.text.trim();
    final confirmPass = _adminConfirmPassController.text.trim();

    if (oldPass.isEmpty) {
      setState(() {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'कृपया हालको एडमिन पासवर्ड प्रविष्ट गर्नुहोस्!',
          en: 'Please enter the current admin password!',
          ko: '현재 관리자 비밀번호를 입력해주세요!',
        );
        _isAdminSuccess = false;
      });
      return;
    }

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'नयाँ पासवर्ड र कन्फर्म पासवर्ड मिलेन!',
          en: 'New password and confirmation do not match!',
          ko: '새 비밀번호와 확인 비밀번호가 일치하지 않습니다!',
        );
        _isAdminSuccess = false;
      });
      return;
    }

    final success = AuthService.instance.changeAdminCredentials(
      oldPassword: oldPass,
      newUsername: newUsername.isNotEmpty ? newUsername : AuthService.instance.admin.username,
      newPassword: newPass.isNotEmpty ? newPass : AuthService.instance.admin.password,
    );

    setState(() {
      if (success) {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'सफल भयो! एडमिन लगइन विवरण सफलतापूर्वक परिवर्तन गरियो।',
          en: 'Success! Admin login credentials updated successfully.',
          ko: '성공! 관리자 로그인 정보가 변경되었습니다.',
        );
        _isAdminSuccess = true;
        _adminOldPassController.clear();
        _adminNewPassController.clear();
        _adminConfirmPassController.clear();
      } else {
        _adminStatusMsg = LanguageService.instance.trText(
          ne: 'हालको पासवर्ड गलत छ! कृपया सही पासवर्ड हाल्नुहोस्।',
          en: 'Current password is incorrect! Please try again.',
          ko: '현재 비밀번호가 올바르지 않습니다. 다시 입력해주세요.',
        );
        _isAdminSuccess = false;
      }
    });
  }

  void _showStudentQuotaDialog(AppUser student) {
    int currentQuota = student.allowedSetsQuota;
    final quotaCtrl = TextEditingController(text: currentQuota == -1 ? '' : currentQuota.toString());
    DateTime? selectedExpiry = student.validityExpiry;
    bool isUnlimitedExpiry = selectedExpiry == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isUnlimitedQuota = currentQuota == -1;
          final lang = LanguageService.instance;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F766E), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student.name} - ${lang.trText(ne: "कोटा तथा क्यालेन्डर म्याद निर्धारण", en: "Quota & Validity Calendar", ko: "세트 정원 및 유효기간 설정")}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        lang.trText(
                          ne: 'दर्ता नं: ${student.registrationNo ?? "N/A"} • प्रयोगकर्ता: ${student.username}',
                          en: 'Reg: ${student.registrationNo ?? "N/A"} • User: ${student.username}',
                          ko: '수험번호: ${student.registrationNo ?? "N/A"} • 아이디: ${student.username}',
                        ),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Usage stats header card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang.trText(
                                ne: 'हालसम्म हल गरिएका सेट: ${student.setsUsedCount} वटा  |  हालको कोटा: ${student.quotaSummaryText}',
                                en: 'Completed Sets: ${student.setsUsedCount}  |  Current Quota: ${student.quotaSummaryText}',
                                ko: '완료한 세트: ${student.setsUsedCount}개  |  현재 정원: ${student.quotaSummaryText}',
                              ),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. QUESTION SET QUOTA SECTION (1 to Unlimited)
                    Row(
                      children: [
                        const Icon(Icons.assignment_turned_in, size: 18, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        Text(
                          lang.trText(
                            ne: '१. मोडल सेट कोटा निर्धारण (१ देखि असीमित)',
                            en: '1. Question Sets Quota (1 to Unlimited)',
                            ko: '1. 모의고사 세트 정원 (1개 ~ 무제한)',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.trText(
                        ne: 'विद्यार्थीलाई कति सेट प्रश्न हल गर्न दिने छान्नुहोस्:',
                        en: 'Select how many question sets this student can attempt:',
                        ko: '학생이 응시할 수 있는 모의고사 세트 수를 선택하세요:',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),

                    // Quick Quota Presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildQuotaChip(1, '१ सेट (1 Set)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '1';
                          });
                        }),
                        _buildQuotaChip(3, '३ सेट (3 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '3';
                          });
                        }),
                        _buildQuotaChip(5, '५ सेट (5 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '5';
                          });
                        }),
                        _buildQuotaChip(10, '१० सेट (10 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '10';
                          });
                        }),
                        _buildQuotaChip(20, '२० सेट (20 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '20';
                          });
                        }),
                        _buildQuotaChip(30, '३० सेट (30 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '30';
                          });
                        }),
                        _buildQuotaChip(50, '५० सेट (50 Sets)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = val;
                            quotaCtrl.text = '50';
                          });
                        }),
                        _buildQuotaChip(-1, '∞ असीमित (Unlimited)', currentQuota, (val) {
                          setDialogState(() {
                            currentQuota = -1;
                            quotaCtrl.clear();
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Custom Quota Number Input Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quotaCtrl,
                            keyboardType: TextInputType.number,
                            enabled: !isUnlimitedQuota,
                            decoration: InputDecoration(
                              labelText: isUnlimitedQuota
                                  ? lang.trText(ne: 'असीमित कोटा सक्रिय छ', en: 'Unlimited Quota Active', ko: '무제한 정원 활성화됨')
                                  : lang.trText(ne: 'वा इच्छा अनुसार सेट सङ्ख्या हाल्नुहोस् (e.g. 15, 25, 100)', en: 'Or Enter Custom Sets Count (e.g. 15, 25, 100)', ko: '또는 원하는 세트 수 직접 입력 (예: 15, 25, 100)'),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixText: isUnlimitedQuota ? '' : lang.trText(ne: 'सेट', en: 'Sets', ko: '세트'),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null && parsed > 0) {
                                setDialogState(() => currentQuota = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              currentQuota = -1;
                              quotaCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.all_inclusive, size: 18),
                          label: Text(lang.trText(ne: 'असीमित', en: 'Unlimited', ko: '무제한')),
                          style: TextButton.styleFrom(
                            foregroundColor: isUnlimitedQuota ? const Color(0xFF0F766E) : Colors.grey.shade700,
                            backgroundColor: isUnlimitedQuota ? const Color(0xFFCCFBF1) : Colors.transparent,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // 2. VALIDITY DURATION & CALENDAR EXPIRY (1 Day to Unlimited / Months / Calendar)
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 18, color: Color(0xFF0F766E)),
                        const SizedBox(width: 8),
                        Text(
                          lang.trText(
                            ne: '२. क्यालेन्डर म्याद निर्धारण (१ दिन देखि असीमित)',
                            en: '2. Validity Calendar (1 Day to Unlimited)',
                            ko: '2. 캘린더 유효기간 설정 (1일 ~ 무제한)',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.trText(
                        ne: 'क्यालेन्डर खोलेर अन्तिम म्याद (Expiry Date) छान्नुहोस् वा तलका द्रुत बटन थिच्नुहोस्:',
                        en: 'Pick an exact expiry date via calendar or select a quick duration preset below:',
                        ko: '캘린더에서 만료 날짜를 선택하거나 아래 단축 버튼을 누르세요:',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    // Calendar Display Card with picker launcher
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlimitedExpiry
                              ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                              : (selectedExpiry!.isBefore(DateTime.now())
                                  ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                                  : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlimitedExpiry
                              ? Colors.green.shade300
                              : (selectedExpiry!.isBefore(DateTime.now()) ? Colors.red.shade300 : const Color(0xFF0D9488)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Icon(
                              Icons.event_available,
                              color: isUnlimitedExpiry
                                  ? Colors.green.shade700
                                  : (selectedExpiry!.isBefore(DateTime.now()) ? Colors.red.shade700 : const Color(0xFF0F766E)),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.trText(ne: 'छानिएको म्याद (Expiry Date):', en: 'Selected Expiry Date:', ko: '선택된 만료일:'),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isUnlimitedExpiry
                                      ? lang.trText(ne: '✨ असीमित म्याद (कुनै समय सीमा छैन)', en: '✨ Unlimited (No Expiration)', ko: '✨ 무제한 (만료일 없음)')
                                      : '${selectedExpiry!.year}-${selectedExpiry!.month.toString().padLeft(2, '0')}-${selectedExpiry!.day.toString().padLeft(2, '0')}' +
                                          (selectedExpiry!.isBefore(DateTime.now())
                                              ? ' (⚠️ म्याद समाप्त)'
                                              : ' (${selectedExpiry!.difference(DateTime.now()).inDays + 1} दिन बाँकी)'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlimitedExpiry
                                        ? Colors.green.shade900
                                        : (selectedExpiry!.isBefore(DateTime.now()) ? Colors.red.shade900 : const Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: Text(lang.trText(ne: 'क्यालेन्डर', en: 'Calendar', ko: '달력')),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedExpiry ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                                helpText: lang.trText(
                                  ne: 'विद्यार्थीको म्याद समाप्त हुने मिति छान्नुहोस्',
                                  en: 'Select Student Package Expiry Date',
                                  ko: '수험생 패키지 만료 날짜 선택',
                                ),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedExpiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                                  isUnlimitedExpiry = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick duration preset buttons (+7d, +15d, +30d, +60d, +90d, +180d, +1y, Unlimited)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildDurationChip('+७ दिन (+7d)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 7));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+१५ दिन (+15d)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 15));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+३० दिन / १ महिना (+1m)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 30));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+६० दिन / २ महिना (+2m)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 60));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+९० दिन / ३ महिना (+3m)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 90));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+१८० दिन / ६ महिना (+6m)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 180));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('+१ वर्ष (+1 Year)', () {
                          setDialogState(() {
                            selectedExpiry = DateTime.now().add(const Duration(days: 365));
                            isUnlimitedExpiry = false;
                          });
                        }),
                        _buildDurationChip('∞ असीमित (Unlimited)', () {
                          setDialogState(() {
                            selectedExpiry = null;
                            isUnlimitedExpiry = true;
                          });
                        }, isHighlight: isUnlimitedExpiry),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(lang.trText(ne: 'कोटा सेभ गर्नुहोस्', en: 'Save Quota', ko: '정원 설정 저장')),
                onPressed: () {
                  final finalQuota = isUnlimitedQuota ? -1 : (int.tryParse(quotaCtrl.text.trim()) ?? currentQuota);
                  AuthService.instance.updateStudentQuotaAndValidity(
                    studentId: student.id,
                    allowedSetsQuota: finalQuota,
                    validityExpiry: isUnlimitedExpiry ? null : selectedExpiry,
                  );
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.trText(
                        ne: 'विद्यार्थीको सेट कोटा र क्यालेन्डर म्याद सफलतापूर्वक अद्यावधिक गरियो!',
                        en: 'Student set quota and calendar validity updated successfully!',
                        ko: '수험생 세트 정원 및 캘린더 유효기간이 설정되었습니다!',
                      )),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuotaChip(int quotaValue, String label, int currentSelectedQuota, ValueChanged<int> onSelect) {
    final isSelected = currentSelectedQuota == quotaValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      onSelected: (_) => onSelect(quotaValue),
    );
  }

  Widget _buildDurationChip(String label, VoidCallback onTap, {bool isHighlight = false}) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isHighlight ? const Color(0xFFCCFBF1) : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
        color: isHighlight ? const Color(0xFF0F766E) : Colors.black87,
      ),
      side: BorderSide(color: isHighlight ? const Color(0xFF0F766E) : Colors.grey.shade300),
      onPressed: onTap,
    );
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'student123');
    String selectedBatch = '2026 Batch A (बिहानी सत्र)';
    String selectedSector = '제조업 (Manufacturing)';
    String selectedStatus = 'सक्रिय';
    int quota = 10;
    DateTime? expiry = DateTime.now().add(const Duration(days: 30));
    bool isUnlimitedExp = false;
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 10),
              Text(
                LanguageService.instance.trText(
                  ne: 'नयाँ विद्यार्थी थप्नुहोस्',
                  en: 'Add New Student',
                  ko: '새 수험생 등록',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'विद्यार्थीको पूरा नाम*',
                        en: 'Student Full Name*',
                        ko: '수험생 성명*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'दर्ता नम्बर (e.g. 01234575)*',
                        en: 'Registration No (e.g. 01234575)*',
                        ko: '수험번호 (e.g. 01234575)*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: userCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'प्रयोगकर्ता नाम (Username)*',
                              en: 'Username*',
                              ko: '아이디 (Username)*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'पासवर्ड (Password)*',
                              en: 'Password*',
                              ko: '비밀번호*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(
                        ne: 'ब्याच*',
                        en: 'Batch*',
                        ko: '학습 반*',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSector,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'औद्योगिक क्षेत्र',
                              en: 'Industry Sector',
                              ko: '업종 분야',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: _sectorsList.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(LanguageService.instance.sectorText(s), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'स्थिति',
                              en: 'Status',
                              ko: '상태',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'सक्रिय',
                              child: Text(LanguageService.instance.statusText('सक्रिय'), style: const TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'निलम्बित',
                              child: Text(LanguageService.instance.statusText('निलम्बित'), style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) => setDialogState(() => selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Initial Quota & Expiry Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              LanguageService.instance.trText(
                                ne: 'प्रारम्भिक कोटा तथा क्यालेन्डर म्याद:',
                                en: 'Initial Quota & Calendar Validity:',
                                ko: '초기 정원 및 유효기간:',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuotaChip(5, '५ सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(10, '१० सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(20, '२० सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(-1, '∞ असीमित', quota, (v) => setDialogState(() => quota = v)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isUnlimitedExp
                                    ? LanguageService.instance.trText(ne: 'म्याद: असीमित', en: 'Validity: Unlimited', ko: '유효기간: 무제한')
                                    : 'म्याद: ${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')} (${expiry!.difference(DateTime.now()).inDays + 1} दिन)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: const BorderSide(color: Color(0xFF0F766E)),
                              ),
                              icon: const Icon(Icons.edit_calendar, size: 14, color: Color(0xFF0F766E)),
                              label: Text(LanguageService.instance.trText(ne: 'क्यालेन्डर', en: 'Calendar', ko: '달력'), style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E))),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: expiry ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    expiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                                    isUnlimitedExp = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'कृपया सबै आवश्यक विवरण भर्नुहोस्!',
                    en: 'Please fill in all required fields!',
                    ko: '모든 필수 항목을 입력해주세요!',
                  ));
                  return;
                }
                final ok = AuthService.instance.addStudent(
                  name: nameCtrl.text.trim(),
                  registrationNo: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                  username: userCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  batch: selectedBatch,
                  sector: selectedSector,
                  status: selectedStatus,
                  allowedSetsQuota: quota,
                  validityExpiry: isUnlimitedExp ? null : expiry,
                );
                if (ok) {
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LanguageService.instance.trText(
                        ne: 'नयाँ विद्यार्थी सफलतापूर्वक थपियो!',
                        en: 'New student added successfully!',
                        ko: '새 수험생이 등록되었습니다!',
                      )),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  setDialogState(() => error = LanguageService.instance.trText(
                    ne: 'यो Username पहिले नै प्रयोगमा छ!',
                    en: 'This username is already taken!',
                    ko: '이미 사용 중인 아이디입니다!',
                  ));
                }
              },
              child: Text(LanguageService.instance.trText(ne: 'विद्यार्थी सेभ गर्नुहोस्', en: 'Save Student', ko: '수험생 저장')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStudentDialog(AppUser student) {
    final nameCtrl = TextEditingController(text: student.name);
    final userCtrl = TextEditingController(text: student.username);
    final passCtrl = TextEditingController(text: student.password);
    String selectedBatch = student.batch;
    String selectedSector = student.sector;
    String selectedStatus = student.status;
    int quota = student.allowedSetsQuota;
    DateTime? expiry = student.validityExpiry;
    bool isUnlimitedExp = expiry == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${student.name} - ${LanguageService.instance.trText(ne: "विवरण सम्पादन", en: "Edit Credentials", ko: "정보 수정")}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'नाम', en: 'Name', ko: '성명'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: userCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'Username', en: 'Username', ko: '아이디'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'Password', en: 'Password', ko: '비밀번호'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _batchesList.contains(selectedBatch) ? selectedBatch : _batchesList[1],
                    decoration: InputDecoration(
                      labelText: LanguageService.instance.trText(ne: 'ब्याच', en: 'Batch', ko: '학습 반'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _batchesList.skip(1).map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedBatch = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sectorsList.contains(selectedSector) ? selectedSector : _sectorsList.first,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'क्षेत्र', en: 'Sector', ko: '업종'),
                            border: const OutlineInputBorder(),
                          ),
                          items: _sectorsList.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(LanguageService.instance.sectorText(s), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedSector = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(ne: 'स्थिति', en: 'Status', ko: '상태'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'सक्रिय',
                              child: Text(LanguageService.instance.statusText('सक्रिय'), style: const TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'निलम्बित',
                              child: Text(LanguageService.instance.statusText('निलम्बित'), style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) => setDialogState(() => selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Quota & Validity quick box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              LanguageService.instance.trText(
                                ne: 'कोटा तथा क्यालेन्डर म्याद:',
                                en: 'Quota & Calendar Validity:',
                                ko: '정원 및 유효기간:',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuotaChip(5, '५ सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(10, '१० सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(20, '२० सेट', quota, (v) => setDialogState(() => quota = v)),
                            _buildQuotaChip(-1, '∞ असीमित', quota, (v) => setDialogState(() => quota = v)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isUnlimitedExp
                                    ? LanguageService.instance.trText(ne: 'म्याद: असीमित', en: 'Validity: Unlimited', ko: '유효기간: 무제한')
                                    : 'म्याद: ${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')} (${expiry!.difference(DateTime.now()).inDays + 1} दिन)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: const BorderSide(color: Color(0xFF0F766E)),
                              ),
                              icon: const Icon(Icons.edit_calendar, size: 14, color: Color(0xFF0F766E)),
                              label: Text(LanguageService.instance.trText(ne: 'क्यालेन्डर', en: 'Calendar', ko: '달력'), style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E))),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: expiry ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    expiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                                    isUnlimitedExp = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () {
                AuthService.instance.updateStudentCredentials(
                  studentId: student.id,
                  newName: nameCtrl.text.trim(),
                  newUsername: userCtrl.text.trim(),
                  newPassword: passCtrl.text.trim(),
                  newBatch: selectedBatch,
                  newSector: selectedSector,
                  newStatus: selectedStatus,
                  newAllowedSetsQuota: quota,
                  newValidityExpiry: isUnlimitedExp ? null : expiry,
                  clearExpiry: isUnlimitedExp,
                );
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LanguageService.instance.trText(
                      ne: 'विद्यार्थीको विवरण सफलतापूर्वक अद्यावधिक गरियो!',
                      en: 'Student details updated successfully!',
                      ko: '수험생 정보가 변경되었습니다!',
                    )),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
              child: Text(LanguageService.instance.trText(ne: 'अपडेट गर्नुहोस्', en: 'Update', ko: '저장')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent(AppUser student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageService.instance.trText(
          ne: 'विद्यार्थी हटाउने पुष्टि गर्नुहोस्',
          en: 'Confirm Delete Student',
          ko: '수험생 삭제 확인',
        )),
        content: Text(LanguageService.instance.trText(
          ne: 'के तपाईं निश्चित रूपमा "${student.name}" लाई हटाउन चाहनुहुन्छ?',
          en: 'Are you sure you want to delete "${student.name}"?',
          ko: '정말로 "${student.name}" 수험생을 삭제하시겠습니까?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.instance.trText(ne: 'रद्द गर्नुहोस्', en: 'Cancel', ko: '취소')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              AuthService.instance.deleteStudent(student.id);
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LanguageService.instance.trText(
                    ne: 'विद्यार्थी सफलतापूर्वक हटाइयो।',
                    en: 'Student deleted successfully.',
                    ko: '수험생이 삭제되었습니다.',
                  )),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(LanguageService.instance.trText(ne: 'हटाउनुहोस्', en: 'Delete', ko: '삭제')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        final allStudents = AuthService.instance.students;
        final query = _studentSearchController.text.trim().toLowerCase();

        final filteredStudents = allStudents.where((s) {
          final matchesBatch = _selectedBatchFilter.contains('सबै') || _selectedBatchFilter.contains('All') || s.batch == _selectedBatchFilter;
          final matchesQuery = query.isEmpty ||
              s.name.toLowerCase().contains(query) ||
              s.username.toLowerCase().contains(query) ||
              (s.registrationNo?.toLowerCase().contains(query) ?? false);
          return matchesBatch && matchesQuery;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 1. Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.groups_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: 'विद्यार्थी ब्याच तथा क्रेडिसियल व्यवस्थापन',
                          en: 'Student Batch & Credentials Management',
                          ko: '수험생 반별 및 계정 관리',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'ब्याच अनुसार विद्यार्थीहरूको नामावली, क्षेत्र र लगइन क्रेडिसियल नियन्त्रण',
                          en: 'Manage student rosters, industry sectors, and login credentials by batch',
                          ko: '반별 수험생 명단, 업종 선택 및 로그인 계정 정보 제어',
                        ),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Student List with Batch Filter & Search
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 10),
                          Text(
                            LanguageService.instance.trText(
                              ne: 'दर्ता भएका विद्यार्थीहरू (${filteredStudents.length} जना)',
                              en: 'Registered Students (${filteredStudents.length})',
                              ko: '등록된 수험생 목록 (${filteredStudents.length}명)',
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(LanguageService.instance.trText(
                          ne: 'नयाँ विद्यार्थी थप्नुहोस्',
                          en: 'Add Student',
                          ko: '수험생 추가',
                        )),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Batch Filter Bar & Search
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBatchFilter,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'ब्याच फिल्टर',
                              en: 'Filter by Batch',
                              ko: '반별 필터',
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          items: _batchesList.map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(LanguageService.instance.batchText(b), style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedBatchFilter = val!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _studentSearchController,
                          decoration: InputDecoration(
                            hintText: LanguageService.instance.trText(
                              ne: 'विद्यार्थीको नाम, दर्ता नम्बर वा Username खोज्नुहोस्...',
                              en: 'Search by name, reg no, or username...',
                              ko: '이름, 수험번호, 아이디로 검색...',
                            ),
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            suffixIcon: _studentSearchController.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _studentSearchController.clear()))
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Students List
                  if (filteredStudents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Text(
                        LanguageService.instance.trText(
                          ne: 'कुनै विद्यार्थी भेटिएन।',
                          en: 'No students found.',
                          ko: '해당 조건의 수험생이 없습니다.',
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final s = filteredStudents[i];
                        final isActive = s.status.contains('सक्रिय') || s.status.toLowerCase().contains('active');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0] : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(LanguageService.instance.batchText(s.batch), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(LanguageService.instance.sectorText(s.sector), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                LanguageService.instance.trText(
                                  ne: 'दर्ता नं: ${s.registrationNo ?? "N/A"}  •  Username: ${s.username}  •  Password: ${s.password}',
                                  en: 'Reg: ${s.registrationNo ?? "N/A"}  •  User: ${s.username}  •  Pass: ${s.password}',
                                  ko: '수험번호: ${s.registrationNo ?? "N/A"}  •  아이디: ${s.username}  •  비밀번호: ${s.password}',
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 5),
                              // Quota & Validity Badges Row
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Quota badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.assignment_turned_in, size: 12, color: Color(0xFF1E3A8A)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${LanguageService.instance.trText(ne: "कोटा:", en: "Quota:", ko: "정원:")} ${s.quotaSummaryText} (${s.setsUsedCount} हल)',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Validity / Expiry badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: s.isExpired ? Colors.red.shade50 : const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: s.isExpired ? Colors.red.shade300 : const Color(0xFF99F6E4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          s.isExpired ? Icons.event_busy : Icons.calendar_today,
                                          size: 12,
                                          color: s.isExpired ? Colors.red.shade700 : const Color(0xFF0F766E),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${LanguageService.instance.trText(ne: "म्याद:", en: "Validity:", ko: "유효기간:")} ${s.validitySummaryText}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: s.isExpired ? Colors.red.shade800 : const Color(0xFF0F766E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Direct Quota & Calendar Button
                              IconButton(
                                icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F766E), size: 22),
                                tooltip: LanguageService.instance.trText(
                                  ne: 'सेट कोटा तथा क्यालेन्डर म्याद निर्धारण गर्नुहोस्',
                                  en: 'Manage Set Quota & Calendar Validity',
                                  ko: '세트 정원 및 캘린더 유효기간 설정',
                                ),
                                onPressed: () => _showStudentQuotaDialog(s),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isActive ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  LanguageService.instance.statusText(s.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A), size: 20),
                                tooltip: LanguageService.instance.trText(ne: 'सम्पादन गर्नुहोस्', en: 'Edit', ko: '수정'),
                                onPressed: () => _showEditStudentDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: LanguageService.instance.trText(ne: 'हटाउनुहोस्', en: 'Delete', ko: '삭제'),
                                onPressed: () => _confirmDeleteStudent(s),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Admin Credentials Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF0F766E)),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.instance.trText(
                          ne: 'एडमिन क्रेडिसियल तथा पासवर्ड परिवर्तन',
                          en: 'Admin Credentials & Password Management',
                          ko: '학원 관리자 로그인 계정 및 비밀번호 변경',
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_adminStatusMsg.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isAdminSuccess ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isAdminSuccess ? Colors.green : Colors.red),
                      ),
                      child: Text(_adminStatusMsg, style: TextStyle(color: _isAdminSuccess ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adminOldPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'हालको एडमिन पासवर्ड*',
                              en: 'Current Admin Password*',
                              ko: '현재 관리자 비밀번호*',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminNewUsernameController,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ प्रयोगकर्ता नाम (Username)',
                              en: 'New Admin Username',
                              ko: '새 관리자 아이디 (Username)',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adminNewPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ पासवर्ड',
                              en: 'New Password',
                              ko: '새 비밀번호',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _adminConfirmPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'नयाँ पासवर्ड पुष्टि गर्नुहोस्',
                              en: 'Confirm New Password',
                              ko: '새 비밀번호 확인',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                    onPressed: _handleChangeAdminCredentials,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(LanguageService.instance.trText(
                      ne: 'एडमिन विवरण सुरक्षित गर्नुहोस्',
                      en: 'Save Admin Credentials',
                      ko: '관리자 정보 저장',
                    )),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
      },
    );
  }
}
