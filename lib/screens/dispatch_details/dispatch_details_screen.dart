import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../models/dispatch_model.dart';
import '../../services/dispatch_service.dart';
import '../../services/driver_truck_service.dart';

class DispatchDetailsScreen extends StatefulWidget {
  final String dispatchId;

  const DispatchDetailsScreen({super.key, required this.dispatchId});

  @override
  State<DispatchDetailsScreen> createState() => _DispatchDetailsScreenState();
}

class _DispatchDetailsScreenState extends State<DispatchDetailsScreen> {
  DispatchModel? dispatch;
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? assignmentDetails;

  @override
  void initState() {
    super.initState();
    _loadDispatchDetails();
  }

  Future<void> _loadDispatchDetails() async {
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

      print(
        'DEBUG: Dispatch loaded - driverAssignments: ${dispatchResult.driverAssignments}',
      );
      print(
        'DEBUG: Dispatch loaded - assignments: ${dispatchResult.assignments}',
      );

      // Load assignment details if dispatch has assignments (new or old format)
      if ((dispatchResult.driverAssignments?.isNotEmpty == true) ||
          dispatchResult.assignments.isNotEmpty) {
        print('DEBUG: Calling _loadAssignmentDetails()');
        _loadAssignmentDetails();
      } else {
        print('DEBUG: No assignments found to load');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadAssignmentDetails() async {
    if (dispatch == null) return;

    try {
      List<String> driverIds = [];
      List<String> truckIds = [];

      print(
        'DEBUG: Checking dispatch driverAssignments: ${dispatch!.driverAssignments}',
      );

      // Check for new driverAssignments structure first
      if (dispatch!.driverAssignments != null &&
          dispatch!.driverAssignments!.isNotEmpty) {
        final driverAssignments = dispatch!.driverAssignments!;
        print(
          'DEBUG: Found driverAssignments with keys: ${driverAssignments.keys}',
        );

        for (String driverId in driverAssignments.keys) {
          driverIds.add(driverId);
          final assignment =
              driverAssignments[driverId] as Map<String, dynamic>;
          print('DEBUG: Assignment for $driverId: $assignment');
          if (assignment['truckId'] != null) {
            truckIds.add(assignment['truckId'] as String);
          }
        }
      }

      // Fallback to old assignments structure if no driverAssignments found
      if (driverIds.isEmpty && dispatch!.assignments.isNotEmpty) {
        print('DEBUG: Falling back to old assignments structure');
        driverIds = dispatch!.assignments
            .map((assignment) => assignment['driverId'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toList();

        truckIds = dispatch!.assignments
            .map((assignment) => assignment['truckId'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toList();
      }

      print('DEBUG: Final driverIds: $driverIds, truckIds: $truckIds');

      if (driverIds.isNotEmpty || truckIds.isNotEmpty) {
        final details = await DriverTruckService.getAssignmentDetails(
          driverIds: driverIds.isNotEmpty ? driverIds : null,
          truckIds: truckIds.isNotEmpty ? truckIds : null,
        );

        print('DEBUG: Assignment details fetched: $details');

        if (mounted) {
          setState(() {
            assignmentDetails = details;
          });
        }
      }
    } catch (e) {
      print('Error loading assignment details: $e');
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
          'Dispatch Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : error != null
            ? _buildErrorState()
            : dispatch != null
            ? _buildDispatchDetails()
            : _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading dispatch details...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Dispatch not found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _loadDispatchDetails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.truck,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dispatch ID: ${dispatch!.dispatchId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(dispatch!.status),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Basic Details
          _buildDetailCard('Trip Information', [
            _buildDetailRow(
              FontAwesomeIcons.locationDot,
              'Pickup Location',
              dispatch!.sourceLocation,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              FontAwesomeIcons.locationPin,
              'Drop-off Location',
              dispatch!.destinationLocation,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              FontAwesomeIcons.calendar,
              'Created Date',
              _formatDate(dispatch!.createdAt),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              FontAwesomeIcons.clock,
              'Created Time',
              _formatTime(dispatch!.createdAt),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              FontAwesomeIcons.route,
              'Distance',
              dispatch!.formattedDistance,
            ),
          ]),

          const SizedBox(height: 20),

          // Truck Requirements
          _buildDetailCard('Truck Requirements', [
            ...dispatch!.trucksRequired.map((requirement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.truck,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          requirement.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]),

          const SizedBox(height: 20),

          // Assignment Details (Driver & Truck Info)
          if (assignmentDetails != null &&
              ((assignmentDetails!['drivers'] != null &&
                      (assignmentDetails!['drivers'] as List).isNotEmpty) ||
                  (assignmentDetails!['trucks'] != null &&
                      (assignmentDetails!['trucks'] as List).isNotEmpty)))
            _buildDetailCard('Assignment Details', [
              // Display all drivers
              if (assignmentDetails!['drivers'] != null &&
                  (assignmentDetails!['drivers'] as List).isNotEmpty) ...[
                ..._buildDriversList(
                  assignmentDetails!['drivers'] as List<Map<String, dynamic>>,
                ),
              ],
              // Display all trucks
              if (assignmentDetails!['trucks'] != null &&
                  (assignmentDetails!['trucks'] as List).isNotEmpty) ...[
                if (assignmentDetails!['drivers'] != null &&
                    (assignmentDetails!['drivers'] as List).isNotEmpty)
                  const SizedBox(height: 20),
                ..._buildTrucksList(
                  assignmentDetails!['trucks'] as List<Map<String, dynamic>>,
                ),
              ],
            ]),

          if (assignmentDetails != null &&
              (assignmentDetails!['driverName'] != null ||
                  assignmentDetails!['truckPlateNumber'] != null))
            const SizedBox(height: 20),

          const SizedBox(height: 20),

          // Actions (if dispatch can be cancelled)
          if (dispatch!.status == 'pending') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Cancel Dispatch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can cancel this dispatch request since it hasn\'t been assigned yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cancelDispatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel Dispatch',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
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
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

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
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _cancelDispatch() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Dispatch'),
        content: const Text(
          'Are you sure you want to cancel this dispatch request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await DispatchService.cancelDispatch(
          dispatch!.dispatchId,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Dispatch cancelled successfully',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(); // Go back to previous screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to cancel dispatch'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling dispatch: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  List<Widget> _buildDriversList(List<Map<String, dynamic>> drivers) {
    List<Widget> widgets = [];

    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      final isFirst = i == 0;

      if (!isFirst) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          Container(
            height: 1,
            color: AppColors.textSecondary.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 16),
          ),
        );
      }

      // Driver header
      widgets.add(
        Text(
          drivers.length > 1 ? 'Driver ${i + 1}' : 'Driver',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'Poppins',
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));

      // Driver details
      widgets.add(
        _buildDetailRow(
          FontAwesomeIcons.user,
          'Name',
          driver['driverName'] ?? 'Unknown Driver',
        ),
      );

      if (driver['driverPhone'] != null && driver['driverPhone'].isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          _buildDetailRow(
            FontAwesomeIcons.phone,
            'Phone',
            driver['driverPhone'],
          ),
        );
      }

      if (driver['driverEmail'] != null && driver['driverEmail'].isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          _buildDetailRow(
            FontAwesomeIcons.envelope,
            'Email',
            driver['driverEmail'],
          ),
        );
      }

      if (driver['driverLicenseNumber'] != null &&
          driver['driverLicenseNumber'].isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          _buildDetailRow(
            FontAwesomeIcons.idCard,
            'License Number',
            driver['driverLicenseNumber'],
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildTrucksList(List<Map<String, dynamic>> trucks) {
    List<Widget> widgets = [];

    for (int i = 0; i < trucks.length; i++) {
      final truck = trucks[i];
      final isFirst = i == 0;

      if (!isFirst) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          Container(
            height: 1,
            color: AppColors.textSecondary.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 16),
          ),
        );
      }

      // Truck header
      widgets.add(
        Text(
          trucks.length > 1 ? 'Truck ${i + 1}' : 'Truck',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'Poppins',
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));

      // Truck details
      if (truck['truckType'] != null && truck['truckType'].isNotEmpty) {
        widgets.add(
          _buildDetailRow(
            FontAwesomeIcons.truck,
            'Truck Type',
            truck['truckType'],
          ),
        );
      }

      if (truck['truckPlateNumber'] != null &&
          truck['truckPlateNumber'].isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          _buildDetailRow(
            FontAwesomeIcons.idBadge,
            'Plate Number',
            truck['truckPlateNumber'],
          ),
        );
      }

      if (truck['truckModel'] != null && truck['truckModel'].isNotEmpty) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          _buildDetailRow(FontAwesomeIcons.cog, 'Model', truck['truckModel']),
        );
      }
    }

    return widgets;
  }
}
