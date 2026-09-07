import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';

/// Universal Confirmation Dialog before exiting the App
Future<bool> showAppExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LanguageService.instance.trText(
                ne: 'एपबाट बाहिरिन चाहनुहुन्छ?',
                en: 'Exit Application?',
                ko: '앱을 종료하시겠습니까?',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Text(
        LanguageService.instance.trText(
          ne: 'के तपाईं EPS-TOPIK UBT एप बन्द गरी बाहिरिन निश्चित हुनुहुन्छ?',
          en: 'Are you sure you want to close and exit the EPS-TOPIK application?',
          ko: 'EPS-TOPIK UBT 앱을 완전히 종료하시겠습니까?',
        ),
        style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            LanguageService.instance.trText(
              ne: 'रद्द गर्नुहोस् (Cancel)',
              en: 'Cancel',
              ko: '취소',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            LanguageService.instance.trText(
              ne: 'बाहिरिनुहोस् (Exit)',
              en: 'Exit App',
              ko: '종료',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  if (result == true) {
    SystemNavigator.pop();
    return true;
  }
  return false;
}

/// Confirmation Dialog before exiting an active Exam or Editor
Future<bool> showActionExitConfirmationDialog(
  BuildContext context, {
  required String titleNe,
  required String titleEn,
  required String titleKo,
  required String messageNe,
  required String messageEn,
  required String messageKo,
  String? confirmBtnNe,
  String? confirmBtnEn,
  String? confirmBtnKo,
  String? cancelBtnNe,
  String? cancelBtnEn,
  String? cancelBtnKo,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.shade50 : Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDestructive ? Icons.warning_rounded : Icons.info_outline,
              color: isDestructive ? Colors.red.shade700 : Colors.amber.shade800,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LanguageService.instance.trText(
                ne: titleNe,
                en: titleEn,
                ko: titleKo,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Text(
        LanguageService.instance.trText(
          ne: messageNe,
          en: messageEn,
          ko: messageKo,
        ),
        style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF334155)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            LanguageService.instance.trText(
              ne: cancelBtnNe ?? 'जारी राख्नुहोस् (Stay)',
              en: cancelBtnEn ?? 'Stay',
              ko: cancelBtnKo ?? '계속하기',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red.shade700 : const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            LanguageService.instance.trText(
              ne: confirmBtnNe ?? 'छोड्नुहोस् (Leave)',
              en: confirmBtnEn ?? 'Leave',
              ko: confirmBtnKo ?? '나가기',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
