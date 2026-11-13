import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/toast_service.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'trips_service.dart';

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
    Map<String, String>? headers,
  }) async {
    try {
      final fileBytes = await file.readAsBytes();
      final uri = Uri.parse(uploadUrl);
      LoggerService.info('Direct binary upload to GCS (${fileBytes.length} bytes, url: ${uri.host}${uri.path})...');

      // Attempt 1: Upload with backend-specified headers if present, else Content-Type
      final reqHeaders = <String, String>{};
      if (headers != null && headers.isNotEmpty) {
        reqHeaders.addAll(headers);
      } else {
        reqHeaders['Content-Type'] = contentType;
      }

      var response = await http.put(
        uri,
        headers: reqHeaders,
        body: fileBytes,
      );

      // Attempt 2: If GCS returns 403 (often due to Content-Type signature mismatch), retry without Content-Type
      if (response.statusCode == 403 && reqHeaders.containsKey('Content-Type')) {
        LoggerService.warning('GCS returned 403 with Content-Type ($contentType). Retrying without Content-Type...');
        final retryHeaders = Map<String, String>.from(reqHeaders)..remove('Content-Type');
        response = await http.put(
          uri,
          headers: retryHeaders.isEmpty ? null : retryHeaders,
          body: fileBytes,
        );
      }

      // Attempt 3: If still failing with 400 or 403, retry with standard binary stream
      if ((response.statusCode == 400 || response.statusCode == 403) && contentType != 'application/octet-stream') {
        LoggerService.warning('GCS returned ${response.statusCode}. Retrying with application/octet-stream...');
        response = await http.put(
          uri,
          headers: {'Content-Type': 'application/octet-stream'},
          body: fileBytes,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
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
      LoggerService.info('Requesting GCS presigned upload URL (mime: $mime)...');
      final presignRes = await ApiClient.instance.post(
        ApiConfig.hostAvatarPresign,
        data: {'content_type': mime},
      );

      final presign = GcsPresignResponse.fromJson(presignRes);

      if (presign.uploadUrl.isEmpty) {
        throw Exception('Presigned URL returned from backend is empty');
      }

      LoggerService.info('Uploading binary file to GCS: ${presign.key}...');
      await uploadBytesToGcs(
        file: file,
        uploadUrl: presign.uploadUrl,
        contentType: mime,
        headers: presign.headers,
      );

      final publicUrl = presign.publicUrl;
      LoggerService.info('GCS upload completed: $publicUrl');
      return publicUrl;
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
      LoggerService.info('1. Requesting vehicle photo presign for vehicle: $vehicleId (category: $category, mime: $contentType)...');

      Map<String, dynamic> presignRes;
      try {
        presignRes = await ApiClient.instance.post(
          ApiConfig.vehiclePhotosPresign(vehicleId),
          data: {'content_type': contentType, 'category': category.toUpperCase(), 'kind': 'PHOTO'},
        );
      } catch (_) {
        presignRes = await ApiClient.instance.post(
          ApiConfig.vehicleMediaPresign(vehicleId),
          data: {'category': category.toUpperCase(), 'content_type': contentType},
        );
      }

      final presign = GcsPresignResponse.fromJson(presignRes);
      if (presign.uploadUrl.isEmpty) {
        throw Exception('Vehicle photo presigned URL is empty');
      }

      LoggerService.info('2. Uploading photo binary bytes to GCS: ${presign.key}...');
      await uploadBytesToGcs(
        file: imageFile,
        uploadUrl: presign.uploadUrl,
        contentType: contentType,
        headers: presign.headers,
      );

      LoggerService.info('3. Confirming vehicle photo with Ayo Backend ($category)...');
      try {
        try {
          await ApiClient.instance.post(
            ApiConfig.vehiclePhotosBatch(vehicleId),
            data: {
              'photos': [
                {'url': presign.key, 'category': category.toUpperCase()}
              ],
            },
          );
        } catch (_) {
          await ApiClient.instance.post(
            ApiConfig.vehiclePhotosConfirm(vehicleId),
            data: {
              'photo_ref': presign.key,
              'category': category,
            },
          );
        }
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
      LoggerService.info('1. Requesting vehicle document presign for $docType ($contentType)...');

      final presignRes = await ApiClient.instance.post(
        ApiConfig.vehicleDocumentsPresign(vehicleId),
        data: {
          'type': docType,
          'document_type': docType,
          'content_type': contentType,
        },
      );

      final presign = GcsPresignResponse.fromJson(presignRes);
      if (presign.uploadUrl.isEmpty) {
        throw Exception('Vehicle document presigned URL is empty');
      }

      LoggerService.info('2. Uploading document binary bytes to GCS: ${presign.key}...');
      await uploadBytesToGcs(
        file: file,
        uploadUrl: presign.uploadUrl,
        contentType: contentType,
        headers: presign.headers,
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
    String? email,
    String? drivingLicenceFrontUrl,
    String? drivingLicenceBackUrl,
    String? selfieUrl,
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
        if (formattedDob.isNotEmpty) 'dob': formattedDob,
        if (city.trim().isNotEmpty) 'city': city.trim(),
        if (bio.trim().isNotEmpty) 'bio': bio.trim(),
        if (avatarUrl.trim().isNotEmpty) 'avatar_url': avatarUrl.trim(),
      };

      if (drivingLicenceNumber != null && drivingLicenceNumber.trim().isNotEmpty) {
        payload['driving_licence_number'] = drivingLicenceNumber.trim();
      }
      if (email != null && email.trim().isNotEmpty) payload['email'] = email.trim();
      if (drivingLicenceFrontUrl != null && drivingLicenceFrontUrl.isNotEmpty) {
        payload['driving_licence_front_url'] = drivingLicenceFrontUrl;
      }
      if (drivingLicenceBackUrl != null && drivingLicenceBackUrl.isNotEmpty) {
        payload['driving_licence_back_url'] = drivingLicenceBackUrl;
      }
      if (selfieUrl != null && selfieUrl.isNotEmpty) payload['selfie_url'] = selfieUrl;

      final response = await ApiClient.instance.post(
        ApiConfig.hostProfile,
        data: payload,
      );

      // Sync User entity via PATCH /users/me so NestJS User table & HostProfile stay 100% in sync
      try {
        await ApiClient.instance.patch(
          ApiConfig.usersMePatch,
          data: {
            'name': '$firstName $lastName'.trim(),
            if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            if (avatarUrl.trim().isNotEmpty) 'avatar_url': avatarUrl.trim(),
          },
        );
      } catch (e) {
        LoggerService.info('User entity patch notice: $e');
      }

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

  /// Fetches all vehicles for the host by merging the complete list from
  /// `/vehicles/mine` (or `/vehicles/my`) with the live IoT/fleet status from `/vehicles/host/my-cars`.
  static Future<List<Vehicle>> getMyVehicles({String? status}) async {
    try {
      final query = (status == null || status == 'all') ? null : {'status': status};
      final vehicleMap = <String, Map<String, dynamic>>{};

      // 1) Fetch full inventory from /vehicles/mine (contains ALL: DRAFT, PENDING_REVIEW, ACTIVE)
      try {
        final resMine = await ApiClient.instance.get(ApiConfig.vehiclesMine, queryParameters: query);
        LoggerService.info('Raw GET /vehicles/mine response: $resMine');
        final rawMine = resMine['data'] ?? resMine;
        List listMine = [];
        if (rawMine is List) {
          listMine = rawMine;
        } else if (rawMine is Map) {
          listMine = (rawMine['items'] ?? rawMine['vehicles'] ?? rawMine['cars'] ?? rawMine['fleet']) as List? ?? [];
        }
        for (final item in listMine) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              vehicleMap[id] = Map<String, dynamic>.from(item);
            }
          }
        }
      } catch (e) {
        LoggerService.info('/vehicles/mine query failed: $e, trying /vehicles/my fallback');
        try {
          final resMy = await ApiClient.instance.get(ApiConfig.vehiclesMy, queryParameters: query);
          final rawMy = resMy['data'] ?? resMy;
          List listMy = [];
          if (rawMy is List) {
            listMy = rawMy;
          } else if (rawMy is Map) {
            listMy = (rawMy['items'] ?? rawMy['vehicles'] ?? rawMy['cars'] ?? rawMy['fleet']) as List? ?? [];
          }
          for (final item in listMy) {
            if (item is Map) {
              final id = item['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                vehicleMap[id] = Map<String, dynamic>.from(item);
              }
            }
          }
        } catch (_) {}
      }

      // 2) Enrich with IoT / Primary Car data from /vehicles/host/my-cars
      try {
        final res = await ApiClient.instance.get(ApiConfig.vehiclesHostMyCars);
        LoggerService.info('Raw GET /vehicles/host/my-cars response: $res');
        final raw = (res['data'] is Map ? res['data'] : res) as Map;
        final myCarsList = <Map<String, dynamic>>[];
        if (raw['primary_car'] is Map) {
          myCarsList.add(Map<String, dynamic>.from(raw['primary_car'] as Map));
        }
        final carsList = raw['cars'] is List
            ? raw['cars'] as List
            : (raw['fleet'] is List
                ? raw['fleet'] as List
                : (raw['items'] is List
                    ? raw['items'] as List
                    : (raw['vehicles'] is List ? raw['vehicles'] as List : [])));
        for (final e in carsList) {
          if (e is Map) myCarsList.add(Map<String, dynamic>.from(e));
        }

        for (final car in myCarsList) {
          final id = car['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            if (vehicleMap.containsKey(id)) {
              vehicleMap[id]!.addAll(car);
            } else {
              vehicleMap[id] = car;
            }
          }
        }
      } catch (e) {
        LoggerService.info('my-cars route enrich failed: $e');
      }

      // 3) Hydrate full details (photos list, hourly rate) for vehicles from /vehicles/:id
      await Future.wait(vehicleMap.keys.map((id) async {
        try {
          final existing = vehicleMap[id]!;
          final existingPhotos = existing['photos'];
          final existingHourly = existing['hourly_rate'];
          if (existingPhotos == null || (existingPhotos is List && existingPhotos.isEmpty) || existingHourly == null) {
            final detailed = await getVehicleById(id);
            if (detailed != null) {
              if (detailed.photos.isNotEmpty) {
                existing['photos'] = detailed.photos;
              }
              if (detailed.hourlyRate > 0) {
                existing['hourly_rate'] = detailed.hourlyRate;
              }
              if (detailed.imageUrl != null && existing['cover_photo_url'] == null) {
                existing['cover_photo_url'] = detailed.imageUrl;
              }
            }
          }
        } catch (_) {}
      }));

      var list = vehicleMap.values.map(Vehicle.fromJson).toList();
      if (query != null && status != null) {
        final want = status.toUpperCase();
        list = list.where((v) => v.status.toUpperCase() == want).toList();
      }
      return list;
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

  static Future<void> confirmPhotosBatch({
    required String vehicleId,
    required List<Map<String, String>> photos,
  }) async {
    try {
      LoggerService.info('Batch confirming ${photos.length} photos for vehicle $vehicleId');
      await ApiClient.instance.post(
        ApiConfig.vehiclePhotosBatch(vehicleId),
        data: {'photos': photos},
      );
      LoggerService.info('Batch photos confirmed successfully');
    } catch (e) {
      LoggerService.warning('Batch photos confirm failed: $e');
    }
  }

  /// `DELETE /api/v1/vehicles/:id/photos?url=...`
  /// Physically deletes a vehicle photo from Google Cloud Storage and unlinks it from the vehicle.
  static Future<bool> deleteVehiclePhoto({
    required String vehicleId,
    required String photoUrl,
    String? category,
  }) async {
    try {
      final cleanUrl = photoUrl.trim();
      if (cleanUrl.isEmpty) return false;

      final queryParams = <String, dynamic>{'url': cleanUrl};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      LoggerService.info('Deleting vehicle photo from cloud: vehicle=$vehicleId url=$cleanUrl');
      final res = await ApiClient.instance.delete(
        '/vehicles/$vehicleId/photos',
        queryParameters: queryParams,
      );

      final ok = res['ok'] == true || res['success'] == true;
      if (ok) {
        ToastService.showSuccess('Photo removed from vehicle and cloud storage');
      }
      return ok;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        ToastService.showWarning('Cannot delete photos while vehicle has active bookings.');
      } else {
        ToastService.showError('Could not delete photo: ${e.message}');
      }
      return false;
    } catch (e) {
      LoggerService.warning('Failed to delete vehicle photo: $e');
      return false;
    }
  }

  /// `DELETE /api/v1/vehicles/:id/documents/:type`
  /// Permanently removes vehicle document (RC, INSURANCE, POLLUTION) from storage & database.
  static Future<bool> deleteVehicleDocument({
    required String vehicleId,
    required String type,
  }) async {
    try {
      final cleanType = type.trim().toUpperCase();
      LoggerService.info('Deleting vehicle document: vehicle=$vehicleId type=$cleanType');
      final res = await ApiClient.instance.delete(
        '/vehicles/$vehicleId/documents/$cleanType',
      );

      final ok = res['ok'] == true || res['success'] == true;
      if (ok) {
        ToastService.showSuccess('$cleanType document removed successfully');
      }
      return ok;
    } on ApiException catch (e) {
      ToastService.showError('Could not delete $type document: ${e.message}');
      return false;
    } catch (e) {
      LoggerService.warning('Failed to delete vehicle document: $e');
      return false;
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
      final response = await ApiClient.instance.post(
        ApiConfig.vehiclePayListingFee(vehicleId),
        data: {'payment_method': 'RAZORPAY'},
      );
      final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
      return ListingFeeOrderResponse.fromJson(data);
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
      Map<String, dynamic> response;
      try {
        final res = await ApiClient.instance.post(
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
        response = (res['data'] is Map ? res['data'] : res) as Map<String, dynamic>;
      } catch (err) {
        LoggerService.warning('Vehicle fee verify endpoint failed ($err), trying fallback /payments/verify');
        try {
          final res = await ApiClient.instance.post(
            ApiConfig.paymentsVerify,
            data: {
              'vehicle_id': vehicleId,
              'order_id': orderId,
              'payment_id': paymentId,
              'signature': signature,
              'razorpay_order_id': orderId,
              'razorpay_payment_id': paymentId,
              'razorpay_signature': signature,
            },
          );
          response = (res['data'] is Map ? res['data'] : res) as Map<String, dynamic>;
        } catch (_) {
          rethrow;
        }
      }

      // Re-trigger submit to ensure backend transitions vehicle to PENDING_REVIEW
      try {
        await ApiClient.instance.post(ApiConfig.vehicleSubmit(vehicleId));
      } catch (_) {}

      ToastService.showSuccess('Listing fee verified! Vehicle submitted for review.');
      return response;
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
        keyId: '',
        currency: 'INR',
        name: 'AYO Host Platform',
        description: 'Host Listing & Verification Payment',
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
        if (code == 'MISSING_VEHICLE_DOCUMENTS') {
          final missing = (err['missing_documents'] as List?)?.map((e) => e.toString()).toList() ?? [];
          return SubmitVehicleResult(
            success: false,
            missingDocuments: missing,
            message: err['message']?.toString() ?? 'All vehicle documents (RC, Commercial Insurance, Pollution) must be uploaded before listing',
          );
        }
        if (code == 'LISTING_FEE_REQUIRED' || e.response?.statusCode == 402) {
          final payment = (err['payment'] is Map ? err['payment'] as Map<String, dynamic> : null) ??
              (resData['payment'] is Map ? resData['payment'] as Map<String, dynamic> : null) ??
              {};
          final listingFeeObj = (err['listing_fee'] is Map ? err['listing_fee'] as Map<String, dynamic> : null) ??
              (resData['listing_fee'] is Map ? resData['listing_fee'] as Map<String, dynamic> : null) ??
              {};
          final rawOrderId = (payment['order_id'] ??
                  payment['razorpay_order_id'] ??
                  err['order_id'] ??
                  resData['order_id'] ??
                  '')
              .toString().trim();
          final orderId = rawOrderId.startsWith('order_') ? rawOrderId : '';
          var amount = 0;
          if (payment['amount'] != null) {
            amount = payment['amount'] is int ? payment['amount'] : int.tryParse(payment['amount'].toString()) ?? 0;
          } else if (listingFeeObj['amount'] != null) {
            amount = listingFeeObj['amount'] is int ? listingFeeObj['amount'] : int.tryParse(listingFeeObj['amount'].toString()) ?? 0;
          } else if (err['amount'] != null) {
            amount = err['amount'] is int ? err['amount'] : int.tryParse(err['amount'].toString()) ?? 0;
          }
          if (amount > 0 && amount < 1000) {
            amount = amount * 100;
          }
          if (amount == 0) {
            try {
              amount = (await getListingFee()).feePaise;
            } catch (_) {
              amount = 0;
            }
          }
          final keyId = (payment['key_id'] ??
                  payment['key'] ??
                  err['key_id'] ??
                  resData['key_id'] ??
                  '')
              .toString();

          LoggerService.info('Listing fee required (₹${(amount / 100).toInt()}) with Order ID: $orderId');
          return SubmitVehicleResult(
            success: false,
            listingFeeRequired: true,
            orderId: orderId,
            amountPaise: amount,
            keyId: keyId,
            message: err['message']?.toString() ?? resData['message']?.toString() ?? 'Listing fee required',
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

  /// Direct Handover QR scan: `POST /api/v1/trips/scan-handover`
  static Future<Map<String, dynamic>> scanHandover({
    required String handoverToken,
    double? hostLat,
    double? hostLng,
  }) async {
    final body = {
      'handover_token': handoverToken.trim(),
      // ignore: use_null_aware_elements
      if (hostLat != null) 'host_lat': hostLat,
      // ignore: use_null_aware_elements
      if (hostLng != null) 'host_lng': hostLng,
      // ignore: use_null_aware_elements
      if (hostLng != null) 'host_lon': hostLng,
    };
    try {
      LoggerService.info('Scanning and verifying handover token directly...');
      final response = await ApiClient.instance.post(
        ApiConfig.tripScanHandover,
        data: body,
      );
      ToastService.showSuccess('Vehicle handover verified! Trip is now ACTIVE.');
      return (response['data'] is Map ? response['data'] : response) as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Direct scan handover failed', error: e);
      rethrow;
    }
  }

  /// Guide route `POST /trips/:id/verify-handover` (token, odometer, fuel, host location).
  /// Falls back to legacy `/trips/:id/start-handover` if the new route 404s.
  static Future<Map<String, dynamic>> startHandover({
    required String tripId,
    required String token,
    required double hostLat,
    required double hostLng,
    int? odometerReading,
    int? fuelPercent,
  }) async {
    final body = {
      'token': token,
      'handover_token': token,
      // ignore: use_null_aware_elements
      if (odometerReading != null) 'odometer_reading': odometerReading,
      // ignore: use_null_aware_elements
      if (fuelPercent != null) 'fuel_percent': fuelPercent,
      'host_lat': hostLat,
      'host_lng': hostLng,
    };
    try {
      Map<String, dynamic> response;
      try {
        response = await ApiClient.instance.post(ApiConfig.tripVerifyHandover(tripId), data: body);
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
        response = await ApiClient.instance.post(ApiConfig.tripHandover(tripId), data: body);
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        response = await ApiClient.instance.post(ApiConfig.tripHandover(tripId), data: body);
      }
      ToastService.showSuccess('Handover verified! Trip started.');
      return (response['data'] is Map ? response['data'] : response) as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Failed to verify handover', error: e);
      rethrow;
    }
  }

  /// `POST /trips/:id/end` — host concludes the trip, triggers deposit refund.
  static Future<Map<String, dynamic>> endTrip(String tripId) async {
    final res = await ApiClient.instance.post(
      ApiConfig.tripEnd(tripId),
      options: Options(headers: {
        'Idempotency-Key': 'end_trip_${tripId}_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    return (res['data'] is Map ? res['data'] : res) as Map<String, dynamic>;
  }

  /// `POST /trips/:id/cancel`
  static Future<Map<String, dynamic>> cancelTrip(String tripId, String reason) async {
    final res = await ApiClient.instance.post(
      ApiConfig.tripCancel(tripId),
      data: {'reason': reason},
      options: Options(headers: {
        'Idempotency-Key': 'cancel_trip_${tripId}_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
    return (res['data'] is Map ? res['data'] : res) as Map<String, dynamic>;
  }

  // ─────────── IoT lock / unlock + listing pause ───────────
  static Future<bool> lockVehicle(String id) async {
    final res = await ApiClient.instance.post(ApiConfig.vehicleLock(id));
    return (res['success'] ?? res['data']?['success'] ?? true) == true;
  }

  static Future<bool> unlockVehicle(String id) async {
    final res = await ApiClient.instance.post(ApiConfig.vehicleUnlock(id));
    return (res['success'] ?? res['data']?['success'] ?? true) == true;
  }

  /// `PATCH /vehicles/:id/toggle-status` -> returns new status (ACTIVE / PAUSED).
  static Future<String> toggleVehicleStatus(String id) async {
    final res = await ApiClient.instance.patch(ApiConfig.vehicleToggleStatus(id));
    final m = (res['data'] is Map ? res['data'] : res) as Map;
    return m['status']?.toString() ?? '';
  }

  // ─────────── Reviews ───────────
  static Future<VehicleReviewsPage> getVehicleReviews(String id, {int page = 1, int limit = 20}) async {
    final res = await ApiClient.instance.get(
      ApiConfig.vehicleReviews(id),
      queryParameters: {'page': page, 'limit': limit},
    );
    return VehicleReviewsPage.fromJson((res['data'] is Map ? res['data'] : res) as Map<String, dynamic>);
  }

  static Future<SupportConfig> getSupportConfig() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.configSupport);
      return SupportConfig.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Failed to fetch support config', error: e);
      return const SupportConfig(
        whatsapp: '',
        phone: '',
        email: '',
        whatsappLink: '',
        telLink: '',
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

  // ─────────── Identity documents (DL front / back / selfie) ───────────
  static Map<String, dynamic> _unwrap(Map<String, dynamic> res) {
    final d = res['data'];
    return d is Map<String, dynamic> ? d : res;
  }

  /// [documentType]: DL_FRONT | DL_BACK | SELFIE. Returns the storage key or URL that
  /// goes into `driving_licence_front_url` / `_back_url` / `selfie_url`.
  static Future<String> uploadHostDocument({
    required String documentType,
    required File file,
  }) async {
    try {
      final mime = _getContentType(file.path);
      LoggerService.info('Requesting host document presign for $documentType ($mime)...');
      final res = await ApiClient.instance.post(
        ApiConfig.hostDocumentPresign,
        data: {
          'document_type': documentType,
          'type': documentType,
          'content_type': mime,
        },
      );
      final presign = GcsPresignResponse.fromJson(res);
      if (presign.uploadUrl.isEmpty) {
        throw Exception('Upload URL not received from server');
      }
      LoggerService.info('Uploading host document binary bytes to GCS: ${presign.key}...');
      await uploadBytesToGcs(
        file: file,
        uploadUrl: presign.uploadUrl,
        contentType: mime,
        headers: presign.headers,
      );
      final returnKey = presign.key.isNotEmpty ? presign.key : presign.publicUrl;
      if (returnKey.isEmpty) {
        throw Exception('Failed to obtain uploaded document reference key');
      }
      LoggerService.info('Host document upload succeeded ($documentType): $returnKey');
      return returnKey;
    } catch (e) {
      LoggerService.error('Host document upload failed ($documentType)', error: e);
      rethrow;
    }
  }

  // ─────────── Dynamic listing fee ───────────
  static Future<ListingFeeConfig> getListingFee() async {
    Map<String, dynamic> res;
    try {
      res = await ApiClient.instance.get(ApiConfig.vehiclesListingFee);
    } catch (_) {
      try {
        res = await ApiClient.instance.get(ApiConfig.hostListingFee);
      } catch (_) {
        res = await ApiClient.instance.get(ApiConfig.listingFee);
      }
    }
    return ListingFeeConfig.fromJson(_unwrap(res));
  }

  // ─────────── Earnings ───────────
  static Future<EarningsStats> getEarnings() async {
    try {
      final res = await ApiClient.instance.get(ApiConfig.hostEarnings);
      return EarningsStats.fromJson(_unwrap(res));
    } catch (_) {
      // Fallback: Compute dynamically from host's completed trips
      try {
        final completed = await TripsService.getCompletedTrips();
        final total = completed.fold<double>(0, (sum, t) => sum + (t.rentPaise / 100.0));
        return EarningsStats(
          total: total,
          thisMonth: total,
          completedTrips: completed.length,
          recent: completed.map((t) => EarningsEntry(
            title: t.vehicle.isNotEmpty ? t.vehicle : 'Rental Trip',
            subtitle: 'Completed Trip',
            amount: t.rentPaise / 100.0,
            status: 'PAID',
          )).toList(),
        );
      } catch (_) {
        return const EarningsStats();
      }
    }
  }
}
