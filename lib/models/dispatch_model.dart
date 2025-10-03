import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchModel {
  final String dispatchId;
  final String customerId;
  final String sourceLocation;
  final String destinationLocation;
  final DateTime pickupDateTime;
  final List<TruckRequirement> trucksRequired;
  final String status; // pending, assigned, in-progress, completed, cancelled
  final Map<String, dynamic> currentStatus; // {status, updatedAt}
  final List<Map<String, dynamic>>
  assignments; // List of driver/truck assignments with details
  final Map<String, dynamic>?
  driverAssignments; // New driver assignment structure
  final String? ownerApproval;
  final DateTime createdAt;
  final DateTime updatedAt; // When the status was last updated
  final double? distance; // Distance in kilometers
  final Map<String, dynamic>? sourceCoordinates; // {lat, lng}
  final Map<String, dynamic>? destinationCoordinates; // {lat, lng}

  DispatchModel({
    required this.dispatchId,
    required this.customerId,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.pickupDateTime,
    required this.trucksRequired,
    this.status = 'pending',
    Map<String, dynamic>? currentStatus,
    this.assignments = const [],
    this.driverAssignments,
    this.ownerApproval,
    required this.createdAt,
    DateTime? updatedAt,
    this.distance,
    this.sourceCoordinates,
    this.destinationCoordinates,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       currentStatus =
           currentStatus ?? {'status': status, 'updatedAt': DateTime.now()};

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'dispatchId': dispatchId,
      'customerId': customerId,
      'sourceLocation': sourceLocation,
      'destinationLocation': destinationLocation,
      'pickupDateTime': Timestamp.fromDate(pickupDateTime),
      'trucksRequired': trucksRequired.map((truck) => truck.toMap()).toList(),
      'status': status,
      'assignments': assignments,
      'driverAssignments': driverAssignments,
      'currentStatus': {
        'status': currentStatus['status'] ?? status,
        'updatedAt': Timestamp.fromDate(
          currentStatus['updatedAt'] ?? DateTime.now(),
        ),
      },
      'ownerApproval': ownerApproval,
      'createdAt': Timestamp.fromDate(createdAt),
      'distance': distance,
      'sourceCoordinates': sourceCoordinates,
      'destinationCoordinates': destinationCoordinates,
    };
  }

  // Create from Firestore document
  factory DispatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Prioritize currentStatus.status over root status field
    // Prioritize the main status field over currentStatus.status
    String actualStatus = data['status'] ?? 'pending';

    // Create synchronized currentStatus
    Map<String, dynamic> syncedCurrentStatus = {
      'status': actualStatus,
      'updatedAt': data['updatedAt'] ?? DateTime.now(),
    };

    return DispatchModel(
      dispatchId: data['dispatchId'] ?? doc.id,
      customerId: data['customerId'] ?? '',
      sourceLocation: data['sourceLocation'] ?? '',
      destinationLocation: data['destinationLocation'] ?? '',
      pickupDateTime: (data['pickupDateTime'] as Timestamp).toDate(),
      trucksRequired:
          (data['trucksRequired'] as List<dynamic>?)
              ?.map((truck) => TruckRequirement.fromMap(truck))
              .toList() ??
          [],
      status: actualStatus,
      assignments:
          (data['assignments'] as List<dynamic>?)
              ?.map((assignment) => Map<String, dynamic>.from(assignment))
              .toList() ??
          [],
      driverAssignments: data['driverAssignments'] as Map<String, dynamic>?,
      currentStatus: syncedCurrentStatus,
      ownerApproval: data['ownerApproval'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      distance: data['distance']?.toDouble(),
      sourceCoordinates: data['sourceCoordinates'],
      destinationCoordinates: data['destinationCoordinates'],
    );
  }

  // Copy with method for updates
  DispatchModel copyWith({
    String? dispatchId,
    String? customerId,
    String? sourceLocation,
    String? destinationLocation,
    DateTime? pickupDateTime,
    List<TruckRequirement>? trucksRequired,
    String? status,
    List<Map<String, dynamic>>? assignments,
    Map<String, dynamic>? driverAssignments,
    Map<String, dynamic>? currentStatus,
    String? ownerApproval,
    DateTime? createdAt,
    double? distance,
    Map<String, dynamic>? sourceCoordinates,
    Map<String, dynamic>? destinationCoordinates,
  }) {
    final newStatus = status ?? this.status;
    return DispatchModel(
      dispatchId: dispatchId ?? this.dispatchId,
      customerId: customerId ?? this.customerId,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      trucksRequired: trucksRequired ?? this.trucksRequired,
      status: newStatus,
      assignments: assignments ?? this.assignments,
      driverAssignments: driverAssignments ?? this.driverAssignments,
      currentStatus:
          currentStatus ?? {'status': newStatus, 'updatedAt': DateTime.now()},
      ownerApproval: ownerApproval ?? this.ownerApproval,
      createdAt: createdAt ?? this.createdAt,
      distance: distance ?? this.distance,
      sourceCoordinates: sourceCoordinates ?? this.sourceCoordinates,
      destinationCoordinates:
          destinationCoordinates ?? this.destinationCoordinates,
    );
  }

  // Get formatted distance
  String get formattedDistance =>
      distance != null ? '${distance!.toStringAsFixed(1)} km' : 'N/A';

  // Get status display
  String get statusDisplay {
    switch (status.toLowerCase()) {
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
        return status;
    }
  }

  // Get total trucks count
  int get totalTrucksCount {
    return trucksRequired.fold(0, (sum, truck) => sum + truck.count);
  }

  // Update status - ensures both status and currentStatus are synchronized
  DispatchModel updateStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      currentStatus: {'status': newStatus, 'updatedAt': DateTime.now()},
    );
  }
}

class TruckRequirement {
  final String truckType;
  final int count;

  TruckRequirement({required this.truckType, required this.count});

  Map<String, dynamic> toMap() {
    return {
      // Store the display name in Firestore
      'truckType': TruckTypes.getDisplayName(truckType),
      'count': count.toString(),
    };
  }

  factory TruckRequirement.fromMap(Map<String, dynamic> map) {
    // Accept display name and convert to internal key if possible
    String displayName = map['truckType'] ?? '';
    String internalKey = TruckTypes.getInternalKey(displayName) ?? displayName;
    return TruckRequirement(
      truckType: internalKey,
      count: int.tryParse(map['count']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  String toString() {
    return '$count x ${TruckTypes.getDisplayName(truckType)}';
  }
}

// Available truck types
class TruckTypes {
  // Map display names to internal keys
  static final Map<String, String> _displayNameToKey = {
    'Turnpike Double / B-Train': 'turnpike_double',
    'Container Hauling': 'container_hauling',
    'Tractor Service (Power-Only)': 'tractor_service',
    'Temperature-Controlled': 'temperature_controlled',
    'Step Deck & Flatdeck': 'step_deck_flatdeck',
    'Dry Van': 'dry_van',
    'Cross Dock': 'cross_dock',
    'Expedited & Hot Shot / 5-Ton': 'expedited_hotshot',
  };

  static String? getInternalKey(String displayName) {
    return _displayNameToKey[displayName];
  }

  static const List<String> availableTypes = [
    'turnpike_double',
    'container_hauling',
    'tractor_service',
    'temperature_controlled',
    'step_deck_flatdeck',
    'dry_van',
    'cross_dock',
    'expedited_hotshot',
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case 'turnpike_double':
        return 'Turnpike Double / B-Train';
      case 'container_hauling':
        return 'Container Hauling';
      case 'tractor_service':
        return 'Tractor Service (Power-Only)';
      case 'temperature_controlled':
        return 'Temperature-Controlled';
      case 'step_deck_flatdeck':
        return 'Step Deck & Flatdeck';
      case 'dry_van':
        return 'Dry Van';
      case 'cross_dock':
        return 'Cross Dock';
      case 'expedited_hotshot':
        return 'Expedited & Hot Shot / 5-Ton';
      default:
        return type;
    }
  }
}
