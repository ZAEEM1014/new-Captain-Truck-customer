import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId; // Customer or driver ID
  final String? tripId; // Made optional for admin notifications
  final String type; // trip_assigned, admin_message, etc.
  final String title;
  final String message;
  final bool isRead; // matches "read" field
  final DateTime createdAt;
  final String? senderId; // Added for admin notifications
  final String? priority; // Added for priority levels
  final Map<String, dynamic>?
  additionalData; // Extra data like driver info, etc.

  NotificationModel({
    required this.notificationId,
    required this.userId,
    this.tripId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderId,
    this.priority = 'normal',
    this.additionalData,
  });

  // Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'],
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead:
          data['read'] ?? data['isRead'] ?? false, // Support both field names
      createdAt:
          (data['timestamp'] ?? data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(), // Support both field names
      senderId: data['senderId'],
      priority: data['priority'] ?? 'normal',
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Create from Map
  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      notificationId: data['notificationId'] ?? '',
      userId: data['userId'] ?? '',
      tripId: data['tripId'],
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['read'] ?? data['isRead'] ?? false,
      createdAt: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] ?? data['timestamp']),
      senderId: data['senderId'],
      priority: data['priority'] ?? 'normal',
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'type': type,
      'title': title,
      'message': message,
      'read': isRead, // Use "read" field to match your structure
      'timestamp': FieldValue.serverTimestamp(), // Use "timestamp" field
      'senderId': senderId,
      'priority': priority ?? 'normal',
      'additionalData': additionalData,
    };
  }

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? tripId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $notificationId, type: $type, title: $title, isRead: $isRead)';
  }
}

// Notification type constants
class NotificationType {
  static const String tripCreated = 'trip_created';
  static const String tripAssigned = 'trip_assigned';
  static const String tripStarted = 'trip_started';
  static const String tripCompleted = 'trip_completed';
  static const String tripCancelled = 'trip_cancelled';
  static const String driverAssigned = 'driver_assigned';
  static const String imageUploaded = 'image_uploaded';
  static const String tripUpdated = 'trip_updated';
  static const String adminMessage =
      'admin_message'; // Added admin message type

  static List<String> get allTypes => [
    tripCreated,
    tripAssigned,
    tripStarted,
    tripCompleted,
    tripCancelled,
    driverAssigned,
    imageUploaded,
    tripUpdated,
    adminMessage,
  ];
}
