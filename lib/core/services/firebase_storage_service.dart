import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Firebase Storage REST API Service
/// Base64 dataUrl lai Firebase Storage ma upload gareko
/// public download URL return garcha.
/// Project: topik-abante
class FirebaseStorageService {
  static final FirebaseStorageService instance =
      FirebaseStorageService._internal();
  FirebaseStorageService._internal();

  static const String _bucket = 'topik-abante.appspot.com';
  static const String _baseUrl =
      'https://firebasestorage.googleapis.com/v0/b/$_bucket/o';

  /// Image upload - Firebase Storage URL return
  Future<String?> uploadImage(String dataUrl, String filename) async {
    return _uploadDataUrl(
      dataUrl: dataUrl,
      storagePath: 'eps_topik/images/${_timestamp()}_$filename',
    );
  }

  /// Audio upload - Firebase Storage URL return
  Future<String?> uploadAudio(String dataUrl, String filename) async {
    return _uploadDataUrl(
      dataUrl: dataUrl,
      storagePath: 'eps_topik/audio/${_timestamp()}_$filename',
    );
  }

  /// PDF upload - Firebase Storage URL return
  Future<String?> uploadPdf(String dataUrl, String filename) async {
    return _uploadDataUrl(
      dataUrl: dataUrl,
      storagePath: 'eps_topik/books/${_timestamp()}_$filename',
    );
  }

  /// Core upload method
  Future<String?> _uploadDataUrl({
    required String dataUrl,
    required String storagePath,
  }) async {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) {
        debugPrint('[FirebaseStorage] Invalid dataUrl format.');
        return null;
      }
      final meta = dataUrl.substring(0, commaIndex);
      final base64Data = dataUrl.substring(commaIndex + 1);
      final mimeType = _parseMimeType(meta);
      final bytes = base64Decode(base64Data);

      final encodedPath = Uri.encodeComponent(storagePath);
      final uploadUrl =
          Uri.parse('$_baseUrl/$encodedPath?uploadType=media');

      final response = await http
          .post(
            uploadUrl,
            headers: {
              'Content-Type': mimeType,
              'Content-Length': bytes.length.toString(),
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final downloadUrl = _buildDownloadUrl(storagePath);
        debugPrint('[FirebaseStorage] Upload successful: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint(
            '[FirebaseStorage] Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[FirebaseStorage] Error: $e');
      return null;
    }
  }

  String _buildDownloadUrl(String storagePath) {
    final encodedPath = Uri.encodeComponent(storagePath);
    return '$_baseUrl/$encodedPath?alt=media';
  }

  String _parseMimeType(String meta) {
    try {
      final withoutData = meta.replaceFirst('data:', '');
      final semicolonIdx = withoutData.indexOf(';');
      if (semicolonIdx == -1) return 'application/octet-stream';
      return withoutData.substring(0, semicolonIdx);
    } catch (_) {
      return 'application/octet-stream';
    }
  }

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
}