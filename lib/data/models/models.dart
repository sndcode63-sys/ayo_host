class HostProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String city;
  final String bio;
  final String tier;
  final double rating;
  final int reviewCount;
  final double responseRate;
  final String memberSince;
  final String? photoUrl;

  const HostProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.city,
    required this.bio,
    required this.tier,
    required this.rating,
    required this.reviewCount,
    required this.responseRate,
    required this.memberSince,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory HostProfile.fromJson(Map<String, dynamic> json) => HostProfile(
        id: json['id'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        city: json['city'] ?? '',
        bio: json['bio'] ?? '',
        tier: json['tier'] ?? 'Host',
        rating: (json['rating'] ?? 0).toDouble(),
        reviewCount: json['reviewCount'] ?? 0,
        responseRate: (json['responseRate'] ?? 0).toDouble(),
        memberSince: json['memberSince'] ?? '',
        photoUrl: json['photoUrl'],
      );
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
  final String status; // On Trip / Available / Draft
  final String? imageUrl;
  final double dailyRate;

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
  });

  String get name => '$make $model';
  bool get isOnTrip => status == 'On Trip';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] ?? '',
        make: json['make'] ?? '',
        model: json['model'] ?? '',
        year: json['year'] ?? 0,
        plate: json['plate'] ?? '',
        state: json['state'] ?? '',
        transmission: json['transmission'] ?? '',
        bodyType: json['bodyType'] ?? '',
        batteryPercent: json['batteryPercent'] ?? 0,
        status: json['status'] ?? 'Draft',
        dailyRate: (json['dailyRate'] ?? 0).toDouble(),
        imageUrl: json['imageUrl'],
      );
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
}
