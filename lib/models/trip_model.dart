import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String tripId;
  final String customerId;
  final String weight; // Stored as string as per Firebase
  final String truckType;
  final int numberOfTrucks; // Added by customer when creating trip
  final String pickupAddress;
  final String dropoffAddress;
  final String distance; // Stored as string as per Firebase
  final String status; // pending, assigned, in-progress, completed, cancelled
  final String? note;
  final String? cancellationReason; // Reason for trip cancellation
  final DateTime createdAt;

  // Coordinates for map display
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  // Fields added by admin/driver (read-only for customer)
  final int? trucksRequested; // Added by admin
  final DateTime? assignedAt;
  final DateTime? inProgressAt; // in-progressAt from Firebase
  final DateTime? completedAt;
  final DateTime? pickupDateTime; // Date and time when truck is needed
  final List<String>? assignedDriverIds;
  final List<String>? assignedTruckIds;
  final List<Map<String, dynamic>>? assignmentDetails;
  final int? totalAssignments;
  final String? truckAssigned;

  // New fields for admin assignment (single driver/truck assignment)
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverEmail;
  final String? driverLicenseNumber;
  final String? truckId;
  final String? truckNumber;
  final String? truckPlateNumber;
  final String? truckModel;

  // Completion fields
  final String? completionImage; // Base64 image uploaded by driver
  final String? completionNotes; // Optional completion notes

  TripModel({
    required this.tripId,
    required this.customerId,
    required this.weight,
    required this.truckType,
    required this.numberOfTrucks,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distance,
    required this.status,
    this.note,
    this.cancellationReason,
    required this.createdAt,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.trucksRequested,
    this.assignedAt,
    this.inProgressAt,
    this.completedAt,
    this.assignedDriverIds,
    this.assignedTruckIds,
    this.assignmentDetails,
    this.totalAssignments,
    this.tripDate, // Initialize tripDate
    this.truckAssigned,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverEmail,
    this.driverLicenseNumber,
    this.truckId,
    this.truckNumber,
    this.truckPlateNumber,
    this.truckModel,
    this.completionImage,
    this.completionNotes,
  });

  // Create from Firestore document
  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel(
      tripId: data['tripId'] ?? doc.id,
      customerId: data['customerId'] ?? '',
      weight: data['weight']?.toString() ?? '0',
      truckType: data['truckType'] ?? '',
      numberOfTrucks: data['numberOfTrucks'] ?? 1,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      distance: data['distance']?.toString() ?? '0',
      status: data['status'] ?? 'pending',
      note: data['note'],
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickupLat: data['pickupLat']?.toDouble(),
      pickupLng: data['pickupLng']?.toDouble(),
      dropoffLat: data['dropoffLat']?.toDouble(),
      dropoffLng: data['dropoffLng']?.toDouble(),
      trucksRequested: data['trucksRequested'],
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      inProgressAt: (data['in-progressAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      assignedDriverIds: (data['assignedDriverIds'] as List?)?.cast<String>(),
      assignedTruckIds: (data['assignedTruckIds'] as List?)?.cast<String>(),
      assignmentDetails: (data['assignmentDetails'] as List?)
          ?.cast<Map<String, dynamic>>(),
    pickupDateTime: data['pickupDateTime'] != null
      ? (data['pickupDateTime'] as Timestamp).toDate()
      : null, // Handle pickupDateTime
      totalAssignments: data['totalAssignments'],
      truckAssigned: data['truckAssigned'],
      // New admin assignment fields
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      driverEmail: data['driverEmail'],
      driverLicenseNumber: data['driverLicenseNumber'],
      truckId: data['truckId'],
      truckNumber: data['truckNumber'],
      truckPlateNumber: data['truckPlateNumber'],
      truckModel: data['truckModel'],
      completionImage: data['completionImage'],
      completionNotes: data['completionNotes'],
    );
  }

  // Create from Map (for JSON serialization)
  factory TripModel.fromMap(Map<String, dynamic> data) {
    return TripModel(
      tripId: data['tripId'] ?? '',
      customerId: data['customerId'] ?? '',
      weight: data['weight']?.toString() ?? '0',
      truckType: data['truckType'] ?? '',
      numberOfTrucks: data['numberOfTrucks'] ?? 1,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      distance: data['distance']?.toString() ?? '0',
      status: data['status'] ?? 'pending',
      note: data['note'],
      cancellationReason: data['cancellationReason'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      pickupLat: data['pickupLat']?.toDouble(),
      pickupLng: data['pickupLng']?.toDouble(),
      dropoffLat: data['dropoffLat']?.toDouble(),
      dropoffLng: data['dropoffLng']?.toDouble(),
      trucksRequested: data['trucksRequested'],
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] is Timestamp
                ? (data['assignedAt'] as Timestamp).toDate()
                : DateTime.parse(data['assignedAt']))
          : null,
      inProgressAt: data['in-progressAt'] != null
          ? (data['in-progressAt'] is Timestamp
                ? (data['in-progressAt'] as Timestamp).toDate()
                : DateTime.parse(data['in-progressAt']))
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] is Timestamp
                ? (data['completedAt'] as Timestamp).toDate()
                : DateTime.parse(data['completedAt']))
          : null,
      assignedDriverIds: (data['assignedDriverIds'] as List?)?.cast<String>(),
      assignedTruckIds: (data['assignedTruckIds'] as List?)?.cast<String>(),
      assignmentDetails: (data['assignmentDetails'] as List?)
          ?.cast<Map<String, dynamic>>(),
  pickupDateTime: data['pickupDateTime'] != null
      ? (data['pickupDateTime'] is Timestamp
        ? (data['pickupDateTime'] as Timestamp).toDate()
        : DateTime.parse(data['pickupDateTime']))
      : null,
      totalAssignments: data['totalAssignments'],
      truckAssigned: data['truckAssigned'],
      // New admin assignment fields
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      driverEmail: data['driverEmail'],
      driverLicenseNumber: data['driverLicenseNumber'],
      truckId: data['truckId'],
      truckNumber: data['truckNumber'],
      truckPlateNumber: data['truckPlateNumber'],
      truckModel: data['truckModel'],
      completionImage: data['completionImage'],
      completionNotes: data['completionNotes'],
    );
  }

  // Convert to Map for Firestore (only customer fields)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'tripId': tripId,
      'customerId': customerId,
      'weight': weight,
      'truckType': truckType,
      'numberOfTrucks': numberOfTrucks,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'distance': distance,
      'status': status,
      'note': note,
      'cancellationReason': cancellationReason,
      'createdAt': FieldValue.serverTimestamp(),
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
    };
    if (pickupDateTime != null) {
      map['pickupDateTime'] = Timestamp.fromDate(pickupDateTime!);
    }
    return map;
  }

  // Create a copy with updated fields
  TripModel copyWith({
    String? tripId,
    String? customerId,
    String? weight,
    String? truckType,
    int? numberOfTrucks,
    String? pickupAddress,
    String? dropoffAddress,
    String? distance,
    String? status,
    String? note,
    String? cancellationReason,
    DateTime? createdAt,
  DateTime? pickupDateTime,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? trucksRequested,
    DateTime? assignedAt,
    DateTime? inProgressAt,
    DateTime? completedAt,
    List<String>? assignedDriverIds,
    List<String>? assignedTruckIds,
    List<Map<String, dynamic>>? assignmentDetails,
    int? totalAssignments,
    String? truckAssigned,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverEmail,
    String? driverLicenseNumber,
    String? truckId,
    String? truckNumber,
    String? truckPlateNumber,
    String? truckModel,
    String? completionImage,
    String? completionNotes,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      customerId: customerId ?? this.customerId,
      weight: weight ?? this.weight,
      truckType: truckType ?? this.truckType,
      numberOfTrucks: numberOfTrucks ?? this.numberOfTrucks,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      note: note ?? this.note,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
  pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      trucksRequested: trucksRequested ?? this.trucksRequested,
      assignedAt: assignedAt ?? this.assignedAt,
      inProgressAt: inProgressAt ?? this.inProgressAt,
      completedAt: completedAt ?? this.completedAt,
      assignedDriverIds: assignedDriverIds ?? this.assignedDriverIds,
      assignedTruckIds: assignedTruckIds ?? this.assignedTruckIds,
      assignmentDetails: assignmentDetails ?? this.assignmentDetails,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      truckAssigned: truckAssigned ?? this.truckAssigned,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverEmail: driverEmail ?? this.driverEmail,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      truckId: truckId ?? this.truckId,
      truckNumber: truckNumber ?? this.truckNumber,
      truckPlateNumber: truckPlateNumber ?? this.truckPlateNumber,
      truckModel: truckModel ?? this.truckModel,
      completionImage: completionImage ?? this.completionImage,
      completionNotes: completionNotes ?? this.completionNotes,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get formattedWeight => '$weight kg';
  String get formattedDistance => '$distance km';
  String get statusDisplay => status.replaceAll('-', ' ').toUpperCase();

  // Get number of trucks (for display)
  String get numberOfTrucksDisplay =>
      truckAssigned ?? trucksRequested?.toString() ?? numberOfTrucks.toString();

  @override
  String toString() {
    return 'TripModel(tripId: $tripId, status: $status, pickupAddress: $pickupAddress, dropoffAddress: $dropoffAddress)';
  }
}

// Trip status constants
class TripStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String inProgress = 'in-progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static List<String> get allStatuses => [
    pending,
    assigned,
    inProgress,
    completed,
    cancelled,
  ];
}

// Truck type constants
class TruckType {
  static const String container = 'Container';
  static const String flatbed = 'Flatbed';
  static const String refrigerated = 'Refrigerated';
  static const String tanker = 'Tanker';
  static const String boxTruck = 'Box Truck';
  static const String pickup = 'Pickup';

  static List<String> get allTypes => [
    container,
    flatbed,
    refrigerated,
    tanker,
    boxTruck,
    pickup,
  ];
}
