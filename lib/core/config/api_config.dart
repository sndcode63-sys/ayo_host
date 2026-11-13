class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://ayo-platform-api-1015630533512.europe-west1.run.app/api/v1/';
  static const bool useMockData = false;
  static const Duration timeout = Duration(seconds: 30);

  // Google Cloud Storage (GCS)
  static const String gcsBucket = 'ayo-rentals';
  static const String gcsPublicBaseUrl = 'https://storage.googleapis.com/ayo-rentals';

  // Razorpay Gateway
  static const String defaultRazorpayKey = '';

  // Authentication Endpoints
  static const String authExchange = '/auth/exchange';
  static const String authQuickLogin = '/auth/quick-login';
  static const String authMe = '/auth/me';
  static const String authSendOtp = '/auth/send-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authRetryOtp = '/auth/retry-otp';

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
  static const String tripScanHandover = '/trips/scan-handover';
  static String tripHandover(String tripId) => '/trips/$tripId/start-handover';

  // Host documents, listing fee & earnings
  static const String hostDocumentPresign = '/host/document/presign';
  static const String listingFee = '/host/listing-fee';
  static const String hostListingFee = '/host/listing-fee';
  static const String vehiclesListingFee = '/vehicles/listing-fee';
  static const String hostEarnings = '/host/earnings';
  static const String vehiclesMy = '/vehicles/my';

  // Notifications & FCM
  static const String fcmToken = '/notifications/fcm-token';
  static const String notifications = '/notifications';
  static const String notificationsMine = '/notifications/mine';
  static const String notificationsUnread = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Config & Policies Endpoints
  static const String configSupport = '/config/support';
  static const String configPolicies = '/config/policies';

  // --- Added per Master API Guide ---
  static const String vehiclesHostMyCars = '/vehicles/host/my-cars';
  static String vehicleLock(String id) => '/vehicles/$id/lock';
  static String vehicleUnlock(String id) => '/vehicles/$id/unlock';
  static String vehicleToggleStatus(String id) => '/vehicles/$id/toggle-status';
  static String vehicleMediaPresign(String id) => '/vehicles/$id/media/presign';
  static String vehiclePhotosBatch(String id) => '/vehicles/$id/photos/batch';
  static String vehicleReviews(String id) => '/vehicles/$id/reviews';
  static String vehicleCalendar(String id) => '/vehicles/$id/calendar-availability';
  static String tripVerifyHandover(String id) => '/trips/$id/verify-handover';
  static String tripEnd(String id) => '/trips/$id/end';
  static String tripCancel(String id) => '/trips/$id/cancel';
  static const String usersMePatch = '/users/me';
}
