import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugHelper {
  static void log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$level] $timestamp - $message');
  }

  static void logError(String message, [dynamic error]) {
    log('ERROR: $message${error != null ? ' - $error' : ''}', level: 'ERROR');
  }

  static void logSuccess(String message) {
    log('SUCCESS: $message', level: 'SUCCESS');
  }

  // Debug profile image upload process
  static Future<void> debugImageUpload(File imageFile) async {
    log('🔍 DEBUG: Starting profile image upload debug...');

    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logError('No authenticated user found');
        return;
      }
      log('✅ User authenticated: ${user.uid}');

      // Check file existence and size
      if (!await imageFile.exists()) {
        logError('Image file does not exist: ${imageFile.path}');
        return;
      }

      final fileSize = await imageFile.length();
      log(
        '📄 File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
      );

      // Check Firebase Storage connection
      try {
        final storage = FirebaseStorage.instance;
        // Just verify we can create a reference
        storage.ref().child('test/connection_test.txt');
        log('🔗 Firebase Storage connection test passed');
      } catch (e) {
        logError('Firebase Storage connection failed', e);
        return;
      }

      // Test upload path
      final originalFileName = imageFile.path.split('/').last;
      final storagePath = 'customers/${user.uid}/$originalFileName';
      log('📂 Upload path: $storagePath');

      // Check Firestore connection
      try {
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore
            .collection('customers')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          log('✅ User document exists in Firestore');
          final userData = userDoc.data();
          log(
            '👤 Current profile image: ${userData?['profileImage'] ?? 'none'}',
          );
        } else {
          logError('User document does not exist in Firestore');
        }
      } catch (e) {
        logError('Firestore connection failed', e);
      }

      log('🔍 DEBUG: Profile image upload debug completed');
    } catch (e) {
      logError('Debug process failed', e);
    }
  }

  // Check Firebase Storage rules and permissions
  static Future<void> checkStoragePermissions() async {
    log('🔍 Checking Firebase Storage permissions...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logError('No authenticated user for permission check');
        return;
      }

      final storage = FirebaseStorage.instance;
      final testPath = 'customers/${user.uid}/test.txt';
      final ref = storage.ref().child(testPath);

      // Try to upload a small test file
      try {
        final testData = 'test data ${DateTime.now().millisecondsSinceEpoch}';
        await ref.putString(testData);
        log('✅ Storage write permission: OK');

        // Try to read the test file
        final downloadUrl = await ref.getDownloadURL();
        log('✅ Storage read permission: OK');
        log('🔗 Test file URL: $downloadUrl');

        // Clean up test file
        await ref.delete();
        log('✅ Storage delete permission: OK');
      } catch (e) {
        logError('Storage permission test failed', e);
      }
    } catch (e) {
      logError('Permission check failed', e);
    }
  }

  // List all files in user's storage folder
  static Future<void> listUserFiles() async {
    log('📁 Listing user files in storage...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logError('No authenticated user');
        return;
      }

      final storage = FirebaseStorage.instance;
      final folderRef = storage.ref().child('customers/${user.uid}');

      final listResult = await folderRef.listAll();

      if (listResult.items.isEmpty) {
        log('📁 No files found in user folder');
      } else {
        log('📁 Found ${listResult.items.length} files:');
        for (var item in listResult.items) {
          try {
            final metadata = await item.getMetadata();
            final downloadUrl = await item.getDownloadURL();
            log('   📄 ${item.name} - Size: ${metadata.size} bytes');
            log('   🔗 URL: $downloadUrl');
          } catch (e) {
            log('   ❌ Error getting info for ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      logError('Failed to list user files', e);
    }
  }
}
