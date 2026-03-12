import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cv_extraction_response.dart';
import '../models/cv_approval_request.dart';
import '../models/otp_verification_request.dart';
import '../../../auth/data/models/login_response_model.dart';

class CVAuthRepository {
  final DioClient _dioClient;

  CVAuthRepository(this._dioClient);

  /// Step 1: Upload CV and extract data
  Future<CVExtractionResponse> uploadCV(File cvFile, String role) async {
    try {
      final formData = FormData.fromMap({
        'cvFile': await MultipartFile.fromFile(
          cvFile.path,
          filename: cvFile.path.split('/').last,
        ),
        'role': role,
      });

      final response = await _dioClient.dio.post(
        '/auth/cv/register/upload',
        data: formData,
      );

      return CVExtractionResponse.fromJson(response.data);
    } catch (e) {
      print('Error uploading CV: $e');
      rethrow;
    }
  }

  /// Step 2: Approve or reject extracted data
  Future<Map<String, dynamic>> approveExtraction(CVApprovalRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/cv/register/approve',
        data: request.toJson(),
      );

      return response.data;
    } catch (e) {
      print('Error approving CV data: $e');
      rethrow;
    }
  }

  /// Step 3: Verify OTP and complete registration
  Future<LoginResponseModel> verifyOTPAndRegister(OTPVerificationRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/cv/register/verify-otp',
        data: request.toJson(),
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }

  /// Login with CV
  Future<LoginResponseModel> loginWithCV(File cvFile) async {
    try {
      final formData = FormData.fromMap({
        'cvFile': await MultipartFile.fromFile(
          cvFile.path,
          filename: cvFile.path.split('/').last,
        ),
      });

      final response = await _dioClient.dio.post(
        '/auth/cv/login',
        data: formData,
      );

      return LoginResponseModel.fromJson(response.data);
    } catch (e) {
      print('Error logging in with CV: $e');
      rethrow;
    }
  }
}
