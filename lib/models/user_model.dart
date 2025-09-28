import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String cnic;
  final String role; // 'customer' or 'user'
  final String status; // 'active', 'inactive', 'suspended'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImage; // Firebase Storage URL only

  UserModel({
    required this.customerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.cnic,
    this.role = 'customer',
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
    this.profileImage,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      customerId: data['customerId'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      cnic: data['cnic'] ?? '',
      role: data['role'] ?? 'customer',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      profileImage: data['profileImage'], // Firebase Storage URL only
    );
  }

  // Convert from Map (for real-time updates)
  factory UserModel.fromMap(Map<String, dynamic> data, String customerId) {
    return UserModel(
      customerId: data['customerId'] ?? customerId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      cnic: data['cnic'] ?? '',
      role: data['role'] ?? 'customer',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      profileImage: data['profileImage'], // Firebase Storage URL only
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'cnic': cnic,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImage': profileImage, // Firebase Storage URL only
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? cnic,
    String? role,
    String? status,
    DateTime? updatedAt,
    String? profileImage,
  }) {
    return UserModel(
      customerId: customerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cnic: cnic ?? this.cnic,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  String toString() {
    return 'UserModel(customerId: $customerId, name: $name, email: $email, role: $role, status: $status)';
  }
}
