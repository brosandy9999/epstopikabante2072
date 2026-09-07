import 'dart:convert';
import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/gemini_ai_service.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/widgets/app_exit_dialog.dart';
import 'paper_exam_print_screen.dart';

enum ImportFormat { aiPdf, csv, json }

/// Phase 14 & 15: Gemini AI & CSV / JSON Bulk Question Ingestion Portal
class ImportWorkflowScreen extends StatefulWidget {
  const ImportWorkflowScreen({super.key});

  @override
  State<ImportWorkflowScreen> createState() => _ImportWorkflowScreenState();
}

class _ImportWorkflowScreenState extends State<ImportWorkflowScreen> {
  ImportFormat _selectedFormat = ImportFormat.aiPdf;
  final TextEditingController _textController = TextEditingController();

  String _targetSetId = 'set_01';
  final TextEditingController _customTitleController =
      TextEditingController(text: '제6회 AI 신규 모의고사 (AI Extracted Set)');
  final TextEditingController _customSectorController =
      TextEditingController(text: '기타/서비스 (Service & General)');

  List<QuestionTemplate> _parsedQuestions = [];
  Map<String, QuestionAnswerInfo> _parsedAnswerKeys = {};
  String? _validationError;
  bool _isParsed = false;
  bool _isAiLoading = false;
  String _aiLoadingStatus = '';

  UploadedFilePayload? _uploadedFile;

  @override
  void initState() {
    super.initState();
    GeminiAiService.instance.init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _customTitleController.dispose();
    _customSectorController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    if (_selectedFormat == ImportFormat.aiPdf) {
      _uploadedFile = null;
      _textController.text =
          '''[1] 다음 그림을 보고 맞는 단어나 문장을 고르십시오.
[가방 그림]
① 가방
② 공책
③ 수첩
④ 안경

[2] 다음 직업을 나타내는 그림을 고르십시오.
[소방관 그림]
① 의사
② 경찰관
③ 소방관
④ 요리사

[3] 다음 표지의 의미는 무엇입니까?
['주차금지' 표지판]
① 차를 세우지 마십시오.
② 담배를 피우지 마십시오.
③ 사진을 찍지 마십시오.
④ 뛰어가지 마십시오.

[4] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.
가: 어디에 가요?
나: 시장에 (      ).
① 가요
② 와요
③ 봐요
④ 사요

[5] 빈칸에 들어갈 가장 알맞은 것을 고르십시오.
사과 한 개에 천 (      )이에요.
① 명
② 개
③ 원
④ 병

[21] [듣기] 들은 것을 고르십시오.
① 공장
② 시장
③ 식당
④ 서점

[22] [듣기] 들은 것을 고르십시오.
① 가방
② 모자
③ 구두
④ 바지

[23] [듣기] 이것은 무엇입니까?
① 안경
② 장갑
③ 안전화
④ 마스크

[24] [듣기] 질문을 듣고 알맞은 대답을 고르십시오.
남: 한국 사람입니까?
① 네, 한국 사람입니다.
② 아니요, 베트남에 갑니다.
③ 네, 회사원입니다.
④ 아니요, 학생이 아닙니다.

[25] [듣기] 질문을 듣고 알맞은 대답을 고르십시오.
여: 지금 몇 시예요?
① 오후 2시예요.
② 2개 있어요.
③ 2만 원이에요.
④ 2층이에요.''';
    } else if (_selectedFormat == ImportFormat.csv) {
      _uploadedFile = null;
      _textController.text =
          'type,questionText,option1,option2,option3,option4,correctIndex,explanation\n'
          'reading,"[1] 다음 그림을 보고 맞는 단어를 고르십시오. (तस्बिर हेर्नुहोस्)","가방","공책","수첩","안경",1,"तस्बिरमा कापी (공책) देखाइएको छ।"\n'
          'reading,"[2] 다음 직업을 나타내는 그림을 고르십시오.","의사","경찰관","소방관","요리사",2,"आगो निभाउने व्यक्तिलाई 소방관 भनिन्छ।"\n'
          'reading,"[3] (주차금지) 표지의 의미는 무엇입니까?","차를 세우지 마십시오.","담배를 피우지 마십시오.","사진을 찍지 마십시오.","뛰어가지 마십시오.",0,"주차금지 को अर्थ गाडी नरोक्नुहोस् हो। "\n'
          'reading,"[4] 가: 어디에 가요?\\n나: 시장에 (      ).","가요","와요","봐요","사요",0,"시장에 가요 (बजार जान्छु) सहि हुन्छ।"\n'
          'reading,"[5] 사과 한 개에 천 (      )이에요.","명","개","원","병",2,"कोरियाली मुद्रा गन्ती गर्दा 원 प्रयोग हुन्छ।"\n'
          'listening,"[21] 들은 것을 고르십시오.","공장","시장","식당","서점",0,"सुनेको शब्द 공장 (फ्याक्ट्री) हो।"\n'
          'listening,"[22] 들은 것을 고르십시오.","가방","모자","구두","바지",1,"सुनेको शब्द 모자 (टोपी) हो।"\n'
          'listening,"[23] 이것은 무엇입니까?","안경","장갑","안전화","마스크",2,"सुरक्षा जुत्तालाई 안전화 भनिन्छ।"\n'
          'listening,"[24] 한국 사람입니까?","네, 한국 사람입니다.","아니요, 베트남에 갑니다.","네, 회사원입니다.","아니요, 학생이 아닙니다.",0,"ने, कोरियन हुँ सहि उत्तर हो।"\n'
          'listening,"[25] 지금 몇 시예요?","오후 2시예요.","2개 있어요.","2만 원이에요.","2층이에요.",0,"समय सोधेकाले दिउँसोको २ बज्यो सहि उत्तर हो।"';
    } else {
      _uploadedFile = null;
      final sampleJson = [
        {
          "type": "reading",
          "questionText": "[1] 다음 그림을 보고 맞는 단어를 고르십시오. (तस्बिर हेर्नुहोस्)",
          "options": ["가방", "공책", "수첩", "안경"],
          "correctIndex": 1,
          "explanation": "तस्बिरमा कापी (공책) देखाइएको छ।"
        },
        {
          "type": "reading",
          "questionText": "[2] 다음 직업을 나타내는 그림을 고르십시오.",
          "options": ["의사", "경찰관", "소방관", "요리사"],
          "correctIndex": 2,
          "explanation": "आगो निभाउने व्यक्तिलाई 소방관 भनिन्छ।"
        },
        {
          "type": "reading",
          "questionText": "[3] '주차금지' 표지의 의미는 무엇입니까?",
          "options": ["차를 세우지 마십시오.", "담배를 피우지 마십시오.", "사진을 찍지 마십시오.", "뛰어가지 마십시오."],
          "correctIndex": 0,
          "explanation": "주차금지 को अर्थ गाडी नरोक्नुहोस् हो।"
        },
        {
          "type": "listening",
          "questionText": "[21] 들은 것을 고르십시오.",
          "options": ["공장", "시장", "식당", "서점"],
          "correctIndex": 0,
          "explanation": "सुनेको शब्द 공장 (फ्याक्ट्री) हो।"
        },
        {
          "type": "listening",
          "questionText": "[22] 들은 것을 고르십시오.",
          "options": ["가방", "모자", "구두", "바지"],
          "correctIndex": 1,
          "explanation": "सुनेको शब्द 모자 (टोपी) हो।"
        }
      ];
      _textController.text = const JsonEncoder.withIndent('  ').convert(sampleJson);
    }
    setState(() {});
  }

  Future<void> _pickFile(bool isPdf) async {
    setState(() {
      _validationError = null;
    });

    try {
      final payload = isPdf
          ? await FileUploadService.instance.pickPdfFile()
          : await FileUploadService.instance.pickImageFile();

      if (payload != null) {
        setState(() {
          _uploadedFile = payload;
          _validationError = null;
        });
      }
    } catch (e) {
      setState(() {
        _validationError = "फाइल छनौट गर्दा समस्या आयो: $e";
      });
    }
  }

  Future<void> _parseWithAi() async {
    setState(() {
      _validationError = null;
      _parsedQuestions = [];
      _parsedAnswerKeys = {};
      _isParsed = false;
      _isAiLoading = true;
      _aiLoadingStatus = 'Google Gemini Flash AI सँग जडान गर्दै...';
    });

    try {
      List<AiExtractedQuestion> extracted;

      if (_uploadedFile != null) {
        setState(() {
          _aiLoadingStatus = '${_uploadedFile!.name} फाइलबाट प्रश्नहरू, विकल्पहरू र उत्तरहरू निकाल्दै...';
        });

        extracted = await GeminiAiService.instance.parseQuestionsFromFile(
          base64Data: _uploadedFile!.dataUrl,
          mimeType: _uploadedFile!.mimeType,
        );
      } else {
        final text = _textController.text.trim();
        if (text.isEmpty) {
          throw Exception("कृपया PDF/तस्बिर फाइल अपलोड गर्नुहोस् वा तल कोरियन प्रश्नको पाठ टाँस्नुहोस्।");
        }

        setState(() {
          _aiLoadingStatus = 'कोरियन प्रश्नहरूको पाठ विश्लेषण गर्दै, सही उत्तर र नेपाली व्याख्या तयार गर्दै...';
        });

        extracted = await GeminiAiService.instance.parseQuestionsFromText(text);
      }

      if (extracted.isEmpty) {
        throw Exception("AI ले कुनै मान्य प्रश्नहरू पत्ता लगाउन सकेन। कृपया इनपुट स्पष्ट छ कि छैन जाँच गर्नुहोस्।");
      }

      // Convert extracted AI questions to UniversalQuestion and AnswerKey
      final List<QuestionTemplate> questions = [];
      final Map<String, QuestionAnswerInfo> answerKeys = {};

      for (int i = 0; i < extracted.length; i++) {
        final item = extracted[i];
        final qNum = item.number > 0 ? item.number : (i + 1);
        final qId = "AI_${qNum < 10 ? '0' : ''}$qNum";

        final isListening = item.type == 'listening' || qNum > 20;

        questions.add(
          UniversalQuestion(
            questionId: qId,
            questionNumber: qNum,
            questionText: item.passage != null && item.passage!.isNotEmpty
                ? '${item.questionText}\n${item.passage}'
                : item.questionText,
            isListening: isListening,
            questionAudioUrl: isListening ? 'assets/audio/sample_listening.mp3' : null,
            textOptions: item.options,
          ),
        );

        answerKeys[qId] = QuestionAnswerInfo(
          correctIndex: item.correctIndex.clamp(0, 3),
          explanation: item.explanation.isNotEmpty
              ? item.explanation
              : "सहि उत्तर विकल्प ${item.correctIndex + 1} हो।",
        );
      }

      setState(() {
        _parsedQuestions = questions;
        _parsedAnswerKeys = answerKeys;
        _isParsed = true;
        _isAiLoading = false;
      });
    } catch (e) {
      setState(() {
        _validationError = "AI प्रशोधन त्रुटि: ${e.toString().replaceAll('Exception: ', '')}";
        _isAiLoading = false;
      });
    }
  }

  void _parseAndValidate() {
    if (_selectedFormat == ImportFormat.aiPdf) {
      _parseWithAi();
      return;
    }

    setState(() {
      _validationError = null;
      _parsedQuestions = [];
      _parsedAnswerKeys = {};
      _isParsed = false;
    });

    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _validationError = "कृपया CSV वा JSON डाटा पेस्ट गर्नुहोस् वा नमुना लोड गर्नुहोस्।");
      return;
    }

    try {
      if (_selectedFormat == ImportFormat.csv) {
        _parseCsv(rawText);
      } else {
        _parseJson(rawText);
      }

      if (_parsedQuestions.isEmpty) {
        setState(() => _validationError = "कुनै पनि मान्य प्रश्न फेला परेन। ढाँचा जाँच गर्नुहोस्।");
      } else {
        setState(() => _isParsed = true);
      }
    } catch (e) {
      setState(() => _validationError = "पार्सिङ त्रुटि: ${e.toString()}");
    }
  }

  void _parseCsv(String csvText) {
    final lines = const LineSplitter().convert(csvText);
    if (lines.isEmpty) return;

    int qIndex = 1;
    bool isHeader = true;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (isHeader && (line.toLowerCase().startsWith('type') || line.toLowerCase().startsWith('question'))) {
        isHeader = false;
        continue;
      }
      isHeader = false;

      final parts = _splitCsvLine(line);
      if (parts.length < 7) continue;

      final type = parts[0].trim().toLowerCase();
      final qText = parts[1].trim();
      final opt1 = parts[2].trim();
      final opt2 = parts[3].trim();
      final opt3 = parts[4].trim();
      final opt4 = parts[5].trim();
      final correctIdx = int.tryParse(parts[6].trim()) ?? 0;
      final explanation = parts.length > 7 ? parts[7].trim() : "सहि उत्तर विकल्प ${correctIdx + 1} हो।";

      final qId = "IMP_${qIndex < 10 ? '0' : ''}$qIndex";
      final options = [opt1, opt2, opt3, opt4];

      if (type.contains('listen')) {
        _parsedQuestions.add(
          UniversalQuestion(
            questionId: qId,
            questionNumber: qIndex,
            questionText: qText,
            isListening: true,
            questionAudioUrl: 'assets/audio/sample_listening.mp3',
            textOptions: options,
          ),
        );
      } else {
        _parsedQuestions.add(
          UniversalQuestion(
            questionId: qId,
            questionNumber: qIndex,
            questionText: qText,
            isListening: false,
            textOptions: options,
          ),
        );
      }

      _parsedAnswerKeys[qId] = QuestionAnswerInfo(
        correctIndex: correctIdx.clamp(0, 3),
        explanation: explanation,
      );

      qIndex++;
    }
  }

  List<String> _splitCsvLine(String line) {
    final List<String> result = [];
    bool insideQuotes = false;
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  void _parseJson(String jsonText) {
    final dynamic decoded = jsonDecode(jsonText);
    final List<dynamic> list = decoded is List ? decoded : [decoded];

    int qIndex = 1;
    for (var item in list) {
      if (item is! Map) continue;

      final type = (item['type'] ?? 'reading').toString().toLowerCase();
      final qText = (item['questionText'] ?? '').toString();
      final List<dynamic> rawOpts = item['options'] ?? [];
      final options = rawOpts.map((o) => o.toString()).toList();
      while (options.length < 4) {
        options.add('विकल्प ${options.length + 1}');
      }
      final correctIdx = (item['correctIndex'] is int)
          ? item['correctIndex'] as int
          : (int.tryParse(item['correctIndex']?.toString() ?? '0') ?? 0);
      final explanation = (item['explanation'] ?? 'सहि उत्तर विकल्प ${correctIdx + 1} हो।').toString();

      final qId = "IMP_${qIndex < 10 ? '0' : ''}$qIndex";

      if (type.contains('listen')) {
        _parsedQuestions.add(
          UniversalQuestion(
            questionId: qId,
            questionNumber: qIndex,
            questionText: qText,
            isListening: true,
            questionAudioUrl: (item['audioUrl'] ?? item['questionAudioUrl'] ?? 'assets/audio/sample_listening.mp3').toString(),
            textOptions: options.sublist(0, 4),
            audioScript: item['audioScript']?.toString(),
            audioScriptNepali: item['audioScriptNepali']?.toString(),
          ),
        );
      } else {
        _parsedQuestions.add(
          UniversalQuestion(
            questionId: qId,
            questionNumber: qIndex,
            questionText: qText,
            isListening: false,
            questionImageUrl: (item['imageUrl'] ?? item['questionImageUrl'])?.toString(),
            textOptions: options.sublist(0, 4),
          ),
        );
      }

      _parsedAnswerKeys[qId] = QuestionAnswerInfo(
        correctIndex: correctIdx.clamp(0, 3),
        explanation: explanation,
      );

      qIndex++;
    }
  }

  void _showApiKeySettings() {
    final keyCtrl = TextEditingController(text: GeminiAiService.instance.apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text("Google Gemini API Key सेटिङ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "यो API Key प्रश्नपत्र PDF, तस्बिर तथा कोरियन पाठलाई स्वचालित रूपमा विश्लेषण गरी EPS-TOPIK मोडलमा रूपान्तरण गर्न प्रयोग हुन्छ।",
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: "Gemini API Key",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "✓ प्रणालीमा सक्रिय डिफल्ट कि पहिले नै कन्फिगर गरिएको छ।",
                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("रद्द गर्नुहोस्"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (keyCtrl.text.trim().isNotEmpty) {
                await GeminiAiService.instance.setApiKey(keyCtrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("सुरक्षित गर्नुहोस्"),
          ),
        ],
      ),
    );
  }

  void _deleteParsedQuestion(int index) {
    setState(() {
      final removed = _parsedQuestions.removeAt(index);
      _parsedAnswerKeys.remove(removed.questionId);
    });
  }

  void _importToQuestionBank() {
    if (_parsedQuestions.isEmpty) return;

    final isSuperAdmin = AuthService.instance.currentUser?.role == UserRole.superAdmin;
    final instituteId = AuthService.instance.currentUser?.instituteId;
    final instituteName = AuthService.instance.currentUser?.instituteName;
    final existingSets = QuestionBankService.instance.getAllMockSets();
    MockTestSet targetSet;

    if (_targetSetId == 'new_set') {
      final newId = 'set_${existingSets.length + 1 < 10 ? '0' : ''}${existingSets.length + 1}';
      targetSet = MockTestSet(
        id: newId,
        title: _customTitleController.text.trim().isEmpty
            ? '제${existingSets.length + 1}회 신규 모의고사'
            : _customTitleController.text.trim(),
        sector: _customSectorController.text.trim().isEmpty
            ? '기타 (Custom)'
            : _customSectorController.text.trim(),
        description: 'Admin द्वारा AI/थोक आयात मार्फत थपिएको ${_parsedQuestions.length} वटा नयाँ प्रश्नहरूको सेट।',
        questions: _parsedQuestions,
        answerKeys: _parsedAnswerKeys,
        isApproved: isSuperAdmin,
        createdByRole: isSuperAdmin ? 'superAdmin' : 'admin',
        instituteId: instituteId,
        instituteName: instituteName,
      );
    } else {
      final current = QuestionBankService.instance.getMockSetById(_targetSetId);
      targetSet = MockTestSet(
        id: current.id,
        title: current.title,
        sector: current.sector,
        description: current.description,
        questions: _parsedQuestions,
        answerKeys: _parsedAnswerKeys,
        isApproved: isSuperAdmin ? current.isApproved : false,
        createdByRole: isSuperAdmin ? current.createdByRole : 'admin',
        instituteId: instituteId ?? current.instituteId,
        instituteName: instituteName ?? current.instituteName,
      );
    }

    QuestionBankService.instance.addOrUpdateMockSet(targetSet);
    CloudSyncService.instance.pushToCloud();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isSuperAdmin ? Icons.check_circle : Icons.hourglass_top_rounded,
                color: isSuperAdmin ? Colors.green : Colors.amber.shade800),
            const SizedBox(width: 8),
            Text(isSuperAdmin ? "थोक प्रश्न आयात सफल भयो!" : "प्रश्न सेट सुरक्षित र स्वीकृतिको प्रतीक्षामा!"),
          ],
        ),
        content: Text(
          isSuperAdmin
              ? "कुल ${_parsedQuestions.length} वटा प्रश्नहरू '${targetSet.title}' मा सफलतापूर्वक थपिएका छन्। यो सेट तुरुन्तै सबै विद्यार्थीहरूका लागि प्रकाशित भएको छ।"
              : "कुल ${_parsedQuestions.length} वटा प्रश्नहरू '${targetSet.title}' मा सफलतापूर्वक सुरक्षित गरिएको छ।\n\n📌 सूचना: यो सेट सुपर एडमिनले जाँच गरी स्वीकृति (Approval) दिएपछि मात्र विद्यार्थीहरूको परीक्षा हल तथा अभ्यास पोर्टलमा देखिनेछ।",
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A)),
            label: const Text("📄 पेपर परीक्षा PDF (८ पृष्ठ) हेर्नुहोस्"),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaperExamPrintScreen(testSet: targetSet)),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("सम्पन्न (Done)"),
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
        final existingSets = QuestionBankService.instance.getAllMockSets();
        final hasUnsavedText = _textController.text.trim().isNotEmpty || _isParsed || _uploadedFile != null;

        return PopScope(
          canPop: !hasUnsavedText,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldLeave = await showActionExitConfirmationDialog(
              context,
              titleNe: 'आयात पोर्टल छोड्ने निश्चित हुनुहुन्छ?',
              titleEn: 'Leave Import Portal?',
              titleKo: '문항 가져오기 화면을 나가시겠습니까?',
              messageNe: 'तपाईंले लोड गर्नुभएको वा टाइप गर्नुभएको प्रश्न डाटा बैंकमा सेभ भएको छैन। बाहिर निस्कँदा डाटा मेटिन सक्छ।',
              messageEn: 'Your imported question draft is not saved to the question bank yet. Leaving now will discard it.',
              messageKo: '작성하거나 불러온 문항 데이터가 아직 문제은행에 등록되지 않았습니다. 지금 나가시면 데이터가 초기화됩니다.',
              confirmBtnNe: 'हो, बाहिर निस्कनुहोस्',
              confirmBtnEn: 'Discard & Leave',
              confirmBtnKo: '나가기',
              cancelBtnNe: 'रद्द गर्नुहोस्',
              cancelBtnEn: 'Keep Editing',
              cancelBtnKo: '계속 편집',
              isDestructive: true,
            );
            if (shouldLeave == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.trText(
                                ne: "🤖 AI र थोक प्रश्न आयात पोर्टल (AI Question Ingestion)",
                                en: "AI & Bulk Question Ingestion Portal",
                                ko: "AI 및 대량 문항 가져오기 포털",
                              ),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang.trText(
                                ne: "PDF फाइल, तस्बिर, वा कोरियन पाठबाट Google Gemini AI ले स्वतः १-४० प्रश्न, सही उत्तर र नेपाली व्याख्या निकाल्दछ।",
                                en: "Extract EPS-TOPIK Q1-40 with options, answers & Nepali explanations directly from PDF/Images via Gemini AI.",
                                ko: "PDF 파일, 이미지 또는 한국어 텍스트에서 Gemini AI가 읽기/듣기 1~40문항, 정답 및 네팔어 해설을 자동 추출합니다.",
                              ),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showApiKeySettings,
                        icon: const Icon(Icons.key, color: Colors.white),
                        tooltip: "Gemini API Key सेटिङ",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Format Selection and Action Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    // Segmented Format Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 16),
                              SizedBox(width: 6),
                              Text("🤖 AI PDF / तस्बिर"),
                            ],
                          ),
                          selected: _selectedFormat == ImportFormat.aiPdf,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: _selectedFormat == ImportFormat.aiPdf ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedFormat = ImportFormat.aiPdf),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("📄 CSV (Excel)"),
                          selected: _selectedFormat == ImportFormat.csv,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: _selectedFormat == ImportFormat.csv ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedFormat = ImportFormat.csv),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("🧩 JSON"),
                          selected: _selectedFormat == ImportFormat.json,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: _selectedFormat == ImportFormat.json ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedFormat = ImportFormat.json),
                        ),
                      ],
                    ),

                    // Load Sample Data Button
                    OutlinedButton.icon(
                      onPressed: _loadSampleData,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(lang.trText(
                        ne: "📋 नमुना डाटा लोड गर्नुहोस्",
                        en: "📋 Load Sample Data",
                        ko: "📋 샘플 데이터 불러오기",
                      )),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // AI PDF/Image Upload Box
                if (_selectedFormat == ImportFormat.aiPdf) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.upload_file_rounded, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text(
                              "१. परीक्षाको PDF फाइल वा तस्बिर (Image) अपलोड गर्नुहोस्:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickFile(true),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text("📄 PDF फाइल छान्नुहोस्"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _pickFile(false),
                              icon: const Icon(Icons.image, size: 18),
                              label: const Text("🖼️ तस्बिर/फोटो छान्नुहोस्"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        if (_uploadedFile != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _uploadedFile!.mimeType.contains('pdf')
                                      ? Icons.picture_as_pdf
                                      : Icons.image,
                                  color: Colors.teal.shade800,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _uploadedFile!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "${_uploadedFile!.formattedSize} • ${_uploadedFile!.mimeType}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: const Text("तयार (Ready)",
                                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  tooltip: "फाइल हटाउनुहोस्",
                                  onPressed: () => setState(() => _uploadedFile = null),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          "वा यहाँ कोरियन प्रश्नको पाठ सिधै पेस्ट गर्नुहोस् (Paste Text or Copy-Paste from PDF):",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Raw Text Area
                TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: _selectedFormat == ImportFormat.aiPdf
                        ? '[1] 다음 그림을 보고 맞는 단어나 문장을 고르십시오.\n① 가방\n② 공책\n③ 수첩\n④ 안경\n\n[2] 다음 직업을 나타내는 그림을 고르십시오...'
                        : (_selectedFormat == ImportFormat.csv
                            ? 'type,questionText,option1,option2,option3,option4,correctIndex,explanation\nreading,"[1] 다음 그림을...",가방,공책,수첩,안경,1,"व्याख्या..."'
                            : '[\n  {\n    "type": "reading",\n    "questionText": "...",\n    "options": ["A", "B", "C", "D"],\n    "correctIndex": 0,\n    "explanation": "..."\n  }\n]'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),

                const SizedBox(height: 16),

                // Parse & Process Action Button
                if (_isAiLoading) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade300),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _aiLoadingStatus,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _parseAndValidate,
                    icon: Icon(_selectedFormat == ImportFormat.aiPdf ? Icons.auto_awesome : Icons.analytics_outlined),
                    label: Text(
                      _selectedFormat == ImportFormat.aiPdf
                          ? "🤖 Gemini AI बाट प्रश्नहरू निकाल्नुहोस् (Extract with AI)"
                          : lang.trText(
                              ne: "डाटा जाँच र प्रमाणीकरण गर्नुहोस् (Validate & Preview)",
                              en: "Validate & Preview Data",
                              ko: "데이터 유효성 검사 및 미리보기",
                            ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],

                if (_validationError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_validationError!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],

                // -------------------------------------------------------------
                // PARSED RESULTS & PREVIEW SECTION
                // -------------------------------------------------------------
                if (_isParsed && _parsedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Summary Counters
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _buildStatBadge("कुल प्रश्न: ${_parsedQuestions.length}", Colors.blueGrey),
                      _buildStatBadge(
                          "Reading: ${_parsedQuestions.where((q) => q is UniversalQuestion ? !q.isListening : true).length}",
                          Colors.blue),
                      _buildStatBadge(
                          "Listening: ${_parsedQuestions.where((q) => q is UniversalQuestion ? q.isListening : false).length}",
                          Colors.orange),
                      _buildStatBadge("✓ सबै प्रश्नहरू मान्य छन्", Colors.green),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Destination Set Picker Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "आयात गर्ने लक्षित सेट छान्नुहोस् (Target Mock Set):",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _targetSetId,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: [
                              ...existingSets.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.title} (${s.sector})"))),
                              const DropdownMenuItem(
                                  value: 'new_set', child: Text("➕ नयाँ कस्टम सेट बनाउनुहोस् (Create New Custom Set)")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _targetSetId = val);
                            },
                          ),

                          if (_targetSetId == 'new_set') ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _customTitleController,
                              decoration:
                                  const InputDecoration(labelText: "नयाँ सेटको नाम (Title)", border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customSectorController,
                              decoration:
                                  const InputDecoration(labelText: "क्षेत्र (Sector)", border: OutlineInputBorder()),
                            ),
                          ],

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _importToQuestionBank,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text("प्रश्न बैंकमा सुरक्षित गर्नुहोस् (Import to Question Bank)",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Questions Preview Table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("आयात गरिने प्रश्नहरूको पूर्वावलोकन (Preview & Edit):",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("कुल ${_parsedQuestions.length} प्रश्नहरू",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _parsedQuestions.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final q = _parsedQuestions[index];
                      final isListening = (q is UniversalQuestion) ? q.isListening : index >= 20;
                      List<String> opts = [];
                      if (q is UniversalQuestion) {
                        opts = q.textOptions;
                      }
                      while (opts.length < 4) {
                        opts.add('');
                      }
                      final ansInfo = _parsedAnswerKeys[q.questionId];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("[문항 ${index + 1}] (${q.questionId})",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(!isListening ? "읽기 (Reading)" : "듣기 (Listening)",
                                          style: TextStyle(
                                              color: !isListening ? Colors.blue.shade900 : Colors.orange.shade900,
                                              fontSize: 11)),
                                      backgroundColor: !isListening ? Colors.blue.shade50 : Colors.orange.shade50,
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      tooltip: "मेटाउनुहोस्",
                                      onPressed: () => _deleteParsedQuestion(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: List.generate(opts.length, (optIdx) {
                                final isCorrect = ansInfo != null && optIdx == ansInfo.correctIndex;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isCorrect ? const Color(0xFFDCFCE7) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    "${optIdx + 1}. ${opts[optIdx]} ${isCorrect ? '✓ (정답)' : ''}",
                                    style: TextStyle(
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        color: isCorrect ? Colors.green.shade900 : Colors.black87),
                                  ),
                                );
                              }),
                            ),
                            if (ansInfo != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Text("💡 व्याख्या: ${ansInfo.explanation}",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.brown.shade800, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
