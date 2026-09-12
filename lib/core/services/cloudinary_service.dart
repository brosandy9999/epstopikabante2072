import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary Upload & Media Streaming Service
/// Supports direct unsigned uploads for Audio, Images, and PDFs.
class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._internal();
  CloudinaryService._internal();

  static const String cloudName = 'ulatxq4n';
  static const String uploadPreset = 'ml_default';

  static const String _apiBase = 'https://api.cloudinary.com/v1_1/$cloudName';

  /// Uploads an Image to Cloudinary and returns the secure HTTPS URL
  Future<String?> uploadImage(dynamic data, String filename) async {
    return _upload(
      data: data,
      filename: filename,
      resourceType: 'image',
      folder: 'eps_topik/images',
    );
  }

  /// Uploads an Audio MP3 to Cloudinary (video/audio resource type) and returns the secure HTTPS streaming URL
  Future<String?> uploadAudio(dynamic data, String filename) async {
    return _upload(
      data: data,
      filename: filename,
      resourceType: 'video', // Cloudinary handles audio files under the 'video' resource type
      folder: 'eps_topik/audio',
    );
  }

  /// Uploads a PDF or Raw Document to Cloudinary and returns the secure HTTPS URL
  Future<String?> uploadPdf(dynamic data, String filename) async {
    return _upload(
      data: data,
      filename: filename,
      resourceType: 'raw', // PDFs & Docs are stored under 'raw' or 'image'
      folder: 'eps_topik/books',
    );
  }

  /// Generic upload method to Cloudinary REST API
  Future<String?> _upload({
    required dynamic data,
    required String filename,
    required String resourceType,
    required String folder,
  }) async {
    try {
      final uploadUrl = Uri.parse('$_apiBase/$resourceType/upload');

      Uint8List bytes;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else if (data is String) {
        if (data.startsWith('http://') || data.startsWith('https://')) {
          // If already a remote URL, return it directly
          return data;
        }
        final commaIdx = data.indexOf(',');
        final base64Part = commaIdx != -1 ? data.substring(commaIdx + 1) : data;
        bytes = base64Decode(base64Part.replaceAll(RegExp(r'\s+'), ''));
      } else {
        debugPrint('[CloudinaryService] Unsupported data type: ${data.runtimeType}');
        return null;
      }

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename.isNotEmpty ? filename : 'file_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final secureUrl = json['secure_url'] as String?;
        debugPrint('[CloudinaryService] Upload successful: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('[CloudinaryService] Upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[CloudinaryService] Upload exception: $e');
      return null;
    }
  }
}
