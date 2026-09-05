import 'dart:async';

class UploadedFilePayload {
  final String name;
  final int sizeInBytes;
  final String dataUrl;   // Local Base64 — fallback
  final String mimeType;
  final String? storageUrl; // Firebase Storage public URL (null = upload failed)

  UploadedFilePayload({
    required this.name,
    required this.sizeInBytes,
    required this.dataUrl,
    required this.mimeType,
    this.storageUrl,
  });

  /// Best available URL: Firebase URL यदि upload सफल, नभए Base64 dataUrl
  String get bestUrl => storageUrl ?? dataUrl;

  String get formattedSize {
    if (sizeInBytes < 1024) return '${(sizeInBytes).toStringAsFixed(0)} B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileUploadService {
  FileUploadService._();
  static final FileUploadService instance = FileUploadService._();

  Future<UploadedFilePayload?> pickImageFile() async {
    return null;
  }

  Future<UploadedFilePayload?> pickAudioFile() async {
    return null;
  }

  Future<UploadedFilePayload?> pickPdfFile() async {
    return null;
  }
}
