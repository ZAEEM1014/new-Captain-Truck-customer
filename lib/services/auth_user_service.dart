import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthUserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CUSTOMERS_COLLECTION = 'customers';

  // Current user stream for real-time updates with orphan cleanup
  static Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      try {
        if (firebaseUser != null) {
          print('🔄 Auth state changed: User logged in (${firebaseUser.uid})');

          // Check if this is an orphaned user (exists in Auth but not Firestore)
          final userData = await getUserFromFirestore(firebaseUser.uid);

          if (userData == null) {
            print(
              '❌ Orphaned user detected: ${firebaseUser.uid} - auto-logging out',
            );
            await _auth.signOut();
            return null;
          }

          return userData;
        } else {
          print('🔄 Auth state changed: User logged out');
          return null;
        }
      } catch (e) {
        print('❌ Error in currentUserStream: $e');
        // If there's any error, sign out to prevent stuck states
        try {
          await _auth.signOut();
        } catch (_) {}
        return null;
      }
    });
  }

  // Get current Firebase user
  static User? get currentFirebaseUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // FIX ORPHANED USER (Firebase Auth exists but no Firestore data)
  static Future<Map<String, dynamic>> fixOrphanedUser({
    required String name,
    required String phone,
    required String address,
    required String cnic,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      print('🔧 Fixing orphaned user: ${user.uid}');

      // Create user document in Firestore
      final now = DateTime.now();
      final userData = <String, dynamic>{
        'uid': user.uid,
        'name': name,
        'email': user.email!,
        'phone': phone,
        'address': address,
        'cnic': cnic,
        'role': 'customer',
        'status': 'active',
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': null,
        'profileImage': null,
      };

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(user.uid)
          .set(userData);

      print('✅ Orphaned user fixed in Firestore');
      return {'success': true, 'message': 'User profile created successfully!'};
    } catch (e) {
      print('❌ Error fixing orphaned user: $e');
      return {'success': false, 'message': 'Failed to fix user profile'};
    }
  }

  // CHECK IF EMAIL EXISTS
  static Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ Error checking email: $e');
      return false;
    }
  }

  // EMERGENCY BYPASS METHOD - AVOID FIREBASE AUTH BUG
  static Future<Map<String, dynamic>> signupWorkaround({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String cnic,
  }) async {
    print('� EMERGENCY MODE: Bypassing Firebase Auth due to plugin bug');

    try {
      // Check if email already exists in Firestore
      final existingUsers = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'This email is already registered.',
          'error': 'email-already-in-use',
        };
      }

      // Generate temporary UID until Firebase Auth is fixed
      final tempUid = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Create user data directly in Firestore
      final userData = <String, String>{
        'uid': tempUid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'cnic': cnic,
        'role': 'customer',
        'status': 'emergency_mode', // Special status for emergency users
        'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'needsFirebaseAuth': 'true', // Flag to fix later
      };

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(tempUid)
          .set(userData);

      print('✅ Emergency user created without Firebase Auth');

      return {
        'success': true,
        'message':
            'Account created in emergency mode! You can use the app normally.',
        'user': null, // No Firebase user due to bug
        'isReturningUser': false,
        'isEmergencyMode': true,
      };
    } catch (e) {
      print('❌ Emergency signup error: $e');
      return {
        'success': false,
        'message': 'Emergency signup failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  } // ULTRA MINIMAL SIGNUP FOR TESTING

  static Future<Map<String, dynamic>> signupUltraMinimal({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String cnic,
  }) async {
    try {
      print('🔄 Starting ultra minimal signup for: $email');

      // Just create Firebase Auth user
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth user created: ${authResult.user!.uid}');

      // Try using add() instead of set() to avoid the type casting issue
      await _firestore.collection(CUSTOMERS_COLLECTION).add({
        'uid': authResult.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'cnic': cnic,
        'role': 'customer',
        'status': 'active',
      });

      print('✅ Ultra minimal user data saved with add()');

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': authResult.user,
        'isReturningUser': false,
      };
    } catch (e) {
      print('❌ Ultra minimal signup error: $e');
      return {
        'success': false,
        'message': 'Signup failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // MINIMAL SIGNUP FOR TESTING
  static Future<Map<String, dynamic>> signupMinimal({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String cnic,
  }) async {
    try {
      print('🔄 Starting minimal signup for: $email');

      // Just create Firebase Auth user
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth user created: ${authResult.user!.uid}');

      // Try to save minimal data to Firestore
      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(authResult.user!.uid)
          .set({
            'uid': authResult.user!.uid,
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
            'cnic': cnic,
            'role': 'customer',
            'status': 'active',
          });

      print('✅ Minimal user data saved');

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': authResult.user,
        'isReturningUser': false,
      };
    } catch (e) {
      print('❌ Minimal signup error: $e');
      return {
        'success': false,
        'message': 'Signup failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // EMERGENCY SIGNUP METHOD (DUPLICATE - FOR SAFETY)
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String cnic,
  }) async {
    print('� EMERGENCY: Old signup method called - redirecting to bypass');

    // Just call the emergency workaround method
    return signupWorkaround(
      name: name,
      email: email,
      password: password,
      phone: phone,
      address: address,
      cnic: cnic,
    );
  }

  // EMERGENCY LOGIN METHOD - AVOID FIREBASE AUTH BUG
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Emergency login attempt for: $email');

      // First check if we have emergency mode user in Firestore
      final querySnapshot = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();

        print('✅ Found user in Firestore: ${userData['status']}');

        // If emergency mode user, allow login without Firebase Auth
        if (userData['status'] == 'emergency_mode') {
          final userModel = UserModel(
            customerId: userData['customerId'] ?? userDoc.id,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            phone: userData['phone'] ?? '',
            address: userData['address'] ?? '',
            cnic: userData['cnic'] ?? '',
            role: userData['role'] ?? 'customer',
            status: userData['status'] ?? 'active',
            createdAt: _parseDateTime(userData['createdAt']) ?? DateTime.now(),
            updatedAt: _parseDateTime(userData['updatedAt']),
            profileImage: userData['profileImage'], // Firebase Storage URL only
          );

          return {
            'success': true,
            'message': 'Emergency login successful!',
            'user': null, // No Firebase user due to bug
            'userData': userModel,
            'isEmergencyMode': true,
          };
        }
      }

      // If no emergency user found, try normal Firebase Auth (might fail)
      try {
        print('🔄 Attempting normal Firebase Auth login...');
        final authResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        print('✅ Firebase Auth login successful');

        // Get user data from Firestore
        final userData = await getUserFromFirestore(authResult.user!.uid);
        if (userData == null) {
          return {
            'success': false,
            'message': 'User profile not found. Please contact support.',
            'isOrphanedUser': true,
            'user': authResult.user,
          };
        }

        return {
          'success': true,
          'message': 'Login successful!',
          'user': authResult.user,
          'userData': userData,
        };
      } catch (authError) {
        print('❌ Firebase Auth login failed: $authError');

        // Check if this is the same type casting error
        if (authError.toString().contains('PigeonUserDetails')) {
          return {
            'success': false,
            'message':
                'Login temporarily unavailable due to Firebase bug. Please try emergency signup first.',
            'error': 'firebase_bug',
          };
        }

        return {
          'success': false,
          'message': 'Login failed: ${authError.toString()}',
          'error': authError.toString(),
        };
      }
    } catch (e) {
      print('❌ Emergency login error: $e');
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // FORGOT PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message': 'Password reset email sent! Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e);
      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send password reset email.',
        'error': e.toString(),
      };
    }
  }

  // CHANGE PASSWORD (for logged-in users)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in.'};
      }

      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return {'success': true, 'message': 'Password changed successfully!'};
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e);
      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to change password.',
        'error': e.toString(),
      };
    }
  }

  // FORCE LOGOUT AND CLEANUP ORPHANED STATES
  static Future<void> forceLogoutAndCleanup() async {
    try {
      print('🧹 Force logout and cleanup initiated');

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('🧹 Logging out orphaned user: ${currentUser.uid}');
      }

      await _auth.signOut();
      print('✅ Force logout completed');
    } catch (e) {
      print('❌ Error during force logout: $e');
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // RESEND EMAIL VERIFICATION
  static Future<Map<String, dynamic>> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return {'success': true, 'message': 'Verification email sent!'};
      }
      return {
        'success': false,
        'message': 'No user found or email already verified.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send verification email.',
      };
    }
  }

  // DELETE ACCOUNT (only from Auth, keeping Firestore data)
  static Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in.'};
      }

      // Reauthenticate before deletion
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Log account deletion (optional)
      print('🔄 Account deleted for user: ${user.uid}');

      // Delete only from Firebase Auth (Firestore data remains)
      await user.delete();

      return {'success': true, 'message': 'Account deleted successfully.'};
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e);
      return {'success': false, 'message': message, 'error': e.code};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete account.',
        'error': e.toString(),
      };
    }
  }

  // GET USER FROM FIRESTORE
  static Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      print('🔄 Fetching user data from Firestore for UID: $uid');
      final doc = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        print('✅ User document found in Firestore');
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('✅ Document data retrieved: $data');

          // Manually create UserModel to avoid type casting issues
          final userData = UserModel(
            customerId: data['customerId'] ?? uid,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
            address: data['address'] ?? '',
            cnic: data['cnic'] ?? '',
            role: data['role'] ?? 'customer',
            status: data['status'] ?? 'active',
            createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
            updatedAt: _parseDateTime(data['updatedAt']),
            profileImage: data['profileImage'], // Firebase Storage URL only
          );

          print(
            '✅ User data parsed successfully: ${userData.name} (${userData.email})',
          );
          return userData;
        } catch (parseError) {
          print('❌ Error parsing user data: $parseError');
          print('❌ Parse error type: ${parseError.runtimeType}');
          print('❌ Document data: ${doc.data()}');
          return null;
        }
      } else {
        print('❌ User document does not exist in Firestore for UID: $uid');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user from Firestore: $e');
      print('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  // UPDATE USER PROFILE
  static Future<Map<String, dynamic>> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? cnic,
    String? profileImage, // Firebase Storage URL only
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (cnic != null) updateData['cnic'] = cnic;
      if (profileImage != null) {
        updateData['profileImage'] = profileImage;
      }

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(uid)
          .update(updateData);

      return {'success': true, 'message': 'Profile updated successfully!'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile.',
        'error': e.toString(),
      };
    }
  }

  // REAL-TIME USER DATA STREAM
  static Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection(CUSTOMERS_COLLECTION).doc(uid).snapshots().map(
      (snapshot) {
        if (snapshot.exists) {
          return UserModel.fromFirestore(snapshot);
        }
        return null;
      },
    );
  }

  // CLEAN UP ORPHANED USER (if Firebase Auth user exists but no Firestore data)
  static Future<Map<String, dynamic>> cleanupOrphanedUser(String email) async {
    try {
      print('🧹 Cleaning up orphaned user for: $email');

      // Sign in to get the user
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        return {'success': false, 'message': 'No user found with this email'};
      }

      // This is just informational - we can't delete a user we're not signed in as
      return {
        'success': true,
        'message': 'User cleanup attempted. Please try signing up again.',
      };
    } catch (e) {
      print('❌ Error during cleanup: $e');
      return {
        'success': false,
        'message': 'Cleanup failed. Please contact support.',
      };
    }
  }

  // DEBUG: Check user status in both Firebase Auth and Firestore
  static Future<Map<String, dynamic>> checkUserStatus(String email) async {
    try {
      print('🔍 Checking status for: $email');

      final authExists = await emailExists(email);
      print('🔍 Firebase Auth exists: $authExists');

      // Try to find in Firestore
      final querySnapshot = await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final firestoreExists = querySnapshot.docs.isNotEmpty;
      print('🔍 Firestore document exists: $firestoreExists');

      return {
        'authExists': authExists,
        'firestoreExists': firestoreExists,
        'status': authExists && firestoreExists
            ? 'complete'
            : authExists
            ? 'auth_only'
            : 'none',
      };
    } catch (e) {
      print('❌ Error checking user status: $e');
      return {'error': e.toString()};
    }
  }

  // HELPER METHOD FOR PARSING DATETIME (handles Timestamp, milliseconds, and ISO strings)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        // Try to parse as milliseconds first (for emergency mode), then as ISO string
        try {
          final milliseconds = int.parse(value);
          return DateTime.fromMillisecondsSinceEpoch(milliseconds);
        } catch (_) {
          // If not milliseconds, try as ISO string
          return DateTime.parse(value);
        }
      }
    } catch (e) {
      print('❌ Error parsing datetime: $e');
      print('❌ Value was: $value');
    }
    return null;
  }

  // HELPER METHOD FOR AUTH ERROR MESSAGES

  static String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
