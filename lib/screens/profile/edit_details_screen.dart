import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/form_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_popup.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class EditDetailsScreen extends StatefulWidget {
  const EditDetailsScreen({super.key});

  @override
  State<EditDetailsScreen> createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cnicController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  // ignore: unused_field
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentFirebaseUser;
      if (user != null) {
        final userData = await AuthService.getUserFromFirestore(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = userData;
            _nameController.text = userData.name;
            _emailController.text = userData.email;
            _phoneController.text = userData.phone;
            _addressController.text = userData.address;
            _cnicController.text = userData.cnic;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        CustomPopup.showError(context, 'Error', 'Failed to load user data');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = AuthService.currentFirebaseUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final result = await AuthService.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        cnic: _cnicController.text.trim(),
      );

      if (result['success']) {
        CustomPopup.showSuccess(
          context,
          'Success!',
          'Profile updated successfully',
        );
        // Wait a moment then go back
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        CustomPopup.showError(
          context,
          'Update Failed',
          result['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      CustomPopup.showError(context, 'Error', 'An unexpected error occurred');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Details',
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
              FontAwesomeIcons.userPen,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: FadeSlideAnimation(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.userPen,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Update your personal details below',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Name
                              FormTextField(
                                controller: _nameController,
                                hintText: 'Full Name',
                                prefixIcon: FontAwesomeIcons.user,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'Name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Email (read-only)
                              FormTextField(
                                controller: _emailController,
                                hintText: 'Email Address',
                                prefixIcon: FontAwesomeIcons.envelope,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email cannot be changed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Phone
                              FormTextField(
                                controller: _phoneController,
                                hintText: 'Phone Number',
                                prefixIcon: FontAwesomeIcons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Address
                              FormTextField(
                                controller: _addressController,
                                hintText: 'Address',
                                prefixIcon: FontAwesomeIcons.locationDot,
                                maxLines: 2,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'Address is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // CNIC
                              FormTextField(
                                controller: _cnicController,
                                hintText: 'CNIC Number',
                                prefixIcon: FontAwesomeIcons.idCard,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.trim().isEmpty ?? true) {
                                    return 'CNIC is required';
                                  }
                                  // Basic CNIC validation (13 digits with optional dashes)
                                  final cnicPattern = RegExp(
                                    r'^\d{5}-?\d{7}-?\d{1}$',
                                  );
                                  if (!cnicPattern.hasMatch(
                                    value!.replaceAll('-', ''),
                                  )) {
                                    return 'Enter a valid CNIC (e.g., 12345-1234567-1)';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: CustomButton(
                          text: _isSaving ? 'Saving...' : 'Save Changes',
                          onPressed: () => _saveDetails(),
                          enabled: !_isSaving,
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
