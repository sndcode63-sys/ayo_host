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
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory HostProfile.fromJson(Map<String, dynamic> json) {
    final avatarUrlValue = json['avatar_url'] ?? json['photoUrl'];
    final photoUrlValue = json['photoUrl'] ?? json['avatar_url'];
    return HostProfile(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      dob: json['dob'],
      city: json['city'] ?? '',
      bio: json['bio'] ?? '',
      avatarUrl: avatarUrlValue,
      photoUrl: photoUrlValue,
      payoutMethod: json['payout_method'] ?? json['payoutMethod'],
      step: json['step'] ?? 0,
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      tier: json['tier'] ?? 'Superhost',
      rating: (json['rating'] ?? json['rating_avg'] ?? 4.98).toDouble(),
      reviewCount: json['reviewCount'] ?? json['rating_count'] ?? 86,
      responseRate: (json['responseRate'] ?? 99.0).toDouble(),
      memberSince: json['memberSince'] ?? '2024',
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
      photoList = (json['photos'] as List).map((e) => e.toString()).toList();
    }

    String? img = json['cover_photo_url'] ?? json['imageUrl'];
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
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        status: json['status'] ?? 'REQUIRED',
        isUploaded: json['is_uploaded'] ?? false,
        isVerified: json['is_verified'] ?? false,
        fileName: json['file_name'] ?? json['fileName'],
        fileMeta: json['file_size_formatted'] ?? json['fileMeta'],
        url: json['url'],
      );
}

class DocumentStatusChecklist {
  final String vehicleId;
  final int step;
  final String stepTitle;
  final bool isDetailsCompleted;
  final bool isDocumentsCompleted;
  final bool canSubmit;
  final List<VehicleDocument> documents;

  const DocumentStatusChecklist({
    required this.vehicleId,
    required this.step,
    required this.stepTitle,
    required this.isDetailsCompleted,
    required this.isDocumentsCompleted,
    required this.canSubmit,
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
        subtitle: 'Smart card or paper RC certificate',
        status: rc['status'] ?? 'REQUIRED',
        isUploaded: rc['is_uploaded'] ?? false,
        fileName: rc['file_name'],
        fileMeta: rc['file_size_formatted'],
        url: rc['url'],
      ));
    }

    if (docsJson.containsKey('host_dl')) {
      final dl = docsJson['host_dl'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'DL',
        title: dl['title'] ?? "Host Driver's License",
        subtitle: 'Official Driver License',
        status: dl['status'] ?? 'VERIFIED',
        isUploaded: dl['is_uploaded'] ?? true,
        isVerified: dl['is_verified'] ?? true,
      ));
    }

    if (docsJson.containsKey('insurance')) {
      final ins = docsJson['insurance'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'INSURANCE',
        title: ins['title'] ?? 'Commercial Insurance',
        subtitle: 'Comprehensive active insurance coverage',
        status: ins['status'] ?? 'REQUIRED',
        isUploaded: ins['is_uploaded'] ?? false,
        url: ins['url'],
      ));
    }

    if (docsJson.containsKey('pollution')) {
      final pol = docsJson['pollution'] as Map<String, dynamic>;
      list.add(VehicleDocument(
        type: 'POLLUTION',
        title: pol['title'] ?? 'Pollution / Smog Check',
        subtitle: 'Valid pollution test report',
        status: pol['status'] ?? 'REQUIRED',
        isUploaded: pol['is_uploaded'] ?? false,
        url: pol['url'],
      ));
    }

    return DocumentStatusChecklist(
      vehicleId: json['vehicle_id'] ?? '',
      step: json['step'] ?? 2,
      stepTitle: json['step_title'] ?? 'Step 2 of 2 · Document Verification',
      isDetailsCompleted: json['is_details_completed'] ?? true,
      isDocumentsCompleted: json['is_documents_completed'] ?? false,
      canSubmit: json['can_submit'] ?? false,
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
  final HostProfile? profile;
  final dynamic payout;

  const OnboardingStatus({
    required this.onboardingCompleted,
    required this.currentStep,
    required this.profileCompleted,
    required this.payoutCompleted,
    required this.kycStatus,
    this.profile,
    this.payout,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) =>
      OnboardingStatus(
        onboardingCompleted:
            json['onboarding_completed'] ?? json['onboardingCompleted'] ?? false,
        currentStep: json['current_step'] ?? json['currentStep'] ?? '',
        profileCompleted:
            json['profile_completed'] ?? json['profileCompleted'] ?? false,
        payoutCompleted:
            json['payout_completed'] ?? json['payoutCompleted'] ?? false,
        kycStatus: json['kyc_status'] ?? json['kycStatus'] ?? 'NOT_STARTED',
        profile: json['profile'] != null
            ? HostProfile.fromJson(json['profile'])
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

