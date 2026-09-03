import 'package:flutter/material.dart';
import '../../core/models/institute_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/institute_service.dart';

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
      const SnackBar(
        content: Text('इन्स्टिच्युट प्रोफाइल, लोगो र कन्ट्याक्ट विवरण सुरक्षित भयो!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('इन्स्टिच्युट प्रोफाइल तथा ब्रान्डिङ (Institute Profile & Branding)'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
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
                              'सुपर एडमिनबाट उपलब्ध सेट कोटा: ${_institute.allowedSetsQuota} वटा सेट • म्याद: ${_institute.daysRemaining} दिन बाँकी',
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
                        const Text(
                          '🎨 इन्स्टिच्युट लोगो तथा पहिचान (Logo & Identity):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'यहाँ छानिएको लोगो र नाम तपाईंको एडमिन प्यानल तथा सबै विद्यार्थीहरूको ड्यासबोर्ड र About Us मा देखिनेछ:',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 14),

                        // Logo Selectors
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: const Icon(Icons.school, size: 40, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('इन्स्टिच्युट ब्याज (Badge / Logo Style):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('क्लासिक लोगो (Classic)'),
                                        selected: _selectedLogo.contains('default'),
                                        onSelected: (_) => setState(() => _selectedLogo = _logoPresets[0]),
                                      ),
                                      ChoiceChip(
                                        label: const Text('ब्लु ब्याच (Royal Blue)'),
                                        selected: _selectedLogo.contains('blue'),
                                        onSelected: (_) => setState(() => _selectedLogo = _logoPresets[1]),
                                      ),
                                      ChoiceChip(
                                        label: const Text('गोल्ड ब्याच (Golden)'),
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
                          decoration: const InputDecoration(
                            labelText: 'इन्स्टिच्युटको पूरा नाम (Institute Name)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.apartment),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'सम्पर्क फोन / मोबाइल नम्बर',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'इमेल ठेगाना',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ठेगाना (स्थान)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _aboutUsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'हाम्रो बारेमा (About Us - विद्यार्थीहरूले हेर्ने विवरण तथा सन्देश)',
                            border: OutlineInputBorder(),
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
                            label: const Text('💾 इन्स्टिच्युट विवरण सेभ गर्नुहोस् (Save Profile)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  }
}
