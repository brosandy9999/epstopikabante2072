import 'dart:convert';
import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/models/mock_test_model.dart';
import '../../core/services/question_bank_service.dart';
import '../../core/services/language_service.dart';

enum ImportFormat { csv, json }

/// Phase 14 & 15: CSV / JSON Bulk Question Ingestion Portal
class ImportWorkflowScreen extends StatefulWidget {
  const ImportWorkflowScreen({super.key});

  @override
  State<ImportWorkflowScreen> createState() => _ImportWorkflowScreenState();
}

class _ImportWorkflowScreenState extends State<ImportWorkflowScreen> {
  ImportFormat _selectedFormat = ImportFormat.csv;
  final TextEditingController _textController = TextEditingController();

  String _targetSetId = 'set_01';
  final TextEditingController _customTitleController =
      TextEditingController(text: '제6회 신규 추가 모의고사 (New Custom Set)');
  final TextEditingController _customSectorController =
      TextEditingController(text: '기타/서비스 (Service & General)');

  List<QuestionTemplate> _parsedQuestions = [];
  Map<String, QuestionAnswerInfo> _parsedAnswerKeys = {};
  String? _validationError;
  bool _isParsed = false;

  @override
  void dispose() {
    _textController.dispose();
    _customTitleController.dispose();
    _customSectorController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    if (_selectedFormat == ImportFormat.csv) {
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
  }

  void _parseAndValidate() {
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
          ListeningAudioQuestion(
            questionId: qId,
            questionText: qText,
            audioAssetPath: 'assets/audio/sample_listening.mp3',
            textOptions: options,
          ),
        );
      } else {
        _parsedQuestions.add(
          ReadingTextQuestion(
            questionId: qId,
            questionText: qText,
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
          ListeningAudioQuestion(
            questionId: qId,
            questionText: qText,
            audioAssetPath: 'assets/audio/sample_listening.mp3',
            textOptions: options.sublist(0, 4),
          ),
        );
      } else {
        _parsedQuestions.add(
          ReadingTextQuestion(
            questionId: qId,
            questionText: qText,
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

  void _importToQuestionBank() {
    if (_parsedQuestions.isEmpty) return;

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
        description: 'Admin द्वारा CSV/JSON मार्फत थपिएको ${_parsedQuestions.length} वटा नयाँ प्रश्नहरूको सेट।',
        questions: _parsedQuestions,
        answerKeys: _parsedAnswerKeys,
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
      );
    }

    QuestionBankService.instance.addOrUpdateMockSet(targetSet);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("थोक प्रश्न आयात सफल भयो!"),
          ],
        ),
        content: Text(
          "कुल ${_parsedQuestions.length} वटा प्रश्नहरू '${targetSet.title}' मा सफलतापूर्वक थपिएका छन्। विद्यार्थीहरूले अब परीक्षा हल र अभ्यास मोडमा यी प्रश्नहरू देख्नेछन्।",
        ),
        actions: [
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

        return SingleChildScrollView(
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
                      child: Icon(Icons.upload_file, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.trText(
                              ne: "CSV / JSON थोक प्रश्न आयात पोर्टल (Bulk Ingestion)",
                              en: "CSV / JSON Bulk Question Ingestion Portal",
                              ko: "CSV / JSON 대량 문항 가져오기 포털",
                            ),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang.trText(
                              ne: "Excel, CSV वा JSON बाट एकै पटक धेरै प्रश्नहरू (Reading र Listening) एपमा थप्नुहोस् वा अपडेट गर्नुहोस्।",
                              en: "Bulk import or update Reading & Listening questions seamlessly via Excel, CSV, or JSON.",
                              ko: "Excel, CSV 또는 JSON 파일을 통해 읽기 및 듣기 문항을 일괄 등록하고 업데이트하세요.",
                            ),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Format Selection and Sample Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Segmented Format Toggle
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("📄 CSV Format (Excel)"),
                        selected: _selectedFormat == ImportFormat.csv,
                        selectedColor: const Color(0xFF0F766E),
                        labelStyle: TextStyle(
                          color: _selectedFormat == ImportFormat.csv ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _selectedFormat = ImportFormat.csv),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("🧩 JSON Format"),
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
                      ne: "📋 नमुना (${_selectedFormat == ImportFormat.csv ? 'CSV' : 'JSON'}) डाटा लोड गर्नुहोस्",
                      en: "📋 Load Sample (${_selectedFormat == ImportFormat.csv ? 'CSV' : 'JSON'}) Data",
                      ko: "📋 샘플 (${_selectedFormat == ImportFormat.csv ? 'CSV' : 'JSON'}) 데이터 불러오기",
                    )),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Raw Text Area
              TextField(
                controller: _textController,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: _selectedFormat == ImportFormat.csv
                      ? 'type,questionText,option1,option2,option3,option4,correctIndex,explanation\\nreading,"[1] 다음 그림을...",가방,공책,수첩,안경,1,"व्याख्या..."'
                      : '[\\n  {\\n    "type": "reading",\\n    "questionText": "...",\\n    "options": ["A", "B", "C", "D"],\\n    "correctIndex": 0,\\n    "explanation": "..."\\n  }\\n]',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),

              const SizedBox(height: 16),

              // Parse and Validate Button
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _parseAndValidate,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(
                      lang.trText(
                        ne: "डाटा जाँच र प्रमाणीकरण गर्नुहोस् (Validate & Preview)",
                        en: "Validate & Preview Data",
                        ko: "데이터 유효성 검사 및 미리보기",
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),

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
            Row(
              children: [
                _buildStatBadge("कुल प्रश्न: ${_parsedQuestions.length}", Colors.blueGrey),
                const SizedBox(width: 10),
                _buildStatBadge(
                    "Reading: ${_parsedQuestions.whereType<ReadingTextQuestion>().length}", Colors.blue),
                const SizedBox(width: 10),
                _buildStatBadge(
                    "Listening: ${_parsedQuestions.whereType<ListeningAudioQuestion>().length}", Colors.orange),
                const SizedBox(width: 10),
                _buildStatBadge("✓ सबै मान्य (Valid)", Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            // Destination Set Picker
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

            const SizedBox(height: 20),

            // Questions Preview Table
            const Text("आयात गरिने प्रश्नहरूको पूर्वावलोकन (Preview):",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedQuestions.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final q = _parsedQuestions[index];
                final isReading = q is ReadingTextQuestion;
                final opts = isReading ? q.textOptions : (q as ListeningAudioQuestion).textOptions;
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
                          Text("문항 ${index + 1} (${q.questionId})",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          Chip(
                            label: Text(isReading ? "읽기 (Reading)" : "듣기 (Listening)",
                                style: TextStyle(
                                    color: isReading ? Colors.blue.shade900 : Colors.orange.shade900,
                                    fontSize: 11)),
                            backgroundColor: isReading ? Colors.blue.shade50 : Colors.orange.shade50,
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        const SizedBox(height: 8),
                        Text("💡 ${ansInfo.explanation}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
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
