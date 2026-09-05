import 'dart:async';
import 'dart:html' as html;
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
}
