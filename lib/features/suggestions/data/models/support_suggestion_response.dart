import '../../../../core/utils/date_utils.dart';
import 'suggestion_attachment_response.dart';
import 'suggestion_status.dart';

class SupportSuggestionResponse {
  final int id;
  final int userId;
  final String userEmail;
  final String userFullName;
  final String title;
  final String description;
  final SuggestionStatus status;
  final String? adminNotes;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? message;
  final List<SuggestionAttachmentResponse> attachments;

  SupportSuggestionResponse({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.title,
    required this.description,
    required this.status,
    this.adminNotes,
    this.adminResponse,
    required this.createdAt,
    this.updatedAt,
    this.message,
    this.attachments = const [],
  });

  factory SupportSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SupportSuggestionResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      userFullName: json['userFullName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: SuggestionStatusExtension.fromString(
        json['status'] as String? ?? 'NEW',
      ),
      adminNotes: json['adminNotes'] as String?,
      adminResponse: json['adminResponse'] as String?,
      createdAt: parseServerDateTime(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? parseServerDateTime(json['updatedAt'] as String)
          : null,
      message: json['message'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => SuggestionAttachmentResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
      'title': title,
      'description': description,
      'status': status.apiValue,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (adminResponse != null) 'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (message != null) 'message': message,
      'attachments': attachments.map((a) => {
        'id': a.id,
        'fileName': a.fileName,
        'contentType': a.contentType,
        'fileSize': a.fileSize,
        if (a.downloadUrl != null) 'downloadUrl': a.downloadUrl,
        'createdAt': a.createdAt.toIso8601String(),
      }).toList(),
    };
  }
}
