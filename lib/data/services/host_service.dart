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

  static String _getContentType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Direct Binary PUT upload to Google Cloud Storage (GCS bucket: `ayo-rentals`)
  static Future<void> uploadBytesToGcs({
    required File file,
    required String uploadUrl,
    String contentType = 'image/jpeg',
  }) async {
    try {
      LoggerService.info('Direct binary PUT upload to Google Cloud Storage (ayo-rentals)...');
      final fileBytes = await file.readAsBytes();

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('GCS direct upload failed with status ${response.statusCode}: ${response.body}');
      }

      LoggerService.info('GCS Direct Binary Upload Success! Status: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Failed GCS direct binary upload', error: e);
      rethrow;
    }
  }

  /// Presigns and uploads any image/file directly to Google Cloud Storage (`ayo-rentals`)
  static Future<String> uploadImageToGcs(File file, {String? contentType}) async {
    try {
      final mime = contentType ?? _getContentType(file.path);
      LoggerService.info('Requesting GCS presigned upload URL...');
      final presignRes = await ApiClient.instance.post(
        ApiConfig.hostAvatarPresign,
        data: {'content_type': mime},
      );

      final data = presignRes['data'] as Map<String, dynamic>;
      final presign = GcsPresignResponse.fromJson(data);

      if (presign.uploadUrl.isEmpty) {
        throw Exception('Presigned URL returned from backend is empty');
      }

      LoggerService.info('Uploading binary file to GCS: ${presign.key}...');
      await uploadBytesToGcs(file: file, uploadUrl: presign.uploadUrl, contentType: mime);

      LoggerService.info('GCS upload completed: ${presign.publicUrl}');
      return presign.publicUrl;
    } catch (e) {
      LoggerService.error('Failed GCS direct upload', error: e);
      rethrow;
    }
  }

  /// Presigns and uploads Host Avatar Photo directly to GCS (`ayo-rentals`)
  static Future<String> uploadAvatarToGcs(File imageFile) async {
    return await uploadImageToGcs(imageFile);
  }

  static Future<AvatarPresignResponse> getAvatarPresignUrl({
    required String contentType,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.hostAvatarPresign,
        data: {'content_type': contentType},
      );
      return AvatarPresignResponse.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to get avatar presign URL', error: e);
      rethrow;
    }
  }

  /// Uploads vehicle photo directly to GCS and confirms with vehicle ID
  static Future<String> uploadVehiclePhotoGcs({
    required String vehicleId,
    required File imageFile,
    String category = 'COVER',
  }) async {
    try {
      final contentType = _getContentType(imageFile.path);
      LoggerService.info('1. Requesting vehicle photo presign for vehicle: $vehicleId (category: $category)...');

      final presignRes = await ApiClient.instance.post(
        ApiConfig.vehiclePhotosPresign(vehicleId),
        data: {
          'content_type': contentType,
          'kind': 'PHOTO',
        },
      );

      final presign = GcsPresignResponse.fromJson(presignRes['data'] as Map<String, dynamic>);
      if (presign.uploadUrl.isEmpty) {
        throw Exception('Vehicle photo presigned URL is empty');
      }

      LoggerService.info('2. Uploading photo binary bytes to GCS...');
      await uploadBytesToGcs(
        file: imageFile,
        uploadUrl: presign.uploadUrl,
        contentType: contentType,
      );

      LoggerService.info('3. Confirming vehicle photo with Ayo Backend ($category)...');
      try {
        await ApiClient.instance.post(
          ApiConfig.vehiclePhotosConfirm(vehicleId),
          data: {
            'photo_ref': presign.key,
            'category': category,
          },
        );
      } catch (e) {
        LoggerService.warning('Vehicle photo confirm warning: $e');
      }

      return presign.publicUrl;
    } catch (e) {
      LoggerService.error('Failed vehicle photo GCS upload', error: e);
      rethrow;
    }
  }

  /// Uploads vehicle legal document (RC, Insurance, Pollution) directly to GCS and confirms
  static Future<String> uploadVehicleDocumentGcs({
    required String vehicleId,
    required File file,
    required String docType,
  }) async {
    try {
      final contentType = _getContentType(file.path);
      LoggerService.info('1. Requesting vehicle document presign for $docType...');

      final presignRes = await ApiClient.instance.post(
        ApiConfig.vehicleDocumentsPresign(vehicleId),
        data: {
          'type': docType,
          'content_type': contentType,
        },
      );

      final presign = GcsPresignResponse.fromJson(presignRes['data'] as Map<String, dynamic>);
      if (presign.uploadUrl.isEmpty) {
        throw Exception('Vehicle document presigned URL is empty');
      }

      LoggerService.info('2. Uploading document binary bytes to GCS...');
      await uploadBytesToGcs(
        file: file,
        uploadUrl: presign.uploadUrl,
        contentType: contentType,
      );

      final fileSizeBytes = await file.length();
      final fileName = file.path.split(Platform.pathSeparator).last;

      LoggerService.info('3. Confirming vehicle document with Ayo Backend ($docType)...');
      try {
        await ApiClient.instance.post(
          ApiConfig.vehicleDocumentsConfirm(vehicleId),
          data: {
            'type': docType,
            'key': presign.key,
            'file_name': fileName,
            'file_size_bytes': fileSizeBytes,
          },
        );
      } catch (e) {
        LoggerService.warning('Vehicle document confirm warning: $e');
      }

      return presign.publicUrl;
    } catch (e) {
      LoggerService.error('Failed vehicle document GCS upload', error: e);
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
    String? drivingLicenceNumber,
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
        'avatar_url': avatarUrl.trim().isNotEmpty ? avatarUrl.trim() : null,
      };

      if (drivingLicenceNumber != null && drivingLicenceNumber.trim().isNotEmpty) {
        final dl = drivingLicenceNumber.trim();
        payload['driving_licence_number'] = dl;
        payload['driving_licence'] = dl;
        payload['dl_number'] = dl;
      }

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
      if (profileData == null) {
        return const HostProfile(
          id: '',
          firstName: '',
          lastName: '',
          city: '',
          bio: '',
          step: 0,
          isCompleted: false,
        );
      }

      final profileMap = (profileData is Map && profileData.containsKey('profile'))
          ? profileData['profile']
          : profileData;

      final profile = HostProfile.fromJson(
        profileMap is Map<String, dynamic> ? profileMap : null,
      );

      LoggerService.info('Host profile fetched successfully');
      return profile;
    } catch (e) {
      LoggerService.error('Failed to fetch host profile', error: e);
      return const HostProfile(
        id: '',
        firstName: '',
        lastName: '',
        city: '',
        bio: '',
        step: 0,
        isCompleted: false,
      );
    }
  }

  static Future<UpiVerificationResponse> verifyUpiId({
    required String upiId,
    String? expectedName,
  }) async {
    try {
      LoggerService.info('Verifying UPI ID: $upiId with expectedName: $expectedName');

      final data = <String, dynamic>{'upi_id': upiId.trim()};
      if (expectedName != null && expectedName.trim().isNotEmpty) {
        data['expected_name'] = expectedName.trim();
      }

      final response = await ApiClient.instance.post(
        ApiConfig.payoutVerifyUpi,
        data: data,
      );

      final verificationResponse =
          UpiVerificationResponse.fromJson(response['data'] ?? {});

      if (verificationResponse.valid) {
        ToastService.showSuccess(
          verificationResponse.registeredName != null
              ? 'Verified: ${verificationResponse.registeredName}'
              : 'UPI ID verified successfully!',
        );
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
    String? drivingLicenceNumber,
  }) async {
    try {
      LoggerService.info('Saving payout method: $payoutMethod');

      final data = <String, dynamic>{'payout_method': payoutMethod};

      if (drivingLicenceNumber != null && drivingLicenceNumber.trim().isNotEmpty) {
        final dl = drivingLicenceNumber.trim();
        data['driving_licence_number'] = dl;
        data['driving_licence'] = dl;
        data['dl_number'] = dl;
      }

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

      final status = OnboardingStatus.fromJson(
        (response['data'] is Map<String, dynamic>) ? response['data'] : {},
      );

      LoggerService.info(
        'Onboarding status: ${status.onboardingCompleted}, Step: ${status.currentStep}',
      );

      return status;
    } catch (e) {
      LoggerService.error('Failed to fetch onboarding status', error: e);
      return const OnboardingStatus(
        onboardingCompleted: false,
        currentStep: '1',
        profileCompleted: false,
        payoutCompleted: false,
        kycStatus: 'NOT_STARTED',
      );
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

  static Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.vehicleById(vehicleId));
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        return Vehicle.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get vehicle by id: $vehicleId', error: e);
      return null;
    }
  }

  static Future<ListingFeeOrderResponse> payListingFee(String vehicleId) async {
    try {
      LoggerService.info('Creating listing fee order for vehicle: $vehicleId');
      final response = await ApiClient.instance.post(ApiConfig.vehiclePayListingFee(vehicleId));
      return ListingFeeOrderResponse.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to create listing fee order', error: e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyListingFeePayment(
    String vehicleId, {
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      LoggerService.info('Verifying listing fee payment for vehicle: $vehicleId');
      final response = await ApiClient.instance.post(
        ApiConfig.vehiclePayListingFeeVerify(vehicleId),
        data: {
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': signature,
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      ToastService.showSuccess('Listing fee verified! Vehicle submitted for review.');
      return response['data'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to verify listing fee payment', error: e);
      rethrow;
    }
  }

  static Future<PaymentsConfig> getPaymentsConfig() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.paymentsConfig);
      return PaymentsConfig.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to fetch payments config', error: e);
      return const PaymentsConfig(
        keyId: 'rzp_test_Tq48KTS6e99UpX',
        currency: 'INR',
        name: 'AYO Rentals',
        description: 'Car Rental & Security Deposit Payment',
      );
    }
  }

  static Future<SubmitVehicleResult> submitVehicleForReview(String vehicleId) async {
    try {
      LoggerService.info('Submitting vehicle for review: $vehicleId');
      await ApiClient.instance.post(ApiConfig.vehicleSubmit(vehicleId));
      ToastService.showSuccess('Vehicle submitted for review!');
      return const SubmitVehicleResult(success: true, message: 'Submitted for review');
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData != null && resData is Map) {
        final err = resData['error'] as Map<String, dynamic>? ?? {};
        final code = err['code']?.toString() ?? '';
        if (code == 'LISTING_FEE_REQUIRED' || e.response?.statusCode == 402) {
          final payment = err['payment'] as Map<String, dynamic>? ?? {};
          final orderId = payment['order_id']?.toString() ?? '';
          final amount = payment['amount'] is int ? payment['amount'] as int : 49900;
          final keyId = payment['key_id']?.toString() ?? ApiConfig.defaultRazorpayKey;

          LoggerService.info('Listing fee required (₹${(amount / 100).toInt()}) with Order ID: $orderId');
          return SubmitVehicleResult(
            success: false,
            listingFeeRequired: true,
            orderId: orderId,
            amountPaise: amount,
            keyId: keyId,
            message: err['message']?.toString() ?? 'Listing fee required',
          );
        }
      }
      LoggerService.error('Failed to submit vehicle', error: e);
      rethrow;
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
