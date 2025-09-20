// presentation/providers/location_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSub;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // Get current position (initial fix)
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // If accuracy is poor, attempt to refine with a short live stream
      if (_currentPosition != null &&
          (_currentPosition!.accuracy.isNaN ||
              _currentPosition!.accuracy > 50)) {
        try {
          final completer = Completer<Position?>();
          Position? best = _currentPosition;
          int received = 0;
          _positionSub?.cancel();
          _positionSub =
              Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 0,
                ),
              ).listen((pos) {
                received++;
                if (best == null || pos.accuracy < best!.accuracy) {
                  best = pos;
                  if (pos.accuracy <= 25) {
                    // Good enough
                    completer.complete(best);
                  }
                }
                if (received >= 5 && !completer.isCompleted) {
                  completer.complete(best);
                }
              });
          // Cap wait time
          final refined = await completer.future.timeout(
            const Duration(seconds: 8),
            onTimeout: () => best,
          );
          await _positionSub?.cancel();
          _positionSub = null;
          if (refined != null) {
            _currentPosition = refined;
          }
        } catch (e) {
          debugPrint('Refine position failed: $e');
        }
      }

      // Get address from coordinates
      await _getAddressFromCoordinates();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error getting current location: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_currentPosition == null) {
      _currentAddress = 'Location not available';
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build address with null safety
        final street = (place.street?.isNotEmpty ?? false)
            ? place.street
            : (place.thoroughfare?.isNotEmpty ?? false)
            ? place.thoroughfare
            : 'Unknown Street';
        final locality = (place.locality?.isNotEmpty ?? false)
            ? place.locality
            : (place.subAdministrativeArea?.isNotEmpty ?? false)
            ? place.subAdministrativeArea
            : 'Unknown Area';
        final adminArea = (place.administrativeArea?.isNotEmpty ?? false)
            ? place.administrativeArea
            : (place.country?.isNotEmpty ?? false)
            ? place.country
            : 'Unknown Region';

        _currentAddress = '$street, $locality, $adminArea';
      } else {
        _currentAddress = 'Address not found';
      }
    } catch (e) {
      // On web or when services are unavailable, geocoding can throw
      debugPrint('Error getting address (non-fatal): $e');
      _currentAddress = 'Address not available';
    }
  }

  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build address with null safety
        final street = place.street ?? 'Unknown Street';
        final locality = place.locality ?? 'Unknown Area';
        final adminArea = place.administrativeArea ?? 'Unknown Region';

        return '$street, $locality, $adminArea';
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
    }
    return 'Address not available';
  }

  double? calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    try {
      return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
