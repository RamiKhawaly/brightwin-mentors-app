import '../../../../core/utils/date_utils.dart';

class SuggestionAttachmentResponse {
  final int id;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String? downloadUrl;
  final DateTime createdAt;

  SuggestionAttachmentResponse({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    this.downloadUrl,
    required this.createdAt,
  });

  factory SuggestionAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionAttachmentResponse(
      id: json['id'] as int,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      fileSize: json['fileSize'] as int,
      downloadUrl: json['downloadUrl'] as String?,
      createdAt: parseServerDateTime(json['createdAt'] as String),
    );
  }
}
