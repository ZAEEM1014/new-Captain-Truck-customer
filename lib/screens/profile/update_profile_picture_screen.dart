import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_popup.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
// ignore: unused_import
import '../../utils/debug_helper.dart';

class UpdateProfilePictureScreen extends StatefulWidget {
  const UpdateProfilePictureScreen({super.key});

  @override
  State<UpdateProfilePictureScreen> createState() =>
      _UpdateProfilePictureScreenState();
}

class _UpdateProfilePictureScreenState
    extends State<UpdateProfilePictureScreen> {
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentProfilePicture();
  }

  Future<void> _loadCurrentProfilePicture() async {
    final user = AuthService.currentFirebaseUser;
    if (user != null) {
      final userData = await AuthService.getUserFromFirestore(user.uid);
      if (userData != null &&
          userData.profileImage != null &&
          userData.profileImage!.isNotEmpty) {
        setState(() {
          _currentImageUrl = userData.profileImage;
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: FontAwesomeIcons.camera,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: FontAwesomeIcons.image,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (_currentImageUrl != null || _selectedImage != null)
                  _buildSourceOption(
                    icon: FontAwesomeIcons.trash,
                    label: 'Remove',
                    onTap: () => _removeImage(),
                    color: AppColors.error,
                  ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      CustomPopup.showError(
        context,
        'Error',
        'Failed to pick image. Please try again.',
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });

    // Remove from Firebase Storage and update Firestore
    await _updateProfilePicture(null);
  }

  Future<void> _updateProfilePicture(File? imageFile) async {
    setState(() => _isLoading = true);

    try {
      final user = AuthService.currentFirebaseUser;
      if (user == null) {
        print('❌ No user logged in');
        CustomPopup.showError(context, 'Error', 'No user logged in');
        return;
      }

      print('📸 User UID: ${user.uid}');

      String? profileImageUrl;

      if (imageFile != null) {
        print('📸 Starting image upload for user: ${user.uid}');
        print('📸 Image file path: ${imageFile.path}');
        print('📸 Image file size: ${await imageFile.length()} bytes');

        // Upload to Firebase Storage
        final uploadResult = await StorageService.uploadProfileImage(imageFile);

        print('📸 Upload result: $uploadResult');

        if (!uploadResult['success']) {
          print('❌ Upload failed: ${uploadResult['message']}');
          CustomPopup.showError(
            context,
            'Upload Error',
            uploadResult['message'] ?? 'Failed to upload image',
          );
          return;
        }

        profileImageUrl = uploadResult['downloadUrl'];
        print('📸 Got download URL: $profileImageUrl');
      } else {
        print('📸 Deleting profile image');
        // Delete from Firebase Storage
        final deleteResult = await StorageService.deleteProfileImage();
        print('📸 Delete result: $deleteResult');
        profileImageUrl = null;
      }

      // Update user profile in Firestore
      print('📸 Updating Firestore with URL: $profileImageUrl');
      final result = await AuthService.updateUserProfile(
        uid: user.uid,
        profileImage:
            profileImageUrl, // Use download URL instead of storage path
      );

      print('📸 Firestore update result: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ Profile picture updated successfully');
        CustomPopup.showSuccess(
          context,
          'Success!',
          imageFile == null
              ? 'Profile picture removed successfully!'
              : 'Profile picture updated successfully!',
        );

        // Reload the current image after successful update
        await _loadCurrentProfilePicture();

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        print('❌ Firestore update failed: ${result['message']}');
        CustomPopup.showError(
          context,
          'Error',
          result['message'] ?? 'Failed to update profile picture',
        );
      }
    } catch (e) {
      print('📸 Error in _updateProfilePicture: $e');
      print('📸 Stack trace: ${StackTrace.current}');
      if (mounted) {
        CustomPopup.showError(
          context,
          'Error',
          'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null) return;
    await _updateProfilePicture(_selectedImage);
  }

  Widget _buildImagePreview() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : _currentImageUrl != null
            ? _buildCurrentImage()
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, size: 80, color: AppColors.primary),
              ),
      ),
    );
  }

  // Helper method to build current profile image widget
  Widget _buildCurrentImage() {
    if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, size: 80, color: AppColors.primary),
      );
    }

    // Display Firebase Storage URL
    return Image.network(
      _currentImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, size: 80, color: AppColors.primary),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.arrowLeft,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Update Profile Picture',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FontAwesomeIcons.camera,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        FontAwesomeIcons.userPen,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Profile Picture',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload or change your profile picture',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Image Preview
                _buildImagePreview(),
                SizedBox(height: 32),

                // Action Buttons
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Select Image Button
                      CustomButton(
                        text: 'Select Image',
                        onPressed: _isLoading ? () {} : _showImageSourceDialog,
                      ),
                      SizedBox(height: 16),

                      // Save Button (only show if image is selected)
                      if (_selectedImage != null)
                        CustomButton(
                          text: _isLoading ? 'Updating...' : 'Save Changes',
                          onPressed: _isLoading ? () {} : _saveImage,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Guidelines
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Guidelines:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Use a clear, front-facing photo\n'
                        '• Square images work best\n'
                        '• Image will be automatically resized\n'
                        '• Supported formats: JPG, PNG',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
