import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Supabase Cloud Storage & Realtime Sync Service
/// Project: ysrxjsmqipzudwwnqorb (topik-abante)
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  static const String projectRef = 'ysrxjsmqipzudwwnqorb';
  static const String baseUrl = 'https://$projectRef.supabase.co';
  static const String apiKey = 'sb_secret_2EmpXQ4nPKPiw0pUMQiqWA_I1OPgOKY';

  Map<String, String> get _headers => {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
      };

  /// Uploads an Image file / dataUrl to Supabase Storage 'media' bucket
  Future<String?> uploadImage(dynamic data, String filename) async {
    return _uploadData(
      bucket: 'media',
      path: 'images/${_timestamp()}_$filename',
      data: data,
      contentType: 'image/png',
    );
  }

  /// Uploads an Audio MP3 file / dataUrl to Supabase Storage 'media' bucket
  Future<String?> uploadAudio(dynamic data, String filename) async {
    return _uploadData(
      bucket: 'media',
      path: 'audio/${_timestamp()}_$filename',
      data: data,
      contentType: 'audio/mpeg',
    );
  }

  /// Uploads a Book PDF file / dataUrl to Supabase Storage 'books' bucket
  Future<String?> uploadPdf(dynamic data, String filename) async {
    return _uploadData(
      bucket: 'books',
      path: 'chapters/${_timestamp()}_$filename',
      data: data,
      contentType: 'application/pdf',
    );
  }

  /// Pushes the entire App/Project Sync Payload directly to Supabase Storage
  Future<bool> pushSyncPayload(Map<String, dynamic> payload) async {
    try {
      final jsonBytes = utf8.encode(jsonEncode(payload));
      final url = Uri.parse('$baseUrl/storage/v1/object/media/sync/eps_sync_data.json');
      final resp = await http
          .post(
            url,
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
              'x-upsert': 'true',
            },
            body: jsonBytes,
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        debugPrint('[SupabaseService] Sync payload uploaded successfully to Supabase!');
        return true;
      } else {
        debugPrint('[SupabaseService] Sync push error: ${resp.statusCode} ${resp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Sync push exception: $e');
      return false;
    }
  }

  /// Pulls the latest Sync Payload from Supabase Storage
  Future<Map<String, dynamic>?> pullSyncPayload() async {
    try {
      final url = Uri.parse(
          '$baseUrl/storage/v1/object/public/media/sync/eps_sync_data.json?_t=${DateTime.now().millisecondsSinceEpoch}');
      final resp = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          debugPrint('[SupabaseService] Pull sync payload successful from Supabase!');
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] Pull sync error: $e');
    }
    return null;
  }

  Future<String?> _uploadData({
    required String bucket,
    required String path,
    required dynamic data,
    required String contentType,
  }) async {
    try {
      Uint8List bytes;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else if (data is String) {
        final commaIdx = data.indexOf(',');
        final base64Part = commaIdx != -1 ? data.substring(commaIdx + 1) : data;
        bytes = base64Decode(base64Part.replaceAll(RegExp(r'\s+'), ''));
      } else {
        return null;
      }

      final url = Uri.parse('$baseUrl/storage/v1/object/$bucket/$path');
      final resp = await http
          .post(
            url,
            headers: {
              ..._headers,
              'Content-Type': contentType,
              'x-upsert': 'true',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final publicUrl = '$baseUrl/storage/v1/object/public/$bucket/$path';
        debugPrint('[SupabaseService] Uploaded to $publicUrl');
        return publicUrl;
      } else {
        debugPrint('[SupabaseService] Upload failed: ${resp.statusCode} ${resp.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Upload exception: $e');
      return null;
    }
  }

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
}
