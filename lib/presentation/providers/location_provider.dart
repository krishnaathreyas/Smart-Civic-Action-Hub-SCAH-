// presentation/providers/location_provider.dart
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;

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

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build address with null safety
        final street = place.street ?? 'Unknown Street';
        final locality = place.locality ?? 'Unknown Area';
        final adminArea = place.administrativeArea ?? 'Unknown Region';

        _currentAddress = '$street, $locality, $adminArea';
      } else {
        _currentAddress = 'Address not found';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
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
