import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/main_navigation_wrapper.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../active_trips/active_trips_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationWrapper();
  }
}

class HeroImageSection extends StatefulWidget {
  const HeroImageSection({super.key});

  @override
  State<HeroImageSection> createState() => _HeroImageSectionState();
}

class _HeroImageSectionState extends State<HeroImageSection>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late AnimationController _heroImageController;

  final List<String> _heroImages = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
  ];

  @override
  void initState() {
    super.initState();
    _heroImageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _startImageRotation();
  }

  void _startImageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _heroImages.length;
        });
        _heroImageController.forward().then((_) {
          _heroImageController.reset();
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _heroImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Image.asset(
                _heroImages[_currentImageIndex],
                key: ValueKey(_currentImageIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Journey Awaits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request a ride and explore the world with comfort and style',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardContent({super.key, this.onNavigateToTab});

  void _navigateToTab(int tabIndex) {
    onNavigateToTab?.call(tabIndex);
  }

  void _navigateToActiveTrips(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService.currentUserStream,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Fixed Header - Not scrollable
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: FadeSlideAnimation(
                    child: _buildStylishHeader(currentUser),
                  ),
                ),

                // Scrollable content below header
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image with Animation - Isolated component
                        FadeSlideAnimation(
                          beginOffset: const Offset(0, 0.3),
                          child: const HeroImageSection(),
                        ),
                        const SizedBox(height: 40),

                        // All Navigation Options
                        FadeSlideAnimation(
                          beginOffset: const Offset(0, 0.4),
                          child: _buildAllNavigationOptions(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStylishHeader(UserModel? currentUser) {
    // Get the user's first name (or fallback)
    final userName = currentUser?.name.split(' ').first ?? 'User';

    // Check for profile image (Firebase Storage URL only)
    final profileImageUrl = currentUser?.profileImage;
    final hasProfileImage = profileImageUrl?.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.textQuaternary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        color: AppColors.primary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 28,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your next adventure?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _navigateToTab(4), // Navigate to Profile tab
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasProfileImage
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.textQuaternary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: hasProfileImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: _buildProfileImage(currentUser!),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build profile image widget
  Widget _buildProfileImage(UserModel currentUser) {
    final profileImageUrl = currentUser.profileImage;

    // Check if we have a Firebase Storage URL
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return Image.network(
        profileImageUrl,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, color: Colors.white, size: 28);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
      );
    }

    // Default fallback icon
    return const Icon(Icons.person, color: Colors.white, size: 28);
  }

  Widget _buildAllNavigationOptions(BuildContext context) {
    return Column(
      children: [
        // Row 1: New Request & History
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                title: 'Create New\nRequest',
                subtitle: 'Book your next trip',
                icon: FontAwesomeIcons.plus,
                color: AppColors.primary,
                onTap: () => _navigateToTab(2),
                isSmall: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavigationCard(
                title: 'History',
                subtitle: 'View previous trips',
                icon: FontAwesomeIcons.clockRotateLeft,
                color: AppColors.success,
                onTap: () => _navigateToTab(1),
                isSmall: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Notifications & Profile
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                title: 'Notifications',
                subtitle: 'Check updates',
                icon: FontAwesomeIcons.bell,
                color: AppColors.textQuaternary,
                onTap: () => _navigateToTab(3),
                isSmall: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavigationCard(
                title: 'Profile',
                subtitle: 'Manage account',
                icon: FontAwesomeIcons.user,
                color: AppColors.error,
                onTap: () => _navigateToTab(4),
                isSmall: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 3: Active Trips (Full Width)
        _buildNavigationCard(
          title: 'Active Trips',
          subtitle: 'View and track your current trips',
          icon: FontAwesomeIcons.truckFast,
          color: AppColors.success,
          onTap: () => _navigateToActiveTrips(context),
          isSmall: false,
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? null : double.infinity,
        height: isSmall ? 140 : null,
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: color.withOpacity(0.08), width: 1),
        ),
        child: isSmall
            ? _buildSmallCardContent(title, subtitle, icon, color)
            : _buildLargeCardContent(title, subtitle, icon, color),
      ),
    );
  }

  Widget _buildSmallCardContent(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _getButtonText(title),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeCardContent(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _getButtonText(title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  String _getButtonText(String title) {
    if (title.contains('New') || title.contains('Create')) return 'GO';
    if (title.contains('History') || title.contains('View')) return 'VIEW';
    if (title.contains('Notifications') || title.contains('Check')) {
      return 'OPEN';
    }
    if (title.contains('Profile') || title.contains('Manage')) return 'EDIT';
    return 'OPEN';
  }
}
