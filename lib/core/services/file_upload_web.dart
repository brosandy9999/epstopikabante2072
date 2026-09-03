import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'file_upload_stub.dart';

export 'file_upload_stub.dart' show UploadedFilePayload;

class FileUploadService {
  FileUploadService._();
  static final FileUploadService instance = FileUploadService._();

  Future<UploadedFilePayload?> pickImageFile() async {
    return _pickFile(accept: 'image/png,image/jpeg,image/jpg,image/webp,image/gif');
  }

  Future<UploadedFilePayload?> pickAudioFile() async {
    return _pickFile(accept: 'audio/mpeg,audio/mp3,audio/wav,audio/m4a,audio/ogg,audio/aac,.mp3,.wav,.m4a');
  }

  Future<UploadedFilePayload?> pickPdfFile() async {
    return _pickFile(accept: 'application/pdf,.pdf');
  }

  Future<UploadedFilePayload?> _pickFile({required String accept}) async {
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

        reader.onLoadEnd.listen((e) {
          final result = reader.result as String?;
          if (result != null && result.isNotEmpty) {
            completer.complete(UploadedFilePayload(
              name: file.name,
              sizeInBytes: file.size,
              dataUrl: result,
              mimeType: file.type.isNotEmpty ? file.type : accept.split(',')[0],
            ));
          } else {
            completer.complete(null);
          }
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
}
