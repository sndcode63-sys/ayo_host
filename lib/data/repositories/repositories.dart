import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/host_service.dart';

/// Auth + host profile repository calls.
class AuthRepository {
  AuthRepository([ApiClient? _]);

  Future<AuthResponse> exchangeFirebaseToken({
    required String idToken,
    String role = 'HOST',
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

  Future<AuthResponse> quickLoginHost() async {
    return await AuthService.quickLogin(role: 'HOST');
  }

  Future<User?> getAuthMe() async {
    return await AuthService.getAuthMe();
  }

  Future<AuthResponse> devMockExchange({
    required String phone,
    String role = 'HOST',
  }) async {
    try {
      final mockUid = 'host_${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
      final mockIdToken = 'mock:$mockUid:$phone';
      return await exchangeFirebaseToken(
        idToken: mockIdToken,
        role: role,
        consentAccepted: true,
        consentVersion: '1.0',
      );
    } catch (_) {
      return await quickLoginHost();
    }
  }

  Future<OnboardingStatus> getOnboardingStatus() async {
    return await HostService.getOnboardingStatus();
  }

  Future<void> logout() async {
    await AuthService.logout();
  }

  Future<bool> isAuthenticated() async {
    return await AuthService.isAuthenticated();
  }
}

/// Dashboard stats + fleet repository calls.
class HostRepository {
  HostRepository(this._api);
  final ApiClient _api;

  Future<DashboardStats> fetchDashboard() async {
    try {
      final res = await _api.get('/host/dashboard');
      return DashboardStats.fromJson(res['data'] ?? res);
    } catch (_) {
      // Aggregate dynamically from real host vehicles, trips, and profile
      final vehicles = await fetchVehicles();
      final profile = await fetchProfile();
      final activeCount = vehicles.where((v) => v.status == 'ACTIVE' || v.status == 'ON_TRIP').length;
      final totalDailyRent = vehicles.fold<double>(0, (sum, v) => sum + v.dailyRate);

      return DashboardStats(
        greeting: 'Welcome,',
        hostName: profile.firstName.isNotEmpty ? profile.firstName : 'Host Partner',
        totalRevenue: totalDailyRent,
        revenueChangePercent: 0,
        pendingPayout: 0,
        payoutDate: 'Auto Transfer',
        activeRides: activeCount,
        totalVehicles: vehicles.length,
        occupancyPercent: vehicles.isEmpty ? 0 : ((activeCount / vehicles.length) * 100),
      );
    }
  }

  Future<List<Vehicle>> fetchVehicles() async {
    return await HostService.getMyVehicles();
  }

  Future<HostProfile> fetchProfile() async {
    return await HostService.getHostProfile();
  }

  Future<HostProfile> saveProfile(Map<String, dynamic> payload) async {
    return await HostService.saveHostProfile(
      firstName: payload['first_name'] ?? payload['firstName'] ?? '',
      lastName: payload['last_name'] ?? payload['lastName'] ?? '',
      dob: payload['dob'] ?? '',
      city: payload['city'] ?? '',
      bio: payload['bio'] ?? '',
      avatarUrl: payload['avatar_url'] ?? payload['avatarUrl'] ?? '',
      drivingLicenceNumber: payload['driving_licence_number'] ?? payload['driving_licence'] ?? payload['dl_number'],
    );
  }

  Future<AvatarPresignResponse> getAvatarPresignUrl({
    required String contentType,
  }) async {
    return await HostService.getAvatarPresignUrl(contentType: contentType);
  }

  Future<UpiVerificationResponse> verifyUpiId({
    required String upiId,
    String? expectedName,
  }) async {
    return await HostService.verifyUpiId(upiId: upiId, expectedName: expectedName);
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

/// Vehicle listing + documents + payout onboarding repository calls.
class OnboardingRepository {
  OnboardingRepository([ApiClient? _]);

  Future<Map<String, dynamic>> createVehicleListing(Map<String, dynamic> payload) async {
    return await HostService.createVehicle(payload);
  }

  Future<DocumentStatusChecklist?> fetchDocumentStatus(String vehicleId) async {
    if (vehicleId.isEmpty) return null;
    return await HostService.getDocumentStatus(vehicleId);
  }

  Future<List<VehicleDocument>> fetchDocuments([String? vehicleId]) async {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      final checklist = await fetchDocumentStatus(vehicleId);
      if (checklist != null) return checklist.documents;
    }
    return [];
  }

  Future<void> confirmDocument({
    required String vehicleId,
    required String type,
    required String url,
    String? fileName,
    int? fileSizeBytes,
    String? expiryDate,
  }) async {
    await HostService.confirmDocument(
      vehicleId: vehicleId,
      type: type,
      url: url,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      expiryDate: expiryDate,
    );
  }

  Future<SubmitVehicleResult> submitVehicleForReview(String vehicleId) async {
    return await HostService.submitVehicleForReview(vehicleId);
  }

  Future<void> submitDocuments([String? vehicleId]) async {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      await submitVehicleForReview(vehicleId);
    }
  }

  Future<ListingFeeOrderResponse> payListingFee(String vehicleId) async {
    return await HostService.payListingFee(vehicleId);
  }

  Future<Map<String, dynamic>> verifyListingFeePayment(
    String vehicleId, {
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    return await HostService.verifyListingFeePayment(
      vehicleId,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
  }

  Future<bool> verifyPayoutUpi(String upiId, [String? expectedName]) async {
    final res = await HostService.verifyUpiId(upiId: upiId, expectedName: expectedName);
    return res.valid;
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
