import 'package:flutter/material.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final AuthRepository _repo;

  HostProfile? host;
  bool loading = false;
  String? error;

  Future<bool> signInWithPhone(String phone) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repo.requestOtp(phone);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      host = await _repo.verifyOtp(phone, code);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> socialSignIn(String provider) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      host = await _repo.socialSignIn(provider);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void signOut() {
    host = null;
    notifyListeners();
  }
}

class DashboardController extends ChangeNotifier {
  DashboardController(this._repo);
  final HostRepository _repo;

  DashboardStats? stats;
  List<Vehicle> vehicles = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchDashboard(),
        _repo.fetchVehicles(),
      ]);
      stats = results[0] as DashboardStats;
      vehicles = results[1] as List<Vehicle>;
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
      await _repo.createVehicleListing({
        'bodyType': bodyType,
        'make': make,
        'model': model,
        'year': year,
        'transmission': transmission,
        'plate': plate,
        'plateState': plateState,
        'dailyRate': dailyRate,
        'hourlyRentals': hourlyRentals,
        'hostDelivery': hostDelivery,
        'pickupAddress': pickupAddress,
      });
      return true;
    } catch (_) {
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
