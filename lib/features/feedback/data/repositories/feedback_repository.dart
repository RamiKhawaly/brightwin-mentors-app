import '../../../../core/network/dio_client.dart';
import '../models/feedback_model.dart';
import '../models/submit_feedback_request.dart';
import '../models/submit_mentor_rating_request.dart';
import '../models/submit_candidate_rating_request.dart';
import '../../domain/entities/feedback_entity.dart';

class FeedbackRepository {
  final DioClient _dioClient;

  FeedbackRepository(this._dioClient);

  /// POST /api/ratings/candidate - Submit candidate rating after session (Mentor to Job Seeker)
  Future<Map<String, dynamic>> submitCandidateRating(SubmitCandidateRatingRequest request) async {
    try {
      print('📤 Submitting candidate rating for session: ${request.mentorshipSessionId}');
      final response = await _dioClient.dio.post(
        '/api/ratings/candidate',
        data: request.toJson(),
      );

      print('✅ Candidate rating submitted successfully');
      return response.data;
    } catch (e) {
      print('❌ Error submitting candidate rating: $e');
      rethrow;
    }
  }

  /// POST /api/ratings/mentor - Submit mentor rating after session (Job Seeker to Mentor)
  Future<Map<String, dynamic>> submitMentorRating(SubmitMentorRatingRequest request) async {
    try {
      print('📤 Submitting mentor rating for session: ${request.mentorshipSessionId}');
      final response = await _dioClient.dio.post(
        '/api/ratings/mentor',
        data: request.toJson(),
      );

      print('✅ Mentor rating submitted successfully');
      return response.data;
    } catch (e) {
      print('❌ Error submitting mentor rating: $e');
      rethrow;
    }
  }

  /// POST /api/feedback/mentor/submit - Submit feedback for a job seeker after session (legacy)
  Future<FeedbackEntity> submitFeedback(SubmitFeedbackRequest request) async {
    try {
      print('📤 Submitting feedback for session: ${request.sessionId}');
      final response = await _dioClient.dio.post(
        '/api/feedback/mentor/submit',
        data: request.toJson(),
      );

      print('✅ Feedback submitted successfully');
      final model = FeedbackModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  /// GET /api/feedback/mentor/given - Get all feedback given by the mentor
  Future<List<FeedbackEntity>> getGivenFeedback() async {
    try {
      print('📡 Fetching given feedback');
      final response = await _dioClient.dio.get(
        '/api/feedback/mentor/given',
      );

      print('✅ Response received: ${response.statusCode}');

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['feedback'] ?? response.data['data'] ?? []);

      print('✅ Parsed ${data.length} feedback entries');
      return data.map((json) => FeedbackModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      print('❌ Error fetching given feedback: $e');
      rethrow;
    }
  }

  /// GET /api/feedback/{id} - Get specific feedback by ID
  Future<FeedbackEntity> getFeedbackById(String feedbackId) async {
    try {
      print('📡 Fetching feedback: $feedbackId');
      final response = await _dioClient.dio.get(
        '/api/feedback/$feedbackId',
      );

      print('✅ Feedback details received');
      final model = FeedbackModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error fetching feedback details: $e');
      rethrow;
    }
  }

  /// GET /api/feedback/session/{sessionId} - Get feedback for a specific session
  Future<FeedbackEntity?> getFeedbackBySessionId(String sessionId) async {
    try {
      print('📡 Fetching feedback for session: $sessionId');
      final response = await _dioClient.dio.get(
        '/api/feedback/session/$sessionId',
      );

      if (response.data == null) {
        return null;
      }

      print('✅ Feedback found for session');
      final model = FeedbackModel.fromJson(response.data);
      return model.toEntity();
    } catch (e) {
      print('❌ Error fetching session feedback: $e');
      // Return null if not found instead of throwing
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  /// GET /api/ratings/mentor/stats/{mentorId} - Get mentor's rating statistics
  Future<Map<String, dynamic>> getMentorRatingStats(int mentorId) async {
    try {
      print('📡 Fetching mentor rating stats: $mentorId');
      final response = await _dioClient.dio.get(
        '/api/ratings/mentor/stats/$mentorId',
      );

      print('✅ Mentor rating stats received');
      return response.data;
    } catch (e) {
      print('❌ Error fetching mentor rating stats: $e');
      rethrow;
    }
  }

  /// GET /api/ratings/mentor/for-mentor/{mentorId} - Get all ratings for a mentor
  Future<List<Map<String, dynamic>>> getMentorRatings(int mentorId) async {
    try {
      print('📡 Fetching mentor ratings: $mentorId');
      final response = await _dioClient.dio.get(
        '/api/ratings/mentor/for-mentor/$mentorId',
      );

      print('✅ Mentor ratings received');
      final List<dynamic> data = response.data is List ? response.data : [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error fetching mentor ratings: $e');
      rethrow;
    }
  }

  /// GET /api/feedback/mentor/{mentorId}/rating - Get mentor's average rating (legacy)
  Future<Map<String, dynamic>> getMentorRating(String mentorId) async {
    try {
      print('📡 Fetching mentor rating: $mentorId');
      final response = await _dioClient.dio.get(
        '/api/feedback/mentor/$mentorId/rating',
      );

      print('✅ Mentor rating received');
      return {
        'averageRating': response.data['averageRating'] ?? 0.0,
        'totalFeedbacks': response.data['totalFeedbacks'] ?? 0,
        'ratingBreakdown': response.data['ratingBreakdown'] ?? {},
      };
    } catch (e) {
      print('❌ Error fetching mentor rating: $e');
      rethrow;
    }
  }
}
