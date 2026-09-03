import 'dart:async';

class UploadedFilePayload {
  final String name;
  final int sizeInBytes;
  final String dataUrl;
  final String mimeType;

  UploadedFilePayload({
    required this.name,
    required this.sizeInBytes,
    required this.dataUrl,
    required this.mimeType,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '\ B';
    if (sizeInBytes < 1024 * 1024) return '\ KB';
    return '\ MB';
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
