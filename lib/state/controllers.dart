import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/services/logger_service.dart';
import '../core/services/toast_service.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/host_service.dart';
import '../data/services/trips_service.dart';
import '../ui/widgets/app_image_view.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final AuthRepository _repo;

  User? user;
  HostProfile? host;
  OnboardingStatus? onboardingStatus;
  bool loading = false;
  String? error;

  String? verificationId;
  int? resendToken;
  bool isCodeSent = false;

  String? get userPhone => user?.phone ?? host?.phone;
  String? get userEmail => user?.email ?? host?.email;

  Future<void> checkSession() async {
    final isAuth = await _repo.isAuthenticated();
    if (isAuth) {
      try {
        user = await _repo.getAuthMe();
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final completer = Completer<bool>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final idToken = await userCredential.user?.getIdToken();
            if (idToken != null) {
              await exchangeToken(idToken);
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (e) {
            error = e.toString();
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          error = e.message ?? 'SMS Verification failed';
          ToastService.showError(error!);
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String vId, int? rToken) {
          verificationId = vId;
          resendToken = rToken;
          isCodeSent = true;
          ToastService.showSuccess('OTP sent successfully to $phoneNumber');
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );

      final success = await completer.future;
      return success;
    } catch (e) {
      error = e.toString();
      ToastService.showError('Failed to send OTP: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtpCode(String smsCode) async {
    if (verificationId == null) {
      error = 'Verification ID missing. Please resend OTP.';
      ToastService.showError(error!);
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Could not retrieve Firebase ID Token');
      }

      return await exchangeToken(idToken);
    } catch (e) {
      error = e.toString();
      ToastService.showError('Invalid OTP code. Please check and retry.');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> exchangeToken(String idToken) async {
    try {
      final authResponse = await _repo.exchangeFirebaseToken(
        idToken: idToken,
        role: 'HOST',
        consentAccepted: true,
        consentVersion: '1.0',
      );

      user = authResponse.user;

      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {}

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> quickLoginHost() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await _repo.quickLoginHost();
      user = authResponse.user;

      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {}

      return true;
    } catch (e) {
      error = e.toString();
      ToastService.showError('Login failed: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> devMockLogin(String phone) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await _repo.devMockExchange(
        phone: phone,
        role: 'HOST',
      );

      user = authResponse.user;

      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {}

      return true;
    } catch (e) {
      // Fallback to quick-login host
      try {
        final authResponse = await _repo.quickLoginHost();
        user = authResponse.user;
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
        return true;
      } catch (e2) {
        error = e2.toString();
        return false;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.logout();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    user = null;
    host = null;
    onboardingStatus = null;
    isCodeSent = false;
    verificationId = null;
    notifyListeners();
  }
}

class DashboardController extends ChangeNotifier {
  DashboardController(this._repo);
  final HostRepository _repo;

  DashboardStats? stats;
  List<Vehicle> vehicles = [];
  List<Trip> upcomingTrips = [];
  HostProfile? hostProfile;
  SupportConfig? supportConfig;
  PlatformPolicies? platformPolicies;
  OnboardingStatus? onboardingStatus;
  PaymentsConfig? paymentsConfig;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchVehicles().catchError((e) {
          LoggerService.error('Fetch vehicles error', error: e);
          return <Vehicle>[];
        }),
        TripsService.getUpcomingTrips().catchError((e) {
          LoggerService.error('Fetch upcoming trips error', error: e);
          return <Trip>[];
        }),
        _repo.fetchProfile().catchError((e) {
          return const HostProfile(
            id: '',
            firstName: '',
            lastName: '',
            city: '',
            bio: '',
            step: 0,
            isCompleted: false,
          );
        }),
        HostService.getSupportConfig().catchError((e) {
          LoggerService.error('Fetch support config error', error: e);
          return const SupportConfig(
            whatsapp: '',
            phone: '1800-296-0000',
            email: 'support@ayo.com',
            whatsappLink: '',
            telLink: '',
          );
        }),
        HostService.getPlatformPolicies().catchError((e) {
          LoggerService.error('Fetch platform policies error', error: e);
          return const PlatformPolicies(
            minRenterAge: 21,
            cancellationFreeHours: 24,
            coverageText: 'Comprehensive insurance with 24/7 roadside assistance.',
            currency: 'INR',
          );
        }),
        HostService.getOnboardingStatus().catchError((e) {
          LoggerService.error('Fetch onboarding status error', error: e);
          return const OnboardingStatus(
            onboardingCompleted: false,
            currentStep: '1',
            profileCompleted: false,
            payoutCompleted: false,
            kycStatus: 'NOT_STARTED',
          );
        }),
        HostService.getPaymentsConfig().catchError((e) {
          LoggerService.error('Fetch payments config error', error: e);
          return const PaymentsConfig(
            keyId: 'rzp_test_Tq48KTS6e99UpX',
            currency: 'INR',
            name: 'AYO Rentals',
            description: 'Car Rental & Security Deposit Payment',
          );
        }),
      ]);

      vehicles = results[0] as List<Vehicle>;
      upcomingTrips = results[1] as List<Trip>;
      hostProfile = results[2] as HostProfile;
      supportConfig = results[3] as SupportConfig;
      platformPolicies = results[4] as PlatformPolicies;
      onboardingStatus = results[5] as OnboardingStatus;
      paymentsConfig = results[6] as PaymentsConfig;

      Handover? nextHandover;
      if (upcomingTrips.isNotEmpty) {
        final firstTrip = upcomingTrips.first;
        nextHandover = Handover(
          tripId: firstTrip.id,
          vehicleName: firstTrip.vehicle,
          guestName: firstTrip.customer.name,
          timeLabel: DateFormat('MMM dd, hh:mm a').format(firstTrip.startTime),
          location: 'Host Spot',
          countdown: 'Upcoming',
        );
      }

      final activeCount = vehicles.where((v) => v.status == 'ACTIVE' || v.status == 'ON_TRIP').length;
      final totalRevenue = vehicles.fold<double>(0, (sum, v) => sum + v.dailyRate);

      stats = DashboardStats(
        greeting: 'Welcome,',
        hostName: hostProfile?.firstName.isNotEmpty == true
            ? hostProfile!.firstName
            : 'Host Partner',
        totalRevenue: totalRevenue,
        revenueChangePercent: 0,
        pendingPayout: 0,
        payoutDate: 'Auto Transfer',
        activeRides: activeCount,
        totalVehicles: vehicles.length,
        occupancyPercent: vehicles.isEmpty ? 0 : ((activeCount / vehicles.length) * 100),
        nextHandover: nextHandover,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> startTripHandover({
    required String tripId,
    required String token,
    required double hostLat,
    required double hostLng,
  }) async {
    try {
      await HostService.startHandover(
        tripId: tripId,
        token: token,
        hostLat: hostLat,
        hostLng: hostLng,
      );
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ProfileController extends ChangeNotifier {
  ProfileController(this._repo);
  final HostRepository _repo;

  HostProfile? profile;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      profile = await _repo.fetchProfile();
    } catch (e) {
      LoggerService.error('Failed to load profile', error: e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, dynamic> payload) async {
    loading = true;
    notifyListeners();
    try {
      profile = await _repo.saveProfile(payload);
      return true;
    } catch (_) {
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._repo);
  final OnboardingRepository _repo;

  // Body/Class Types list
  List<String> bodyTypes = [
    'Sedan',
    'SUV',
    'Electric',
    'Hatchback',
    'Sports Car',
    'Luxury',
    'Convertible',
  ];

  // Complete List of All 34 Indian States & Union Territories
  static const List<String> allIndianStates = [
    'KA - Karnataka',
    'MH - Maharashtra',
    'DL - Delhi NCR',
    'TN - Tamil Nadu',
    'TS - Telangana',
    'HR - Haryana',
    'UP - Uttar Pradesh',
    'GJ - Gujarat',
    'RJ - Rajasthan',
    'MP - Madhya Pradesh',
    'WB - West Bengal',
    'AP - Andhra Pradesh',
    'KL - Kerala',
    'PB - Punjab',
    'UK - Uttarakhand',
    'BR - Bihar',
    'CG - Chhattisgarh',
    'GA - Goa',
    'HP - Himachal Pradesh',
    'JK - Jammu & Kashmir',
    'JH - Jharkhand',
    'OR - Odisha',
    'TR - Tripura',
    'AS - Assam',
    'MN - Manipur',
    'ML - Meghalaya',
    'MZ - Mizoram',
    'NL - Nagaland',
    'SK - Sikkim',
    'PY - Puducherry',
    'CH - Chandigarh',
    'AN - Andaman & Nicobar',
    'DN - Dadra & Nagar Haveli',
    'LA - Ladakh',
  ];

  // Vehicle listing draft fields
  String createdVehicleId = '';
  String bodyType = 'Sedan';
  String make = '';
  String model = '';
  String year = DateTime.now().year.toString();
  String transmission = 'Automatic';
  String plate = '';
  String plateState = 'KA - Karnataka';
  String pincode = '';
  double dailyRate = 0; // in Rupees
  double hourlyRate = 0; // in Rupees
  bool hourlyRentals = false;
  bool hostDelivery = false;
  String pickupAddress = '';

  // 3 Mandatory Vehicle Listing Photo Slots (Front/Cover, Interior, Rear)
  String frontPhotoUrl = '';      // Front Angle (COVER) - Mandatory
  String? frontPhotoLocalPath;

  String interiorPhotoUrl = '';   // Interior / Cockpit - Mandatory
  String? interiorPhotoLocalPath;

  String rearPhotoUrl = '';       // Rear & Trunk - Mandatory
  String? rearPhotoLocalPath;

  List<String> additionalPhotoUrls = []; // Extra angles up to 8 total
  List<String> additionalPhotoLocalPaths = [];

  List<String> get photoUrls {
    final list = <String>[];
    if (frontPhotoUrl.isNotEmpty) list.add(frontPhotoUrl);
    if (interiorPhotoUrl.isNotEmpty) list.add(interiorPhotoUrl);
    if (rearPhotoUrl.isNotEmpty) list.add(rearPhotoUrl);
    list.addAll(additionalPhotoUrls);
    return list;
  }

  bool get hasThreeMandatoryPhotos =>
      (frontPhotoUrl.isNotEmpty || (frontPhotoLocalPath != null && frontPhotoLocalPath!.isNotEmpty)) &&
      (interiorPhotoUrl.isNotEmpty || (interiorPhotoLocalPath != null && interiorPhotoLocalPath!.isNotEmpty)) &&
      (rearPhotoUrl.isNotEmpty || (rearPhotoLocalPath != null && rearPhotoLocalPath!.isNotEmpty));

  int get mandatoryPhotosCount =>
      ((frontPhotoUrl.isNotEmpty || (frontPhotoLocalPath != null && frontPhotoLocalPath!.isNotEmpty)) ? 1 : 0) +
      ((interiorPhotoUrl.isNotEmpty || (interiorPhotoLocalPath != null && interiorPhotoLocalPath!.isNotEmpty)) ? 1 : 0) +
      ((rearPhotoUrl.isNotEmpty || (rearPhotoLocalPath != null && rearPhotoLocalPath!.isNotEmpty)) ? 1 : 0);

  // Map storing uploaded legal document URLs ('RC', 'HOST_DL', 'INSURANCE', 'POLLUTION')
  Map<String, String> uploadedDocUrls = {};

  DocumentStatusChecklist? documentChecklist;
  List<VehicleDocument> get documents => (documentChecklist?.documents ?? [])
      .where((doc) => doc.type.toUpperCase() != 'DL' && doc.type.toUpperCase() != 'HOST_DL')
      .toList();
  bool documentsLoading = false;

  bool saving = false;
  bool uploadingPhoto = false;
  bool uploadingDoc = false;
  bool pincodeLoading = false;
  bool verifyingUpi = false;
  bool upiVerified = false;
  String? upiRegisteredName;
  String? lastError;
  SubmitVehicleResult? submitResult;

  void setBodyType(String v) {
    bodyType = v;
    notifyListeners();
  }

  void addCustomBodyType(String customType) {
    final clean = customType.trim();
    if (clean.isNotEmpty) {
      if (!bodyTypes.contains(clean)) {
        bodyTypes.add(clean);
      }
      bodyType = clean;
      notifyListeners();
      ToastService.showSuccess('Custom vehicle class "$clean" added and selected!');
    }
  }

  void setHourlyRentals(bool v) {
    hourlyRentals = v;
    notifyListeners();
  }

  void setHourlyRate(double rate) {
    hourlyRate = rate;
    notifyListeners();
  }

  double get effectiveHourlyRate =>
      hourlyRate > 0 ? hourlyRate : (dailyRate > 0 ? (dailyRate / 10).roundToDouble() : 299);

  double get estimatedHourlyTrip => effectiveHourlyRate * 3;

  void setFrontPhoto(String url) {
    frontPhotoUrl = url.trim();
    notifyListeners();
  }

  void setInteriorPhoto(String url) {
    interiorPhotoUrl = url.trim();
    notifyListeners();
  }

  void setRearPhoto(String url) {
    rearPhotoUrl = url.trim();
    notifyListeners();
  }

  void removeFrontPhoto() {
    frontPhotoUrl = '';
    frontPhotoLocalPath = null;
    notifyListeners();
  }

  void removeInteriorPhoto() {
    interiorPhotoUrl = '';
    interiorPhotoLocalPath = null;
    notifyListeners();
  }

  void removeRearPhoto() {
    rearPhotoUrl = '';
    rearPhotoLocalPath = null;
    notifyListeners();
  }

  void addAdditionalPhoto(String url, {String? localPath}) {
    final clean = url.trim();
    if (clean.isNotEmpty) {
      if (additionalPhotoUrls.length < 5) {
        additionalPhotoUrls.add(clean);
        if (localPath != null && localPath.isNotEmpty) {
          additionalPhotoLocalPaths.add(localPath);
        }
        notifyListeners();
      } else {
        ToastService.showWarning('Maximum 8 total vehicle photos allowed');
      }
    }
  }

  void removeAdditionalPhoto(int index) {
    if (index >= 0 && index < additionalPhotoUrls.length) {
      additionalPhotoUrls.removeAt(index);
      if (index < additionalPhotoLocalPaths.length) {
        additionalPhotoLocalPaths.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setHostDelivery(bool v) {
    hostDelivery = v;
    notifyListeners();
  }

  void resetVehicleDraft() {
    createdVehicleId = '';
    bodyType = 'Sedan';
    make = '';
    model = '';
    year = DateTime.now().year.toString();
    transmission = 'Automatic';
    plate = '';
    plateState = 'KA - Karnataka';
    pincode = '';
    dailyRate = 0;
    hourlyRate = 0;
    hourlyRentals = false;
    hostDelivery = false;
    pickupAddress = '';
    frontPhotoUrl = '';
    frontPhotoLocalPath = null;
    interiorPhotoUrl = '';
    interiorPhotoLocalPath = null;
    rearPhotoUrl = '';
    rearPhotoLocalPath = null;
    additionalPhotoUrls = [];
    additionalPhotoLocalPaths = [];
    uploadedDocUrls = {};
    documentChecklist = null;
    notifyListeners();
  }

  double get estimatedMonthly => dailyRate * 22;

  /// Pincode Lookup API (https://api.postalpincode.in/pincode/$pin)
  Future<bool> fetchAddressFromPincode(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.length != 6) {
      ToastService.showWarning('Please enter a valid 6-digit Pincode');
      return false;
    }

    pincodeLoading = true;
    pincode = cleanPin;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$cleanPin'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final po = postOffices.first;
            final name = po['Name'] ?? '';
            final district = po['District'] ?? '';
            final state = po['State'] ?? '';

            pickupAddress = '$name, $district, $state - $cleanPin';

            final matchedState = allIndianStates.firstWhere(
              (s) => s.toLowerCase().contains(state.toLowerCase()),
              orElse: () => plateState,
            );
            plateState = matchedState;

            ToastService.showSuccess('Location fetched: $district, $state');
            notifyListeners();
            return true;
          }
        }
      }
      ToastService.showWarning('Pincode location not found. Please enter address manually.');
      return false;
    } catch (e) {
      LoggerService.error('Pincode fetch error', error: e);
      return false;
    } finally {
      pincodeLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadVehiclePhoto(File file, {String? slot}) async {
    // 1. Immediately set local path so the UI previews the chosen photo with 0ms latency
    if (slot == 'FRONT') {
      frontPhotoLocalPath = file.path;
    } else if (slot == 'INTERIOR') {
      interiorPhotoLocalPath = file.path;
    } else if (slot == 'REAR') {
      rearPhotoLocalPath = file.path;
    } else {
      if (frontPhotoLocalPath == null && frontPhotoUrl.isEmpty) {
        frontPhotoLocalPath = file.path;
      } else if (interiorPhotoLocalPath == null && interiorPhotoUrl.isEmpty) {
        interiorPhotoLocalPath = file.path;
      } else if (rearPhotoLocalPath == null && rearPhotoUrl.isEmpty) {
        rearPhotoLocalPath = file.path;
      } else {
        additionalPhotoLocalPaths.add(file.path);
      }
    }

    uploadingPhoto = true;
    notifyListeners();
    try {
      final String category = slot == 'FRONT'
          ? 'COVER'
          : slot == 'INTERIOR'
              ? 'INTERIOR'
              : slot == 'REAR'
                  ? 'REAR_TRUNK'
                  : 'OTHER';

      final String url;
      if (createdVehicleId.isNotEmpty) {
        url = await HostService.uploadVehiclePhotoGcs(
          vehicleId: createdVehicleId,
          imageFile: file,
          category: category,
        );
      } else {
        url = await HostService.uploadImageToGcs(file);
      }

      // 2. Register with in-memory image cache
      AppImageCache.register(url, file.path);

      if (slot == 'FRONT') {
        frontPhotoUrl = url;
      } else if (slot == 'INTERIOR') {
        interiorPhotoUrl = url;
      } else if (slot == 'REAR') {
        rearPhotoUrl = url;
      } else {
        if (frontPhotoUrl.isEmpty) {
          frontPhotoUrl = url;
        } else if (interiorPhotoUrl.isEmpty) {
          interiorPhotoUrl = url;
        } else if (rearPhotoUrl.isEmpty) {
          rearPhotoUrl = url;
        } else {
          addAdditionalPhoto(url, localPath: file.path);
        }
      }
      notifyListeners();
      return url;
    } catch (e) {
      ToastService.showError('Photo upload failed: $e');
      return null;
    } finally {
      uploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<String?> uploadDocumentFile(String docType, File file) async {
    uploadingDoc = true;
    notifyListeners();
    try {
      final String url;
      if (createdVehicleId.isNotEmpty) {
        url = await HostService.uploadVehicleDocumentGcs(
          vehicleId: createdVehicleId,
          file: file,
          docType: docType,
        );
      } else {
        url = await HostService.uploadImageToGcs(file);
      }

      uploadedDocUrls[docType] = url;
      ToastService.showSuccess('$docType uploaded successfully to Google Cloud Storage!');
      notifyListeners();
      return url;
    } catch (e) {
      ToastService.showError('$docType upload failed: $e');
      return null;
    } finally {
      uploadingDoc = false;
      notifyListeners();
    }
  }

  void saveUploadedDocUrl(String docType, String url) {
    uploadedDocUrls[docType] = url.trim();
    notifyListeners();
  }

  void addPhotoUrl(String url, {String? slot}) {
    final clean = url.trim();
    if (clean.isNotEmpty) {
      if (slot == 'FRONT') {
        frontPhotoUrl = clean;
      } else if (slot == 'INTERIOR') {
        interiorPhotoUrl = clean;
      } else if (slot == 'REAR') {
        rearPhotoUrl = clean;
      } else {
        if (frontPhotoUrl.isEmpty) {
          frontPhotoUrl = clean;
        } else if (interiorPhotoUrl.isEmpty) {
          interiorPhotoUrl = clean;
        } else if (rearPhotoUrl.isEmpty) {
          rearPhotoUrl = clean;
        } else {
          addAdditionalPhoto(clean);
        }
      }
      notifyListeners();
    }
  }

  void removePhotoUrl(int index) {
    final all = photoUrls;
    if (index >= 0 && index < all.length) {
      final target = all[index];
      if (target == frontPhotoUrl) {
        frontPhotoUrl = '';
      } else if (target == interiorPhotoUrl) {
        interiorPhotoUrl = '';
      } else if (target == rearPhotoUrl) {
        rearPhotoUrl = '';
      } else {
        additionalPhotoUrls.remove(target);
      }
      notifyListeners();
    }
  }

  Future<bool> verifyListingFee({
    required String vehicleId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    saving = true;
    notifyListeners();
    try {
      await _repo.verifyListingFeePayment(
        vehicleId,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      await loadDocuments(vehicleId);
      ToastService.showSuccess('Listing fee verified! Vehicle moved to review.');
      return true;
    } catch (e) {
      lastError = e.toString();
      ToastService.showError('Listing fee verification failed: $e');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> submitListing() async {
    if (make.trim().isEmpty || model.trim().isEmpty) {
      ToastService.showWarning('Please enter vehicle Make and Model');
      return false;
    }
    final currentYear = DateTime.now().year;
    final yearInt = int.tryParse(year.trim()) ?? currentYear;
    if (yearInt < 1990 || yearInt > currentYear + 1) {
      ToastService.showWarning('Please enter a valid 4-digit manufacturing year (1990 - ${currentYear + 1})');
      return false;
    }
    if (plate.trim().isEmpty) {
      ToastService.showWarning('Please enter vehicle Registration Plate number');
      return false;
    }
    if (dailyRate <= 0) {
      ToastService.showWarning('Please enter a valid daily rental rate in ₹');
      return false;
    }
    if (pickupAddress.trim().isEmpty) {
      ToastService.showWarning('Please enter vehicle pickup address or pincode');
      return false;
    }

    if (!hasThreeMandatoryPhotos) {
      ToastService.showWarning(
          'Please upload all 3 mandatory photos: Front Angle (Cover), Interior / Cockpit, and Rear & Trunk.');
      return false;
    }

    saving = true;
    lastError = null;
    notifyListeners();
    try {
      final ratePaise = (dailyRate * 100).round();
      final validPhotos = photoUrls.where((u) => u.startsWith('http')).toList();

      final payload = <String, dynamic>{
        'make': make.trim(),
        'model': model.trim(),
        'year': yearInt,
        'body_type': bodyType,
        'transmission': transmission.trim().isEmpty ? 'Automatic' : transmission.trim(),
        'registration_number': '${plateState.split(' - ').first} ${plate.trim().toUpperCase()}',
        'name': '${make.trim()} ${model.trim()}',
        'description': 'Host vehicle listed on AYO platform.',
        'daily_rate': ratePaise,
        'weekend_daily_rate': (ratePaise * 1.2).round(),
        'hourly_rate': hourlyRentals ? (ratePaise / 10).round() : 0,
        'lat': 12.9716,
        'lng': 77.5946,
        'address': pickupAddress.trim(),
        'photos': validPhotos,
        'instant_unlock': true,
        'delivery_available': hostDelivery,
        'delivery_fee': hostDelivery ? 50000 : 0,
        'km_limit_per_day': 250,
        'extra_km_fee': 2500,
        'smoking_allowed': false,
        'pets_allowed': true,
        'return_condition_note': 'Return with minimum 20% fuel/charge.',
      };

      final result = await _repo.createVehicleListing(payload);
      if (result.containsKey('id')) {
        createdVehicleId = result['id'].toString();

        // Confirm vehicle documents with backend (RC, INSURANCE, POLLUTION only - DL is on Host Profile)
        for (final entry in uploadedDocUrls.entries) {
          if (entry.key.toUpperCase() == 'DL' || entry.key.toUpperCase() == 'HOST_DL') continue;
          await confirmDocument(
            vehicleId: createdVehicleId,
            type: entry.key,
            url: entry.value,
          );
        }

        // Fetch document status checklist
        await loadDocuments(createdVehicleId);

        // Submit vehicle for admin review or prepare listing fee gate
        submitResult = await _repo.submitVehicleForReview(createdVehicleId);
        if (submitResult?.listingFeeRequired == true) {
          lastError = 'LISTING_FEE_REQUIRED';
          return true;
        }

        ToastService.showSuccess('Vehicle submitted for review! Check fleet status on Dashboard.');
        return true;
      }

      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> loadDocuments([String? vId]) async {
    final vehicleId = vId ?? createdVehicleId;
    if (vehicleId.isEmpty) return;

    documentsLoading = true;
    notifyListeners();
    try {
      documentChecklist = await _repo.fetchDocumentStatus(vehicleId);
    } catch (e) {
      LoggerService.error('Failed loading vehicle document checklist', error: e);
    } finally {
      documentsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmDocument({
    required String vehicleId,
    required String type,
    required String url,
    String? fileName,
    int? fileSizeBytes,
    String? expiryDate,
  }) async {
    saving = true;
    notifyListeners();
    try {
      await _repo.confirmDocument(
        vehicleId: vehicleId,
        type: type,
        url: url,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        expiryDate: expiryDate,
      );
      uploadedDocUrls[type] = url;
      await loadDocuments(vehicleId);
      return true;
    } catch (e) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> submitVehicleForReview([String? vId]) async {
    final vehicleId = vId ?? createdVehicleId;
    if (vehicleId.isEmpty) {
      ToastService.showError('Vehicle ID missing. Please create vehicle first.');
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      await loadDocuments(vehicleId);
      submitResult = await _repo.submitVehicleForReview(vehicleId);
      await loadDocuments(vehicleId);

      if (submitResult?.listingFeeRequired == true) {
        lastError = 'LISTING_FEE_REQUIRED';
        return true;
      }

      ToastService.showSuccess('Vehicle submitted for Admin Review!');
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> submitDocuments([String? vId]) => submitVehicleForReview(vId);

  Future<bool> verifyUpi(String upiId, [String? expectedName]) async {
    if (upiId.trim().isEmpty) {
      ToastService.showWarning('Please enter a UPI ID');
      return false;
    }

    verifyingUpi = true;
    upiVerified = false;
    upiRegisteredName = null;
    notifyListeners();
    try {
      final res = await HostService.verifyUpiId(
        upiId: upiId.trim(),
        expectedName: expectedName,
      );
      upiVerified = res.valid;
      upiRegisteredName = res.registeredName;
      return upiVerified;
    } catch (e) {
      upiVerified = false;
      return false;
    } finally {
      verifyingUpi = false;
      notifyListeners();
    }
  }
}
