import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'file_upload_stub.dart';

export 'file_upload_stub.dart' show UploadedFilePayload;

class FileUploadService {
  FileUploadService._();
  static final FileUploadService instance = FileUploadService._();

  Future<UploadedFilePayload?> pickImageFile() async {
    return _pickAndUpload(
      accept: 'image/png,image/jpeg,image/jpg,image/webp,image/gif',
      folder: 'images',
    );
  }

  Future<UploadedFilePayload?> pickAudioFile() async {
    return _pickAndUpload(
      accept: 'audio/mpeg,audio/mp3,audio/wav,audio/m4a,audio/ogg,audio/aac,.mp3,.wav,.m4a',
      folder: 'audio',
    );
  }

  Future<UploadedFilePayload?> pickPdfFile() async {
    return _pickAndUpload(
      accept: 'application/pdf,.pdf',
      folder: 'books',
    );
  }

  /// Direct non-blocking streaming upload from browser file directly to Supabase Storage
  Future<String?> _uploadBrowserFileToFirebase(html.File file, String folder) async {
    final completer = Completer<String?>();
    try {
      const projectRef = 'ysrxjsmqipzudwwnqorb';
      const baseUrl = 'https://$projectRef.supabase.co';
      const apiKey = 'sb_secret_2EmpXQ4nPKPiw0pUMQiqWA_I1OPgOKY';

      final bucket = folder == 'books' ? 'books' : 'media';
      final subpath = folder == 'books' ? 'chapters' : folder;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final destinationPath = '$subpath/${timestamp}_$cleanName';

      final uploadUrl = '$baseUrl/storage/v1/object/$bucket/$destinationPath';
      final request = html.HttpRequest();
      request.open('POST', uploadUrl);
      final mime = file.type.isNotEmpty ? file.type : (folder == 'books' ? 'application/pdf' : 'application/octet-stream');
      request.setRequestHeader('apikey', apiKey);
      request.setRequestHeader('Authorization', 'Bearer $apiKey');
      request.setRequestHeader('Content-Type', mime);
      request.setRequestHeader('x-upsert', 'true');

      request.onLoad.listen((_) {
        if (request.status == 200 || request.status == 201) {
          final downloadUrl = '$baseUrl/storage/v1/object/public/$bucket/$destinationPath';
          debugPrint('[SupabaseStorage] Web stream upload success: $downloadUrl');
          completer.complete(downloadUrl);
        } else {
          debugPrint('[SupabaseStorage] Web upload failed: ${request.status} ${request.responseText}');
          completer.complete(null);
        }
      });

      request.onError.listen((e) {
        debugPrint('[SupabaseStorage] Web upload error: $e');
        completer.complete(null);
      });

      request.send(file);
    } catch (e) {
      debugPrint('[SupabaseStorage] Web upload exception: $e');
      completer.complete(null);
    }
    return completer.future;
  }

  /// File pick गर्छ → Browser File Direct Stream Upload गर्छ
  /// Zero-Memory Bloat: 50MB+ PDF/Audio लाई Base64 मा कन्भर्ट नगरी सिधै C++ Native Network बाट Upload गर्छ
  Future<UploadedFilePayload?> _pickAndUpload({
    required String accept,
    required String folder,
  }) async {
    final completer = Completer<UploadedFilePayload?>();
    try {
      final input = html.FileUploadInputElement()
        ..accept = accept
        ..multiple = false;
      input.click();

      input.onChange.listen((event) async {
        final files = input.files;
        if (files == null || files.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }

        final file = files[0];
        final mimeType = file.type.isNotEmpty ? file.type : accept.split(',')[0];
        final isLargeFile = file.size > 2 * 1024 * 1024; // > 2MB

        // 1. Direct Background Streaming Upload to Firebase Storage
        final storageUrl = await _uploadBrowserFileToFirebase(file, folder);

        // 2. Generate Safe Preview / Fallback URL
        String previewDataUrl = '';
        if (storageUrl != null && storageUrl.isNotEmpty) {
          previewDataUrl = storageUrl;
        } else if (isLargeFile) {
          // For large files, Blob URL is instantaneous (0 memory overhead, 0 CPU delay)
          previewDataUrl = html.Url.createObjectUrlFromBlob(file);
        } else {
          // For small files (< 2MB), small Base64 is safe
          try {
            final reader = html.FileReader();
            reader.readAsDataUrl(file);
            await reader.onLoadEnd.first;
            previewDataUrl = (reader.result as String?) ?? '';
          } catch (_) {
            previewDataUrl = html.Url.createObjectUrlFromBlob(file);
          }
        }

        if (!completer.isCompleted) {
          completer.complete(UploadedFilePayload(
            name: file.name,
            sizeInBytes: file.size,
            dataUrl: previewDataUrl,
            mimeType: mimeType,
            storageUrl: storageUrl,
          ));
        }
      });
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  /// क्लिपबोर्डबाट सिधै फोटो (Screenshot / Copy-Pasted Image / Image URL) पढ्ने
  Future<UploadedFilePayload?> pasteImageFromClipboard() async {
    final completer = Completer<UploadedFilePayload?>();
    try {
      _ensureClipboardJsHelper();

      StreamSubscription? sub;
      Timer? timeoutTimer;

      timeoutTimer = Timer(const Duration(seconds: 8), () {
        sub?.cancel();
        if (!completer.isCompleted) completer.complete(null);
      });

      sub = html.window.on['__eps_clipboard_response'].listen((html.Event event) async {
        timeoutTimer?.cancel();
        sub?.cancel();

        if (event is html.CustomEvent) {
          final detail = event.detail?.toString();
          if (detail == null || detail.isEmpty || detail == 'null') {
            if (!completer.isCompleted) completer.complete(null);
            return;
          }

          try {
            final data = jsonDecode(detail) as Map<String, dynamic>;
            final dataUrl = data['dataUrl'] as String?;
            if (dataUrl == null || dataUrl.isEmpty) {
              if (!completer.isCompleted) completer.complete(null);
              return;
            }
            final size = (data['size'] as num?)?.toInt() ?? 0;
            final type = data['type']?.toString() ?? 'image/png';
            final name = data['name']?.toString() ??
                'clipboard_${DateTime.now().millisecondsSinceEpoch}.png';

            String? storageUrl;
            try {
              final commaIdx = dataUrl.indexOf(',');
              if (commaIdx != -1) {
                final base64Part = dataUrl.substring(commaIdx + 1);
                final bytes = base64Decode(base64Part);
                final blob = html.Blob([bytes], type);
                final file = html.File([blob], name, {'type': type});
                storageUrl = await _uploadBrowserFileToFirebase(file, 'images');
              }
            } catch (_) {}

            if (!completer.isCompleted) {
              completer.complete(UploadedFilePayload(
                name: name,
                sizeInBytes: size,
                dataUrl: storageUrl ?? dataUrl,
                mimeType: type,
                storageUrl: storageUrl,
              ));
            }
          } catch (e) {
            debugPrint('[Clipboard] JSON parse error: $e');
            if (!completer.isCompleted) completer.complete(null);
          }
        }
      });

      // Dispatch request event
      html.window.dispatchEvent(html.CustomEvent('__eps_request_clipboard'));
    } catch (e) {
      debugPrint('[Clipboard] Exception: $e');
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  void _ensureClipboardJsHelper() {
    final scriptId = '__eps_clipboard_helper_script';
    if (html.document.getElementById(scriptId) != null) return;

    final script = html.ScriptElement()
      ..id = scriptId
      ..text = '''
(function() {
  if (window.__epsClipboardInited) return;
  window.__epsClipboardInited = true;

  window.addEventListener('__eps_request_clipboard', function() {
    function reply(data) {
      window.dispatchEvent(new CustomEvent('__eps_clipboard_response', {
        detail: data ? JSON.stringify(data) : null
      }));
    }

    if (!navigator.clipboard) {
      reply(null);
      return;
    }

    if (navigator.clipboard.read) {
      navigator.clipboard.read().then(function(items) {
        if (!items || items.length === 0) {
          fallbackText();
          return;
        }
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          for (var t = 0; t < item.types.length; t++) {
            var type = item.types[t];
            if (type.indexOf('image/') === 0) {
              item.getType(type).then(function(blob) {
                var reader = new FileReader();
                reader.onloadend = function() {
                  reply({
                    dataUrl: reader.result,
                    size: blob.size,
                    type: type,
                    name: 'clipboard_' + Date.now() + '.' + (type.split('/')[1] || 'png')
                  });
                };
                reader.readAsDataURL(blob);
              }).catch(function() {
                fallbackText();
              });
              return;
            }
          }
        }
        fallbackText();
      }).catch(function() {
        fallbackText();
      });
    } else {
      fallbackText();
    }

    function fallbackText() {
      if (navigator.clipboard.readText) {
        navigator.clipboard.readText().then(function(text) {
          text = (text || '').trim();
          if (text.indexOf('data:image/') === 0 || 
             (text.indexOf('http') === 0 && /\\.(png|jpe?g|webp|gif|svg)(\\?.*)?\$/i.test(text))) {
            reply({
              dataUrl: text,
              size: text.length,
              type: 'image/png',
              name: 'clipboard_link_' + Date.now() + '.png'
            });
          } else {
            reply(null);
          }
        }).catch(function() { reply(null); });
      } else {
        reply(null);
      }
    }
  });
})();
''';
    html.document.head?.append(script);
  }

  /// JSON ब्याकअप फाइल डिभाइसबाट छानेर सिधै String को रूपमा पढ्ने
  Future<String?> pickJsonFileContent() async {
    final completer = Completer<String?>();
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.json,application/json';
      input.click();
      input.onChange.listen((e) {
        final files = input.files;
        if (files == null || files.isEmpty) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsText(file);
        reader.onLoadEnd.listen((_) {
          final text = reader.result as String?;
          if (!completer.isCompleted) completer.complete(text);
        });
        reader.onError.listen((_) {
          if (!completer.isCompleted) completer.complete(null);
        });
      });
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }
}
