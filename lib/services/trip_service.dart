import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_user_service.dart';
import '../services/notification_service.dart';
import '../services/driver_truck_service.dart';

class TripService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Changed to use user subcollections for better scalability and data isolation
  static const String CUSTOMERS_COLLECTION = 'customers';
  static const String TRIPS_SUBCOLLECTION = 'trips';

  // Create a new trip
  static Future<Map<String, dynamic>> createTrip({
    required String weight,
    required String truckType,
    required int numberOfTrucks,
    required String pickupAddress,
    required String dropoffAddress,
    String? note,
    DateTime? pickupDateTime, // Renamed for consistency with TripModel
  }) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Generate trip ID
      final tripId = _generateTripId();

      // Validate addresses are not empty
      if (pickupAddress.trim().isEmpty) {
        return {'success': false, 'message': 'Pickup address cannot be empty'};
      }

      if (dropoffAddress.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Drop-off address cannot be empty',
        };
      }

      // Create trip model without coordinates (map functionality removed)
      final trip = TripModel(
        tripId: tripId,
        customerId: currentUser.uid,
        weight: weight,
        truckType: truckType,
        numberOfTrucks: numberOfTrucks,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        distance: "N/A", // Distance calculation removed
        status: 'pending', // Default status
        note: note,
        createdAt: DateTime.now(),
        pickupDateTime: pickupDateTime, // Pass pickupDateTime to TripModel
        pickupLat: null, // Coordinates removed
        pickupLng: null,
        dropoffLat: null,
        dropoffLng: null,
      );

      // Save to user's trips subcollection for better data isolation and scalability
      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(TRIPS_SUBCOLLECTION)
          .doc(tripId)
          .set(trip.toMap());

      // Log analytics
      await FirebaseService.logEvent(
        'trip_created',
        parameters: {
          'trip_id': tripId,
          'customer_id': currentUser.uid,
          'weight': weight,
          'truck_type': truckType,
          'number_of_trucks': numberOfTrucks,
        },
      );

      // Create notification for trip creation
      await NotificationService.createNotification(
        userId: currentUser.uid,
        tripId: tripId,
        type: 'trip_created',
        title: 'Trip Request Created',
        message:
            'Your $truckType trip request has been submitted successfully and is pending assignment.',
        additionalData: {'truckType': truckType, 'weight': weight},
      );

      return {
        'success': true,
        'message': 'Trip request created successfully!',
        'tripId': tripId,
        'trip': trip,
      };
    } catch (e) {
      await FirebaseService.logUserAction(
        'trip_creation_failed',
        parameters: {'error': e.toString()},
      );
      return {
        'success': false,
        'message': 'Failed to create trip: ${e.toString()}',
      };
    }
  }

  // Get user's trips stream for real-time updates using subcollections
  static Stream<List<TripModel>> getUserTripsStream(String userId) {
    return _firestore
        .collection(CUSTOMERS_COLLECTION)
        .doc(userId)
        .collection(TRIPS_SUBCOLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final trips = snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc))
              .toList();
          return await _enrichTripsWithDetails(trips);
        });
  }

  // Get active trips (not completed or cancelled) using subcollections
  static Stream<List<TripModel>> getActiveTripsStream(String userId) {
    return _firestore
        .collection(CUSTOMERS_COLLECTION)
        .doc(userId)
        .collection(TRIPS_SUBCOLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final trips = snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc))
              .where(
                (trip) => [
                  'pending',
                  'assigned',
                  'in-progress',
                ].contains(trip.status),
              )
              .toList();
          return await _enrichTripsWithDetails(trips);
        })
        .handleError((error) {
          print('Error in getActiveTripsStream: $error');
          return <TripModel>[];
        });
  }

  // Get active trips for current user (convenience method)
  static Stream<List<TripModel>> getCurrentUserActiveTripsStream() {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        print('No current user found for active trips');
        return Stream.value([]);
      }
      print('Getting active trips for user: ${currentUser.uid}');
      return getActiveTripsStream(currentUser.uid);
    } catch (e) {
      print('Error in getCurrentUserActiveTripsStream: $e');
      return Stream.value([]);
    }
  }

  // Get previous trips (completed and cancelled) using subcollections
  static Stream<List<TripModel>> getPreviousTripsStream(String userId) {
    return _firestore
        .collection(CUSTOMERS_COLLECTION)
        .doc(userId)
        .collection(TRIPS_SUBCOLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final trips = snapshot.docs
              .map((doc) => TripModel.fromFirestore(doc))
              .where((trip) => ['completed', 'cancelled'].contains(trip.status))
              .toList();
          return await _enrichTripsWithDetails(trips);
        })
        .handleError((error) {
          print('Error in getPreviousTripsStream: $error');
          return <TripModel>[];
        });
  }

  // Get previous trips for current user (convenience method)
  static Stream<List<TripModel>> getCurrentUserPreviousTripsStream() {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        print('No current user found for previous trips');
        return Stream.value([]);
      }
      print('Getting previous trips for user: ${currentUser.uid}');
      return getPreviousTripsStream(currentUser.uid);
    } catch (e) {
      print('Error in getCurrentUserPreviousTripsStream: $e');
      return Stream.value([]);
    }
  }

  // Get trip by ID from user's subcollection with enriched data
  static Future<TripModel?> getTripById(String tripId, [String? userId]) async {
    try {
      // If userId not provided, use current user
      final uid = userId ?? AuthUserService.currentFirebaseUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(uid)
          .collection(TRIPS_SUBCOLLECTION)
          .doc(tripId)
          .get();
      if (doc.exists) {
        final trip = TripModel.fromFirestore(doc);
        return await _enrichTripWithDetails(trip);
      }
      return null;
    } catch (e) {
      print('Error getting trip: $e');
      return null;
    }
  }

  // Enrich trip with driver and truck details from collections
  static Future<TripModel> _enrichTripWithDetails(TripModel trip) async {
    try {
      Map<String, dynamic> enrichmentData = {};

      // Get driver and truck details if trip is assigned or in progress
      if (['assigned', 'in-progress', 'completed'].contains(trip.status)) {
        final details = await DriverTruckService.getAssignmentDetails(
          driverIds: trip.assignedDriverIds,
          truckIds: trip.assignedTruckIds,
        );
        enrichmentData.addAll(details);
      }

      // For completed trips, also try to fetch completion image if missing
      if (trip.status == 'completed' && trip.completionImage == null) {
        try {
          final currentUser = AuthUserService.currentFirebaseUser;
          if (currentUser != null) {
            final completionImage =
                await DriverTruckService.fetchCompletionImageFromAnySource(
                  trip.tripId,
                  currentUser.uid,
                  trip.assignedDriverIds,
                );
            if (completionImage != null) {
              enrichmentData['completionImage'] = completionImage;
            }
          }
        } catch (e) {
          print('Error fetching completion image: $e');
        }
      }

      // Apply enrichment if we have any data
      if (enrichmentData.isNotEmpty) {
        return trip.copyWith(
          driverName: enrichmentData['driverName'],
          driverPhone: enrichmentData['driverPhone'],
          driverEmail: enrichmentData['driverEmail'],
          driverLicenseNumber: enrichmentData['driverLicenseNumber'],
          truckNumber: enrichmentData['truckNumber'],
          truckPlateNumber: enrichmentData['truckPlateNumber'],
          truckModel: enrichmentData['truckModel'],
          completionImage: enrichmentData['completionImage'],
        );
      }
    } catch (e) {
      print('Error enriching trip details: $e');
    }

    return trip;
  }

  // Helper method to enrich a list of trips
  static Future<List<TripModel>> _enrichTripsWithDetails(
    List<TripModel> trips,
  ) async {
    List<TripModel> enrichedTrips = [];

    for (final trip in trips) {
      final enrichedTrip = await _enrichTripWithDetails(trip);
      enrichedTrips.add(enrichedTrip);
    }

    return enrichedTrips;
  }

  // Cancel trip (only if pending) using subcollections
  static Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final trip = await getTripById(tripId, currentUser.uid);
      if (trip == null) {
        return {'success': false, 'message': 'Trip not found'};
      }

      if (trip.status != TripStatus.pending) {
        return {
          'success': false,
          'message':
              'Trip cannot be cancelled. Current status: ${trip.statusDisplay}',
        };
      }

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(currentUser.uid)
          .collection(TRIPS_SUBCOLLECTION)
          .doc(tripId)
          .update({
            'status': TripStatus.cancelled,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Send cancellation notification
      await NotificationService.createNotification(
        userId: currentUser.uid,
        tripId: tripId,
        type: 'trip_cancelled',
        title: 'Trip Cancelled',
        message: 'Your trip request has been cancelled successfully.',
        additionalData: {'reason': 'Cancelled by customer'},
      );

      await FirebaseService.logEvent(
        'trip_cancelled',
        parameters: {'trip_id': tripId, 'customer_id': trip.customerId},
      );

      return {'success': true, 'message': 'Trip cancelled successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel trip: ${e.toString()}',
      };
    }
  }

  // Private helper methods
  static String _generateTripId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'TRP-$timestamp';
  }

  // Test notification method (for debugging)
  static Future<Map<String, dynamic>> sendTestNotification({
    required String tripId,
    String? customMessage,
  }) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      await NotificationService.createNotification(
        userId: currentUser.uid,
        tripId: tripId,
        type: 'trip_updated',
        title: 'Test Notification',
        message: customMessage ?? 'This is a test notification for your trip.',
        additionalData: {'test': true},
      );

      return {
        'success': true,
        'message': 'Test notification sent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send test notification: ${e.toString()}',
      };
    }
  }
}
