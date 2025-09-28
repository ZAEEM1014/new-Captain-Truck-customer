import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/custom_button.dart';
import '../../constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/custom_popup.dart';
import '../../widgets/email_verification_popup.dart';
import '../../services/auth_service.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  void _showEmailVerificationDialog(String message, String title) {
    EmailVerificationPopup.show(context);
  }

  void _showEmailExistsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Account Already Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            SizedBox(height: 16),
            Text(
              'This email is already registered. Would you like to login instead?',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      nameController.clear();
      mobileController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      addressController.clear();
      passwordObscure = true;
      confirmPasswordObscure = true;
    });
  }
  bool _isLoading = false;
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();

  bool passwordObscure = true;
  bool confirmPasswordObscure = true;

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        phone: mobileController.text.trim(),
        address: addressController.text.trim(),
        // CNIC removed for Canadian format
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showEmailVerificationDialog(
          result['message'] ?? 'Please verify your email',
          'Account created successfully!',
        );
      } else {
        final errorCode = result['error'];
        final message =
            result['message'] ?? 'Failed to create account. Please try again.';

        if (errorCode == 'email-already-in-use') {
          _showEmailExistsDialog(message);
        } else {
          CustomPopup.showError(context, 'Signup Failed', message);
        }
      }
    } catch (e) {
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

  bool _validateAllFields() {
    // Name validation - only letters, spaces, hyphens, apostrophes
    String name = nameController.text.trim();
    if (name.isEmpty) {
      CustomPopup.showError(context, 'Validation Error', 'Name is required');
      return false;
    }
    // Accepts letters (including accents), spaces, hyphens, apostrophes
    if (!RegExp(r"^[A-Za-zÀ-ÿ'\- ]+").hasMatch(name)) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Name should only contain letters, spaces, hyphens, or apostrophes',
      );
      return false;
    }
    if (name.replaceAll(RegExp(r"[^A-Za-zÀ-ÿ]"), '').length < 2) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Name must be at least 2 letters long',
      );
      return false;
    }

    // Phone validation - Canadian format
    String phone = mobileController.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Phone number is required',
      );
      return false;
    }
    // Accepts 10 digits, or +1 followed by 10 digits
    if (!RegExp(r'^(\+1)?[2-9][0-9]{9}$').hasMatch(phone)) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Please enter a valid Canadian mobile number (e.g., 4161234567 or +14161234567)',
      );
      return false;
    }

    // Email validation
    String email = emailController.text.trim();
    if (email.isEmpty) {
      CustomPopup.showError(context, 'Validation Error', 'Email is required');
      return false;
    }
    // RFC 5322 Official Standard email regex (simplified)
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(email)) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Please enter a valid email address',
      );
      return false;
    }

    // Password validation - strong password requirements
    String password = passwordController.text;
    if (password.isEmpty) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Password is required',
      );
      return false;
    }
    if (password.length < 8) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Password must be at least 8 characters long',
      );
      return false;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_\-])[A-Za-z\d!@#\$&*~_\-]{8,}$').hasMatch(password)) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character (!@#\$&*~_-)',
      );
      return false;
    }

    // Confirm password validation
    String confirmPassword = confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Please confirm your password',
      );
      return false;
    }
    if (password != confirmPassword) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Passwords do not match',
      );
      return false;
    }

    // Address validation
    String address = addressController.text.trim();
    if (address.isEmpty) {
      CustomPopup.showError(context, 'Validation Error', 'Address is required');
      return false;
    }
    if (address.length < 10) {
      CustomPopup.showError(
        context,
        'Validation Error',
        'Please enter a complete address (at least 10 characters)',
      );
      return false;
    }

    return true;
    setState(() {
      nameController.clear();
      mobileController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      addressController.clear();
      passwordObscure = true;
      confirmPasswordObscure = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth > 500
                          ? constraints.maxWidth * 0.2
                          : 24.0,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          width: size.width * 0.60,
                          height: size.width * 0.60,
                        ),
                        Transform(
                          transform: Matrix4.translationValues(0, -50, 0),
                          child: Text(
                            'Book & Relax',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextField(
                                  label: 'Name',
                                  hint: 'Enter Name',
                                  controller: nameController,
                                  keyboardType: TextInputType.name,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.user,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  helpText: 'Only letters and spaces allowed (minimum 2 characters)',
                                  key: const ValueKey('nameField'),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Mobile Number',
                                  hint: 'Enter Mobile Number',
                                  controller: mobileController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.phone,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  helpText: 'Canadian format: 4161234567 or +14161234567',
                                  key: const ValueKey('mobileField'),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Email',
                                  hint: 'thisand@that.com',
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.envelope,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  helpText: 'Valid email address required for verification',
                                  key: const ValueKey('emailField'),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Password',
                                  hint: 'Enter Password',
                                  controller: passwordController,
                                  obscureText: passwordObscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.lock,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      passwordObscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        passwordObscure = !passwordObscure;
                                      });
                                    },
                                  ),
                                  helpText: 'At least 8 characters with uppercase, lowercase, number, and special character',
                                  key: const ValueKey('passwordField'),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Confirm Password',
                                  hint: 'Re-enter Password',
                                  controller: confirmPasswordController,
                                  obscureText: confirmPasswordObscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.lock,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      confirmPasswordObscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        confirmPasswordObscure = !confirmPasswordObscure;
                                      });
                                    },
                                  ),
                                  helpText: 'Must match the password entered above',
                                  key: const ValueKey('confirmPasswordField'),
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  label: 'Address',
                                  hint: 'Enter Address',
                                  controller: addressController,
                                  keyboardType: TextInputType.streetAddress,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.locationDot,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                  helpText: 'Complete address with at least 10 characters',
                                  key: const ValueKey('addressField'),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: _isLoading ? 'Creating Account...' : 'Create Account',
                                  onPressed: _isLoading ? () {} : () { _handleSignup(); },
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _resetForm,
                                    icon: Icon(
                                      FontAwesomeIcons.penToSquare,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Reset',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.background,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
