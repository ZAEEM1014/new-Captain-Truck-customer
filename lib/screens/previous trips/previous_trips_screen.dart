import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/dispatch_card.dart';
import '../../widgets/custom_animation.dart';
import '../../services/dispatch_service.dart';
import '../../models/dispatch_model.dart';
import 'previous_trip_details_screen.dart';

class PreviousTripsScreen extends StatefulWidget {
  final bool showAppBar;

  const PreviousTripsScreen({super.key, this.showAppBar = true});

  @override
  State<PreviousTripsScreen> createState() => _PreviousTripsScreenState();
}

class _PreviousTripsScreenState extends State<PreviousTripsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DispatchModel> _filteredDispatches = [];
  List<DispatchModel> _allDispatches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDispatches);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDispatches);
    _searchController.dispose();
    super.dispose();
  }

  void _filterDispatches() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredDispatches = _allDispatches;
      } else {
        _filteredDispatches = _allDispatches.where((dispatch) {
          final dispatchId = dispatch.dispatchId.toLowerCase();
          final date = dispatch.createdAt.toString().toLowerCase();
          final pickup = dispatch.sourceLocation.toLowerCase();
          final dropOff = dispatch.destinationLocation.toLowerCase();
          final status = dispatch.status.toLowerCase();

          return dispatchId.contains(_searchQuery) ||
              date.contains(_searchQuery) ||
              pickup.contains(_searchQuery) ||
              dropOff.contains(_searchQuery) ||
              status.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primary.withOpacity(0.3),
        automaticallyImplyLeading: false,
        title: const Text(
          'Previous Trips',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: false,
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
              FontAwesomeIcons.clockRotateLeft,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeSlideAnimation(
          child: StreamBuilder<List<DispatchModel>>(
            stream: DispatchService.getCurrentUserPreviousDispatchesStream(),
            builder: (context, snapshot) {
              // Handle different states with timeout for better UX
              return FutureBuilder(
                future: Future.delayed(Duration(seconds: 2)),
                builder: (context, timeoutSnapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData &&
                      timeoutSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  final dispatches = snapshot.data ?? [];
                  _allDispatches = dispatches;

                  // Apply search filter if there's a query
                  final dispatchesToDisplay = _searchQuery.isEmpty
                      ? dispatches
                      : _filteredDispatches;

                  return Column(
                    children: [
                      // Search Bar
                      Container(
                        margin: const EdgeInsets.all(16),
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search dispatches by date, location, or status...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: AppColors.textSecondary.withOpacity(0.6),
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                    },
                                    child: Icon(
                                      FontAwesomeIcons.xmark,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.6),
                                      size: 16,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      // Dispatches List
                      Expanded(
                        child: dispatchesToDisplay.isEmpty
                            ? _searchQuery.isNotEmpty
                                  ? _buildNoResultsState()
                                  : _buildEmptyState()
                            : _buildPreviousDispatchesList(dispatchesToDisplay),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Previous Dispatches...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your dispatch history',
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

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to Load Dispatches',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load your dispatch history.\nPlease check your connection and try again.',
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary.withOpacity(0.1),
                  AppColors.textSecondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              FontAwesomeIcons.clockRotateLeft,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Previous Dispatches',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed and canceled dispatches\nwill appear here for future reference',
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

  Widget _buildPreviousDispatchesList(List<DispatchModel> dispatches) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.clockRotateLeft,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Previous Dispatches',
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
            '${dispatches.length} dispatch${dispatches.length > 1 ? 'es' : ''} found',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: dispatches.length,
              itemBuilder: (context, index) {
                final dispatch = dispatches[index];
                return DispatchCard(
                  dispatch: dispatch,
                  onViewDetails: () => _navigateToDispatchDetails(dispatch),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDispatchDetails(DispatchModel dispatch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PreviousTripDetailsScreen(dispatchId: dispatch.dispatchId),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary.withOpacity(0.1),
                  AppColors.textSecondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Dispatches Found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No dispatches match your search criteria.\nTry adjusting your search terms.',
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
}
