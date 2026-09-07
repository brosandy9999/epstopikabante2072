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
    List<String> rawOptions = [];
    if (question is UniversalQuestion) {
      rawOptions = (question as UniversalQuestion).textOptions;
    } else if (question is ReadingTextQuestion) {
      rawOptions = (question as ReadingTextQuestion).textOptions;
    } else if (question is ReadingImageQuestion) {
      rawOptions = (question as ReadingImageQuestion).textOptions;
    } else if (question is ListeningAudioQuestion) {
      rawOptions = (question as ListeningAudioQuestion).textOptions;
    }

    final List<String> options = List.generate(4, (index) {
      if (index < rawOptions.length) {
        return rawOptions[index];
      }
      return '';
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==========================================
        // LEFT PANE: Question Prompt & Material Box
        // ==========================================
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Question Instruction Text
                    Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.35, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),

                    // Visual Illustration / Passage Box
                    _buildQuestionMaterial(question.questionId, question.questionText),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ==========================================
        // RIGHT PANE: 4 Multiple-Choice Options
        // ==========================================
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "[선택지] 맞는 것을 고르십시오",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                        if (selectedOptionIndex != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              "선택: ${selectedOptionIndex! + 1}번",
                              style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 4 Options Stacked Vertically
                    ...List.generate(4, (index) {
                      final isSelected = selectedOptionIndex == index;
                      const circledNumbers = ["①", "②", "③", "④"];
                      final numLabel = circledNumbers[index];
                      final optionText = options[index].trim();

                      String? imageOptionUrl;
                      if (question is UniversalQuestion) {
                        final uq = question as UniversalQuestion;
                        if (index < uq.imageOptions.length && uq.imageOptions[index] != null && uq.imageOptions[index]!.trim().isNotEmpty) {
                          imageOptionUrl = uq.imageOptions[index]!.trim();
                        }
                      }

                      String? audioOptionUrl;
                      if (question is UniversalQuestion) {
                        final uq = question as UniversalQuestion;
                        if (index < uq.audioOptions.length && uq.audioOptions[index] != null && uq.audioOptions[index]!.trim().isNotEmpty) {
                          audioOptionUrl = uq.audioOptions[index]!.trim();
                        }
                      }

                      final displayText = optionText.isNotEmpty 
                          ? optionText 
                          : (imageOptionUrl == null ? "${index + 1}번" : "");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () => onOptionSelected(index),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Circled Number
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Text(
                                      numLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Option Text & Media
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (displayText.isNotEmpty)
                                          Text(
                                            displayText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                            ),
                                          ),
                                        if (imageOptionUrl != null) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            constraints: const BoxConstraints(maxHeight: 90),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: SmartImageWidget(
                                              imageSource: imageOptionUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                        if (audioOptionUrl != null) ...[
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: () => AudioPlaybackService.instance.playAudioUrl(audioOptionUrl!),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.blue.shade200),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.play_circle_fill, size: 14, color: Color(0xFF1E3A8A)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    LanguageService.instance.trText(
                                                      ne: 'अडियो सुन्नुहोस्',
                                                      en: 'Play Audio',
                                                      ko: '오디오 듣기',
                                                    ),
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
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
