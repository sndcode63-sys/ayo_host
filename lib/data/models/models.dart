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
  final String? drivingLicenceFrontUrl;
  final String? drivingLicenceBackUrl;
  final String? selfieUrl;

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
    this.drivingLicenceFrontUrl,
    this.drivingLicenceBackUrl,
    this.selfieUrl,
  });

  bool get hasAllIdentityDocs =>
      (drivingLicenceFrontUrl?.isNotEmpty ?? false) &&
      (drivingLicenceBackUrl?.isNotEmpty ?? false) &&
      (selfieUrl?.isNotEmpty ?? false);

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

    final userObj = json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null;

    var firstName = (json['first_name'] ?? json['firstName'] ?? userObj?['first_name'] ?? userObj?['firstName'])?.toString() ?? '';
    var lastName = (json['last_name'] ?? json['lastName'] ?? userObj?['last_name'] ?? userObj?['lastName'])?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      final nameStr = (json['name'] ?? json['fullName'] ?? userObj?['name'])?.toString() ?? '';
      if (nameStr.isNotEmpty) {
        final parts = nameStr.trim().split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    var avatar = (json['avatar_url'] ?? json['photoUrl'] ?? json['avatar'] ?? userObj?['avatar_url'])?.toString().trim();
    if (avatar != null && (avatar.contains('default_avatar.jpg') || avatar.isEmpty)) {
      avatar = null;
    } else if (avatar != null && !avatar.startsWith('http://') && !avatar.startsWith('https://')) {
      final clean = avatar.replaceAll(RegExp(r'^/+'), '');
      avatar = 'https://storage.googleapis.com/ayo-rentals/$clean';
    }

    var photo = (json['photoUrl'] ?? json['avatar_url'] ?? json['photo'] ?? userObj?['avatar_url'])?.toString().trim();
    if (photo != null && (photo.contains('default_avatar.jpg') || photo.isEmpty)) {
      photo = null;
    } else if (photo != null && !photo.startsWith('http://') && !photo.startsWith('https://')) {
      final clean = photo.replaceAll(RegExp(r'^/+'), '');
      photo = 'https://storage.googleapis.com/ayo-rentals/$clean';
    }

    return HostProfile(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? userObj?['email']?.toString(),
      phone: json['phone']?.toString() ?? userObj?['phone']?.toString(),
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
      drivingLicenceFrontUrl: _nonEmpty(json['driving_licence_front_url'] ?? json['driving_license_front_url']),
      drivingLicenceBackUrl: _nonEmpty(json['driving_licence_back_url'] ?? json['driving_license_back_url']),
      selfieUrl: _nonEmpty(json['selfie_url']),
    );
  }
}

class VehiclePhotosCache {
  static final Map<String, List<String>> _cache = {};

  static void set(String vehicleId, List<String> photos) {
    if (vehicleId.trim().isEmpty || photos.isEmpty) return;
    final valid = photos.where((p) => p.trim().isNotEmpty).toList();
    if (valid.isNotEmpty) {
      _cache[vehicleId.trim()] = valid;
    }
  }

  static List<String> get(String vehicleId) {
    return _cache[vehicleId.trim()] ?? const [];
  }
}

String? _nonEmpty(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

class Vehicle {
  final String id;
  final String make;
  final String model;
  final String? rawName;
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
  final double hourlyRate; // in Rupees
  final String? address;
  final String? description;
  // IoT / device status (from GET /vehicles/host/my-cars)
  final bool? isLocked;
  final bool? isOnline;
  final double? lat;
  final double? lng;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    this.rawName,
    required this.year,
    required this.plate,
    required this.state,
    required this.transmission,
    required this.bodyType,
    required this.batteryPercent,
    required this.status,
    required this.dailyRate,
    this.hourlyRate = 0,
    this.imageUrl,
    this.photos = const [],
    this.address,
    this.description,
    this.isLocked,
    this.isOnline,
    this.lat,
    this.lng,
  });

  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get canControl => status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'PAUSED';

  String get name {
    final combined = '$make $model'.trim();
    if (combined.isNotEmpty) return combined;
    if (rawName != null && rawName!.trim().isNotEmpty) return rawName!.trim();
    return 'Vehicle Listed';
  }

  bool get isOnTrip => status == 'On Trip' || status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'ON_TRIP';

  double get effectiveHourlyRate {
    if (hourlyRate > 0) return hourlyRate;
    if (dailyRate > 0) return (dailyRate / 10).roundToDouble();
    return 0;
  }

  String get displayPrice {
    final h = effectiveHourlyRate;
    if (dailyRate > 0 && h > 0) {
      return '₹${dailyRate.toInt()}/day · ₹${h.toInt()}/hr';
    } else if (dailyRate > 0) {
      return '₹${dailyRate.toInt()}/day';
    } else if (h > 0) {
      return '₹${h.toInt()}/hr';
    }
    return 'Rate Pending';
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Check daily_rate_inr / hourly_rate_inr first (standard INR), else daily_rate / hourly_rate (paise or INR)
    double rate = 0;
    if (json['daily_rate_inr'] != null && json['daily_rate_inr'] is num) {
      rate = (json['daily_rate_inr'] as num).toDouble();
    } else if (json['daily_rate'] != null) {
      final rawRate = json['daily_rate'];
      if (rawRate is num) {
        rate = rawRate > 10000 ? (rawRate / 100.0) : rawRate.toDouble();
      }
    } else if (json['dailyRate'] != null) {
      rate = (json['dailyRate'] as num).toDouble();
    }

    double hRate = 0;
    if (json['hourly_rate_inr'] != null && json['hourly_rate_inr'] is num) {
      hRate = (json['hourly_rate_inr'] as num).toDouble();
    } else if (json['hourly_rate'] != null) {
      final rawHRate = json['hourly_rate'];
      if (rawHRate is num) {
        hRate = rawHRate > 1000 ? (rawHRate / 100.0) : rawHRate.toDouble();
      }
    } else if (json['hourlyRate'] != null) {
      hRate = (json['hourlyRate'] as num).toDouble();
    }
    if (hRate <= 0 && rate > 0) {
      hRate = (rate / 10).roundToDouble();
    }

    final String vId = json['id']?.toString() ?? '';
    final List<String> photoList = [];

    void addValidPhoto(dynamic p) {
      if (p == null) return;
      if (p is String) {
        final clean = p.trim();
        if (clean.isNotEmpty) {
          final url = clean.startsWith('http')
              ? clean
              : 'https://storage.googleapis.com/ayo-rentals/${clean.replaceAll(RegExp(r"^/+"), "")}';
          if (!photoList.contains(url)) photoList.add(url);
        }
      } else if (p is Map) {
        final raw = (p['url'] ?? p['photo_url'] ?? p['photo_ref'] ?? p['key'] ?? '')?.toString().trim();
        if (raw != null && raw.isNotEmpty) {
          final url = raw.startsWith('http')
              ? raw
              : 'https://storage.googleapis.com/ayo-rentals/${raw.replaceAll(RegExp(r"^/+"), "")}';
          if (!photoList.contains(url)) photoList.add(url);
        }
      }
    }

    // 1) From photos array
    if (json['photos'] is List) {
      for (final p in (json['photos'] as List)) {
        addValidPhoto(p);
      }
    }

    // 2) From photo_categories map
    if (json['photo_categories'] is Map) {
      final cats = json['photo_categories'] as Map;
      addValidPhoto(cats['cover']);
      addValidPhoto(cats['interior']);
      addValidPhoto(cats['rear_trunk']);
      if (cats['other'] is List) {
        for (final o in (cats['other'] as List)) {
          addValidPhoto(o);
        }
      }
    }

    // 3) From photos_meta list
    if (json['photos_meta'] is List) {
      for (final m in (json['photos_meta'] as List)) {
        addValidPhoto(m);
      }
    }

    // 4) From media_items list
    if (json['media_items'] is List) {
      for (final m in (json['media_items'] as List)) {
        addValidPhoto(m);
      }
    }

    // 5) From local photo cache (photos uploaded during listing)
    if (vId.isNotEmpty) {
      for (final cached in VehiclePhotosCache.get(vId)) {
        addValidPhoto(cached);
      }
    }

    String? img = (json['cover_photo_url'] ?? json['cover_photo'] ?? json['imageUrl'] ?? json['image_url'])?.toString().trim();
    if (img != null && img.isNotEmpty && !img.startsWith('http://') && !img.startsWith('https://')) {
      img = 'https://storage.googleapis.com/ayo-rentals/${img.replaceAll(RegExp(r"^/+"), "")}';
    }
    if (img != null && img.isNotEmpty) {
      addValidPhoto(img);
    }
    if ((img == null || img.isEmpty) && photoList.isNotEmpty) {
      img = photoList.first;
    }

    final dev = json['device_status'] is Map ? json['device_status'] as Map : const {};
    final loc = json['location'] is Map ? json['location'] as Map : const {};
    double? numOrNull(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

    String make = (json['make'] ?? '')?.toString().trim() ?? '';
    String model = (json['model'] ?? '')?.toString().trim() ?? '';
    final String rName = (json['name'] ?? json['title'] ?? '')?.toString().trim() ?? '';
    if (make.isEmpty && model.isEmpty && rName.isNotEmpty) {
      final parts = rName.split(' ');
      make = parts.first;
      model = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final String statusStr = (json['status'] ?? 'DRAFT')?.toString().toUpperCase() ?? 'DRAFT';
    final String plateStr = (json['registration_number'] ?? json['plate'] ?? json['reg_number'] ?? '')?.toString().trim() ?? '';
    final String bodyTypeStr = (json['body_type'] ?? json['bodyType'] ?? json['type'] ?? 'Sedan')?.toString().trim() ?? 'Sedan';
    final int yearInt = json['year'] is num
        ? (json['year'] as num).toInt()
        : (int.tryParse(json['year']?.toString() ?? '') ?? 2024);

    return Vehicle(
      id: json['id'] ?? '',
      make: make,
      model: model,
      rawName: rName,
      year: yearInt,
      plate: plateStr,
      state: json['state'] ?? '',
      transmission: json['transmission'] ?? 'Automatic',
      bodyType: bodyTypeStr,
      batteryPercent: (dev['battery_percentage'] as num?)?.toInt() ?? json['batteryPercent'] ?? 88,
      status: statusStr,
      dailyRate: rate,
      hourlyRate: hRate,
      imageUrl: img,
      photos: photoList,
      address: json['address'] ?? loc['address'],
      description: json['description'],
      isLocked: dev['is_locked'] as bool?,
      isOnline: dev['is_online'] as bool?,
      lat: numOrNull(json['lat'] ?? loc['lat']),
      lng: numOrNull(json['lng'] ?? loc['lng']),
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

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v is num) {
        return v > 100000 ? (v / 100.0) : v.toDouble();
      }
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    final rev = parseNum(json['total_revenue'] ?? json['totalRevenue'] ?? json['total_earnings'] ?? json['earnings'] ?? json['revenue']);
    final revChange = parseNum(json['revenue_change_percent'] ?? json['revenueChangePercent'] ?? json['growth']);
    final payout = parseNum(json['pending_payout'] ?? json['pendingPayout'] ?? json['payout']);
    final active = parseInt(json['active_rides'] ?? json['activeRides'] ?? json['active_trips'] ?? json['active_bookings']);
    final totalVeh = parseInt(json['total_vehicles'] ?? json['totalVehicles'] ?? json['fleet_count'] ?? json['total_cars']);
    final occ = parseNum(json['occupancy_percent'] ?? json['occupancyPercent'] ?? json['occupancy_rate'] ?? json['occupancyRate'] ?? json['occupancy']);

    return DashboardStats(
      greeting: json['greeting']?.toString() ?? 'Hello',
      hostName: json['host_name']?.toString() ?? json['hostName']?.toString() ?? json['name']?.toString() ?? '',
      totalRevenue: rev,
      revenueChangePercent: revChange,
      pendingPayout: payout,
      payoutDate: json['payout_date']?.toString() ?? json['payoutDate']?.toString() ?? 'Auto Transfer',
      activeRides: active,
      totalVehicles: totalVeh,
      occupancyPercent: occ,
      nextHandover: json['next_handover'] != null
          ? Handover.fromJson(Map<String, dynamic>.from(json['next_handover'] as Map))
          : (json['nextHandover'] != null
              ? Handover.fromJson(Map<String, dynamic>.from(json['nextHandover'] as Map))
              : null),
    );
  }
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
    final paise = json['amount_paise'] is int
        ? json['amount_paise'] as int
        : int.tryParse(json['amount_paise']?.toString() ?? '') ?? 0;
    return ListingFeeInfo(
      amountPaise: paise,
      currency: json['currency']?.toString() ?? 'INR',
      displayAmount: json['display_amount']?.toString() ?? '₹${(paise / 100).toStringAsFixed(paise % 100 == 0 ? 0 : 2)}',
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
  final List<String> missingDocuments;

  const SubmitVehicleResult({
    required this.success,
    this.listingFeeRequired = false,
    this.orderId = '',
    this.amountPaise = 0,
    this.keyId = '',
    this.message = '',
    this.missingDocuments = const [],
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
      key: json['key']?.toString() ?? json['photo_key']?.toString() ?? json['file_key']?.toString() ?? json['s3_key']?.toString() ?? '',
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



// ─────────────────────────── Listing fee (dynamic, admin controlled) ───────────────────────────
class ListingFeeConfig {
  final int feeInr;
  final int feePaise;
  final String currency;
  final bool bypass;
  final String description;

  const ListingFeeConfig({
    required this.feeInr,
    required this.feePaise,
    this.currency = 'INR',
    this.bypass = false,
    this.description = '',
  });

  String get display => bypass ? 'Waived' : '₹$feeInr';

  factory ListingFeeConfig.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is num ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    final paise = json['listing_fee_paise'] != null
        ? toInt(json['listing_fee_paise'])
        : toInt(json['listing_fee_inr']) * 100;
    final inr = json['listing_fee_inr'] != null ? toInt(json['listing_fee_inr']) : paise ~/ 100;
    return ListingFeeConfig(
      feeInr: inr,
      feePaise: paise,
      currency: json['currency']?.toString() ?? 'INR',
      bypass: json['listing_fee_bypass'] == true,
      description: json['description']?.toString() ?? '',
    );
  }
}

// ─────────────────────────── Earnings ───────────────────────────
class EarningsPoint {
  final String label;
  final double amount;
  const EarningsPoint(this.label, this.amount);
}

class EarningsEntry {
  final String title;
  final String subtitle;
  final double amount;
  final String status;
  const EarningsEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });
}

/// Tolerant parser: backend field names for /host/earnings are read from several
/// likely keys, and any `*_paise` value is converted to rupees.
class EarningsStats {
  final double total;
  final double thisMonth;
  final double lastMonth;
  final double pendingPayout;
  final double paidOut;
  final int completedTrips;
  final double changePercent;
  final List<EarningsPoint> monthly;
  final List<EarningsEntry> recent;

  const EarningsStats({
    this.total = 0,
    this.thisMonth = 0,
    this.lastMonth = 0,
    this.pendingPayout = 0,
    this.paidOut = 0,
    this.completedTrips = 0,
    this.changePercent = 0,
    this.monthly = const [],
    this.recent = const [],
  });

  bool get isEmpty =>
      total == 0 && thisMonth == 0 && pendingPayout == 0 && paidOut == 0 && recent.isEmpty;

  static double _money(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final paise = j['${k}_paise'];
      if (paise is num) return paise / 100.0;
      if (paise != null) {
        final p = double.tryParse(paise.toString());
        if (p != null) return p / 100.0;
      }
      final v = j[k];
      if (v is num) return v.toDouble();
      if (v != null) {
        final d = double.tryParse(v.toString());
        if (d != null) return d;
      }
    }
    return 0;
  }

  factory EarningsStats.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> src = j;
    for (final k in ['summary', 'stats', 'earnings']) {
      if (j[k] is Map<String, dynamic> && j[k]['total'] == null && j['total_earnings'] == null) {
        src = {...j, ...(j[k] as Map<String, dynamic>)};
        break;
      }
    }

    final monthlyRaw = src['monthly'] ?? src['monthly_earnings'] ?? src['chart'] ?? src['series'];
    final monthly = <EarningsPoint>[];
    if (monthlyRaw is List) {
      for (final e in monthlyRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          monthly.add(EarningsPoint(
            (m['label'] ?? m['month'] ?? m['period'] ?? '').toString(),
            _money(m, ['amount', 'earnings', 'total', 'value']),
          ));
        }
      }
    }

    final recentRaw = src['recent'] ?? src['transactions'] ?? src['payouts'] ?? src['history'] ?? src['items'];
    final recent = <EarningsEntry>[];
    if (recentRaw is List) {
      for (final e in recentRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          recent.add(EarningsEntry(
            title: (m['title'] ?? m['vehicle'] ?? m['description'] ?? m['type'] ?? 'Trip earning').toString(),
            subtitle: (m['date'] ?? m['created_at'] ?? m['paid_at'] ?? m['booking_id'] ?? '').toString(),
            amount: _money(m, ['amount', 'net', 'earnings', 'payout']),
            status: (m['status'] ?? '').toString(),
          ));
        }
      }
    }

    final trips = src['completed_trips'] ?? src['total_trips'] ?? src['trips'] ?? src['trips_completed'];
    return EarningsStats(
      total: _money(src, ['total_earnings', 'total_revenue', 'totalRevenue', 'total', 'lifetime']),
      thisMonth: _money(src, ['this_month', 'month_earnings', 'current_month', 'month']),
      lastMonth: _money(src, ['last_month', 'previous_month']),
      pendingPayout: _money(src, ['pending_payout', 'pendingPayout', 'pending', 'upcoming_payout']),
      paidOut: _money(src, ['paid_out', 'total_paid', 'paid', 'settled']),
      completedTrips: trips is num ? trips.toInt() : int.tryParse(trips?.toString() ?? '') ?? 0,
      changePercent: _money(src, ['change_percent', 'revenue_change_percent', 'growth']),
      monthly: monthly,
      recent: recent,
    );
  }
}

// ─────────────────────────── Notifications ───────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = '',
    this.isRead = false,
    this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final read = j['is_read'] ?? j['isRead'] ?? j['read'];
    return AppNotification(
      id: j['id']?.toString() ?? '',
      title: (j['title'] ?? 'AYO').toString(),
      body: (j['body'] ?? j['message'] ?? '').toString(),
      type: (j['type'] ?? j['category'] ?? '').toString(),
      isRead: read is bool ? read : (j['read_at'] != null),
      createdAt: DateTime.tryParse((j['created_at'] ?? j['createdAt'] ?? '').toString())?.toLocal(),
    );
  }
}


// ─────────────────────────── Vehicle reviews (GET /vehicles/:id/reviews) ───────────────────────────
class VehicleReview {
  final String id;
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const VehicleReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory VehicleReview.fromJson(Map<String, dynamic> j) => VehicleReview(
        id: j['id']?.toString() ?? '',
        reviewerName: j['reviewer_name']?.toString() ?? 'Guest',
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

class VehicleReviewsPage {
  final int total;
  final double ratingAvg;
  final List<VehicleReview> items;
  const VehicleReviewsPage({required this.total, required this.ratingAvg, required this.items});

  factory VehicleReviewsPage.fromJson(Map<String, dynamic> j) => VehicleReviewsPage(
        total: (j['total'] as num?)?.toInt() ?? 0,
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => VehicleReview.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
