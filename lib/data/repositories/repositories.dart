import '../../core/config/api_config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/host_service.dart';

/// Auth + host profile calls.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<void> requestOtp(String phone) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _api.post('/auth/otp/request', data: {'phone': phone});
  }

  Future<HostProfile> verifyOtp(String phone, String code) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return MockData.host;
    }
    final res = await _api
        .post('/auth/otp/verify', data: {'phone': phone, 'code': code});
    return HostProfile.fromJson(res['host']);
  }

  Future<HostProfile> socialSignIn(String provider) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return MockData.host;
    }
    final res = await _api.post('/auth/social', data: {'provider': provider});
    return HostProfile.fromJson(res['host']);
  }

  Future<AuthResponse> exchangeFirebaseToken({
    required String idToken,
    String? role,
    bool consentAccepted = true,
    String consentVersion = '1.0',
  }) async {
    return await AuthService.exchangeFirebaseToken(
      idToken: idToken,
      role: role,
      consentAccepted: consentAccepted,
      consentVersion: consentVersion,
    );
  }

  Future<void> logout() async {
    await AuthService.logout();
  }

  Future<bool> isAuthenticated() async {
    return await AuthService.isAuthenticated();
  }
}

/// Dashboard stats + fleet.
class HostRepository {
  HostRepository(this._api);
  final ApiClient _api;

  Future<DashboardStats> fetchDashboard() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.dashboard;
    }
    final res = await _api.get(ApiConfig.dashboard);
    return DashboardStats.fromJson(res);
  }

  Future<List<Vehicle>> fetchVehicles() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockData.vehicles;
    }
    final res = await _api.get(ApiConfig.vehicles);
    return (res['items'] as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HostProfile> fetchProfile() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return MockData.host;
    }
    final res = await _api.get(ApiConfig.hostProfile);
    return HostProfile.fromJson(res);
  }

  Future<void> saveProfile(Map<String, dynamic> payload) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    await _api.put(ApiConfig.hostProfile, data: payload);
  }

  Future<AvatarPresignResponse> getAvatarPresignUrl({
    required String contentType,
  }) async {
    return await HostService.getAvatarPresignUrl(contentType: contentType);
  }

  Future<UpiVerificationResponse> verifyUpiId({
    required String upiId,
  }) async {
    return await HostService.verifyUpiId(upiId: upiId);
  }

  Future<KycResponse> savePayoutMethod({
    required String payoutMethod,
    String? upiId,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
  }) async {
    return await HostService.savePayoutMethod(
      payoutMethod: payoutMethod,
      upiId: upiId,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      accountHolderName: accountHolderName,
    );
  }

  Future<OnboardingStatus> getOnboardingStatus() async {
    return await HostService.getOnboardingStatus();
  }
}

/// Vehicle listing + documents + payout onboarding.
class OnboardingRepository {
  OnboardingRepository(this._api);
  final ApiClient _api;

  Future<void> createVehicleListing(Map<String, dynamic> payload) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      return;
    }
    await _api.post(ApiConfig.vehicles, data: payload);
  }

  Future<List<VehicleDocument>> fetchDocuments() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return MockData.documents;
    }
    final res = await _api.get(ApiConfig.documents);
    return (res['items'] as List)
        .map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitDocuments() async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      return;
    }
    await _api.post(ApiConfig.documents);
  }

  Future<bool> verifyPayoutUpi(String upiId) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 900));
      return upiId.contains('@');
    }
    final res = await _api
        .post('${ApiConfig.payout}/verify-upi', data: {'upiId': upiId});
    return res['verified'] == true;
  }

  Future<HostProfile> saveHostProfile({
    required String firstName,
    required String lastName,
    required String dob,
    required String city,
    required String bio,
    required String avatarUrl,
  }) async {
    return await HostService.saveHostProfile(
      firstName: firstName,
      lastName: lastName,
      dob: dob,
      city: city,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }
}

/// Mock payload matching the AYO design. Replaced automatically when
/// [ApiConfig.useMockData] is false.
class MockData {
  MockData._();

  static const host = HostProfile(
    id: 'host_001',
    firstName: 'Marcus',
    lastName: 'Vance',
    email: 'marcus.vance@example.com',
    phone: '+1 (415) 890-0194',
    city: 'San Francisco, CA',
    bio: 'Superhost · San Francisco, CA',
    tier: 'Superhost Elite',
    rating: 4.98,
    reviewCount: 86,
    responseRate: 99,
    memberSince: '2023',
    step: 1,
    isCompleted: false,
  );

  static const dashboard = DashboardStats(
    greeting: 'Good morning,',
    hostName: 'Marcus',
    totalRevenue: 14850.00,
    revenueChangePercent: 16.4,
    pendingPayout: 2420,
    payoutDate: 'Oct 29',
    activeRides: 6,
    totalVehicles: 8,
    occupancyPercent: 88,
    nextHandover: Handover(
      vehicleName: 'Porsche Taycan 4S',
      guestName: 'Sarah J.',
      timeLabel: 'Today, 02:30 PM',
      location: 'SFO T2',
      countdown: 'In 45 min',
    ),
  );

  static const vehicles = [
    Vehicle(
      id: 'v1',
      make: 'Porsche',
      model: 'Taycan 4S',
      year: 2024,
      plate: '7AYO081',
      state: 'CA',
      transmission: 'Automatic',
      bodyType: 'Sports Car',
      batteryPercent: 94,
      status: 'On Trip',
      dailyRate: 120,
    ),
    Vehicle(
      id: 'v2',
      make: 'BMW',
      model: 'i4 M50',
      year: 2023,
      plate: '7AYO432',
      state: 'CA',
      transmission: 'Automatic',
      bodyType: 'Sedan',
      batteryPercent: 78,
      status: 'On Trip',
      dailyRate: 98,
    ),
    Vehicle(
      id: 'v3',
      make: 'Tesla',
      model: 'Model S Plaid',
      year: 2024,
      plate: '8AYO916',
      state: 'CA',
      transmission: 'Automatic',
      bodyType: 'Sedan',
      batteryPercent: 88,
      status: 'Available',
      dailyRate: 135,
    ),
  ];

  static const documents = [
    VehicleDocument(
      type: 'rc',
      title: 'Registration Certificate',
      subtitle: 'Smart card or paper RC, front & back',
      status: 'Uploaded',
      fileName: 'rc_front_2\u2026',
      fileMeta: '1.1 MB · Ready',
    ),
    VehicleDocument(
      type: 'dl',
      title: "Host Driver's License",
      subtitle: 'CA DL \u2022\u2022\u2022\u20228962 · Expires 11/2028',
      status: 'Verified',
    ),
    VehicleDocument(
      type: 'insurance',
      title: 'Commercial Insurance',
      subtitle: 'Comprehensive active coverage',
      status: 'Required',
    ),
    VehicleDocument(
      type: 'smog',
      title: 'Pollution / Smog Check',
      subtitle: 'Valid inspection test report',
      status: 'Required',
    ),
  ];
}
