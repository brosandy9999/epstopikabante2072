import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'exam_service.dart';
import 'auth_service.dart';

/// Cross-platform CSV / Excel Export Service
/// Generates CSV files from student exam records and triggers download safely.
class CsvExportService {
  static final CsvExportService instance = CsvExportService._internal();
  CsvExportService._internal();

  /// Generates clean CSV content for exam attempt records
  String generateExamResultsCsv(List<ExamAttemptRecord> records) {
    final buffer = StringBuffer();

    // UTF-8 BOM for proper Nepali / Korean rendering in Microsoft Excel
    buffer.write('\uFEFF');

    // Header Row
    buffer.writeln(
      'क्र.सं. (SN),'
      'विद्यार्थीको नाम (Candidate Name),'
      'दर्ता नम्बर (Registration No),'
      'ब्याच (Batch),'
      'औद्योगिक क्षेत्र (Sector),'
      'परीक्षा सेट (Exam Set),'
      'रिडिङ अङ्क (Reading Score / 100),'
      'लिसनिङ अङ्क (Listening Score / 100),'
      'कुल प्राप्ताङ्क (Total Score / 200),'
      'प्रतिशत (Percentage %),'
      'नतिजा (Result),'
      'समय (Minutes),'
      'परीक्षा मिति (Exam Date)',
    );

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final student = AuthService.instance.getStudentById(r.studentId);
      final batch = student?.batch ?? '2026 Batch A (बिहानी सत्र)';
      final sector = student?.sector ?? '제조업 (Manufacturing)';
      final percentage = (r.score / 100.0 * 100).toStringAsFixed(1);
      final minutes = (r.timeSpentSeconds / 60).toStringAsFixed(1);
      final dateStr = '${r.completedAt.year}-${r.completedAt.month.toString().padLeft(2, '0')}-${r.completedAt.day.toString().padLeft(2, '0')} ${r.completedAt.hour.toString().padLeft(2, '0')}:${r.completedAt.minute.toString().padLeft(2, '0')}';
      final status = r.isPassed ? '합격 (PASSED)' : '불합격 (FAILED)';

      buffer.writeln(
        '${i + 1},'
        '"${_clean(r.studentName)}",'
        '"${_clean(r.registrationNo)}",'
        '"${_clean(batch)}",'
        '"${_clean(sector)}",'
        '"${_clean(r.setTitle)}",'
        '${r.readingScore.toStringAsFixed(1)},'
        '${r.listeningScore.toStringAsFixed(1)},'
        '${r.score.toStringAsFixed(1)},'
        '$percentage%,'
        '"$status",'
        '$minutes 분,'
        '"$dateStr"',
      );
    }

    return buffer.toString();
  }

  String _clean(String val) {
    return val.replaceAll('"', '""');
  }

  /// Copies CSV data to clipboard for instant pasting into Excel or Google Sheets
  Future<void> copyToClipboard(String csvContent) async {
    await Clipboard.setData(ClipboardData(text: csvContent));
  }
}
