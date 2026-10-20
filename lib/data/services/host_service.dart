import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class HostService {
  HostService._();

  /// Direct image upload to Cloudinary (Target: https://api.cloudinary.com/v1_1/rohitrv7/image/upload)
  static Future<String> uploadToCloudinary(File imageFile, {String? cloudName, String? preset}) async {
    try {
      final cName = (cloudName != null && cloudName.isNotEmpty)
          ? cloudName
          : ApiConfig.cloudinaryCloudName;
      final cPreset = (preset != null && preset.isNotEmpty)
          ? preset
          : ApiConfig.cloudinaryUploadPreset;

      LoggerService.info('Uploading photo directly to Cloudinary (Cloud: $cName, Preset: $cPreset)...');

      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cName/image/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = cPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseData.body);
        final String secureUrl = data['secure_url'];
        LoggerService.info('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        final errText = responseData.body;
        LoggerService.error('Cloudinary upload error: $errText');
        ToastService.showError('Cloudinary upload failed: $errText');
        throw Exception("Cloudinary upload failed: $errText");
      }
    } catch (e) {
      LoggerService.error('Cloudinary upload exception', error: e);
      rethrow;
    }
  }

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

      // Auto format date to YYYY-MM-DD for NestJS/PostgreSQL date column
      String formattedDob = dob.trim();
      if (formattedDob.contains('/')) {
        final parts = formattedDob.split('/');
        if (parts.length == 3) {
          if (parts[2].length == 4) {
            // MM/DD/YYYY or DD/MM/YYYY -> YYYY-MM-DD
            final year = parts[2];
            final m = parts[0].padLeft(2, '0');
            final d = parts[1].padLeft(2, '0');
            formattedDob = '$year-$m-$d';
          }
        }
      }

      final payload = <String, dynamic>{
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'dob': formattedDob.isNotEmpty ? formattedDob : '2000-01-01',
        'city': city.trim().isNotEmpty ? city.trim() : 'Bengaluru',
        'bio': bio.trim().isNotEmpty ? bio.trim() : 'AYO Host Partner',
        'avatar_url': avatarUrl.trim().isNotEmpty
            ? avatarUrl.trim()
            : 'https://res.cloudinary.com/rohitrv7/image/upload/v1/default_avatar.jpg',
      };

      final response = await ApiClient.instance.post(
        ApiConfig.hostProfile,
        data: payload,
      );

      final profileData = response['data'];
      final profileMap = profileData is Map && profileData.containsKey('profile')
          ? profileData['profile']
          : profileData;

      final profile = HostProfile.fromJson(profileMap as Map<String, dynamic>);

      LoggerService.info('Host profile saved successfully');
      ToastService.showSuccess('Host profile saved successfully');

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

      final profileData = response['data'];
      final profileMap = profileData is Map && profileData.containsKey('profile')
          ? profileData['profile']
          : profileData;

      final profile = HostProfile.fromJson(profileMap as Map<String, dynamic>);

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
          UpiVerificationResponse.fromJson(response['data'] ?? {});

      if (verificationResponse.valid) {
        ToastService.showSuccess('UPI ID verified successfully!');
      } else {
        ToastService.showError('Invalid UPI ID. Please check.');
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
        data['vpa'] = upiId;
      } else if (payoutMethod == 'BANK') {
        data['account_number'] = accountNumber;
        data['ifsc_code'] = ifscCode;
        data['ifsc'] = ifscCode;
        data['account_holder_name'] = accountHolderName;
      }

      final response = await ApiClient.instance.post(
        ApiConfig.hostKyc,
        data: data,
      );

      final kycResponse = KycResponse.fromJson(response['data'] ?? {});

      LoggerService.info('Payout method saved successfully');
      ToastService.showSuccess(
        kycResponse.message.isNotEmpty
            ? kycResponse.message
            : 'Payout method saved successfully',
      );

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

      final status = OnboardingStatus.fromJson(response['data'] ?? {});

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

      return items
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
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
      final response = await ApiClient.instance.patch(
        ApiConfig.vehicleById(id),
        data: data,
      );
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to update vehicle', error: e);
      rethrow;
    }
  }

  static Future<DocumentStatusChecklist> getDocumentStatus(String vehicleId) async {
    try {
      LoggerService.info('Fetching document status for vehicle: $vehicleId');
      final response = await ApiClient.instance.get(
        ApiConfig.vehicleDocumentsStatus(vehicleId),
      );
      return DocumentStatusChecklist.fromJson(response['data'] as Map<String, dynamic>);
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

  static Future<void> confirmPhoto({
    required String vehicleId,
    required String kind, // PHOTO or TOUR_360
    required String url,
  }) async {
    try {
      LoggerService.info('Confirming $kind for vehicle: $vehicleId');
      await ApiClient.instance.post(
        ApiConfig.vehiclePhotosConfirm(vehicleId),
        data: {'kind': kind, 'url': url},
      );
      ToastService.showSuccess('Photo saved to vehicle!');
    } catch (e) {
      LoggerService.error('Failed to confirm photo', error: e);
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

  static Future<Map<String, dynamic>> startHandover({
    required String tripId,
    required String token,
    required double hostLat,
    required double hostLng,
  }) async {
    try {
      LoggerService.info('Starting handover for trip: $tripId');
      final response = await ApiClient.instance.post(
        ApiConfig.tripHandover(tripId),
        data: {
          'token': token,
          'host_lat': hostLat,
          'host_lng': hostLng,
        },
      );
      ToastService.showSuccess('Handover complete! Trip started.');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to start handover', error: e);
      rethrow;
    }
  }

  static Future<SupportConfig> getSupportConfig() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.configSupport);
      return SupportConfig.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to fetch support config', error: e);
      return const SupportConfig(
        whatsapp: '+919999900000',
        phone: '1800-296-0000',
        email: 'support@ayo.com',
        whatsappLink: 'whatsapp://send?phone=+919999900000',
        telLink: 'tel:+9118002960000',
      );
    }
  }

  static Future<PlatformPolicies> getPlatformPolicies() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.configPolicies);
      return PlatformPolicies.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to fetch platform policies', error: e);
      return const PlatformPolicies(
        minRenterAge: 21,
        cancellationFreeHours: 24,
        coverageText: 'Comprehensive insurance with 24/7 roadside assistance.',
        currency: 'INR',
      );
    }
  }
}
