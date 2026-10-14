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

  String get fullName => '$firstName $lastName';
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
      tier: json['tier'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      responseRate: json['responseRate']?.toDouble(),
      memberSince: json['memberSince'],
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
  final double dailyRate;
  final String? address;

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
    this.address,
  });

  String get name => '$make $model';
  bool get isOnTrip => status == 'On Trip' || status == 'ACTIVE';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // If daily_rate is in paise (e.g. 1500000), convert to Rupees (1500.0)
    double rate = 0;
    if (json['daily_rate'] != null) {
      final rawRate = json['daily_rate'];
      if (rawRate is num) {
        rate = rawRate > 10000 ? (rawRate / 100.0) : rawRate.toDouble();
      }
    } else if (json['dailyRate'] != null) {
      rate = (json['dailyRate'] as num).toDouble();
    }

    String? img = json['cover_photo_url'] ?? json['imageUrl'];
    if (img == null && json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      img = json['photos'][0].toString();
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
      address: json['address'],
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
  final String vehicleName;
  final String guestName;
  final String timeLabel;
  final String location;
  final String countdown;
  final String? imageUrl;

  const Handover({
    required this.vehicleName,
    required this.guestName,
    required this.timeLabel,
    required this.location,
    required this.countdown,
    this.imageUrl,
  });

  factory Handover.fromJson(Map<String, dynamic> json) => Handover(
        vehicleName: json['vehicleName'] ?? '',
        guestName: json['guestName'] ?? '',
        timeLabel: json['timeLabel'] ?? '',
        location: json['location'] ?? '',
        countdown: json['countdown'] ?? '',
        imageUrl: json['imageUrl'],
      );
}

class VehicleDocument {
  final String type;
  final String title;
  final String subtitle;
  final String status; // Uploaded / Verified / Required
  final String? fileName;
  final String? fileMeta;

  const VehicleDocument({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.fileName,
    this.fileMeta,
  });

  bool get isDone => status == 'Uploaded' || status == 'Verified';

  factory VehicleDocument.fromJson(Map<String, dynamic> json) =>
      VehicleDocument(
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        status: json['status'] ?? '',
        fileName: json['fileName'],
        fileMeta: json['fileMeta'],
      );
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
        vehicleId: json['vehicle_id'] ?? '',
        vehicle: json['vehicle'] ?? '',
        startTime: DateTime.parse(json['start_time']),
        endTime: DateTime.parse(json['end_time']),
        splitType: json['split_type'] ?? '',
        rentPaise: json['rent_paise'] ?? 0,
        onlinePaidPaise: json['online_paid_paise'] ?? 0,
        cashDuePaise: json['cash_due_paise'] ?? 0,
        customer: Customer.fromJson(json['customer']),
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
        name: json['name'] ?? '',
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
