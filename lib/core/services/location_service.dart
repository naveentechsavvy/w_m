import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geocoding_helper_stub.dart'
    if (dart.library.io) 'geocoding_helper_io.dart';

/// Wraps GPS permission handling + current-position lookup so no
/// controller has to talk to the platform location APIs directly.
class LocationService {
  /// Ensures location services are enabled and permission is granted.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("[LocationService] Location services are disabled.");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("[LocationService] Permission denied by user.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("[LocationService] Permission permanently denied.");
      return false;
    }

    return true;
  }

  /// Current device position, or null if permission/GPS isn't available.
  /// Caller decides the fallback (e.g. keep showing unfiltered meetups).
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint("[LocationService] getCurrentPosition failed: $e");
      return null;
    }
  }

  /// "Area, City" label for a lat/lng, for a Home greeting chip.
  ///
  /// On web this always resolves to null via the stub implementation
  /// (geocoding has no web support — see geocoding_helper_stub.dart).
  /// On Android/iOS/desktop it does a real reverse-geocode lookup via
  /// geocoding_helper_io.dart. The conditional import above picks the
  /// right file per platform at compile time.
  Future<String?> getReadableAddress(double lat, double lng) async {
    try {
      return await getPlacemarkLabel(lat, lng);
    } catch (e) {
      debugPrint("[LocationService] getReadableAddress failed: $e");
      return null;
    }
  }

  /// Distance in kilometers between two coordinates.
  double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}