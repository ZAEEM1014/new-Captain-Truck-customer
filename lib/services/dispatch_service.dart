import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../models/dispatch_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_user_service.dart';
import '../services/notification_service.dart';
import '../services/google_maps_service.dart';

class DispatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String DISPATCHES_COLLECTION = 'dispatches';
  static const String CUSTOMERS_COLLECTION = 'customers';
  static const String NOTIFICATIONS_COLLECTION = 'notifications';

  /// Create a new dispatch request
  static Future<Map<String, dynamic>> createDispatch({
    required String weight,
    required List<TruckRequirement> truckRequirements,
    required String pickupAddress,
    required String dropoffAddress,
    String? additionalNotes,
    DateTime? pickupDateTime,
  }) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Fetch customer name from Firestore
      String customerName = 'Customer';
      try {
        final customerDoc = await FirebaseFirestore.instance
            .collection(CUSTOMERS_COLLECTION)
            .doc(currentUser.uid)
            .get();
        if (customerDoc.exists && customerDoc.data() != null) {
          final data = customerDoc.data() as Map<String, dynamic>;
          if (data['name'] != null &&
              data['name'].toString().trim().isNotEmpty) {
            customerName = data['name'];
          }
        }
      } catch (e) {
        print('Error fetching customer name: $e');
      }

      // Generate dispatch ID
      final dispatchId = _generateDispatchId();

      // Validate addresses
      if (pickupAddress.trim().isEmpty || dropoffAddress.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Both pickup and dropoff addresses are required',
        };
      }

      // Get coordinates and calculate route using Google Maps
      final pickupCoordinates = await GoogleMapsService.geocodeAddress(
        pickupAddress,
      );

      final dropoffCoordinates = await GoogleMapsService.geocodeAddress(
        dropoffAddress,
      );

      // Allow dispatch creation even without coordinates
      double distanceKm = 0.0;
      Map<String, dynamic>? sourceCoords;
      Map<String, dynamic>? destCoords;

      if (pickupCoordinates != null) {
        sourceCoords = {
          'lat': pickupCoordinates['lat'],
          'lng': pickupCoordinates['lng'],
        };
      }

      if (dropoffCoordinates != null) {
        destCoords = {
          'lat': dropoffCoordinates['lat'],
          'lng': dropoffCoordinates['lng'],
        };
      }

      // Calculate distance only if both coordinates are available
      if (pickupCoordinates != null && dropoffCoordinates != null) {
        // Create LatLng objects from coordinates
        final pickupLatLng = LatLng(
          pickupCoordinates['lat'],
          pickupCoordinates['lng'],
        );
        final dropoffLatLng = LatLng(
          dropoffCoordinates['lat'],
          dropoffCoordinates['lng'],
        );

        print(
          '🗺️ Calculating route distance from ${pickupLatLng} to ${dropoffLatLng}',
        );

        // Get route information from Google Maps
        final routeResult = await GoogleMapsService.getDirections(
          pickupLatLng,
          dropoffLatLng,
        );

        if (routeResult != null) {
          final distanceValue = routeResult['distance_value'] ?? 0;
          distanceKm = GoogleMapsService.calculateDistanceInKm(distanceValue);
          print('✅ Route distance calculated: ${distanceKm} km');
        } else {
          print('❌ Could not get route information from Google Maps');
          // Fallback: Calculate straight-line distance if route calculation fails
          distanceKm = _calculateStraightLineDistance(
            pickupLatLng,
            dropoffLatLng,
          );
          print('📏 Using straight-line distance: ${distanceKm} km');
        }
      } else {
        print('❌ Could not calculate distance - coordinates missing');
        print('   Pickup coordinates: $pickupCoordinates');
        print('   Dropoff coordinates: $dropoffCoordinates');
      }

      // Update customer trip count
      await _updateCustomerTripCount(currentUser.uid);

      // Use the passed truck requirements
      final dispatch = DispatchModel(
        dispatchId: dispatchId,
        customerId: currentUser.uid,
        sourceLocation: pickupAddress,
        destinationLocation: dropoffAddress,
        pickupDateTime: pickupDateTime ?? DateTime.now(),
        trucksRequired: truckRequirements,
        status: 'pending',
        createdAt: DateTime.now(),
        distance: distanceKm,
        sourceCoordinates: sourceCoords,
        destinationCoordinates: destCoords,
      );

      // Save to global dispatches collection
      await _firestore
          .collection(DISPATCHES_COLLECTION)
          .doc(dispatchId)
          .set(dispatch.toMap());

      // Log analytics
      await FirebaseService.logEvent(
        'dispatch_created',
        parameters: {
          'dispatch_id': dispatchId,
          'customer_id': currentUser.uid,
          'weight': weight,
          'truck_types': truckRequirements
              .map((t) => TruckTypes.getDisplayName(t.truckType))
              .join(', '),
          'total_trucks': truckRequirements.fold(0, (sum, t) => sum + t.count),
          'distance': distanceKm.toString(),
        },
      );

      // Create notification for dispatch creation in global collection
      await _createGlobalNotification(
        dispatchId: dispatchId,
        customerId: currentUser.uid,
        customerName: customerName,
        type: 'dispatch_created',
        title: 'New Dispatch Request',
        message:
            'Customer $customerName created a new dispatch request for ${truckRequirements.map((t) => '${t.count} ${TruckTypes.getDisplayName(t.truckType)}').join(', ')}',
        additionalData: {
          'truckTypes': truckRequirements
              .map((t) => TruckTypes.getDisplayName(t.truckType))
              .join(', '),
          'weight': weight,
          'pickupAddress': pickupAddress,
          'dropoffAddress': dropoffAddress,
          'distance': dispatch.formattedDistance,
        },
      );

      // Create customer notification
      await NotificationService.createNotification(
        userId: currentUser.uid,
        tripId: dispatchId,
        type: 'dispatch_created',
        title: 'Dispatch Request Created',
        message:
            'Your dispatch request for ${truckRequirements.map((t) => '${t.count} ${TruckTypes.getDisplayName(t.truckType)}').join(', ')} has been submitted successfully and is pending assignment.',
        additionalData: {
          'truckTypes': truckRequirements
              .map((t) => TruckTypes.getDisplayName(t.truckType))
              .join(', '),
          'weight': weight,
          'distance': dispatch.formattedDistance,
        },
      );

      return {
        'success': true,
        'message': 'Dispatch request created successfully!',
        'dispatchId': dispatchId,
        'dispatch': dispatch,
      };
    } catch (e) {
      await FirebaseService.logUserAction(
        'dispatch_creation_failed',
        parameters: {'error': e.toString()},
      );
      return {
        'success': false,
        'message': 'Failed to create dispatch request: ${e.toString()}',
      };
    }
  }

  /// Get customer's dispatch requests stream
  static Stream<List<DispatchModel>> getCustomerDispatchesStream(
    String customerId,
  ) {
    return _firestore
        .collection(DISPATCHES_COLLECTION)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DispatchModel.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('Error in getCustomerDispatchesStream: $error');
          return <DispatchModel>[];
        });
  }

  /// Get current user's dispatch requests
  static Stream<List<DispatchModel>> getCurrentUserDispatchesStream() {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        print('No current user found for dispatches');
        return Stream.value([]);
      }
      return getCustomerDispatchesStream(currentUser.uid);
    } catch (e) {
      print('Error in getCurrentUserDispatchesStream: $e');
      return Stream.value([]);
    }
  }

  /// Get active dispatch requests for current user
  static Stream<List<DispatchModel>> getCurrentUserActiveDispatchesStream() {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection(DISPATCHES_COLLECTION)
          .where('customerId', isEqualTo: currentUser.uid)
          .where(
            'status',
            whereIn: ['pending', 'accepted', 'assigned', 'in-progress'],
          )
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DispatchModel.fromFirestore(doc))
                .toList(),
          )
          .handleError((error) {
            print('Error in getCurrentUserActiveDispatchesStream: $error');
            return <DispatchModel>[];
          });
    } catch (e) {
      print('Error in getCurrentUserActiveDispatchesStream: $e');
      return Stream.value([]);
    }
  }

  /// Get previous dispatch requests for current user
  static Stream<List<DispatchModel>> getCurrentUserPreviousDispatchesStream() {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection(DISPATCHES_COLLECTION)
          .where('customerId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['completed', 'cancelled', 'rejected'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DispatchModel.fromFirestore(doc))
                .toList(),
          )
          .handleError((error) {
            print('Error in getCurrentUserPreviousDispatchesStream: $error');
            return <DispatchModel>[];
          });
    } catch (e) {
      print('Error in getCurrentUserPreviousDispatchesStream: $e');
      return Stream.value([]);
    }
  }

  /// Get all dispatch requests (for admin/dispatch operators)
  static Stream<List<DispatchModel>> getAllDispatchesStream() {
    return _firestore
        .collection(DISPATCHES_COLLECTION)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DispatchModel.fromFirestore(doc))
              .toList(),
        )
        .handleError((error) {
          print('Error in getAllDispatchesStream: $error');
          return <DispatchModel>[];
        });
  }

  /// Get dispatch by ID
  static Future<DispatchModel?> getDispatchById(String dispatchId) async {
    try {
      final doc = await _firestore
          .collection(DISPATCHES_COLLECTION)
          .doc(dispatchId)
          .get();

      if (doc.exists) {
        return DispatchModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting dispatch: $e');
      return null;
    }
  }

  /// Cancel dispatch request (only if pending)
  static Future<Map<String, dynamic>> cancelDispatch(String dispatchId) async {
    try {
      final currentUser = AuthUserService.currentFirebaseUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final dispatch = await getDispatchById(dispatchId);
      if (dispatch == null) {
        return {'success': false, 'message': 'Dispatch not found'};
      }

      // Check if user owns this dispatch
      if (dispatch.customerId != currentUser.uid) {
        return {
          'success': false,
          'message': 'You can only cancel your own dispatch requests',
        };
      }

      if (dispatch.status != 'pending') {
        return {
          'success': false,
          'message':
              'Dispatch cannot be cancelled. Current status: ${dispatch.statusDisplay}',
        };
      }

      // Update dispatch status
      await _firestore.collection(DISPATCHES_COLLECTION).doc(dispatchId).update(
        {
          'status': 'cancelled',
          'currentStatus': {
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Create global notification for cancellation
      await _createGlobalNotification(
        dispatchId: dispatchId,
        customerId: currentUser.uid,
        customerName: currentUser.displayName ?? 'Customer',
        type: 'dispatch_cancelled',
        title: 'Dispatch Request Cancelled',
        message:
            'Customer ${currentUser.displayName ?? 'Unknown'} cancelled dispatch request $dispatchId',
        additionalData: {'reason': 'Cancelled by customer'},
      );

      // Send customer notification
      await NotificationService.createNotification(
        userId: currentUser.uid,
        tripId: dispatchId,
        type: 'dispatch_cancelled',
        title: 'Dispatch Cancelled',
        message: 'Your dispatch request has been cancelled successfully.',
        additionalData: {'reason': 'Cancelled by customer'},
      );

      await FirebaseService.logEvent(
        'dispatch_cancelled',
        parameters: {
          'dispatch_id': dispatchId,
          'customer_id': dispatch.customerId,
        },
      );

      return {'success': true, 'message': 'Dispatch cancelled successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel dispatch: ${e.toString()}',
      };
    }
  }

  /// Update dispatch status (for admin/dispatch operators)
  static Future<Map<String, dynamic>> updateDispatchStatus(
    String dispatchId,
    String newStatus, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = {
        'status': newStatus,
        'currentStatus': {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          updateData[key] = value;
        });
      }

      await _firestore
          .collection(DISPATCHES_COLLECTION)
          .doc(dispatchId)
          .update(updateData);

      // Get dispatch info for notifications
      final dispatch = await getDispatchById(dispatchId);
      if (dispatch != null) {
        // Create global notification
        await _createGlobalNotification(
          dispatchId: dispatchId,
          customerId: dispatch.customerId,
          customerName: dispatch.customerId, // Use customerId as temporary name
          type: 'dispatch_updated',
          title: 'Dispatch Status Updated',
          message:
              'Dispatch $dispatchId status changed to ${_getStatusDisplay(newStatus)}',
          additionalData: additionalData ?? {},
        );

        // Send customer notification
        await NotificationService.createNotification(
          userId: dispatch.customerId,
          tripId: dispatchId,
          type: 'dispatch_updated',
          title: 'Dispatch Status Updated',
          message:
              'Your dispatch request status has been updated to ${_getStatusDisplay(newStatus)}',
          additionalData: additionalData ?? {},
        );
      }

      return {
        'success': true,
        'message': 'Dispatch status updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update dispatch status: ${e.toString()}',
      };
    }
  }

  /// Private helper methods
  static String _generateDispatchId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'DSP-$timestamp';
  }

  static String _getStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Update customer trip count in their document
  static Future<void> _updateCustomerTripCount(String customerId) async {
    try {
      final customerDocRef = _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(customerId);

      await _firestore.runTransaction((transaction) async {
        final customerDoc = await transaction.get(customerDocRef);

        int currentCount = 0;
        if (customerDoc.exists) {
          final data = customerDoc.data();
          currentCount = data?['totalTrips'] ?? 0;
        }

        transaction.set(customerDocRef, {
          'totalTrips': currentCount + 1,
          'lastTripDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error updating customer trip count: $e');
      // Don't throw error as this is not critical for dispatch creation
    }
  }

  /// Create global notification in the notifications collection
  static Future<void> _createGlobalNotification({
    required String dispatchId,
    required String customerId,
    required String customerName,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationId = _firestore
          .collection(NOTIFICATIONS_COLLECTION)
          .doc()
          .id;

      final notification = {
        'id': notificationId,
        'dispatchId': dispatchId,
        'customerId': customerId,
        'customerName': customerName,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
      };

      await _firestore
          .collection(NOTIFICATIONS_COLLECTION)
          .doc(notificationId)
          .set(notification);
    } catch (e) {
      print('Error creating global notification: $e');
      // Don't throw error as this is not critical
    }
  }

  /// Calculate straight-line distance between two points using Haversine formula
  static double _calculateStraightLineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    // Haversine formula
    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  /// Get global notifications stream (for admin/dispatch operators)
  static Stream<List<Map<String, dynamic>>> getGlobalNotificationsStream() {
    return _firestore
        .collection(NOTIFICATIONS_COLLECTION)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent notifications
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        )
        .handleError((error) {
          print('Error in getGlobalNotificationsStream: $error');
          return <Map<String, dynamic>>[];
        });
  }
}
