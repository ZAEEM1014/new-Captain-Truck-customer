import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CUSTOMERS_COLLECTION = 'customers';

  // Current user stream for real-time updates
  static Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser != null) {
        print('🔄 Auth state changed: User logged in (${firebaseUser.uid})');
        return getUserStream(firebaseUser.uid);
      } else {
        print('🔄 Auth state changed: User logged out');
        return Stream.value(null);
      }
    });
  }

  // Get current Firebase user
  static User? get currentFirebaseUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // SIGNUP
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    String? cnic,
  }) async {
    try {
      print('🔄 Starting signup process for: $email');

      // Basic validation
      if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Please fill in all required fields.',
          'error': 'validation_failed',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long.',
          'error': 'weak-password',
        };
      }

      UserCredential? authResult;
      User? user;

      try {
        // Attempt Firebase Auth creation
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = authResult.user;
      } catch (authError) {
        // Handle the specific Firebase Auth plugin bug
        if (authError.toString().contains(
          'type \'List<Object?>\' is not a subtype of type \'PigeonUserDetails?\'',
        )) {
          print('🔄 Detected Firebase Auth plugin bug, attempting recovery...');

          // The user was likely created but the plugin crashed
          // Try to get the current user after a brief delay
          await Future.delayed(Duration(milliseconds: 500));
          user = _auth.currentUser;

          if (user == null) {
            // If still no user, the creation truly failed
            print('❌ Firebase Auth creation failed completely');
            return {
              'success': false,
              'message':
                  'Account creation failed due to Firebase Auth plugin issue. Please try again.',
              'error': 'firebase_auth_plugin_error',
            };
          } else {
            print(
              '✅ Recovered from Firebase Auth plugin bug - user exists: ${user.uid}',
            );
          }
        } else {
          // Re-throw other auth errors normally
          rethrow;
        }
      }

      if (user == null) {
        throw Exception('User creation failed - no user returned');
      }

      print('✅ Firebase Auth user created/recovered: ${user.uid}');

      // Create user document in Firestore
      final userData = {
        'customerId': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'cnic': cnic,
        'role': 'customer',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'profileImage': null,
      };

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(user.uid)
          .set(userData);
      print('✅ User document created in Firestore');

      // Send email verification (with error handling)
      try {
        await user.sendEmailVerification();
        print('✅ Email verification sent');
      } catch (verificationError) {
        print('⚠️ Email verification failed: $verificationError');
        // Continue anyway - verification failure shouldn't block signup
      }

      return {
        'success': true,
        'message': 'Account created successfully! Please verify your email.',
        'user': user,
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');

      // Clean up if user was created but Firestore failed
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}

      return {
        'success': false,
        'message': _getAuthErrorMessage(e),
        'error': e.code,
      };
    } catch (e) {
      print('❌ Unexpected signup error: $e');

      // Clean up if user was created but Firestore failed
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}

      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Attempting login for: $email');

      UserCredential? authResult;
      User? user;

      try {
        // Attempt Firebase Auth sign in
        authResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = authResult.user;
      } catch (authError) {
        // Handle the specific Firebase Auth plugin bug
        if (authError.toString().contains(
          'type \'List<Object?>\' is not a subtype of type \'PigeonUserDetails?\'',
        )) {
          print(
            '🔄 Detected Firebase Auth plugin bug during login, attempting recovery...',
          );

          // Check if user got signed in despite the crash
          await Future.delayed(Duration(milliseconds: 500));
          user = _auth.currentUser;

          if (user == null) {
            print('❌ Login failed completely due to Firebase Auth plugin bug');
            return {
              'success': false,
              'message':
                  'Login failed due to Firebase Auth plugin issue. Please try again.',
              'error': 'firebase_auth_plugin_error',
            };
          } else {
            print(
              '✅ Recovered from Firebase Auth plugin bug - user signed in: ${user.uid}',
            );
          }
        } else {
          // Re-throw other auth errors normally
          rethrow;
        }
      }

      if (user == null) {
        throw Exception('Login failed - no user returned');
      }

      print('✅ Firebase Auth login successful/recovered');

      // CHECK EMAIL VERIFICATION
      if (!user.emailVerified) {
        await _auth.signOut();
        return {
          'success': false,
          'needsEmailVerification': true,
          'message':
              'Please verify your email before logging in. Check your inbox and click the verification link.',
          'error': 'email_not_verified',
          'user': user,
        };
      }

      // Get user data from Firestore
      final userData = await getUserFromFirestore(user.uid);
      if (userData == null) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User profile not found. Please contact support.',
          'error': 'profile_not_found',
        };
      }

      // Check user status
      if (userData.status != 'active') {
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Your account is ${userData.status}. Please contact support.',
          'error': 'account_${userData.status}',
        };
      }

      print('✅ Login successful for: ${userData.name}');

      return {
        'success': true,
        'message': 'Login successful!',
        'user': user,
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth login error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e),
        'error': e.code,
      };
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
        'error': e.toString(),
      };
    }
  }

  // FORGOT PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔄 Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent');

      return {
        'success': true,
        'message': 'Password reset email sent! Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e),
        'error': e.code,
      };
    } catch (e) {
      print('❌ Unexpected password reset error: $e');
      return {
        'success': false,
        'message': 'Failed to send password reset email.',
        'error': e.toString(),
      };
    }
  }

  // CHANGE PASSWORD
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔄 Changing password');

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user logged in.',
          'error': 'no_user',
        };
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      print('✅ User re-authenticated');

      // Update password
      await user.updatePassword(newPassword);
      print('✅ Password updated successfully');

      return {'success': true, 'message': 'Password changed successfully!'};
    } on FirebaseAuthException catch (e) {
      print('❌ Change password error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e),
        'error': e.code,
      };
    } catch (e) {
      print('❌ Unexpected change password error: $e');
      return {
        'success': false,
        'message': 'Failed to change password.',
        'error': e.toString(),
      };
    }
  }

  // DELETE ACCOUNT
  static Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      print('🔄 Deleting account');

      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user logged in.',
          'error': 'no_user',
        };
      }

      final uid = user.uid;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      print('✅ User re-authenticated for deletion');

      // Update user status in Firestore instead of deleting (for data integrity)
      await _firestore.collection(CUSTOMERS_COLLECTION).doc(uid).update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User marked as deleted in Firestore');

      // Delete Firebase Auth account
      await user.delete();
      print('✅ Firebase Auth account deleted');

      return {'success': true, 'message': 'Account deleted successfully.'};
    } on FirebaseAuthException catch (e) {
      print('❌ Delete account error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e),
        'error': e.code,
      };
    } catch (e) {
      print('❌ Unexpected delete account error: $e');
      return {
        'success': false,
        'message': 'Failed to delete account.',
        'error': e.toString(),
      };
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      print('🔄 Logging out user');
      await _auth.signOut();
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // RESEND EMAIL VERIFICATION
  static Future<Map<String, dynamic>> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in.'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email is already verified.'};
      }

      await user.sendEmailVerification();
      print('✅ Email verification resent');

      return {
        'success': true,
        'message': 'Verification email sent! Please check your inbox.',
      };
    } catch (e) {
      print('❌ Resend email verification error: $e');
      return {
        'success': false,
        'message': 'Failed to send verification email.',
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
        return UserModel.fromFirestore(doc);
      } else {
        print('❌ User document not found in Firestore for UID: $uid');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user from Firestore: $e');
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
      print('🔄 Updating user profile for UID: $uid');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        updateData['phone'] = phone.trim();
      }
      if (address != null && address.trim().isNotEmpty) {
        updateData['address'] = address.trim();
      }
      if (cnic != null && cnic.trim().isNotEmpty) {
        updateData['cnic'] = cnic.trim();
      }

      // Handle profile image - Firebase Storage URL only
      if (profileImage != null) {
        updateData['profileImage'] = profileImage;
      }

      // Remove old base64 field if it exists (cleanup)
      updateData['profileImageBase64'] = FieldValue.delete();

      await _firestore
          .collection(CUSTOMERS_COLLECTION)
          .doc(uid)
          .update(updateData);

      print('✅ User profile updated successfully');

      return {'success': true, 'message': 'Profile updated successfully!'};
    } catch (e) {
      print('❌ Error updating user profile: $e');
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
        if (snapshot.exists && snapshot.data() != null) {
          return UserModel.fromFirestore(snapshot);
        }
        return null;
      },
    );
  }

  // Helper method for auth error messages
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
      case 'requires-recent-login':
        return 'Please log out and log back in before performing this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
