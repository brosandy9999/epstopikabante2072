import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/services/audio_playback_service.dart';
import '../../core/services/language_service.dart';

/// Authentic HRDK EPS-TOPIK UBT Reading Question Widget
/// Split Layout: Question & Passage / Graphic on LEFT, Options 1-4 on RIGHT
class ReadingQuestionWidget extends StatelessWidget {
  final QuestionTemplate question;
  final int? selectedOptionIndex;
  final Function(int) onOptionSelected;

  const ReadingQuestionWidget({
    super.key,
    required this.question,
    this.selectedOptionIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = (question is UniversalQuestion)
        ? (question as UniversalQuestion).textOptions
        : ((question is ReadingTextQuestion)
            ? (question as ReadingTextQuestion).textOptions
            : ((question is ReadingImageQuestion)
                ? (question as ReadingImageQuestion).textOptions
                : <String>[]));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // LEFT PANE: Question Prompt & Material Box
        // ==========================================
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          LanguageService.instance.readingSectionText(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.instance.trText(ne: "प्रश्न प्रकार: ", en: "Question Type: ", ko: "문제 유형: "),
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main Question Instruction Text
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Visual Illustration / Passage Box (Pinch-to-Zoom Enabled)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LanguageService.instance.trText(
                          ne: "📌 प्रश्न विवरण तथा सामग्री:",
                          en: "📌 Question Material & Passage:",
                          ko: "📌 지문 및 문제 자료:",
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pinch, size: 12, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 4),
                            Text(
                              LanguageService.instance.trText(
                                ne: 'पिन्च गरी जुम गर्नुहोस्',
                                en: 'Pinch / Scroll to zoom',
                                ko: '확대/축소 가능',
                              ),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InteractiveViewer(
                    minScale: 0.85,
                    maxScale: 3.5,
                    clipBehavior: Clip.none,
                    child: _buildQuestionMaterial(question.questionId, question.questionText),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 25),

        // ==========================================
        // RIGHT PANE: 4 Multiple-Choice Options
        // ==========================================
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "[선택지] 맞는 것을 고르십시오",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    if (selectedOptionIndex != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          "선택: ${selectedOptionIndex! + 1}번",
                          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                  ],
                ),
                const Divider(height: 24),

                // 4 Options Stacked Vertically
                ...List.generate(options.length, (index) {
                  final isSelected = selectedOptionIndex == index;
                  const circledNumbers = ["\u2460", "\u2461", "\u2462", "\u2463"];
                  final numLabel = index < circledNumbers.length ? circledNumbers[index] : "${index + 1}";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => onOptionSelected(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Circled Number or Radio
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  numLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Option Text & Media
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (options[index].isNotEmpty)
                                      Text(
                                        options[index],
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                        ),
                                      ),
                                    if (question is UniversalQuestion) ...[
                                      if (index < (question as UniversalQuestion).imageOptions.length &&
                                          (question as UniversalQuestion).imageOptions[index] != null &&
                                          (question as UniversalQuestion).imageOptions[index]!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          constraints: const BoxConstraints(maxHeight: 120),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: SmartImageWidget(
                                            imageSource: (question as UniversalQuestion).imageOptions[index]!.trim(),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                      if (index < (question as UniversalQuestion).audioOptions.length &&
                                          (question as UniversalQuestion).audioOptions[index] != null &&
                                          (question as UniversalQuestion).audioOptions[index]!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => AudioPlaybackService.instance.playAudioUrl(
                                              (question as UniversalQuestion).audioOptions[index]!.trim()),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.blue.shade200),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.play_circle_fill, size: 16, color: Color(0xFF1E3A8A)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  LanguageService.instance.trText(
                                                    ne: 'अडियो सुन्नुहोस्',
                                                    en: 'Play Audio',
                                                    ko: '오디오 듣기',
                                                  ),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),

                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds authentic illustrations, signage, receipts, or dialog boxes for Korean test items
  Widget _buildQuestionMaterial(String qId, String text) {
    String? customImage;
    if (question is UniversalQuestion) {
      customImage = (question as UniversalQuestion).questionImageUrl;
    } else if (question is ReadingImageQuestion) {
      customImage = (question as ReadingImageQuestion).imageAssetPath;
    }

    if (customImage != null && customImage.trim().isNotEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SmartImageWidget(imageSource: customImage.trim(), height: 190, fit: BoxFit.contain),
      );
    }

    if (qId == 'Q01') {
      // Notebook / Book picture prompt
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 70, color: Colors.blueGrey.shade700),
            const SizedBox(height: 10),
            const Text("[ 공 책 (Notebook) ]", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    } else if (qId == 'Q02') {
      // Firefighter / Police / Doctor picture prompt
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 70, color: Colors.deepOrange.shade600),
            const SizedBox(height: 10),
            const Text("[ 소방관 (Firefighter) ]", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    } else if (qId == 'Q03') {
      // No Parking Signboard
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.directions_car, size: 60, color: Colors.grey.shade800),
                Icon(Icons.block, size: 85, color: Colors.red.shade700),
              ],
            ),
            const SizedBox(height: 8),
            const Text("주 차 금 지 (No Parking)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          ],
        ),
      );
    } else if (qId == 'Q09') {
      // Mart Receipt Box
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text("=== [영수증 영수증] ===", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Divider(color: Colors.black45),
            Text("• 품목: 사과, 우유, 빵"),
            Text("• 결제 금액: 15,000원"),
            Text("• 결제 수단: 신용카드 (KB국민)"),
            Text("• 일시: 2026. 09. 03  14:20"),
          ],
        ),
      );
    } else {
      // Clean Korean Passage Box
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text.contains('\n') ? text.split('\n').skip(1).join('\n') : text,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      );
    }
  }
}
