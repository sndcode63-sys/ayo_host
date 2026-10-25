import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'logger_service.dart';

/// Result of reverse geocoding the device position.
class PlaceInfo {
  const PlaceInfo({
    required this.lat,
    required this.lng,
    this.address = '',
    this.pincode = '',
    this.city = '',
    this.state = '',
  });

  final double lat;
  final double lng;
  final String address;
  final String pincode;
  final String city;
  final String state;
}

/// Device location + (reverse) geocoding. Never throws; returns null on failure.
class LocationService {
  LocationService._();

  static Future<({double lat, double lng})?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (e) {
      LoggerService.warning('Location unavailable: $e');
      return null;
    }
  }

  /// Current GPS position + readable address / pincode / city / state.
  static Future<PlaceInfo?> currentPlace() async {
    final pos = await currentPosition();
    if (pos == null) return null;
    try {
      final marks = await placemarkFromCoordinates(pos.lat, pos.lng);
      if (marks.isEmpty) return PlaceInfo(lat: pos.lat, lng: pos.lng);
      final p = marks.first;
      final parts = <String>[];
      for (final raw in [p.street, p.subLocality, p.locality, p.administrativeArea]) {
        final v = (raw ?? '').trim();
        if (v.isNotEmpty && !parts.contains(v)) parts.add(v);
      }
      final pin = (p.postalCode ?? '').trim();
      final address = parts.join(', ') + (pin.isNotEmpty ? ' - $pin' : '');
      return PlaceInfo(
        lat: pos.lat,
        lng: pos.lng,
        address: address,
        pincode: pin,
        city: (p.locality ?? p.subAdministrativeArea ?? '').trim(),
        state: (p.administrativeArea ?? '').trim(),
      );
    } catch (e) {
      LoggerService.warning('Reverse geocoding failed: $e');
      return PlaceInfo(lat: pos.lat, lng: pos.lng);
    }
  }

  /// Address text -> coordinates (used for manual address / pincode entry).
  static Future<({double lat, double lng})?> geocodeAddress(String address) async {
    final q = address.trim();
    if (q.isEmpty) return null;
    try {
      final res = await locationFromAddress(q);
      if (res.isEmpty) return null;
      return (lat: res.first.latitude, lng: res.first.longitude);
    } catch (e) {
      LoggerService.warning('Forward geocoding failed: $e');
      return null;
    }
  }
}
