import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/dispatch_model.dart';
import '../../services/dispatch_service.dart';

class PreviousTripDetailsScreen extends StatefulWidget {
  final String dispatchId;

  const PreviousTripDetailsScreen({super.key, required this.dispatchId});

  @override
  State<PreviousTripDetailsScreen> createState() =>
      _PreviousTripDetailsScreenState();
}

class _PreviousTripDetailsScreenState extends State<PreviousTripDetailsScreen> {
  DispatchModel? dispatch;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  Future<void> _loadTripDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final dispatchResult = await DispatchService.getDispatchById(
        widget.dispatchId,
      );

      if (dispatchResult == null) {
        setState(() {
          isLoading = false;
          error = 'Dispatch not found';
        });
        return;
      }

      setState(() {
        dispatch = dispatchResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'Loading...',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (dispatch == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'Dispatch Not Found',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text('Dispatch details could not be loaded.'),
        ),
      );
    }

    final isCompleted = dispatch!.status.toLowerCase() == 'completed';
    final isCanceled = dispatch!.status.toLowerCase() == 'cancelled';
    final isRejected = dispatch!.status.toLowerCase() == 'rejected';

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
          'Previous Dispatch',
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
            child: Icon(
              isCompleted
                  ? FontAwesomeIcons.checkCircle
                  : (isCanceled || isRejected)
                  ? FontAwesomeIcons.xmark
                  : FontAwesomeIcons.clock,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Route Overview Card (replaces map)
            if (!isCanceled && !isRejected) _buildRouteOverviewCard(),

            // Trip Details Card
            _buildTripDetailsCard(isCompleted, isCanceled, isRejected),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteOverviewCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.route, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Trip Route',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pickup location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dispatch!.sourceLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Connecting line
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: 20,
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 12),
                if (dispatch!.distance != null && dispatch!.distance! > 0) ...[
                  Icon(
                    FontAwesomeIcons.road,
                    color: AppColors.textSecondary,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${dispatch!.distance!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Dropoff location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drop-off Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dispatch!.destinationLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(
    bool isCompleted,
    bool isCanceled,
    bool isRejected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Dispatch ID: ${dispatch!.dispatchId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(flex: 1, child: _buildStatusChip(dispatch!.status)),
            ],
          ),

          const SizedBox(height: 24),

          // Show cancellation/rejection details if canceled or rejected
          if (isCanceled || isRejected) ...[
            _buildCancellationDetails(),
            const SizedBox(height: 20),
          ],

          _buildDetailRow(
            'Pick Up',
            dispatch!.sourceLocation,
            FontAwesomeIcons.locationDot,
            AppColors.success,
          ),

          const SizedBox(height: 20),

          _buildDetailRow(
            'Drop-Off',
            dispatch!.destinationLocation,
            FontAwesomeIcons.locationPin,
            AppColors.error,
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  'Pickup Date',
                  '${dispatch!.pickupDateTime.day.toString().padLeft(2, '0')}-${dispatch!.pickupDateTime.month.toString().padLeft(2, '0')}-${dispatch!.pickupDateTime.year}',
                  FontAwesomeIcons.calendar,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailRow(
                  'Pickup Time',
                  '${dispatch!.pickupDateTime.hour.toString().padLeft(2, '0')}:${dispatch!.pickupDateTime.minute.toString().padLeft(2, '0')}',
                  FontAwesomeIcons.clock,
                  AppColors.primary,
                ),
              ),
            ],
          ),

          if (isCompleted) ...[
            const SizedBox(height: 20),
            _buildCompletionDetails(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCancellationDetails() {
    final isRejected = dispatch!.status.toLowerCase() == 'rejected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.xmark, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRejected ? 'Dispatch Rejected' : 'Dispatch Cancelled',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.error,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isRejected
                ? 'This dispatch request was rejected by the admin'
                : 'This dispatch request was cancelled',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${dispatch!.createdAt.day.toString().padLeft(2, '0')}-${dispatch!.createdAt.month.toString().padLeft(2, '0')}-${dispatch!.createdAt.year} at ${dispatch!.createdAt.hour.toString().padLeft(2, '0')}:${dispatch!.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.checkCircle,
                color: AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dispatch Completed Successfully',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.success,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Completed on: ${dispatch!.createdAt.day.toString().padLeft(2, '0')}-${dispatch!.createdAt.month.toString().padLeft(2, '0')}-${dispatch!.createdAt.year} at ${dispatch!.createdAt.hour.toString().padLeft(2, '0')}:${dispatch!.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        statusColor = AppColors.error;
        break;
      case 'accepted':
      case 'assigned':
      case 'in-progress':
        statusColor = AppColors.primary;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        _getStatusDisplayText(status),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'accepted':
        return 'Accepted';
      case 'assigned':
        return 'Assigned';
      case 'in-progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
