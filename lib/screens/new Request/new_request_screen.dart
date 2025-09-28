import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/custom_app_bar.dart';
import 'dispatch_request_screen.dart';

class NewRequestScreen extends StatefulWidget {
  final bool showAppBar;

  const NewRequestScreen({super.key, this.showAppBar = true});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'New Request',
              actions: [
                GestureDetector(
                  onTap: () => _navigateToDispatch(),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.plus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(child: _buildCreateRequestState()),
    );
  }

  Widget _buildCreateRequestState() {
    return FadeSlideAnimation(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nothing image
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/delivery.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Text
            Text(
              'Ready to Create Request',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start your new dispatch request\nand track your shipments efficiently',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Create Request Button
            GestureDetector(
              onTap: () => _navigateToDispatch(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.textQuaternary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.plus, color: Colors.white, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Create New Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDispatch() async {
    // Navigate to dispatch screen and when request is created,
    // it will be added to Active Trips automatically
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DispatchRequestScreen()),
    );
  }
}
