class ApiConfig {
  ApiConfig._();

  /// Point this to the real backend when ready. Every repository call goes
  /// through [ApiClient], so wiring the live API is a one-line change plus
  /// flipping [useMockData] to false.
  static const String baseUrl = 'https://api.ayo-host.com/v1';
  static const bool useMockData = true;
  static const Duration timeout = Duration(seconds: 20);

  // Endpoints
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String hostProfile = '/host/profile';
  static const String dashboard = '/host/dashboard';
  static const String vehicles = '/host/vehicles';
  static const String payout = '/host/payout';
  static const String documents = '/host/vehicles/documents';
}
