import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../models/dispatch_model.dart';

class DispatchCard extends StatelessWidget {
  final DispatchModel dispatch;
  final VoidCallback onViewDetails;

  const DispatchCard({
    super.key,
    required this.dispatch,
    required this.onViewDetails,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return AppColors.primary;
      case 'in-progress':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'assigned':
        return FontAwesomeIcons.userCheck;
      case 'in-progress':
        return FontAwesomeIcons.truckMoving;
      case 'completed':
        return FontAwesomeIcons.checkCircle;
      case 'cancelled':
        return FontAwesomeIcons.xmark;
      case 'rejected':
        return FontAwesomeIcons.xmark;
      default:
        return FontAwesomeIcons.truck;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with dispatch ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch #${dispatch.dispatchId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(dispatch.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(dispatch.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(dispatch.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(dispatch.status),
                          color: _getStatusColor(dispatch.status),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dispatch.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(dispatch.status),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Addresses
              Column(
                children: [
                  _buildAddressRow(
                    FontAwesomeIcons.locationDot,
                    'From',
                    dispatch.sourceLocation,
                    AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _buildAddressRow(
                    FontAwesomeIcons.locationPin,
                    'To',
                    dispatch.destinationLocation,
                    AppColors.error,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Truck requirements and distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.truck,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dispatch.totalTrucksCount} truck${dispatch.totalTrucksCount != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dispatch.formattedDistance,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressRow(
    IconData icon,
    String label,
    String address,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
