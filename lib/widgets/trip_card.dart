import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../models/trip_model.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onViewDetails;

  const TripCard({super.key, required this.trip, required this.onViewDetails});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'approved':
        return AppColors.success;
      case 'on the way':
        return AppColors.primary;
      case 'completed':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    FontAwesomeIcons.image,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip ID: ${trip.tripId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.calendar,
                            color: AppColors.textSecondary,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${trip.createdAt.day.toString().padLeft(2, '0')}-${trip.createdAt.month.toString().padLeft(2, '0')}-${trip.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            FontAwesomeIcons.clock,
                            color: AppColors.textSecondary,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(trip.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      // Show driver info if assigned
                      if (trip.driverName != null ||
                          (trip.assignedDriverIds != null &&
                              trip.assignedDriverIds!.isNotEmpty)) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.userCheck,
                              color: AppColors.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                trip.assignedDriverIds != null &&
                                        trip.assignedDriverIds!.isNotEmpty
                                    ? '${trip.assignedDriverIds!.length} driver${trip.assignedDriverIds!.length > 1 ? 's' : ''} assigned'
                                    : 'Driver: ${trip.driverName ?? 'Assigned'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Show truck info if assigned
                      if (trip.truckNumber != null ||
                          trip.truckPlateNumber != null ||
                          (trip.assignedTruckIds != null &&
                              trip.assignedTruckIds!.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.truck,
                              color: AppColors.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                trip.assignedTruckIds != null &&
                                        trip.assignedTruckIds!.isNotEmpty
                                    ? '${trip.assignedTruckIds!.length} truck${trip.assignedTruckIds!.length > 1 ? 's' : ''} assigned'
                                    : 'Truck: ${trip.truckNumber ?? trip.truckPlateNumber ?? 'Assigned'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(trip.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    trip.status,
                    style: TextStyle(
                      color: _getStatusColor(trip.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
