import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'file_upload_stub.dart';
import 'firebase_storage_service.dart';

export 'file_upload_stub.dart' show UploadedFilePayload;

class FileUploadService {
  FileUploadService._();
  static final FileUploadService instance = FileUploadService._();

  Future<UploadedFilePayload?> pickImageFile() async {
    return _pickAndUpload(
      accept: 'image/png,image/jpeg,image/jpg,image/webp,image/gif',
      uploadFn: (dataUrl, name) =>
          FirebaseStorageService.instance.uploadImage(dataUrl, name),
    );
  }

  Future<UploadedFilePayload?> pickAudioFile() async {
    return _pickAndUpload(
      accept: 'audio/mpeg,audio/mp3,audio/wav,audio/m4a,audio/ogg,audio/aac,.mp3,.wav,.m4a',
      uploadFn: (dataUrl, name) =>
          FirebaseStorageService.instance.uploadAudio(dataUrl, name),
    );
  }

  Future<UploadedFilePayload?> pickPdfFile() async {
    return _pickAndUpload(
      accept: 'application/pdf,.pdf',
      uploadFn: (dataUrl, name) =>
          FirebaseStorageService.instance.uploadPdf(dataUrl, name),
    );
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
              storageUrl = await FirebaseStorageService.instance.uploadImage(dataUrl, name);
            } catch (_) {}

            if (!completer.isCompleted) {
              completer.complete(UploadedFilePayload(
                name: name,
                sizeInBytes: size,
                dataUrl: dataUrl,
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

  /// File pick गर्छ → Base64 dataUrl बनाउँछ → Firebase Storage मा upload गर्छ
  /// storageUrl (Firebase URL) र dataUrl (Base64 fallback) दुवै return गर्छ
  Future<UploadedFilePayload?> _pickAndUpload({
    required String accept,
    required Future<String?> Function(String dataUrl, String name) uploadFn,
  }) async {
    final completer = Completer<UploadedFilePayload?>();
    try {
      final input = html.FileUploadInputElement()
        ..accept = accept
        ..multiple = false;
      input.click();

      input.onChange.listen((event) {
        final files = input.files;
        if (files == null || files.isEmpty) {
          completer.complete(null);
          return;
        }

        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);

        reader.onLoadEnd.listen((e) async {
          final dataUrl = reader.result as String?;
          if (dataUrl == null || dataUrl.isEmpty) {
            completer.complete(null);
            return;
          }

          final mimeType =
              file.type.isNotEmpty ? file.type : accept.split(',')[0];

          // Firebase Storage मा upload गर्ने (background)
          String? storageUrl;
          try {
            storageUrl = await uploadFn(dataUrl, file.name);
          } catch (_) {
            storageUrl = null; // upload fail भए dataUrl fallback प्रयोग गर्छ
          }

          completer.complete(UploadedFilePayload(
            name: file.name,
            sizeInBytes: file.size,
            dataUrl: dataUrl,
            mimeType: mimeType,
            storageUrl: storageUrl,
          ));
        });

        reader.onError.listen((e) {
          completer.complete(null);
        });
      });
    } catch (_) {
      completer.complete(null);
    }
    return completer.future;
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
