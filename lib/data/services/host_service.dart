import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class HostService {
  HostService._();

  static Future<AvatarPresignResponse> getAvatarPresignUrl({
    required String contentType,
  }) async {
    try {
      LoggerService.info('Requesting avatar presign URL');

      final response = await ApiClient.instance.post(
        ApiConfig.hostAvatarPresign,
        data: {'content_type': contentType},
      );

      final presignResponse = AvatarPresignResponse.fromJson(response['data']);

      LoggerService.info('Avatar presign URL obtained: ${presignResponse.key}');
      return presignResponse;
    } catch (e) {
      LoggerService.error('Failed to get avatar presign URL', error: e);
      rethrow;
    }
  }

  static Future<void> uploadAvatarToS3({
    required String uploadUrl,
    required File imageFile,
    required String contentType,
  }) async {
    try {
      LoggerService.info('Uploading avatar to S3');

      final dio = Dio();
      final fileBytes = await imageFile.readAsBytes();

      await dio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {'Content-Type': contentType},
        ),
      );

      LoggerService.info('Avatar uploaded to S3 successfully');
    } catch (e) {
      LoggerService.error('Failed to upload avatar to S3', error: e);
      rethrow;
    }
  }

  static Future<HostProfile> saveHostProfile({
    required String firstName,
    required String lastName,
    required String dob,
    required String city,
    required String bio,
    required String avatarUrl,
  }) async {
    try {
      LoggerService.info('Saving host profile');

      final response = await ApiClient.instance.post(
        ApiConfig.hostProfile,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'dob': dob,
          'city': city,
          'bio': bio,
          'avatar_url': avatarUrl,
        },
      );

      final profile = HostProfile.fromJson(response['data']['profile']);

      LoggerService.info('Host profile saved successfully');
      ToastService.showSuccess('Profile saved successfully');

      return profile;
    } catch (e) {
      LoggerService.error('Failed to save host profile', error: e);
      rethrow;
    }
  }

  static Future<HostProfile> getHostProfile() async {
    try {
      LoggerService.info('Fetching host profile');

      final response = await ApiClient.instance.get(ApiConfig.hostProfile);

      final profile = HostProfile.fromJson(response['data']);

      LoggerService.info('Host profile fetched successfully');
      return profile;
    } catch (e) {
      LoggerService.error('Failed to fetch host profile', error: e);
      rethrow;
    }
  }

  static Future<UpiVerificationResponse> verifyUpiId({
    required String upiId,
  }) async {
    try {
      LoggerService.info('Verifying UPI ID: $upiId');

      final response = await ApiClient.instance.post(
        ApiConfig.payoutVerifyUpi,
        data: {'upi_id': upiId},
      );

      final verificationResponse =
          UpiVerificationResponse.fromJson(response['data']);

      LoggerService.info(
        'UPI verification result: ${verificationResponse.valid}',
      );

      if (verificationResponse.valid) {
        ToastService.showSuccess('UPI ID verified successfully');
      } else {
        ToastService.showError('Invalid UPI ID');
      }

      return verificationResponse;
    } catch (e) {
      LoggerService.error('Failed to verify UPI ID', error: e);
      rethrow;
    }
  }

  static Future<KycResponse> savePayoutMethod({
    required String payoutMethod,
    String? upiId,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
  }) async {
    try {
      LoggerService.info('Saving payout method: $payoutMethod');

      final data = <String, dynamic>{'payout_method': payoutMethod};

      if (payoutMethod == 'UPI' && upiId != null) {
        data['upi_id'] = upiId;
      } else if (payoutMethod == 'BANK') {
        data['account_number'] = accountNumber;
        data['ifsc_code'] = ifscCode;
        data['account_holder_name'] = accountHolderName;
      }

      final response = await ApiClient.instance.post(
        ApiConfig.hostKyc,
        data: data,
      );

      final kycResponse = KycResponse.fromJson(response['data']);

      LoggerService.info('Payout method saved successfully');
      ToastService.showSuccess(kycResponse.message);

      return kycResponse;
    } catch (e) {
      LoggerService.error('Failed to save payout method', error: e);
      rethrow;
    }
  }

  static Future<OnboardingStatus> getOnboardingStatus() async {
    try {
      LoggerService.info('Fetching onboarding status');

      final response =
          await ApiClient.instance.get(ApiConfig.onboardingStatus);

      final status = OnboardingStatus.fromJson(response['data']);

      LoggerService.info(
        'Onboarding status: ${status.onboardingCompleted}, Step: ${status.currentStep}',
      );

      return status;
    } catch (e) {
      LoggerService.error('Failed to fetch onboarding status', error: e);
      rethrow;
    }
  }
}
