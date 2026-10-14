class ApiConfig {
  ApiConfig._();


  static const String baseUrl = 'https://costly-internidal-moses.ngrok-free.dev/api/v1';
  static const bool useMockData = false;
  static const Duration timeout = Duration(seconds: 30);

  // Authentication Endpoints
  static const String authExchange = '/auth/exchange';

  // Host Profile Endpoints
  static const String hostProfile = '/host/profile';
  static const String hostAvatarPresign = '/host/avatar/presign';

  // Payout & KYC Endpoints
  static const String payoutVerifyUpi = '/host/payout/verify-upi';
  static const String hostKyc = '/host/kyc';

  // Onboarding Endpoints
  static const String onboardingStatus = '/host/onboarding/status';

  // Trips & Dashboard Endpoints
  static const String hostTrips = '/host/trips';
  static const String dashboard = '/host/dashboard';

  // Vehicles Endpoints
  static const String vehicles = '/vehicles';
  static const String vehiclesMine = '/vehicles/mine';
  static String vehicleById(String id) => '/vehicles/$id';
  static String vehicleDocumentsStatus(String id) => '/vehicles/$id/documents-status';
  static String vehicleDocumentsConfirm(String id) => '/vehicles/$id/documents/confirm';
  static String vehiclePhotosConfirm(String id) => '/vehicles/$id/photos/confirm';
  static String vehicleSubmit(String id) => '/vehicles/$id/submit';
  static const String documents = '/host/vehicles/documents';
  static const String payout = '/host/payout';

  // Trips & Handover
  static String tripHandover(String tripId) => '/trips/$tripId/start-handover';
}
