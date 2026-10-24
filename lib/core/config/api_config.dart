class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://ayo-platform-api-1015630533512.europe-west1.run.app/api/v1';
  static const bool useMockData = false;
  static const Duration timeout = Duration(seconds: 30);

  // Google Cloud Storage (GCS)
  static const String gcsBucket = 'ayo-rentals';
  static const String gcsPublicBaseUrl = 'https://storage.googleapis.com/ayo-rentals';

  // Razorpay Gateway
  static const String defaultRazorpayKey = 'rzp_test_Tq48KTS6e99UpX';

  // Authentication Endpoints
  static const String authExchange = '/auth/exchange';
  static const String authQuickLogin = '/auth/quick-login';
  static const String authMe = '/auth/me';

  // User Endpoints
  static const String usersMe = '/users/me';
  static const String usersProfile = '/users/profile';

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
  static String vehiclePhotosPresign(String id) => '/vehicles/$id/photos/presign';
  static String vehicleDocumentsPresign(String id) => '/vehicles/$id/documents/presign';
  static String vehicleSubmit(String id) => '/vehicles/$id/submit';
  static String vehiclePayListingFee(String id) => '/vehicles/$id/pay-listing-fee';
  static String vehiclePayListingFeeVerify(String id) => '/vehicles/$id/pay-listing-fee/verify';
  static const String documents = '/host/vehicles/documents';
  static const String payout = '/host/payout';

  // Payments Endpoints
  static const String paymentsConfig = '/payments/config';
  static const String paymentsVerify = '/payments/verify';

  // Trips & Handover
  static String tripHandover(String tripId) => '/trips/$tripId/start-handover';

  // Config & Policies Endpoints
  static const String configSupport = '/config/support';
  static const String configPolicies = '/config/policies';
}
