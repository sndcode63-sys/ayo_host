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

  static Future<List<Vehicle>> getMyVehicles() async {
    try {
      LoggerService.info('Fetching host vehicles from /vehicles/mine');
      final response = await ApiClient.instance.get(ApiConfig.vehiclesMine);
      
      final dynamic raw = response['data'];
      List items = [];
      if (raw is Map && raw['items'] is List) {
        items = raw['items'];
      } else if (raw is List) {
        items = raw;
      }
      
      return items.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      LoggerService.error('Failed to fetch host vehicles', error: e);
      return [];
    }
  }

  static Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    try {
      LoggerService.info('Creating vehicle listing: ${data['make']} ${data['model']}');
      final response = await ApiClient.instance.post(ApiConfig.vehicles, data: data);
      ToastService.showSuccess('Vehicle submitted for review!');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to create vehicle', error: e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data) async {
    try {
      LoggerService.info('Updating vehicle: $id');
      final response = await ApiClient.instance.dio.patch(
        '${ApiConfig.baseUrl}${ApiConfig.vehicleById(id)}',
        data: data,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to update vehicle', error: e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getDocumentStatus(String vehicleId) async {
    try {
      LoggerService.info('Fetching document status for vehicle: $vehicleId');
      final response = await ApiClient.instance.get(ApiConfig.vehicleDocumentsStatus(vehicleId));
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to get document status', error: e);
      rethrow;
    }
  }

  static Future<void> confirmDocument({
    required String vehicleId,
    required String type,
    required String url,
    String? fileName,
    int? fileSizeBytes,
    String? expiryDate,
  }) async {
    try {
      LoggerService.info('Confirming document $type for vehicle: $vehicleId');
      final data = <String, dynamic>{
        'type': type,
        'url': url,
      };
      if (fileName != null) data['file_name'] = fileName;
      if (fileSizeBytes != null) data['file_size_bytes'] = fileSizeBytes;
      if (expiryDate != null) data['expiry_date'] = expiryDate;

      await ApiClient.instance.post(
        ApiConfig.vehicleDocumentsConfirm(vehicleId),
        data: data,
      );
      ToastService.showSuccess('$type document saved!');
    } catch (e) {
      LoggerService.error('Failed to confirm document', error: e);
      rethrow;
    }
  }

  static Future<void> submitVehicleForReview(String vehicleId) async {
    try {
      LoggerService.info('Submitting vehicle for review: $vehicleId');
      await ApiClient.instance.post(ApiConfig.vehicleSubmit(vehicleId));
      ToastService.showSuccess('Vehicle submitted for review!');
    } catch (e) {
      LoggerService.error('Failed to submit vehicle', error: e);
      rethrow;
    }
  }
}
