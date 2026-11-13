import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/host_service.dart';

/// Auth + host profile repository calls.
class AuthRepository {
  AuthRepository([ApiClient? _]);

  /// Send 6-digit OTP via MSG91
  Future<bool> sendOtp({
    required String phone,
    String role = 'HOST',
  }) async {
    return await AuthService.sendOtp(phone: phone, role: role);
  }

  /// Verify 6-digit OTP & get JWT session token
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
    String role = 'HOST',
    String? name,
  }) async {
    return await AuthService.verifyOtp(phone: phone, otp: otp, role: role, name: name);
  }

  /// Retry OTP via SMS ('text') or Voice Call ('voice')
  Future<bool> retryOtp({
    required String phone,
    bool viaVoice = false,
  }) async {
    return await AuthService.retryOtp(phone: phone, viaVoice: viaVoice);
  }

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
  HostRepository([ApiClient? _]);

  Future<DashboardStats> fetchDashboard() async {
    try {
      final vehicles = await fetchVehicles();
      final profile = await fetchProfile();
      EarningsStats? earnings;
      try {
        earnings = await HostService.getEarnings();
      } catch (_) {}

      final activeCount = vehicles.where((v) => v.status == 'ACTIVE' || v.isOnTrip).length;
      final totalVeh = vehicles.length;
      final occ = totalVeh > 0 ? ((activeCount / totalVeh) * 100.0) : 0.0;
      final totalRev = earnings?.total ?? 0.0;

      return DashboardStats(
        greeting: 'Welcome back,',
        hostName: profile.firstName.isNotEmpty ? profile.firstName : '',
        totalRevenue: totalRev,
        revenueChangePercent: earnings?.changePercent ?? 0,
        pendingPayout: earnings?.pendingPayout ?? 0,
        payoutDate: '',
        activeRides: activeCount,
        totalVehicles: totalVeh,
        occupancyPercent: occ,
      );
    } catch (_) {
      return const DashboardStats(
        greeting: 'Hello,',
        hostName: '',
        totalRevenue: 0,
        revenueChangePercent: 0,
        pendingPayout: 0,
        payoutDate: '',
        activeRides: 0,
        totalVehicles: 0,
        occupancyPercent: 0,
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
      email: payload['email'],
      drivingLicenceFrontUrl: payload['driving_licence_front_url'],
      drivingLicenceBackUrl: payload['driving_licence_back_url'],
      selfieUrl: payload['selfie_url'],
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

  Future<Map<String, dynamic>> updateVehicleListing(String id, Map<String, dynamic> payload) async {
    return await HostService.updateVehicle(id, payload);
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
