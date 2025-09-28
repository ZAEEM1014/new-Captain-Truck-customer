import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/previous%20trips/previous_trips_screen.dart';
import '../screens/new%20Request/new_request_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/notification_service.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Listen to unread notifications count
    NotificationService.getUnreadNotificationsCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTapped(int index) {
    // Mark notifications as read when visiting notifications screen
    if (index == 3 && _unreadNotificationsCount > 0) {
      NotificationService.markAllNotificationsAsRead();
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    return [
      const BottomNavigationBarItem(
        icon: FaIcon(FontAwesomeIcons.house),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: FaIcon(FontAwesomeIcons.clockRotateLeft),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: FaIcon(FontAwesomeIcons.plus),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Stack(
          children: [
            const FaIcon(FontAwesomeIcons.bell),
            if (_unreadNotificationsCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadNotificationsCount > 99
                        ? '99+'
                        : '$_unreadNotificationsCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: FaIcon(FontAwesomeIcons.user),
        label: '',
      ),
    ];
  }

  void _navigateToTab(int index) {
    _onNavigationTapped(index);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardContent(onNavigateToTab: _navigateToTab);
      case 1:
        return const PreviousTripsScreen(showAppBar: false);
      case 2:
        return const NewRequestScreen(showAppBar: false);
      case 3:
        return const NotificationsScreen(showAppBar: false);
      case 4:
        return const ProfileScreen(showAppBar: false);
      default:
        return DashboardContent(onNavigateToTab: _navigateToTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on dashboard (index 0), navigate to dashboard
        if (_currentIndex != 0) {
          _onNavigationTapped(0);
          return false; // Don't exit the app
        }
        // If on dashboard, allow exit
        return true;
      },
      child: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: 5, // Fixed count for 5 navigation items
          itemBuilder: (context, index) => _buildScreen(index),
        ),
        bottomNavigationBar: Container(
          height: 85, // Increased height
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavigationTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textTertiary,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            iconSize: 24,
            items: _buildNavigationItems(),
          ),
        ),
      ),
    );
  }
}
