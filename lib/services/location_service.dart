import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String PERMISSION_ASKED_KEY = 'location_permission_asked';
  static const String PERMISSION_GRANTED_KEY = 'location_permission_granted';
  static const String _tag = 'LocationService';

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Request location permission using geolocator (simpler approach)
  static Future<bool> requestLocationPermissionAdvanced() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('$_tag: Location services are disabled.');
      return false;
    }

    // Request permission using geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('$_tag: Location permission requested, result: $permission');
    }

    if (permission == LocationPermission.denied) {
      print('$_tag: Location permission denied.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      print('$_tag: Location permission permanently denied.');
      // Try to open app settings
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location
  static Future<Position?> getCurrentLocationPosition() async {
    try {
      // Check if permission is granted
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('$_tag: Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('$_tag: Location permissions are permanently denied');
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('$_tag: Location services are disabled');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
        '$_tag: Current location: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      print('$_tag: Error getting current location: $e');
      return null;
    }
  }

  /// Get current location with fallback to last known location
  static Future<Position?> getCurrentLocationWithFallback() async {
    try {
      Position? position = await getCurrentLocationPosition();
      if (position != null) {
        return position;
      }

      // Fallback to last known position
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        print(
          '$_tag: Using last known location: ${lastKnown.latitude}, ${lastKnown.longitude}',
        );
        return lastKnown;
      }

      print('$_tag: No location available');
      return null;
    } catch (e) {
      print('$_tag: Error getting location with fallback: $e');
      return null;
    }
  }

  /// Convert Position to LatLng format
  static Map<String, double>? positionToLatLng(Position? position) {
    if (position == null) return null;

    return {'lat': position.latitude, 'lng': position.longitude};
  }

  /// Check if location permissions are properly granted
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Initialize location service (call this on app startup)
  static Future<bool> initialize() async {
    try {
      print('$_tag: Initializing location service...');

      // Request location permission
      bool hasPermission = await requestLocationPermissionAdvanced();
      if (!hasPermission) {
        print('$_tag: Location permission not granted');
        return false;
      }

      // Get initial location to warm up the service
      Position? position = await getCurrentLocationWithFallback();
      if (position != null) {
        print('$_tag: Location service initialized successfully');
        return true;
      } else {
        print('$_tag: Could not get initial location');
        return false;
      }
    } catch (e) {
      print('$_tag: Error initializing location service: $e');
      return false;
    }
  }

  // Legacy methods for compatibility
  static Future<Map<String, dynamic>> checkLocationStatus() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      bool hasPermission = await hasLocationPermission();

      return {
        'success': serviceEnabled && hasPermission,
        'message': serviceEnabled && hasPermission
            ? 'Location services are available'
            : 'Location services are not available',
        'needsServiceEnable': !serviceEnabled,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking location status: $e',
        'needsServiceEnable': false,
      };
    }
  }

  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      Position? position = await getCurrentLocationWithFallback();
      if (position != null) {
        return {
          'success': true,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
      } else {
        return {'success': false, 'message': 'Could not get current location'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting current location: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // This would need to be implemented using a geocoding service
    return {
      'success': false,
      'message': 'Address lookup is not implemented yet.',
    };
  }

  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  static Future<void> resetPermissionTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PERMISSION_ASKED_KEY);
    await prefs.remove(PERMISSION_GRANTED_KEY);
  }

  static Future<bool> shouldShowPermissionRationale() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied;
  }
}
