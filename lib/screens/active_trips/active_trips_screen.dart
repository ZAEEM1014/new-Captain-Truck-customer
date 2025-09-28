import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/dispatch_card.dart';
import '../../models/dispatch_model.dart';
import '../../services/dispatch_service.dart';
import '../dispatch_details/dispatch_details_screen.dart';

class ActiveTripsScreen extends StatefulWidget {
  const ActiveTripsScreen({super.key});

  @override
  State<ActiveTripsScreen> createState() => _ActiveTripsScreenState();
}

class _ActiveTripsScreenState extends State<ActiveTripsScreen> {
  late Stream<List<DispatchModel>> _activeDispatchesStream;

  @override
  void initState() {
    super.initState();
    // Get active dispatches stream (pending, assigned, in-progress)
    _activeDispatchesStream =
        DispatchService.getCurrentUserActiveDispatchesStream();
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
          'Active Trips',
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
              FontAwesomeIcons.listCheck,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Active Trips',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on any trip to view detailed information',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<DispatchModel>>(
                  stream: _activeDispatchesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }

                    final dispatches = snapshot.data ?? [];

                    if (dispatches.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      itemCount: dispatches.length,
                      itemBuilder: (context, index) {
                        final dispatch = dispatches[index];
                        return DispatchCard(
                          dispatch: dispatch,
                          onViewDetails: () =>
                              _navigateToTripDetails(context, dispatch),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load trips',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Image.asset('assets/images/nothing.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Trips',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your active trips will appear here\nonce you create a new dispatch request',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTripDetails(BuildContext context, DispatchModel dispatch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DispatchDetailsScreen(dispatchId: dispatch.dispatchId),
      ),
    );
  }
}
