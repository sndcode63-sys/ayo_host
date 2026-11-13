import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/services/location_service.dart';
import '../core/services/logger_service.dart';
import '../core/services/push_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/services/toast_service.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/host_service.dart';
import '../data/services/notification_service.dart';
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

  String? currentPhone;
  bool isCodeSent = false;

  String? get userPhone => user?.phone ?? host?.phone ?? currentPhone;
  String? get userEmail => user?.email ?? host?.email;

  Future<void> checkSession() async {
    final isAuth = await _repo.isAuthenticated();
    if (isAuth) {
      final role = await SecureStorageService.getUserRole();
      if (role?.toUpperCase() == 'CUSTOMER') {
        await _repo.logout();
        user = null;
        host = null;
        onboardingStatus = null;
        notifyListeners();
        return;
      }
      try {
        user = await _repo.getAuthMe();
        if (user?.role.toUpperCase() == 'CUSTOMER') {
          await _repo.logout();
          user = null;
          host = null;
          onboardingStatus = null;
          notifyListeners();
          return;
        }
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
        notifyListeners();
      } catch (_) {}
    }
  }

  /// 1. Send 6-digit OTP via MSG91 (POST /api/v1/auth/send-otp)
  Future<bool> sendPhoneOtp(String rawPhone) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final clean = rawPhone.replaceAll(RegExp(r'\D'), '');
      final tenDigit = clean.length > 10 && clean.startsWith('91')
          ? clean.substring(clean.length - 10)
          : clean;

      currentPhone = tenDigit;
      final ok = await _repo.sendOtp(phone: tenDigit, role: 'HOST');
      isCodeSent = ok;
      return ok;
    } catch (e) {
      error = e.toString();
      ToastService.showError('Failed to send OTP: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 2. Verify 6-digit OTP via AYO Backend (POST /api/v1/auth/verify-otp)
  Future<bool> verifyOtpCode(String smsCode, [String? name]) async {
    final phone = currentPhone;
    if (phone == null || phone.isEmpty) {
      error = 'Mobile number missing. Please enter your mobile number.';
      ToastService.showError(error!);
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await _repo.verifyOtp(
        phone: phone,
        otp: smsCode.trim(),
        role: 'HOST',
        name: name,
      );

      user = authResponse.user;

      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {}

      return true;
    } catch (e) {
      error = e.toString();
      final errStr = e.toString();
      if (errStr.contains('already registered as a Customer')) {
        ToastService.showError('This mobile number is already registered for Customer. Please use a Host account or register with a different number.');
      } else {
        ToastService.showError('Invalid OTP code. Please check and retry.');
      }
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 3. Resend / Retry OTP via SMS ('text') or Voice Call ('voice') (POST /api/v1/auth/retry-otp)
  Future<bool> retryPhoneOtp({bool viaVoice = false}) async {
    final phone = currentPhone;
    if (phone == null || phone.isEmpty) {
      ToastService.showError('Mobile number missing.');
      return false;
    }

    loading = true;
    notifyListeners();

    try {
      return await _repo.retryOtp(phone: phone, viaVoice: viaVoice);
    } catch (e) {
      ToastService.showError('Retry failed: $e');
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



  Future<void> signOut() async {
    await _repo.logout();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    user = null;
    host = null;
    onboardingStatus = null;
    isCodeSent = false;
    currentPhone = null;
    notifyListeners();
  }
}

class DashboardController extends ChangeNotifier {
  DashboardController(this._repo);
  final HostRepository _repo;

  DashboardStats? stats;
  List<Vehicle> vehicles = [];
  List<Trip> upcomingTrips = [];
  List<Trip> activeTrips = [];
  HostProfile? hostProfile;
  SupportConfig? supportConfig;
  PlatformPolicies? platformPolicies;
  OnboardingStatus? onboardingStatus;
  PaymentsConfig? paymentsConfig;
  bool loading = false;
  String? error;

  void reset() {
    stats = null;
    vehicles = [];
    upcomingTrips = [];
    activeTrips = [];
    hostProfile = null;
    supportConfig = null;
    platformPolicies = null;
    onboardingStatus = null;
    paymentsConfig = null;
    loading = false;
    error = null;
    notifyListeners();
  }

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
            phone: '',
            email: '',
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
            keyId: '',
            currency: 'INR',
            name: 'AYO Host Platform',
            description: 'Host Listing & Verification Payment',
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
      activeTrips = await TripsService.getActiveTrips();

      EarningsStats? earnings;
      try {
        earnings = await HostService.getEarnings();
      } catch (e) {
        LoggerService.info('Earnings unavailable for dashboard: $e');
      }

      Handover? nextHandover;
      if (upcomingTrips.isNotEmpty) {
        final firstTrip = upcomingTrips.first;
        final matchingVehicle = vehicles.where((v) => v.id == firstTrip.vehicleId).firstOrNull;
        final handoverLoc = (matchingVehicle?.address?.isNotEmpty == true)
            ? matchingVehicle!.address!
            : (matchingVehicle?.name ?? firstTrip.vehicle);
        nextHandover = Handover(
          tripId: firstTrip.id,
          vehicleName: firstTrip.vehicle,
          guestName: firstTrip.customer.name,
          timeLabel: DateFormat('MMM dd, hh:mm a').format(firstTrip.startTime),
          location: handoverLoc,
          countdown: _countdownLabel(firstTrip.startTime),
        );
      }

      final activeCount = vehicles.where((v) => v.status == 'ACTIVE' || v.status == 'ON_TRIP').length;

      stats = DashboardStats(
        greeting: 'Welcome back,',
        hostName: hostProfile?.firstName.isNotEmpty == true
            ? hostProfile!.firstName
            : '',
        totalRevenue: earnings?.total ?? 0,
        revenueChangePercent: earnings?.changePercent ?? 0,
        pendingPayout: earnings?.pendingPayout ?? 0,
        payoutDate: '',
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

  /// QR handover scan via POST /trips/scan-handover
  Future<bool> scanDirectHandover({
    required String handoverToken,
    double? hostLat,
    double? hostLng,
  }) async {
    try {
      var lat = hostLat;
      var lng = hostLng;
      if (lat == null || lng == null) {
        final pos = await LocationService.currentPosition();
        if (pos != null) {
          lat = pos.lat;
          lng = pos.lng;
        }
      }
      await HostService.scanHandover(
        handoverToken: handoverToken,
        hostLat: lat,
        hostLng: lng,
      );
      await load();
      return true;
    } catch (e) {
      ToastService.showError(HostService.tripErrorMessage(e));
      return false;
    }
  }

  // ─────────── Trip end / cancel ───────────
  /// Last end-trip response's `late_return` (null = on time). UI reads this to show the late fee.
  Map<String, dynamic>? lastLateReturn;

  static String _countdownLabel(DateTime start) {
    final diff = start.toLocal().difference(DateTime.now());
    if (diff.isNegative) return 'Due now';
    if (diff.inDays >= 1) return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'in ${diff.inMinutes}m';
  }

  Future<bool> endTrip(String tripId) async {
    lastLateReturn = null;
    try {
      final res = await HostService.endTrip(tripId);
      final late = res['late_return'];
      if (late is Map) {
        lastLateReturn = Map<String, dynamic>.from(late);
        ToastService.showWarning(late['message']?.toString() ?? 'Trip completed – late return');
      } else {
        ToastService.showSuccess('Trip completed.');
      }
      await load();
      return true;
    } catch (e) {
      ToastService.showError(HostService.tripErrorMessage(e));
      return false;
    }
  }

  Future<bool> cancelTrip(String tripId, String reason) async {
    try {
      await HostService.cancelTrip(tripId, reason);
      ToastService.showSuccess('Trip cancelled.');
      await load();
      return true;
    } catch (e) {
      ToastService.showError(HostService.tripErrorMessage(e));
      return false;
    }
  }

  // ─────────── Vehicle remote controls ───────────
  final Set<String> busyVehicleIds = {};
  bool isBusy(String id) => busyVehicleIds.contains(id);

  Future<void> _runVehicleAction(String id, Future<void> Function() action) async {
    if (busyVehicleIds.contains(id)) return;
    busyVehicleIds.add(id);
    notifyListeners();
    try {
      await action();
      await load();
    } catch (e) {
      ToastService.showError('Action failed: $e');
    } finally {
      busyVehicleIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> lockVehicle(String id) => _runVehicleAction(id, () async {
        final ok = await HostService.lockVehicle(id);
        ok ? ToastService.showSuccess('Car locked') : ToastService.showError('Lock failed');
      });

  Future<void> unlockVehicle(String id) => _runVehicleAction(id, () async {
        final ok = await HostService.unlockVehicle(id);
        ok ? ToastService.showSuccess('Car unlocked') : ToastService.showError('Unlock failed');
      });

  Future<void> toggleVehicleStatus(String id) => _runVehicleAction(id, () async {
        final status = await HostService.toggleVehicleStatus(id);
        ToastService.showSuccess(status == 'PAUSED' ? 'Listing paused' : 'Listing resumed');
      });
}

class ProfileController extends ChangeNotifier {
  ProfileController(this._repo);
  final HostRepository _repo;

  HostProfile? profile;
  bool loading = false;

  void reset() {
    profile = null;
    loading = false;
    notifyListeners();
  }

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

  // Car vs Bike body types
  static const List<String> carBodyTypes = [
    'Sedan',
    'SUV',
    'Electric',
    'Hatchback',
    'Sports Car',
    'Luxury',
    'Convertible',
  ];

  static const List<String> bikeBodyTypes = [
    'Cruiser Bike',
    'Sports Bike',
    'Scooter',
    'Commuter',
    'Touring / Adventure',
    'Electric Scooter',
    'Cafe Racer',
  ];

  // Active Body/Class Types list
  List<String> bodyTypes = List.from(carBodyTypes);

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
  String vehicleType = 'CAR'; // 'CAR' or 'BIKE'
  String bodyType = 'Sedan';
  String make = '';
  String model = '';
  String year = DateTime.now().year.toString();
  String transmission = 'Automatic';
  String plate = '';
  String plateState = '';
  String pincode = '';
  double dailyRate = 0; // in Rupees
  double hourlyRate = 0; // in Rupees
  bool hourlyRentals = false;
  bool hostDelivery = false;
  String pickupAddress = '';
  double? pickupLat;
  double? pickupLng;
  bool locationLoading = false;
  double weekendRate = 0; // in Rupees, 0 = auto (1.2x daily)
  int seatingCapacity = 5;
  String mileage = '';
  String drivetrain = '2WD';
  String fuelType = 'Petrol';

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

  void setVehicleType(String type) {
    final clean = type.trim().toUpperCase() == 'BIKE' ? 'BIKE' : 'CAR';
    if (vehicleType == clean) return;
    vehicleType = clean;
    if (clean == 'BIKE') {
      bodyTypes = List.from(bikeBodyTypes);
      bodyType = 'Cruiser Bike';
      seatingCapacity = 2;
      transmission = 'Manual';
      drivetrain = 'Chain Drive';
      fuelType = 'Petrol';
    } else {
      bodyTypes = List.from(carBodyTypes);
      bodyType = 'Sedan';
      seatingCapacity = 5;
      transmission = 'Automatic';
      drivetrain = '2WD';
      fuelType = 'Petrol';
    }
    notifyListeners();
  }

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
      hourlyRate > 0 ? hourlyRate : (dailyRate > 0 ? (dailyRate / 10).roundToDouble() : 0);

  // Minimum rental duration is 6 hours
  double get estimatedHourlyTrip => effectiveHourlyRate > 0 ? effectiveHourlyRate * 6 : 0;

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

  Future<void> removeFrontPhoto() async {
    final oldUrl = frontPhotoUrl;
    frontPhotoUrl = '';
    frontPhotoLocalPath = null;
    notifyListeners();
    if (createdVehicleId.isNotEmpty && oldUrl.isNotEmpty) {
      await HostService.deleteVehiclePhoto(
        vehicleId: createdVehicleId,
        photoUrl: oldUrl,
        category: 'COVER',
      );
    }
  }

  Future<void> removeInteriorPhoto() async {
    final oldUrl = interiorPhotoUrl;
    interiorPhotoUrl = '';
    interiorPhotoLocalPath = null;
    notifyListeners();
    if (createdVehicleId.isNotEmpty && oldUrl.isNotEmpty) {
      await HostService.deleteVehiclePhoto(
        vehicleId: createdVehicleId,
        photoUrl: oldUrl,
        category: 'INTERIOR',
      );
    }
  }

  Future<void> removeRearPhoto() async {
    final oldUrl = rearPhotoUrl;
    rearPhotoUrl = '';
    rearPhotoLocalPath = null;
    notifyListeners();
    if (createdVehicleId.isNotEmpty && oldUrl.isNotEmpty) {
      await HostService.deleteVehiclePhoto(
        vehicleId: createdVehicleId,
        photoUrl: oldUrl,
        category: 'REAR',
      );
    }
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

  Future<void> removeAdditionalPhoto(int index) async {
    if (index >= 0 && index < additionalPhotoUrls.length) {
      final oldUrl = additionalPhotoUrls[index];
      additionalPhotoUrls.removeAt(index);
      if (index < additionalPhotoLocalPaths.length) {
        additionalPhotoLocalPaths.removeAt(index);
      }
      notifyListeners();
      if (createdVehicleId.isNotEmpty && oldUrl.isNotEmpty) {
        await HostService.deleteVehiclePhoto(
          vehicleId: createdVehicleId,
          photoUrl: oldUrl,
        );
      }
    }
  }

  void setHostDelivery(bool v) {
    hostDelivery = v;
    notifyListeners();
  }

  void resetVehicleDraft() {
    createdVehicleId = '';
    submitResult = null;
    lastError = null;
    saving = false;
    uploadingPhoto = false;
    documentsLoading = false;
    vehicleType = 'CAR';
    bodyTypes = List.from(carBodyTypes);
    bodyType = 'Sedan';
    make = '';
    model = '';
    year = DateTime.now().year.toString();
    transmission = 'Automatic';
    plate = '';
    plateState = '';
    pincode = '';
    dailyRate = 0;
    hourlyRate = 0;
    hourlyRentals = false;
    hostDelivery = false;
    pickupAddress = '';
    pickupLat = null;
    pickupLng = null;
    weekendRate = 0;
    seatingCapacity = 5;
    mileage = '';
    drivetrain = '2WD';
    fuelType = 'Petrol';
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

  /// Auto-detect pickup location from device GPS (address + pincode + coordinates).
  /// [onlyIfEmpty] keeps anything the host already typed.
  Future<bool> autoFetchCurrentLocation({bool silent = false}) async {
    if (locationLoading) return false;
    locationLoading = true;
    notifyListeners();
    try {
      final p = await LocationService.currentPlace();
      if (p == null) {
        if (!silent) {
          ToastService.showWarning('Location unavailable. Enable GPS/permission or enter pincode manually.');
        }
        return false;
      }
      pickupLat = p.lat;
      pickupLng = p.lng;
      if (p.pincode.isNotEmpty) pincode = p.pincode;
      if (p.address.isNotEmpty) pickupAddress = p.address;
      if (!silent) ToastService.showSuccess('Current location fetched');
      return true;
    } finally {
      locationLoading = false;
      notifyListeners();
    }
  }

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
            final g = await LocationService.geocodeAddress('$name, $district, $state, $cleanPin, India');
            pickupLat = g?.lat;
            pickupLng = g?.lng;
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
      if (createdVehicleId.isNotEmpty) {
        VehiclePhotosCache.set(createdVehicleId, photoUrls);
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

    // Resolve pickup coordinates: saved (GPS / pincode) -> geocode typed address -> device GPS.
    double? lat = pickupLat;
    double? lng = pickupLng;
    if (lat == null || lng == null) {
      final g = await LocationService.geocodeAddress('$pickupAddress $pincode India');
      lat = g?.lat;
      lng = g?.lng;
    }
    if (lat == null || lng == null) {
      final pos = await LocationService.currentPosition();
      lat = pos?.lat;
      lng = pos?.lng;
    }
    if (lat == null || lng == null) {
      ToastService.showWarning('Could not locate the pickup address. Tap "Use current location" or enter a valid pincode.');
      return false;
    }

    saving = true;
    lastError = null;
    notifyListeners();
    try {
      final ratePaise = (dailyRate * 100).round();
      final validPhotos = photoUrls.where((u) => u.startsWith('http')).toList();

      final payload = <String, dynamic>{
        'vehicle_type': vehicleType.toUpperCase(),
        'make': make.trim(),
        'model': model.trim(),
        'year': yearInt,
        'body_type': bodyType,
        'transmission': transmission.trim().isEmpty ? 'Automatic' : transmission.trim(),
        'registration_number': '${plateState.split(' - ').first} ${plate.trim().toUpperCase()}',
        'name': '${make.trim()} ${model.trim()}',
        'description': 'Host vehicle listed on AYO platform.',
        'daily_rate': dailyRate.toInt(),
        'daily_rate_inr': dailyRate.toInt(),
        'daily_rate_paise': ratePaise,
        'weekend_daily_rate': weekendRate > 0 ? weekendRate.toInt() : (dailyRate * 1.2).round(),
        'hourly_rate': hourlyRentals ? (hourlyRate > 0 ? hourlyRate.toInt() : (dailyRate / 10).round()) : 0,
        'hourly_rate_inr': hourlyRentals ? (hourlyRate > 0 ? hourlyRate.toInt() : (dailyRate / 10).round()) : 0,
        'lat': lat,
        'lng': lng,
        'location': {
          'lat': lat,
          'lng': lng,
          'address': pickupAddress.trim(),
        },
        'seating_capacity': seatingCapacity,
        'mileage': mileage.trim().isEmpty ? 'N/A' : mileage.trim(),
        'drivetrain': drivetrain,
        'fuel_type': fuelType,
        'address': pickupAddress.trim(),
        'photos': validPhotos,
        'cover_photo_url': frontPhotoUrl.isNotEmpty ? frontPhotoUrl : (validPhotos.isNotEmpty ? validPhotos.first : null),
        'photo_categories': {
          'cover': frontPhotoUrl,
          'interior': interiorPhotoUrl,
          'rear_trunk': rearPhotoUrl,
          'other': additionalPhotoUrls,
        },
        'instant_unlock': true,
        'delivery_available': hostDelivery,
        'delivery_fee': hostDelivery ? 500 : 0,
        'km_limit_per_day': 250,
        'extra_km_fee': 25,
        'smoking_allowed': false,
        'pets_allowed': true,
        'return_condition_note': 'Return with minimum 20% fuel/charge.',
      };

      if (createdVehicleId.isEmpty) {
        final result = await _repo.createVehicleListing(payload);
        if (result.containsKey('id')) {
          createdVehicleId = result['id'].toString();
        }
      }

      // CRITICAL: Always PATCH vehicle specs so make, model, name, year, daily_rate, location, plate are stored permanently on backend!
      if (createdVehicleId.isNotEmpty) {
        try {
          await _repo.updateVehicleListing(createdVehicleId, payload);
        } catch (e) {
          LoggerService.warning('Vehicle specs patch warning: $e');
        }
      }

      if (createdVehicleId.isNotEmpty) {
        // Batch confirm photos with official uppercase categories (COVER, INTERIOR, REAR_TRUNK, OTHER)
        try {
          final photosBatch = <Map<String, String>>[];
          if (frontPhotoUrl.isNotEmpty) photosBatch.add({'url': frontPhotoUrl, 'category': 'COVER'});
          if (interiorPhotoUrl.isNotEmpty) photosBatch.add({'url': interiorPhotoUrl, 'category': 'INTERIOR'});
          if (rearPhotoUrl.isNotEmpty) photosBatch.add({'url': rearPhotoUrl, 'category': 'REAR_TRUNK'});
          for (final u in additionalPhotoUrls) {
            if (u.isNotEmpty) photosBatch.add({'url': u, 'category': 'OTHER'});
          }
          if (photosBatch.isNotEmpty) {
            await HostService.confirmPhotosBatch(vehicleId: createdVehicleId, photos: photosBatch);
          }
          VehiclePhotosCache.set(createdVehicleId, photoUrls);
        } catch (_) {}

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

        if (submitResult?.missingDocuments.isNotEmpty == true) {
          lastError = 'MISSING_VEHICLE_DOCUMENTS';
          return false;
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

  Future<bool> deleteDocument({
    required String vehicleId,
    required String type,
  }) async {
    saving = true;
    notifyListeners();
    try {
      final ok = await HostService.deleteVehicleDocument(
        vehicleId: vehicleId,
        type: type,
      );
      uploadedDocUrls.remove(type);
      await loadDocuments(vehicleId);
      return ok;
    } catch (e) {
      LoggerService.warning('Failed deleting document $type: $e');
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


/// Notification inbox + unread badge.
class NotificationController extends ChangeNotifier {
  List<AppNotification> items = [];
  int unread = 0;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  String? error;
  int _page = 1;
  static const _limit = 20;

  final Set<String> _shownNotificationIds = <String>{};
  bool _initializedShownIds = false;

  void reset() {
    items = [];
    unread = 0;
    loading = false;
    loadingMore = false;
    hasMore = false;
    error = null;
    _page = 1;
    _shownNotificationIds.clear();
    _initializedShownIds = false;
    notifyListeners();
  }

  List<AppNotification> get unreadItems => items.where((e) => !e.isRead).toList();

  Future<void> refreshUnread() async {
    unread = items.where((e) => !e.isRead).length;
    notifyListeners();
  }

  /// Checks for new unread notifications and triggers system-level push notification banners
  Future<void> _notifyNewIncoming(List<AppNotification> fetchedItems) async {
    if (!_initializedShownIds) {
      _shownNotificationIds.addAll(await SecureStorageService.getShownNotificationIds());
      _initializedShownIds = true;
    }

    if (_shownNotificationIds.isEmpty) {
      final unreadList = fetchedItems.where((e) => !e.isRead).toList();
      for (final item in fetchedItems) {
        _shownNotificationIds.add(item.id);
      }
      if (unreadList.isNotEmpty) {
        final top = unreadList.first;
        await PushService.showLocalNotification(
          id: top.id.hashCode,
          title: top.title,
          body: top.body,
          payload: top.type,
        );
      }
      await SecureStorageService.markNotificationsShown(_shownNotificationIds);
      return;
    }

    final newlyArrived = <AppNotification>[];
    for (final item in fetchedItems) {
      if (!item.isRead && !_shownNotificationIds.contains(item.id)) {
        newlyArrived.add(item);
      }
    }

    if (newlyArrived.isNotEmpty) {
      for (final n in newlyArrived) {
        _shownNotificationIds.add(n.id);
        await PushService.showLocalNotification(
          id: n.id.hashCode,
          title: n.title,
          body: n.body,
          payload: n.type,
        );
      }
      await SecureStorageService.markNotificationsShown(newlyArrived.map((e) => e.id));
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final page = await NotificationService.list(page: 1, limit: _limit);
      items = page.items;
      hasMore = page.hasMore;
      _page = 1;
      await refreshUnread();
      await _notifyNewIncoming(page.items);
    } catch (e) {
      if (!silent) {
        error = 'Could not load notifications. Pull down to try again.';
      }
      LoggerService.error('Load notifications failed', error: e);
    } finally {
      if (!silent) {
        loading = false;
        notifyListeners();
      }
    }
  }

  /// Periodic background sync: checks API for new alerts and triggers push notifications
  Future<void> syncLatestNotifications() async {
    try {
      final page = await NotificationService.list(page: 1, limit: 10);
      if (page.items.isNotEmpty) {
        final existingIds = items.map((e) => e.id).toSet();
        final brandNew = page.items.where((e) => !existingIds.contains(e.id)).toList();
        if (brandNew.isNotEmpty) {
          items = [...brandNew, ...items];
          await refreshUnread();
        }
        await _notifyNewIncoming(page.items);
      }
    } catch (e) {
      LoggerService.info('Sync latest notifications note: $e');
    }
  }

  /// Adds a new in-app notification directly (e.g. from push or app event)
  void addNotification(AppNotification notif) {
    items = [notif, ...items.where((e) => e.id != notif.id)];
    if (!notif.isRead) {
      unread += 1;
    }
    _shownNotificationIds.add(notif.id);
    SecureStorageService.markNotificationsShown([notif.id]);
    PushService.showLocalNotification(
      id: notif.id.hashCode,
      title: notif.title,
      body: notif.body,
      payload: notif.type,
    );
    notifyListeners();
  }

  /// Delete notification from cloud backend and local tray (used by swipe-to-delete)
  Future<bool> delete(AppNotification n) async {
    final wasUnread = !n.isRead;
    items = items.where((e) => e.id != n.id).toList();
    if (wasUnread && unread > 0) {
      unread -= 1;
    }
    notifyListeners();

    try {
      final ok = await NotificationService.delete(n.id);
      return ok;
    } catch (e) {
      LoggerService.warning('Failed deleting notification ${n.id}: $e');
      return false;
    }
  }

  /// Delete all notifications from cloud backend and local tray
  Future<bool> clearAll() async {
    if (items.isEmpty) return true;
    final previousItems = List<AppNotification>.from(items);
    final previousUnread = unread;

    items = [];
    unread = 0;
    notifyListeners();

    try {
      final count = await NotificationService.clearAll();
      LoggerService.info('Cleared $count notifications from server');
      return true;
    } catch (e) {
      LoggerService.warning('Failed to clear notifications: $e');
      items = previousItems;
      unread = previousUnread;
      notifyListeners();
      return false;
    }
  }

  /// Triggers an in-app notification alert with sound and haptic vibration
  void triggerDemoAlert({
    String? title,
    String? body,
    String type = 'booking',
  }) {
    if (title == null || title.isEmpty) return;
    PushService.playAlertSound();
    final notif = AppNotification(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body ?? '',
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    items = [notif, ...items];
    unread += 1;
    PushService.showLocalNotification(
      title: notif.title,
      body: notif.body,
      payload: type,
    );
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || loading || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await NotificationService.list(page: _page + 1, limit: _limit);
      _page += 1;
      items = [...items, ...page.items];
      hasMore = page.hasMore;
    } catch (e) {
      LoggerService.error('Load more notifications failed', error: e);
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    final i = items.indexWhere((e) => e.id == n.id);
    if (i != -1) items[i] = n.copyWith(isRead: true);
    if (unread > 0) unread -= 1;
    notifyListeners();
    try {
      await NotificationService.markRead(n.id);
    } catch (e) {
      LoggerService.info('Remote markRead note: $e');
    }
  }

  Future<void> markAllRead() async {
    if (unread == 0 && items.every((e) => e.isRead)) return;
    items = items.map((e) => e.copyWith(isRead: true)).toList();
    unread = 0;
    notifyListeners();
    try {
      await NotificationService.markAllRead();
      ToastService.showSuccess('All notifications marked as read');
    } catch (e) {
      LoggerService.info('Remote markAllRead note: $e');
      ToastService.showSuccess('All notifications marked as read');
    }
  }
}

/// Earnings overview (`GET /host/earnings`).
class EarningsController extends ChangeNotifier {
  EarningsStats? stats;
  bool loading = false;
  String? error;

  void reset() {
    stats = null;
    loading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      stats = await HostService.getEarnings();
    } catch (e) {
      error = 'Could not load earnings. Check your connection and try again.';
      LoggerService.error('Load earnings failed', error: e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
