import 'package:flutter/material.dart';

class PermissionHelper {
  static bool _locationPermissionRequested = false;
  static bool _locationPermissionGranted = false;

  static Future<bool> requestLocationPermission(BuildContext context) async {
    if (_locationPermissionRequested && _locationPermissionGranted) {
      return true;
    }

    if (!_locationPermissionRequested) {
      _locationPermissionRequested = true;

      final bool? granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'Location Permission',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: const Text(
              'We need access to your location to provide better address suggestions and help you find nearby pickup and drop-off locations.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Deny',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Allow',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          );
        },
      );

      _locationPermissionGranted = granted ?? false;
      return _locationPermissionGranted;
    }

    return _locationPermissionGranted;
  }

  static bool get hasLocationPermission => _locationPermissionGranted;

  static void resetPermissions() {
    _locationPermissionRequested = false;
    _locationPermissionGranted = false;
  }
}
