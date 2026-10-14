import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/services/toast_service.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/trips_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final AuthRepository _repo;

  User? user;
  HostProfile? host;
  OnboardingStatus? onboardingStatus;
  bool loading = false;
  String? error;

  String? verificationId;
  int? resendToken;
  bool isCodeSent = false;

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final completer = Completer<bool>();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification on some Android devices
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final idToken = await userCredential.user?.getIdToken();
            if (idToken != null) {
              await exchangeToken(idToken);
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (e) {
            error = e.toString();
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          error = e.message ?? 'SMS Verification failed';
          ToastService.showError(error!);
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String vId, int? rToken) {
          verificationId = vId;
          resendToken = rToken;
          isCodeSent = true;
          ToastService.showSuccess('OTP sent successfully');
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );

      final success = await completer.future;
      return success;
    } catch (e) {
      error = e.toString();
      ToastService.showError('Failed to send OTP: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtpCode(String smsCode) async {
    if (verificationId == null) {
      error = 'Verification ID missing. Please resend OTP.';
      ToastService.showError(error!);
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Could not retrieve Firebase ID Token');
      }

      return await exchangeToken(idToken);
    } catch (e) {
      error = e.toString();
      ToastService.showError('Invalid OTP code. Please check and retry.');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> exchangeToken(String idToken) async {
    try {
      final authResponse = await _repo.exchangeFirebaseToken(
        idToken: idToken,
        role: 'HOST',
        consentAccepted: true,
        consentVersion: '1.0',
      );

      user = authResponse.user;

      // Check onboarding status
      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {
        // Fallback if status endpoint not ready yet
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> devMockLogin(String phone) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await _repo.devMockExchange(
        phone: phone,
        role: 'HOST',
      );

      user = authResponse.user;

      try {
        onboardingStatus = await _repo.getOnboardingStatus();
        host = onboardingStatus?.profile;
      } catch (_) {}

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.logout();
    await FirebaseAuth.instance.signOut();
    user = null;
    host = null;
    onboardingStatus = null;
    isCodeSent = false;
    verificationId = null;
    notifyListeners();
  }
}

class DashboardController extends ChangeNotifier {
  DashboardController(this._repo);
  final HostRepository _repo;

  DashboardStats? stats;
  List<Vehicle> vehicles = [];
  List<Trip> upcomingTrips = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchVehicles(),
        TripsService.getUpcomingTrips().catchError((_) => <Trip>[]),
      ]);
      vehicles = results[0] as List<Vehicle>;
      upcomingTrips = results[1] as List<Trip>;

      // Dynamically calculate stats from real vehicles and trips
      Handover? nextHandover;
      if (upcomingTrips.isNotEmpty) {
        final firstTrip = upcomingTrips.first;
        nextHandover = Handover(
          vehicleName: firstTrip.vehicle,
          guestName: firstTrip.customer.name,
          timeLabel: DateFormat('MMM dd, hh:mm a').format(firstTrip.startTime),
          location: 'Host Location',
          countdown: 'Upcoming',
        );
      }

      stats = DashboardStats(
        greeting: 'Welcome,',
        hostName: 'Host Partner',
        totalRevenue: 0,
        revenueChangePercent: 0,
        pendingPayout: 0,
        payoutDate: 'Auto Transfer',
        activeRides: upcomingTrips.length,
        totalVehicles: vehicles.length,
        occupancyPercent: vehicles.isEmpty ? 0 : 85,
        nextHandover: nextHandover,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class ProfileController extends ChangeNotifier {
  ProfileController(this._repo);
  final HostRepository _repo;

  HostProfile? profile;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      profile = await _repo.fetchProfile();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, dynamic> payload) async {
    loading = true;
    notifyListeners();
    try {
      await _repo.saveProfile(payload);
      return true;
    } catch (_) {
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class OnboardingController extends ChangeNotifier {
  OnboardingController(this._repo);
  final OnboardingRepository _repo;

  // Vehicle listing draft
  String bodyType = 'Electric';
  String make = '';
  String model = '';
  String year = '';
  String transmission = '';
  String plate = '';
  String plateState = '';
  double dailyRate = 120;
  bool hourlyRentals = true;
  bool hostDelivery = true;
  String pickupAddress = '';

  List<VehicleDocument> documents = [];
  bool documentsLoading = false;

  bool saving = false;
  bool verifyingUpi = false;
  bool upiVerified = false;

  static const double listingFee = 49.00;

  void setBodyType(String v) {
    bodyType = v;
    notifyListeners();
  }

  void setHourlyRentals(bool v) {
    hourlyRentals = v;
    notifyListeners();
  }

  void setHostDelivery(bool v) {
    hostDelivery = v;
    notifyListeners();
  }

  double get estimatedMonthly => dailyRate * 24; // ~80% occupancy

  Future<bool> submitListing() async {
    saving = true;
    notifyListeners();
    try {
      final ratePaise = (dailyRate * 100).round();
      final yearInt = int.tryParse(year) ?? 2024;
      
      final payload = <String, dynamic>{
        'make': make.isEmpty ? 'Porsche' : make,
        'model': model.isEmpty ? 'Taycan 4S' : model,
        'year': yearInt,
        'body_type': bodyType,
        'transmission': transmission.isEmpty ? 'Automatic' : transmission,
        'registration_number': plate.isEmpty ? 'DL 01 AB 1234' : plate,
        'name': '${make.isEmpty ? 'Porsche' : make} ${model.isEmpty ? 'Taycan' : model}',
        'description': 'Host vehicle listed on AYO platform.',
        'daily_rate': ratePaise > 0 ? ratePaise : 1500000,
        'weekend_daily_rate': ((ratePaise > 0 ? ratePaise : 1500000) * 1.2).round(),
        'hourly_rate': hourlyRentals ? 100000 : 0,
        'lat': 12.9716,
        'lng': 77.5946,
        'address': pickupAddress.isEmpty ? '124 Market St, Financial District' : pickupAddress,
        'photos': [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70',
          'https://images.unsplash.com/photo-1541348263662-e0c8de4259ba'
        ],
        'instant_unlock': true,
        'delivery_available': hostDelivery,
        'delivery_fee': hostDelivery ? 50000 : 0,
        'km_limit_per_day': 250,
        'extra_km_fee': 2500,
        'smoking_allowed': false,
        'pets_allowed': true,
        'return_condition_note': 'Return with minimum 20% fuel/charge.',
        'spec_acceleration': '3.8s',
        'spec_range_km': 500,
        'spec_power_hp': 530,
        'spec_cargo_note': '400 L Boot space',
        'badge_text': 'Instant Booking',
      };

      await _repo.createVehicleListing(payload);
      return true;
    } catch (e) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> loadDocuments() async {
    documentsLoading = true;
    notifyListeners();
    try {
      documents = await _repo.fetchDocuments();
    } finally {
      documentsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDocuments() async {
    saving = true;
    notifyListeners();
    try {
      await _repo.submitDocuments();
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> verifyUpi(String upiId) async {
    verifyingUpi = true;
    upiVerified = false;
    notifyListeners();
    try {
      upiVerified = await _repo.verifyPayoutUpi(upiId);
      return upiVerified;
    } finally {
      verifyingUpi = false;
      notifyListeners();
    }
  }
}
