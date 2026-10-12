class ApiConfig {
  ApiConfig._();

  /// Base URL from API documentation
  /// Live: https://costly-internidal-moses.ngrok-free.dev/api/v1
  /// Local: http://localhost:3000/api/v1
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
  static const String vehicles = '/host/vehicles';
  static const String documents = '/host/vehicles/documents';
  static const String payout = '/host/payout';
}
