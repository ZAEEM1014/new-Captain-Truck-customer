import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload profile image to Firebase Storage
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Get the original filename with extension
      final originalFileName = imageFile.path.split('/').last;

      // Create file path: customers/{customerId}/{originalFileName}
      final filePath = 'customers/${user.uid}/$originalFileName';

      // Create reference to Firebase Storage
      final ref = _storage.ref().child(filePath);

      // Create proper metadata to avoid null reference error
      final metadata = SettableMetadata(
        contentType: _getContentType(originalFileName),
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file with metadata
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'message': 'Profile image uploaded successfully',
        'downloadUrl': downloadUrl,
        'storagePath': filePath,
        'fileName': originalFileName,
      };
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return {
        'success': false,
        'message': 'Failed to upload image: ${e.toString()}',
      };
    }
  }

  // Helper method to get content type based on file extension
  static String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  // Upload profile image from bytes (for web compatibility)
  static Future<Map<String, dynamic>> uploadProfileImageFromBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Create file path: customers/{customerId}/{fileName}
      final filePath = 'customers/${user.uid}/$fileName';

      // Create reference to Firebase Storage
      final ref = _storage.ref().child(filePath);

      // Create proper metadata to avoid null reference error
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload bytes with metadata
      final uploadTask = ref.putData(imageBytes, metadata);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'message': 'Profile image uploaded successfully',
        'downloadUrl': downloadUrl,
        'storagePath': filePath,
        'fileName': fileName,
      };
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return {
        'success': false,
        'message': 'Failed to upload image: ${e.toString()}',
      };
    }
  }

  // Delete profile image from Firebase Storage
  static Future<Map<String, dynamic>> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // List all files in the customer's folder
      final folderRef = _storage.ref().child('customers/${user.uid}');
      final listResult = await folderRef.listAll();

      // Delete all image files in the folder
      for (var item in listResult.items) {
        try {
          await item.delete();
          print('✅ Deleted file: ${item.name}');
        } catch (e) {
          print('❌ Error deleting ${item.name}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Profile images deleted successfully',
      };
    } catch (e) {
      print('❌ Error deleting profile images: $e');
      return {
        'success': false,
        'message': 'Failed to delete images: ${e.toString()}',
      };
    }
  }

  // Get profile image download URL - now searches for any image file
  static Future<String?> getProfileImageUrl(String customerId) async {
    try {
      // List all files in the customer's folder
      final folderRef = _storage.ref().child('customers/$customerId');
      final listResult = await folderRef.listAll();

      // Find the first image file (you can add more sophisticated logic here)
      for (var item in listResult.items) {
        final fileName = item.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp')) {
          return await item.getDownloadURL();
        }
      }

      return null; // No image found
    } catch (e) {
      print('❌ Error getting profile image URL: $e');
      return null;
    }
  }

  // Check if profile image exists - now checks for any image file
  static Future<bool> profileImageExists(String customerId) async {
    try {
      // List all files in the customer's folder
      final folderRef = _storage.ref().child('customers/$customerId');
      final listResult = await folderRef.listAll();

      // Check if any image file exists
      for (var item in listResult.items) {
        final fileName = item.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp')) {
          return true;
        }
      }

      return false; // No image found
    } catch (e) {
      print('❌ Error checking if profile image exists: $e');
      return false;
    }
  }

  // Get all images for a customer
  static Future<List<Map<String, String>>> getAllCustomerImages(
    String customerId,
  ) async {
    try {
      final folderRef = _storage.ref().child('customers/$customerId');
      final listResult = await folderRef.listAll();

      List<Map<String, String>> images = [];

      for (var item in listResult.items) {
        final fileName = item.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp')) {
          try {
            final downloadUrl = await item.getDownloadURL();
            images.add({
              'fileName': item.name,
              'downloadUrl': downloadUrl,
              'storagePath': item.fullPath,
            });
          } catch (e) {
            print('❌ Error getting download URL for ${item.name}: $e');
          }
        }
      }

      return images;
    } catch (e) {
      print('❌ Error getting customer images: $e');
      return [];
    }
  }
}
