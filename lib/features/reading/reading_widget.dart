import 'package:flutter/material.dart';
import '../question_engine/question_template.dart';
import '../../core/widgets/smart_image_widget.dart';
import '../../core/widgets/sequence_option_widget.dart';

class ReadingQuestionWidget extends StatefulWidget {
  final dynamic question;
  final int? selectedOption;
  final int? selectedOptionIndex;
  final Function(int) onOptionSelected;

  const ReadingQuestionWidget({
    super.key,
    required this.question,
    this.selectedOption,
    this.selectedOptionIndex,
    required this.onOptionSelected,
  });

  @override
  State<ReadingQuestionWidget> createState() => _ReadingQuestionWidgetState();
}

class _ReadingQuestionWidgetState extends State<ReadingQuestionWidget> {
  int? get _currentSelected => widget.selectedOptionIndex ?? widget.selectedOption;

  @override
  Widget build(BuildContext context) {
    List<String> rawOptions = [];
    if (widget.question is UniversalQuestion) {
      rawOptions = (widget.question as UniversalQuestion).textOptions;
    } else if (widget.question is ReadingTextQuestion) {
      rawOptions = (widget.question as ReadingTextQuestion).textOptions;
    } else if (widget.question is ReadingImageQuestion) {
      rawOptions = (widget.question as ReadingImageQuestion).textOptions;
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Pane: Question Prompt & Visual Material (50% Split)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionTitle(isLandscape),
                        const SizedBox(height: 8),
                        _buildQuestionMaterial(widget.question.questionId, widget.question.questionText, isLandscape),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Right Pane: 4 Options (50% Split)
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: _buildOptions(rawOptions, isLandscape),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionTitle(isLandscape),
                const SizedBox(height: 10),
                _buildQuestionMaterial(widget.question.questionId, widget.question.questionText, isLandscape),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildOptions(rawOptions, isLandscape),
        ],
      ),
    );
  }

  Widget _buildQuestionTitle(bool isLandscape) {
    final cleanPrompt = widget.question.questionText.split('\n').first.trim();
    return Text(
      cleanPrompt,
      style: TextStyle(
        fontSize: isLandscape ? 15 : 17,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
        height: 1.35,
      ),
    );
  }

  Widget _buildOptions(List<String> rawOptions, bool isLandscape) {
    final circledNums = ['①', '②', '③', '④'];

    return Column(
      children: [
        ...List.generate(rawOptions.length, (index) {
          final isSelected = _currentSelected == index;
          final numLabel = index < circledNums.length ? circledNums[index] : '${index + 1}';
          final optionText = rawOptions[index].trim();

          String? imageOptionUrl;
          if (widget.question is UniversalQuestion) {
            final uq = widget.question as UniversalQuestion;
            if (index < uq.imageOptions.length &&
                uq.imageOptions[index] != null &&
                uq.imageOptions[index]!.trim().isNotEmpty) {
              imageOptionUrl = uq.imageOptions[index]!.trim();
            }
          }

          final displayText = optionText.isNotEmpty
              ? optionText
              : (imageOptionUrl == null ? '${index + 1}번' : '');

          return Container(
            margin: EdgeInsets.only(bottom: isLandscape ? 6 : 8),
            child: Material(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => widget.onOptionSelected(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 8 : 12,
                    vertical: isLandscape ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Circled Number
                      Container(
                        width: isLandscape ? 24 : 28,
                        height: isLandscape ? 24 : 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          numLabel,
                          style: TextStyle(
                            fontSize: isLandscape ? 13 : 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: isLandscape ? 8 : 12),

                      // Option Text & Media
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayText.isNotEmpty)
                              SequenceOptionWidget(
                                text: displayText,
                                isSelected: isSelected,
                                baseStyle: TextStyle(
                                  fontSize: isLandscape ? 13 : 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                                ),
                              ),
                            if (imageOptionUrl != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                constraints: BoxConstraints(maxHeight: isLandscape ? 75 : 100),
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
    );
  }

  Widget _buildQuestionMaterial(String qId, String text, [bool isLandscape = false]) {
    String? customImage;
    if (widget.question is UniversalQuestion) {
      customImage = (widget.question as UniversalQuestion).questionImageUrl;
    } else if (widget.question is ReadingImageQuestion) {
      customImage = (widget.question as ReadingImageQuestion).imageAssetPath;
    }

    final cleanImg = (customImage != null &&
            customImage.trim().isNotEmpty &&
            customImage.trim() != 'null' &&
            customImage.trim() != 'undefined' &&
            !customImage.trim().endsWith('/null') &&
            !customImage.trim().endsWith('/undefined'))
        ? customImage.trim()
        : null;

    final imgHeight = isLandscape ? 240.0 : 300.0;

    if (cleanImg != null) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: isLandscape ? 180.0 : 220.0,
          maxHeight: isLandscape ? 260.0 : 340.0,
        ),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SmartImageWidget(
          imageSource: cleanImg,
          fit: BoxFit.contain,
        ),
      );
    }

    if (text.contains('\n')) {
      final passageText = text.split('\n').skip(1).join('\n').trim();
      if (passageText.isNotEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            passageText,
            style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF334155)),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
