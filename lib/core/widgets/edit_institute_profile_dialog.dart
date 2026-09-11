import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/institute_model.dart';
import '../services/institute_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'smart_image_widget.dart';

class EditInstituteProfileDialog extends StatefulWidget {
  final InstituteProfile? initialInstitute;

  const EditInstituteProfileDialog({super.key, this.initialInstitute});

  static Future<void> show(BuildContext context, {InstituteProfile? institute}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditInstituteProfileDialog(initialInstitute: institute),
    );
  }

  @override
  State<EditInstituteProfileDialog> createState() => _EditInstituteProfileDialogState();
}

class _EditInstituteProfileDialogState extends State<EditInstituteProfileDialog> {
  late List<InstituteProfile> _institutes;
  late String _selectedInstId;

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _aboutCtrl;
  late TextEditingController _logoUrlCtrl;
  String _currentLogo = '';

  @override
  void initState() {
    super.initState();
    _institutes = InstituteService.instance.getAllInstitutes();
    final defaultInst = widget.initialInstitute ??
        (AuthService.instance.currentUser?.instituteId != null
            ? InstituteService.instance.getInstituteById(AuthService.instance.currentUser!.instituteId!)
            : null) ??
        InstituteService.instance.getDefaultInstitute();

    _selectedInstId = defaultInst.id;

    _nameCtrl = TextEditingController(text: defaultInst.name);
    _codeCtrl = TextEditingController(text: defaultInst.code);
    _phoneCtrl = TextEditingController(text: defaultInst.phone);
    _emailCtrl = TextEditingController(text: defaultInst.email);
    _addressCtrl = TextEditingController(text: defaultInst.address);
    _aboutCtrl = TextEditingController(text: defaultInst.aboutUs);
    _logoUrlCtrl = TextEditingController(text: defaultInst.logoUrl);
    _currentLogo = defaultInst.logoUrl;
  }

  void _onInstituteChanged(String instId) {
    final inst = InstituteService.instance.getInstituteById(instId);
    if (inst == null) return;
    setState(() {
      _selectedInstId = instId;
      _nameCtrl.text = inst.name;
      _codeCtrl.text = inst.code;
      _phoneCtrl.text = inst.phone;
      _emailCtrl.text = inst.email;
      _addressCtrl.text = inst.address;
      _aboutCtrl.text = inst.aboutUs;
      _logoUrlCtrl.text = inst.logoUrl;
      _currentLogo = inst.logoUrl;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _aboutCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  void _saveInstitute() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया इन्स्टिच्युटको नाम भर्नुहोस्।')),
      );
      return;
    }

    final inst = InstituteService.instance.getInstituteById(_selectedInstId);
    if (inst != null) {
      inst.name = name;
      inst.code = _codeCtrl.text.trim();
      inst.phone = _phoneCtrl.text.trim();
      inst.email = _emailCtrl.text.trim();
      inst.address = _addressCtrl.text.trim();
      inst.aboutUs = _aboutCtrl.text.trim();
      inst.logoUrl = _logoUrlCtrl.text.trim();

      InstituteService.instance.updateInstitute(inst);

      AuthService.instance.updateInstituteBranding(
        instituteId: inst.id,
        instituteName: inst.name,
        instituteLogo: inst.logoUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${inst.name} को विवरण र लोगो सफलतापूर्वक सुरक्षित गरियो!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF1E3A8A), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.trText(
                          ne: '🏫 इन्स्टिच्युट प्रोफाइल तथा लोगो सेटिङ',
                          en: '🏫 Institute Profile & Branding Settings',
                          ko: '🏫 기관 프로필 및 로고 설정',
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.trText(
                          ne: 'इन्स्टिच्युटको नाम, ठेगाना, फोन नम्बर तथा लोगो परिवर्तन गर्नुहोस्',
                          en: 'Update institute details, branch address, contact and official logo',
                          ko: '기관명, 지점 주소, 연락처 및 공식 로고를 수정합니다',
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch Selector
                    if (_institutes.length > 1) ...[
                      Text(
                        lang.trText(ne: 'शाखा / क्याम्पस छान्नुहोस् (Select Branch):', en: 'Select Branch:', ko: '지점 선택:'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedInstId,
                            isExpanded: true,
                            items: _institutes.map((inst) {
                              return DropdownMenuItem<String>(
                                value: inst.id,
                                child: Text(
                                  '${inst.name} - ${inst.address}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _onInstituteChanged(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Logo Preview & Input
                    Text(
                      lang.trText(ne: '🖼️ इन्स्टिच्युट लोगो (Official Logo):', en: '🖼️ Official Institute Logo:', ko: '🖼️ 공식 기관 로고:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _currentLogo.isNotEmpty
                              ? SmartImageWidget(imageSource: _currentLogo, fit: BoxFit.contain)
                              : const Icon(Icons.image, size: 36, color: Colors.grey),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _logoUrlCtrl,
                                onChanged: (val) => setState(() => _currentLogo = val.trim()),
                                decoration: InputDecoration(
                                  labelText: lang.trText(ne: 'लोगो URL वा Base64 Data', en: 'Logo URL / File Path / Base64', ko: '로고 URL / 파일 경로'),
                                  hintText: 'https://... वा assets/... वा data:image/...',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang.trText(
                                  ne: 'यो लोगो परीक्षा स्क्रिन, कभर पेज र सर्टिफिकेटमा देखिनेछ।',
                                  en: 'This logo appears on Exam Screens, Paper Prints & Certificates.',
                                  ko: '이 로고는 시험 화면, 표지 및 수료증에 인쇄됩니다.',
                                ),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 1. Institute Name
                    Text(
                      lang.trText(ne: '🏢 इन्स्टिच्युटको पूरा नाम (Institute Full Name):', en: '🏢 Institute Name:', ko: '🏢 기관 전체 이름:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Abante Korean Language (Abante Academy)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Address & Phone (2-Column)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.trText(ne: '📍 शाखा ठेगाना (Branch Address):', en: '📍 Address:', ko: '📍 지점 주소:'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _addressCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Putalisadak, Kathmandu',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.trText(ne: '📞 फोन नम्बर (Contact Phone):', en: '📞 Phone:', ko: '📞 전화번호:'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _phoneCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 014168102 वा 985130020',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3. Email & Code
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.trText(ne: '✉️ इमेल (Official Email):', en: '✉️ Email:', ko: '✉️ 이메일:'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _emailCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. info@abante.edu.np',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.trText(ne: '🏷️ इन्स्टिच्युट कोड (Institute Code):', en: '🏷️ Code:', ko: '🏷️ 기관 코드:'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _codeCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. ABANTE_KTM',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 4. About Us / Notice
                    Text(
                      lang.trText(ne: '📝 थप जानकारी / स्लोगन (About / Slogan):', en: '📝 About Institute / Description:', ko: '📝 기관 소개:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _aboutCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Authentic HRDK EPS-TOPIK Korean Language Center',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(lang.trText(ne: 'रद्द गर्नुहोस् (Cancel)', en: 'Cancel', ko: '취소')),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveInstitute,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(lang.trText(ne: 'परिवर्तन सुरक्षित गर्नुहोस् (Save Details)', en: 'Save Details', ko: '저장하기')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}