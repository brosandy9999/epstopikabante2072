import 'package:flutter/material.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';
import '../../core/services/language_service.dart';

/// Institute Admin Branding & Profile Customization Screen
/// Allows Institute Admins to update their Logo, Name, Contact, and About Us info.
class InstituteProfileScreen extends StatefulWidget {
  const InstituteProfileScreen({super.key});

  @override
  State<InstituteProfileScreen> createState() => _InstituteProfileScreenState();
}

class _InstituteProfileScreenState extends State<InstituteProfileScreen> {
  late InstituteProfile _institute;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _aboutUsCtrl;
  String _selectedLogo = 'assets/images/institute_logo_default.png';

  final List<String> _logoPresets = [
    'assets/images/institute_logo_default.png',
    'assets/images/institute_badge_blue.png',
    'assets/images/institute_badge_gold.png',
    'assets/images/institute_badge_red.png',
  ];

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    final instId = user?.instituteId ?? 'inst_01';
    _institute = InstituteService.instance.getInstituteById(instId) ?? InstituteService.instance.getDefaultInstitute();

    _nameCtrl = TextEditingController(text: _institute.name);
    _phoneCtrl = TextEditingController(text: _institute.phone);
    _emailCtrl = TextEditingController(text: _institute.email);
    _addressCtrl = TextEditingController(text: _institute.address);
    _aboutUsCtrl = TextEditingController(text: _institute.aboutUs);
    _selectedLogo = _institute.logoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _aboutUsCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    _institute.name = _nameCtrl.text.trim();
    _institute.phone = _phoneCtrl.text.trim();
    _institute.email = _emailCtrl.text.trim();
    _institute.address = _addressCtrl.text.trim();
    _institute.aboutUs = _aboutUsCtrl.text.trim();
    _institute.logoUrl = _selectedLogo;

    InstituteService.instance.updateInstitute(_institute);
    AuthService.instance.updateInstituteBranding(
      instituteId: _institute.id,
      instituteName: _institute.name,
      instituteLogo: _selectedLogo,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageService.instance.trText(
          ne: 'इन्स्टिच्युट प्रोफाइल, लोगो र कन्ट्याक्ट विवरण सुरक्षित भयो!',
          en: 'Institute profile, logo and contact details saved successfully!',
          ko: '학원 프로필, 로고 및 연락처 정보가 저장되었습니다!',
        )),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(lang.trText(
              ne: 'इन्स्टिच्युट प्रोफाइल तथा ब्रान्डिङ',
              en: 'Institute Profile & Branding',
              ko: '학원 프로필 및 브랜딩 설정',
            )),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            actions: [
              lang.buildLanguageSwitcherWidget(isDark: true),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Subscription Status Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.verified_user, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _institute.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LanguageService.instance.trText(
                                ne: 'उपलब्ध सेट कोटा: ${_institute.allowedSetsQuota} वटा सेट • म्याद: ${_institute.daysRemaining} दिन बाँकी',
                                en: 'Allowed Sets Quota: ${_institute.allowedSetsQuota} sets • Validity: ${_institute.daysRemaining} days remaining',
                                ko: '허용 문제 세트: ${_institute.allowedSetsQuota} 세트 • 유효 기간: ${_institute.daysRemaining}일 남음',
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

                // Branding Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎨 ' + LanguageService.instance.trText(
                            ne: 'इन्स्टिच्युट लोगो तथा पहिचान:',
                            en: 'Institute Logo & Identity:',
                            ko: '학원 로고 및 브랜딩 설정:',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LanguageService.instance.trText(
                            ne: 'यहाँ छानिएको लोगो र नाम तपाईंको एडमिन प्यानल तथा सबै विद्यार्थीहरूको ड्यासबोर्ड र About Us मा देखिनेछ:',
                            en: 'The chosen logo and name will appear across the admin panel, student dashboard, and About Us section:',
                            ko: '선택한 로고와 학원명은 관리자 화면, 수험생 대시보드 및 소개 페이지에 표시됩니다:',
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 14),

                        // Logo Selectors
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.school, size: 40, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LanguageService.instance.trText(
                                      ne: 'इन्स्टिच्युट ब्याज / लोगो:',
                                      en: 'Institute Badge / Logo:',
                                      ko: '학원 배지 / 로고 선택:',
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    children: [
                                      ChoiceChip(
                                        label: Text(LanguageService.instance.trText(ne: 'क्लासिक लोगो (Classic)', en: 'Classic Logo', ko: '클래식 로고')),
                                        selected: _selectedLogo.contains('default'),
                                        onSelected: (_) => setState(() => _selectedLogo = _logoPresets[0]),
                                      ),
                                      ChoiceChip(
                                        label: Text(LanguageService.instance.trText(ne: 'ब्लु ब्याच (Royal Blue)', en: 'Royal Blue Badge', ko: '로열 블루 배지')),
                                        selected: _selectedLogo.contains('blue'),
                                        onSelected: (_) => setState(() => _selectedLogo = _logoPresets[1]),
                                      ),
                                      ChoiceChip(
                                        label: Text(LanguageService.instance.trText(ne: 'गोल्ड ब्याच (Golden)', en: 'Gold Badge', ko: '골드 배지')),
                                        selected: _selectedLogo.contains('gold'),
                                        onSelected: (_) => setState(() => _selectedLogo = _logoPresets[2]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Contact Fields
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'इन्स्टिच्युटको पूरा नाम (Institute Name)',
                              en: 'Institute Full Name',
                              ko: '학원 정식 명칭 (Institute Name)',
                            ),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.apartment),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(
                                    ne: 'सम्पर्क फोन / मोबाइल नम्बर',
                                    en: 'Contact Phone / Mobile',
                                    ko: '연락처 / 전화번호',
                                  ),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.phone),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  labelText: LanguageService.instance.trText(
                                    ne: 'इमेल ठेगाना',
                                    en: 'Email Address',
                                    ko: '이메일 주소',
                                  ),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.email),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'ठेगाना (स्थान)',
                              en: 'Location / Address',
                              ko: '학원 위치 및 주소',
                            ),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _aboutUsCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: LanguageService.instance.trText(
                              ne: 'हाम्रो बारेमा (About Us - विद्यार्थीहरूले हेर्ने विवरण तथा सन्देश)',
                              en: 'About Us (Message to candidates / Institute intro)',
                              ko: '학원 소개 (About Us - 수험생에게 전하는 안내 메시지)',
                            ),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: Text(
                              '💾 ' + LanguageService.instance.trText(
                                ne: 'इन्स्टिच्युट विवरण सेभ गर्नुहोस्',
                                en: 'Save Institute Profile',
                                ko: '학원 정보 저장하기',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Copyright Notice
                Center(
                  child: Text(
                    InstituteService.platformCopyright,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
