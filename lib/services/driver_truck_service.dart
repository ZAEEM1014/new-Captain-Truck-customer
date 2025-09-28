import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTruckService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch driver details by ID
  static Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'driverName': data['name'] ?? data['fullName'] ?? 'Unknown Driver',
          'driverPhone': data['phone'] ?? data['mobile'] ?? '',
          'driverEmail': data['email'] ?? '',
          'driverLicenseNumber': data['licenseNumber'] ?? data['license'] ?? '',
        };
      }
    } catch (e) {
      print('Error fetching driver details: $e');
    }
    return null;
  }

  // Fetch truck details by ID
  static Future<Map<String, dynamic>?> getTruckDetails(String truckId) async {
    try {
      final doc = await _firestore.collection('trucks').doc(truckId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'truckType': data['truckType'] ?? data['type'] ?? 'Unknown Type',
          'truckPlateNumber': data['plateNumber'] ?? data['plate'] ?? '',
          'truckModel': data['model'] ?? data['truckModel'] ?? '',
        };
      }
    } catch (e) {
      print('Error fetching truck details: $e');
    }
    return null;
  }

  // Fetch both driver and truck details for a trip
  static Future<Map<String, dynamic>> getAssignmentDetails({
    List<String>? driverIds,
    List<String>? truckIds,
  }) async {
    List<Map<String, dynamic>> drivers = [];
    List<Map<String, dynamic>> trucks = [];

    // Get all driver details
    if (driverIds?.isNotEmpty == true) {
      for (String driverId in driverIds!) {
        final driverDetails = await getDriverDetails(driverId);
        if (driverDetails != null) {
          drivers.add(driverDetails);
        }
      }
    }

    // Get all truck details
    if (truckIds?.isNotEmpty == true) {
      for (String truckId in truckIds!) {
        final truckDetails = await getTruckDetails(truckId);
        if (truckDetails != null) {
          trucks.add(truckDetails);
        }
      }
    }

    // For backward compatibility, also include single driver/truck details
    Map<String, dynamic> result = {
      'drivers': drivers,
      'trucks': trucks,
      // Legacy fields for backward compatibility
      'driverName': drivers.isNotEmpty ? drivers.first['driverName'] : null,
      'driverPhone': drivers.isNotEmpty ? drivers.first['driverPhone'] : null,
      'driverEmail': drivers.isNotEmpty ? drivers.first['driverEmail'] : null,
      'driverLicenseNumber': drivers.isNotEmpty
          ? drivers.first['driverLicenseNumber']
          : null,
      'truckType': trucks.isNotEmpty ? trucks.first['truckType'] : null,
      'truckPlateNumber': trucks.isNotEmpty
          ? trucks.first['truckPlateNumber']
          : null,
      'truckModel': trucks.isNotEmpty ? trucks.first['truckModel'] : null,
    };

    return result;
  }

  // Get completion image from user subcollection
  static Future<String?> getCompletionImage(
    String userId,
    String tripId,
  ) async {
    try {
      final doc = await _firestore
          .collection('customers')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['completionImage'] as String?;
      }
    } catch (e) {
      print('Error fetching completion image: $e');
    }
    return null;
  }

  // Try to fetch completion image from multiple possible locations
  static Future<String?> fetchCompletionImageFromAnySource(
    String tripId,
    String customerId,
    List<String>? driverIds,
  ) async {
    try {
      // 1. First try customer's trip subcollection
      String? image = await getCompletionImage(customerId, tripId);
      if (image != null) return image;

      // 2. Try driver's trip records if driver is assigned
      if (driverIds?.isNotEmpty == true) {
        for (final driverId in driverIds!) {
          try {
            final doc = await _firestore
                .collection('drivers')
                .doc(driverId)
                .collection('trips')
                .doc(tripId)
                .get();

            if (doc.exists) {
              final data = doc.data()!;
              final driverImage = data['completionImage'] as String?;
              if (driverImage != null) return driverImage;
            }
          } catch (e) {
            print('Error fetching from driver $driverId: $e');
          }
        }
      }

      // 3. Try global trips collection as fallback
      try {
        final doc = await _firestore.collection('trips').doc(tripId).get();

        if (doc.exists) {
          final data = doc.data()!;
          final globalImage = data['completionImage'] as String?;
          if (globalImage != null) return globalImage;
        }
      } catch (e) {
        print('Error fetching from global trips: $e');
      }
    } catch (e) {
      print('Error in fetchCompletionImageFromAnySource: $e');
    }
    return null;
  }
}
