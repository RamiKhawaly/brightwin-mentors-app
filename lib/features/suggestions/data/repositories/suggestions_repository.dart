import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/dio_client.dart';
import '../models/support_suggestion_request.dart';
import '../models/support_suggestion_response.dart';

class SuggestionsRepository {
  final DioClient _dioClient;

  SuggestionsRepository(this._dioClient);

  /// Get all suggestions for the current user
  Future<List<SupportSuggestionResponse>> getAllSuggestions() async {
    try {
      final response = await _dioClient.dio.get('/api/support/suggestions');
      final List<dynamic> data = response.data as List;
      return data.map((json) => SupportSuggestionResponse.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch suggestions: $e');
    }
  }

  /// Create a new suggestion with optional attachments (multipart/form-data)
  Future<SupportSuggestionResponse> createSuggestion(
    SupportSuggestionRequest request, {
    List<PlatformFile>? attachments,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'title': request.title,
        'description': request.description,
      };

      if (attachments != null && attachments.isNotEmpty) {
        final files = await Future.wait(attachments.map((f) async {
          if (f.bytes != null) {
            return MultipartFile.fromBytes(f.bytes!, filename: f.name);
          } else if (f.path != null) {
            return await MultipartFile.fromFile(f.path!, filename: f.name);
          }
          throw Exception('Cannot read file: ${f.name}');
        }));
        formMap['attachments'] = files;
      }

      final response = await _dioClient.dio.post(
        '/api/support/suggestions',
        data: FormData.fromMap(formMap),
      );
      return SupportSuggestionResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create suggestion: $e');
    }
  }

  /// Update an existing suggestion (only allowed when status is NEW)
  Future<SupportSuggestionResponse> updateSuggestion(int id, SupportSuggestionRequest request) async {
    try {
      final response = await _dioClient.dio.put(
        '/api/support/suggestions/$id',
        data: request.toJson(),
      );
      return SupportSuggestionResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update suggestion: $e');
    }
  }

  /// Delete a suggestion (only allowed when status is NEW)
  Future<void> deleteSuggestion(int id) async {
    try {
      await _dioClient.dio.delete('/api/support/suggestions/$id');
    } catch (e) {
      throw Exception('Failed to delete suggestion: $e');
    }
  }

  /// Add file attachments to an existing suggestion (only allowed when status is NEW)
  /// Max 5 total attachments, 10MB each
  Future<SupportSuggestionResponse> addAttachments(
    int suggestionId,
    List<PlatformFile> files,
  ) async {
    try {
      final multipartFiles = await Future.wait(files.map((f) async {
        if (f.bytes != null) {
          return MultipartFile.fromBytes(f.bytes!, filename: f.name);
        } else if (f.path != null) {
          return await MultipartFile.fromFile(f.path!, filename: f.name);
        }
        throw Exception('Cannot read file: ${f.name}');
      }));

      final response = await _dioClient.dio.post(
        '/api/support/suggestions/$suggestionId/attachments',
        data: FormData.fromMap({'attachments': multipartFiles}),
      );
      return SupportSuggestionResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add attachments: $e');
    }
  }

  /// Delete an attachment (only allowed when status is NEW)
  Future<void> deleteAttachment(int attachmentId) async {
    try {
      await _dioClient.dio.delete('/api/support/suggestions/attachments/$attachmentId');
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  /// Download attachment binary data
  Future<Uint8List> downloadAttachment(int attachmentId) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/support/suggestions/attachments/$attachmentId',
        options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(minutes: 2)),
      );
      return Uint8List.fromList(response.data as List<int>);
    } catch (e) {
      throw Exception('Failed to download attachment: $e');
    }
  }
}
