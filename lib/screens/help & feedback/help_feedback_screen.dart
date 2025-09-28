import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/form_text_field.dart';
import '../../widgets/custom_button.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Company contact information
  final String companyPhone = '+923001234567'; // Pakistani phone number
  final String companyEmail = 'support@customerapp.com';
  final String whatsappNumber =
      '923001234567'; // Pakistani WhatsApp number without +

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _callCompany() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: companyPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Phone app not available');
      }
    } catch (e) {
      _showErrorDialog('Could not open phone dialer: $e');
    }
  }

  Future<void> _emailCompany() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: companyEmail,
      queryParameters: {
        'subject': 'Customer Support Inquiry',
        'body': 'Hello,\n\nI need assistance with...',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Email app not available');
      }
    } catch (e) {
      _showErrorDialog('Could not open email app: $e');
    }
  }

  Future<void> _whatsappCompany() async {
    // Try multiple WhatsApp URL formats for better compatibility
    final List<String> whatsappUrls = [
      'whatsapp://send?phone=$whatsappNumber&text=Hello, I need assistance with my truck dispatch request.',
      'https://wa.me/$whatsappNumber?text=Hello, I need assistance with my truck dispatch request.',
      'https://api.whatsapp.com/send?phone=$whatsappNumber&text=Hello, I need assistance with my truck dispatch request.',
    ];

    bool launched = false;

    for (String urlString in whatsappUrls) {
      try {
        final Uri whatsappUri = Uri.parse(urlString);
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        print('Failed to launch WhatsApp with URL: $urlString - Error: $e');
      }
    }

    if (!launched) {
      _showErrorDialog('WhatsApp is not installed or available on this device');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Error',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Submitting feedback...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );

        // Save feedback to Firestore
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('feedbacks').add({
          'feedback': _feedbackController.text.trim(),
          'customerId': user?.uid,
          'customerEmail': user?.email,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'type': 'general',
        });

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Feedback Sent!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            content: const Text(
              'Thank you for your feedback! We\'ll review it and get back to you soon.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _feedbackController.clear();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close loading dialog if open
        Navigator.of(context).pop();

        // Show error dialog
        _showErrorDialog('Failed to submit feedback. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.3),
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
          'Help & Feedback',
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
              FontAwesomeIcons.headset,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeSlideAnimation(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.headset,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Need Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'re here to help! Contact our support team or send us feedback.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Options
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contact Support',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Cards
                _buildContactCard(
                  icon: FontAwesomeIcons.phone,
                  title: 'Call Us',
                  subtitle: companyPhone,
                  color: Colors.green,
                  onTap: _callCompany,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: FontAwesomeIcons.envelope,
                  title: 'Email Us',
                  subtitle: companyEmail,
                  color: Colors.blue,
                  onTap: _emailCompany,
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: FontAwesomeIcons.whatsapp,
                  title: 'WhatsApp',
                  subtitle: 'Chat with us instantly',
                  color: const Color(0xFF25D366),
                  onTap: _whatsappCompany,
                ),
                const SizedBox(height: 24),

                // Feedback Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Feedback',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let us know how we can improve your experience.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormTextField(
                          controller: _feedbackController,
                          hintText:
                              'Share your thoughts, suggestions, or report issues...',
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your feedback';
                            }
                            if (value.length < 10) {
                              return 'Feedback must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Submit Feedback',
                          onPressed: _submitFeedback,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FontAwesomeIcons.chevronRight,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
