class HostProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? dob;
  final String city;
  final String bio;
  final String? avatarUrl;
  final String? photoUrl;
  final String? payoutMethod;
  final int step;
  final bool isCompleted;
  final String? tier;
  final double? rating;
  final int? reviewCount;
  final double? responseRate;
  final String? memberSince;
  final String? drivingLicenceNumber;

  const HostProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dob,
    required this.city,
    required this.bio,
    this.avatarUrl,
    this.photoUrl,
    this.payoutMethod,
    required this.step,
    required this.isCompleted,
    this.tier,
    this.rating,
    this.reviewCount,
    this.responseRate,
    this.memberSince,
    this.drivingLicenceNumber,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory HostProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const HostProfile(
        id: '',
        firstName: '',
        lastName: '',
        city: '',
        bio: '',
        step: 0,
        isCompleted: false,
      );
    }
    var avatar = (json['avatar_url'] ?? json['photoUrl'] ?? json['avatar'])?.toString().trim();
    if (avatar != null && (avatar.contains('default_avatar.jpg') || avatar.isEmpty)) {
      avatar = null;
    } else if (avatar != null && !avatar.startsWith('http://') && !avatar.startsWith('https://')) {
      final clean = avatar.replaceAll(RegExp(r'^/+'), '');
      avatar = 'https://storage.googleapis.com/ayo-rentals/$clean';
    }

    var photo = (json['photoUrl'] ?? json['avatar_url'] ?? json['photo'])?.toString().trim();
    if (photo != null && (photo.contains('default_avatar.jpg') || photo.isEmpty)) {
      photo = null;
    } else if (photo != null && !photo.startsWith('http://') && !photo.startsWith('https://')) {
      final clean = photo.replaceAll(RegExp(r'^/+'), '');
      photo = 'https://storage.googleapis.com/ayo-rentals/$clean';
    }
    return HostProfile(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      dob: json['dob']?.toString(),
      city: json['city']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      avatarUrl: avatar,
      photoUrl: photo,
      payoutMethod: json['payout_method']?.toString() ?? json['payoutMethod']?.toString(),
      step: json['step'] is int ? json['step'] : int.tryParse(json['step']?.toString() ?? '0') ?? 0,
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      tier: json['tier']?.toString() ?? 'Superhost',
      rating: (json['rating'] ?? json['rating_avg'] ?? 4.98).toDouble(),
      reviewCount: json['reviewCount'] ?? json['rating_count'] ?? 86,
      responseRate: (json['responseRate'] ?? 99.0).toDouble(),
      memberSince: json['memberSince']?.toString() ?? '2024',
      drivingLicenceNumber: json['driving_licence_number']?.toString() ??
          json['driving_licence']?.toString() ??
          json['dl_number']?.toString(),
    );
  }
}

class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plate;
  final String state;
  final String transmission;
  final String bodyType;
  final int batteryPercent;
  final String status; // ACTIVE / PENDING_REVIEW / DRAFT / REJECTED
  final String? imageUrl;
  final List<String> photos;
  final double dailyRate; // in Rupees
  final String? address;
  final String? description;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.state,
    required this.transmission,
    required this.bodyType,
    required this.batteryPercent,
    required this.status,
    required this.dailyRate,
    this.imageUrl,
    this.photos = const [],
    this.address,
    this.description,
  });

  String get name => '$make $model'.trim();
  bool get isOnTrip => status == 'On Trip' || status == 'ACTIVE';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // If daily_rate is in paise (e.g. 1500000 = ₹15,000), convert to Rupees
    double rate = 0;
    if (json['daily_rate'] != null) {
      final rawRate = json['daily_rate'];
      if (rawRate is num) {
        rate = rawRate > 10000 ? (rawRate / 100.0) : rawRate.toDouble();
      }
    } else if (json['dailyRate'] != null) {
      rate = (json['dailyRate'] as num).toDouble();
    }

    List<String> photoList = [];
    if (json['photos'] is List) {
      for (final p in (json['photos'] as List)) {
        if (p is String) {
          final clean = p.trim();
          if (clean.isNotEmpty) {
            photoList.add(clean.startsWith('http')
                ? clean
                : 'https://storage.googleapis.com/ayo-rentals/${clean.replaceAll(RegExp(r"^/+"), "")}');
          }
        } else if (p is Map) {
          final raw = (p['url'] ?? p['photo_url'] ?? p['photo_ref'] ?? p['key'] ?? '')?.toString().trim();
          if (raw != null && raw.isNotEmpty) {
            photoList.add(raw.startsWith('http')
                ? raw
                : 'https://storage.googleapis.com/ayo-rentals/${raw.replaceAll(RegExp(r"^/+"), "")}');
          }
        }
      }
    }

    String? img = (json['cover_photo_url'] ?? json['cover_photo'] ?? json['imageUrl'] ?? json['image_url'])?.toString().trim();
    if (img != null && img.isNotEmpty && !img.startsWith('http://') && !img.startsWith('https://')) {
      img = 'https://storage.googleapis.com/ayo-rentals/${img.replaceAll(RegExp(r"^/+"), "")}';
    }
    if ((img == null || img.isEmpty) && photoList.isNotEmpty) {
      img = photoList.first;
    }

    return Vehicle(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 2024,
      plate: json['registration_number'] ?? json['plate'] ?? '',
      state: json['state'] ?? '',
      transmission: json['transmission'] ?? 'Automatic',
      bodyType: json['body_type'] ?? json['bodyType'] ?? 'Car',
      batteryPercent: json['batteryPercent'] ?? 88,
      status: json['status'] ?? 'DRAFT',
      dailyRate: rate,
      imageUrl: img,
      photos: photoList,
      address: json['address'],
      description: json['description'],
    );
  }
}

class DashboardStats {
  final String greeting;
  final String hostName;
  final double totalRevenue;
  final double revenueChangePercent;
  final double pendingPayout;
  final String payoutDate;
  final int activeRides;
  final int totalVehicles;
  final double occupancyPercent;
  final Handover? nextHandover;

  const DashboardStats({
    required this.greeting,
    required this.hostName,
    required this.totalRevenue,
    required this.revenueChangePercent,
    required this.pendingPayout,
    required this.payoutDate,
    required this.activeRides,
    required this.totalVehicles,
    required this.occupancyPercent,
    this.nextHandover,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        greeting: json['greeting'] ?? 'Hello',
        hostName: json['hostName'] ?? '',
        totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
        revenueChangePercent: (json['revenueChangePercent'] ?? 0).toDouble(),
        pendingPayout: (json['pendingPayout'] ?? 0).toDouble(),
        payoutDate: json['payoutDate'] ?? '',
        activeRides: json['activeRides'] ?? 0,
        totalVehicles: json['totalVehicles'] ?? 0,
        occupancyPercent: (json['occupancyPercent'] ?? 0).toDouble(),
        nextHandover: json['nextHandover'] != null
            ? Handover.fromJson(json['nextHandover'])
            : null,
      );
}

class Handover {
  final String tripId;
  final String vehicleName;
  final String guestName;
  final String timeLabel;
  final String location;
  final String countdown;
  final String? imageUrl;

  const Handover({
    this.tripId = '',
    required this.vehicleName,
    required this.guestName,
    required this.timeLabel,
    required this.location,
    required this.countdown,
    this.imageUrl,
  });

  factory Handover.fromJson(Map<String, dynamic> json) => Handover(
        tripId: json['tripId'] ?? json['trip_id'] ?? '',
        vehicleName: json['vehicleName'] ?? json['vehicle'] ?? '',
        guestName: json['guestName'] ?? json['customer_name'] ?? '',
        timeLabel: json['timeLabel'] ?? json['time'] ?? '',
        location: json['location'] ?? 'Host Location',
        countdown: json['countdown'] ?? 'Upcoming',
        imageUrl: json['imageUrl'],
      );
}

class VehicleDocument {
  final String type;
  final String title;
  final String subtitle;
  final String status; // UPLOADED / VERIFIED / REQUIRED / NOT_UPLOADED
  final bool isUploaded;
  final bool isVerified;
  final String? fileName;
  final String? fileMeta;
  final String? url;
  final String? expiryDate;

  const VehicleDocument({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.isUploaded = false,
    this.isVerified = false,
    this.fileName,
    this.fileMeta,
    this.url,
    this.expiryDate,
  });

  bool get isDone =>
      status == 'UPLOADED' ||
      status == 'Uploaded' ||
      status == 'VERIFIED' ||
      status == 'Verified' ||
      isUploaded ||
      isVerified;

  factory VehicleDocument.fromJson(Map<String, dynamic> json) =>
      VehicleDocument(
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        status: json['status']?.toString() ?? 'REQUIRED',
        isUploaded: json['is_uploaded'] ?? false,
        isVerified: json['is_verified'] ?? false,
        fileName: json['file_name'] ?? json['fileName'],
        fileMeta: json['file_size_formatted'] ?? json['fileMeta'],
        url: json['url']?.toString(),
        expiryDate: json['expiry_date']?.toString() ?? json['valid_until']?.toString(),
      );
}

class ListingFeeInfo {
  final int amountPaise;
  final String currency;
  final String displayAmount;
  final bool bypassEnabled;

  const ListingFeeInfo({
    required this.amountPaise,
    required this.currency,
    required this.displayAmount,
    required this.bypassEnabled,
  });

  double get amountRupees => amountPaise / 100.0;

  factory ListingFeeInfo.fromJson(Map<String, dynamic> json) {
    return ListingFeeInfo(
      amountPaise: json['amount_paise'] is int
          ? json['amount_paise']
          : int.tryParse(json['amount_paise']?.toString() ?? '49900') ?? 49900,
      currency: json['currency']?.toString() ?? 'INR',
      displayAmount: json['display_amount']?.toString() ?? '₹499.00',
      bypassEnabled: json['bypass_enabled'] ?? false,
    );
  }
}

class DocumentStatusChecklist {
  final String vehicleId;
  final int step;
  final String stepTitle;
  final bool isDetailsCompleted;
  final bool isDocumentsCompleted;
  final bool canSubmit;
  final bool isHostKycVerified;
  final List<String> missingDocuments;
  final ListingFeeInfo? listingFee;
  final List<VehicleDocument> documents;

  bool get hasMissingRequiredDocuments => missingVehicleDocuments.isNotEmpty;

  List<String> get missingVehicleDocuments => missingDocuments
      .where((doc) => doc.toUpperCase() != 'DL' && doc.toUpperCase() != 'HOST_DL')
      .toList();

  const DocumentStatusChecklist({
    required this.vehicleId,
    required this.step,
    required this.stepTitle,
    required this.isDetailsCompleted,
    required this.isDocumentsCompleted,
    required this.canSubmit,
    this.isHostKycVerified = true,
    this.missingDocuments = const [],
    this.listingFee,
    required this.documents,
  });

  factory DocumentStatusChecklist.fromJson(Map<String, dynamic> json) {
    final docsJson = json['documents'] as Map<String, dynamic>? ?? {};
    final list = <VehicleDocument>[];

    if (docsJson.containsKey('rc')) {
      final rc = docsJson['rc'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'RC',
        title: rc['title'] ?? 'Registration Certificate',
        subtitle: rc['subtitle'] ?? 'Smart card or paper RC (front & back)',
        status: rc['status'] ?? 'REQUIRED',
        isUploaded: rc['is_uploaded'] ?? false,
        fileName: rc['file_name'],
        fileMeta: rc['file_size_formatted'],
        url: rc['url'],
        expiryDate: rc['expiry_date'],
      ));
    }

    if (docsJson.containsKey('host_dl')) {
      final dl = docsJson['host_dl'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'HOST_DL',
        title: dl['title'] ?? "Host Driver's License",
        subtitle: dl['subtitle'] ?? 'Host License Verification',
        status: dl['status'] ?? 'PENDING',
        isUploaded: dl['is_uploaded'] ?? (dl['is_verified'] ?? false),
        isVerified: dl['is_verified'] ?? false,
      ));
    }

    if (docsJson.containsKey('insurance')) {
      final ins = docsJson['insurance'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'INSURANCE',
        title: ins['title'] ?? 'Commercial Insurance',
        subtitle: ins['subtitle'] ?? 'Comprehensive active coverage',
        status: ins['status'] ?? 'REQUIRED',
        isUploaded: ins['is_uploaded'] ?? false,
        fileName: ins['file_name'],
        url: ins['url'],
        expiryDate: ins['expiry_date'],
      ));
    }

    if (docsJson.containsKey('pollution')) {
      final pol = docsJson['pollution'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'POLLUTION',
        title: pol['title'] ?? 'Pollution / Smog Check',
        subtitle: pol['subtitle'] ?? 'Valid inspection test report',
        status: pol['status'] ?? 'REQUIRED',
        isUploaded: pol['is_uploaded'] ?? false,
        fileName: pol['file_name'],
        url: pol['url'],
        expiryDate: pol['valid_until'],
      ));
    }

    final missing = (json['missing_documents'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    ListingFeeInfo? feeInfo;
    if (json['listing_fee'] != null && json['listing_fee'] is Map<String, dynamic>) {
      feeInfo = ListingFeeInfo.fromJson(json['listing_fee'] as Map<String, dynamic>);
    }

    final isHostVerified = json['is_host_kyc_verified'] ??
        (docsJson['host_dl'] != null ? (docsJson['host_dl']['is_verified'] ?? false) : true);

    return DocumentStatusChecklist(
      vehicleId: json['vehicle_id']?.toString() ?? '',
      step: json['step'] is int ? json['step'] : int.tryParse(json['step']?.toString() ?? '2') ?? 2,
      stepTitle: json['step_title']?.toString() ?? 'Step 2 of 2 · Document Verification',
      isDetailsCompleted: json['is_details_completed'] ?? true,
      isDocumentsCompleted: json['is_documents_completed'] ?? false,
      canSubmit: json['can_submit'] ?? false,
      isHostKycVerified: isHostVerified,
      missingDocuments: missing,
      listingFee: feeInfo,
      documents: list,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] ?? '',
        user: User.fromJson(json['user']),
      );
}

class User {
  final String id;
  final String phone;
  final String? email;
  final String? name;
  final String role;
  final String kycStatus;
  final bool isActive;

  const User({
    required this.id,
    required this.phone,
    this.email,
    this.name,
    required this.role,
    required this.kycStatus,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        name: json['name'],
        role: json['role'] ?? '',
        kycStatus: json['kyc_status'] ?? json['kycStatus'] ?? 'NOT_STARTED',
        isActive: json['is_active'] ?? json['isActive'] ?? true,
      );
}

class AvatarPresignResponse {
  final String key;
  final String uploadUrl;
  final String method;
  final Map<String, String> headers;
  final int expiresIn;

  const AvatarPresignResponse({
    required this.key,
    required this.uploadUrl,
    required this.method,
    required this.headers,
    required this.expiresIn,
  });

  factory AvatarPresignResponse.fromJson(Map<String, dynamic> json) =>
      AvatarPresignResponse(
        key: json['key'] ?? '',
        uploadUrl: json['upload_url'] ?? '',
        method: json['method'] ?? 'PUT',
        headers: Map<String, String>.from(json['headers'] ?? {}),
        expiresIn: json['expires_in'] ?? 300,
      );
}

class SubmitVehicleResult {
  final bool success;
  final bool listingFeeRequired;
  final String orderId;
  final int amountPaise;
  final String keyId;
  final String message;

  const SubmitVehicleResult({
    required this.success,
    this.listingFeeRequired = false,
    this.orderId = '',
    this.amountPaise = 49900,
    this.keyId = '',
    this.message = '',
  });
}

class UpiVerificationResponse {
  final bool valid;
  final String? registeredName;
  final bool nameMatch;

  const UpiVerificationResponse({
    required this.valid,
    this.registeredName,
    required this.nameMatch,
  });

  factory UpiVerificationResponse.fromJson(Map<String, dynamic> json) =>
      UpiVerificationResponse(
        valid: json['valid'] ?? false,
        registeredName: json['registered_name'],
        nameMatch: json['name_match'] ?? false,
      );
}

class KycResponse {
  final String status;
  final int step;
  final bool isCompleted;
  final String message;

  const KycResponse({
    required this.status,
    required this.step,
    required this.isCompleted,
    required this.message,
  });

  factory KycResponse.fromJson(Map<String, dynamic> json) => KycResponse(
        status: json['status'] ?? '',
        step: json['step'] ?? 0,
        isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
        message: json['message'] ?? '',
      );
}

class OnboardingStatus {
  final bool onboardingCompleted;
  final String currentStep;
  final bool profileCompleted;
  final bool payoutCompleted;
  final String kycStatus;
  final String message;
  final String estimatedVerificationTime;
  final HostProfile? profile;
  final dynamic payout;

  const OnboardingStatus({
    required this.onboardingCompleted,
    required this.currentStep,
    required this.profileCompleted,
    required this.payoutCompleted,
    required this.kycStatus,
    this.message = '',
    this.estimatedVerificationTime = '',
    this.profile,
    this.payout,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) =>
      OnboardingStatus(
        onboardingCompleted:
            json['onboarding_completed'] ?? json['onboardingCompleted'] ?? false,
        currentStep: (json['current_step'] ?? json['currentStep'] ?? '').toString(),
        profileCompleted:
            json['profile_completed'] ?? json['profileCompleted'] ?? false,
        payoutCompleted:
            json['payout_completed'] ?? json['payoutCompleted'] ?? false,
        kycStatus: (json['kyc_status'] ?? json['kycStatus'] ?? 'NOT_STARTED').toString(),
        message: (json['message'] ?? '').toString(),
        estimatedVerificationTime:
            (json['estimated_verification_time'] ?? json['estimated_time'] ?? '').toString(),
        profile: json['profile'] != null && json['profile'] is Map<String, dynamic>
            ? HostProfile.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
        payout: json['payout'],
      );
}

class Trip {
  final String id;
  final String status;
  final String vehicleId;
  final String vehicle;
  final DateTime startTime;
  final DateTime endTime;
  final String splitType;
  final int rentPaise;
  final int onlinePaidPaise;
  final int cashDuePaise;
  final Customer customer;

  const Trip({
    required this.id,
    required this.status,
    required this.vehicleId,
    required this.vehicle,
    required this.startTime,
    required this.endTime,
    required this.splitType,
    required this.rentPaise,
    required this.onlinePaidPaise,
    required this.cashDuePaise,
    required this.customer,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] ?? '',
        status: json['status'] ?? '',
        vehicleId: json['vehicle_id'] ?? json['vehicleId'] ?? '',
        vehicle: json['vehicle'] ?? json['vehicle_name'] ?? 'Vehicle',
        startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now().add(const Duration(days: 1)),
        splitType: json['split_type'] ?? '',
        rentPaise: json['rent_paise'] ?? 0,
        onlinePaidPaise: json['online_paid_paise'] ?? 0,
        cashDuePaise: json['cash_due_paise'] ?? 0,
        customer: Customer.fromJson(json['customer'] ?? {}),
      );
}

class Customer {
  final String name;
  final String phone;

  const Customer({
    required this.name,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        name: json['name'] ?? json['first_name'] ?? 'Guest Customer',
        phone: json['phone'] ?? '',
      );
}

class ApiError {
  final String code;
  final String message;
  final List<dynamic>? details;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] ?? '',
        message: json['message'] ?? '',
        details: json['details'],
      );
}

class SupportConfig {
  final String whatsapp;
  final String phone;
  final String email;
  final String whatsappLink;
  final String telLink;

  const SupportConfig({
    required this.whatsapp,
    required this.phone,
    required this.email,
    required this.whatsappLink,
    required this.telLink,
  });

  factory SupportConfig.fromJson(Map<String, dynamic> json) {
    return SupportConfig(
      whatsapp: json['whatsapp'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      whatsappLink: json['whatsapp_link'] ?? '',
      telLink: json['tel_link'] ?? '',
    );
  }
}

class PlatformPolicies {
  final int minRenterAge;
  final int cancellationFreeHours;
  final String coverageText;
  final String currency;

  const PlatformPolicies({
    required this.minRenterAge,
    required this.cancellationFreeHours,
    required this.coverageText,
    required this.currency,
  });

  factory PlatformPolicies.fromJson(Map<String, dynamic> json) {
    return PlatformPolicies(
      minRenterAge: json['min_renter_age'] ?? 21,
      cancellationFreeHours: json['cancellation_free_hours'] ?? 24,
      coverageText: json['coverage_text'] ?? 'Comprehensive insurance with 24/7 roadside assistance.',
      currency: json['currency'] ?? 'INR',
    );
  }
}

class PaymentsConfig {
  final String keyId;
  final String currency;
  final String name;
  final String description;

  const PaymentsConfig({
    required this.keyId,
    required this.currency,
    required this.name,
    required this.description,
  });

  factory PaymentsConfig.fromJson(Map<String, dynamic> json) {
    return PaymentsConfig(
      keyId: json['key_id']?.toString() ?? 'rzp_test_Tq48KTS6e99UpX',
      currency: json['currency']?.toString() ?? 'INR',
      name: json['name']?.toString() ?? 'AYO Rentals',
      description: json['description']?.toString() ?? 'Car Rental & Security Deposit Payment',
    );
  }
}

class ListingFeeOrderResponse {
  final bool bypassed;
  final String message;
  final String orderId;
  final String paymentId;
  final int amount; // in paise
  final String currency;
  final String keyId;
  final String vehicleId;
  final String purpose;

  const ListingFeeOrderResponse({
    this.bypassed = false,
    this.message = '',
    required this.orderId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.vehicleId,
    required this.purpose,
  });

  factory ListingFeeOrderResponse.fromJson(Map<String, dynamic> json) {
    return ListingFeeOrderResponse(
      bypassed: json['bypassed'] ?? false,
      message: json['message']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      amount: json['amount'] is int ? json['amount'] : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      keyId: json['key_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? 'LISTING_FEE',
    );
  }
}

class GcsPresignResponse {
  final String key;
  final String uploadUrl;
  final String method;
  final Map<String, String> headers;
  final int expiresIn;

  const GcsPresignResponse({
    required this.key,
    required this.uploadUrl,
    this.method = 'PUT',
    this.headers = const {'Content-Type': 'image/jpeg'},
    this.expiresIn = 300,
  });

  factory GcsPresignResponse.fromJson(Map<String, dynamic> json) {
    final headersMap = <String, String>{};
    if (json['headers'] is Map) {
      (json['headers'] as Map).forEach((k, v) {
        headersMap[k.toString()] = v.toString();
      });
    }
    return GcsPresignResponse(
      key: json['key']?.toString() ?? '',
      uploadUrl: json['upload_url']?.toString() ?? '',
      method: json['method']?.toString() ?? 'PUT',
      headers: headersMap.isNotEmpty ? headersMap : const {'Content-Type': 'image/jpeg'},
      expiresIn: json['expires_in'] is int
          ? json['expires_in']
          : int.tryParse(json['expires_in']?.toString() ?? json['expires_in_seconds']?.toString() ?? '300') ?? 300,
    );
  }

  String get publicUrl => key.startsWith('http')
      ? key
      : 'https://storage.googleapis.com/ayo-rentals/$key';
}

