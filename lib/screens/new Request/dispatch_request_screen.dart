import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/form_section_title.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/success_popup.dart';
import '../../widgets/address_autocomplete_field.dart';
import '../../widgets/custom_popup.dart';
import '../../services/location_service.dart';
import '../../services/dispatch_service.dart';
import '../../services/auth_user_service.dart';
import '../../models/dispatch_model.dart';
import '../active_trips/active_trips_screen.dart';

class DispatchRequestScreen extends StatefulWidget {
  const DispatchRequestScreen({super.key});

  @override
  State<DispatchRequestScreen> createState() => _DispatchRequestScreenState();
}

class _DispatchRequestScreenState extends State<DispatchRequestScreen> {
  final TextEditingController _numberOfTrucksController =
      TextEditingController();
  final TextEditingController _pickupAddressController =
      TextEditingController();
  final TextEditingController _dropOffAddressController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();

  final List<TruckRequirement> _truckRequirements = [];
  DateTime? _selectedPickupDate;
  bool _isLoading = false;
  bool _locationPermissionChecked = false;

  @override
  void initState() {
    super.initState();
    // Request location permission when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    if (_locationPermissionChecked) return;

    final result = await LocationService.checkLocationStatus();

    setState(() {
      _locationPermissionChecked = true;
    });

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Location access granted! You\'ll get better address suggestions.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result['needsPermissionRequest'] == true) {
      _showLocationPermissionDialog();
    } else if (result['needsSettings'] == true) {
      _showLocationSettingsDialog();
    } else if (result['needsServiceEnable'] == true) {
      _showLocationServiceDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Location Permission'),
          ],
        ),
        content: Text(
          'This app needs location access to provide better address suggestions and calculate accurate distances for your trips.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _checkLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Location Permission'),
        content: Text(
          'Location permissions are permanently denied. Please enable them in app settings to get better address suggestions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await LocationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Location Services'),
        content: Text(
          'Location services are disabled. Please enable them to get better address suggestions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await LocationService.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _numberOfTrucksController.dispose();
    _pickupAddressController.dispose();
    _dropOffAddressController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _updateTruckRequirements(int numberOfTrucks) {
    setState(() {
      _truckRequirements.clear();
      for (int i = 0; i < numberOfTrucks; i++) {
        _truckRequirements.add(
          TruckRequirement(
            truckType: TruckTypes.availableTypes.first,
            count: 1,
          ),
        );
      }
    });
  }

  Future<void> _selectPickupDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedPickupDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedPickupDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _selectedPickupDate = fullDateTime;
          _pickupDateController.text =
              '${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year} '
              '${pickedTime.format(context)}';
        });
      }
    }
  }

  List<Widget> _buildTruckRequirementFields() {
    List<Widget> fields = [];

    for (int i = 0; i < _truckRequirements.length; i++) {
      fields.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Truck ${i + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              CustomDropdownField(
                value: TruckTypes.getDisplayName(
                  _truckRequirements[i].truckType,
                ),
                hint: 'Select truck type',
                items: TruckTypes.availableTypes
                    .map(TruckTypes.getDisplayName)
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      final truckType = TruckTypes.availableTypes.firstWhere(
                        (type) => TruckTypes.getDisplayName(type) == value,
                        orElse: () => TruckTypes.availableTypes.first,
                      );
                      _truckRequirements[i] = TruckRequirement(
                        truckType: truckType,
                        count: 1, // Each truck requirement represents 1 truck
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return fields;
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
          'New Dispatch Request',
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
              FontAwesomeIcons.truck,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard and any active suggestions when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: FadeSlideAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildFormSection(),
                        const SizedBox(height: 30),
                        GradientButton(
                          text: _isLoading
                              ? 'Creating Dispatch...'
                              : 'Create Dispatch Request',
                          onTap: _isLoading ? () {} : _handleCreateTrip,
                        ),
                        const SizedBox(height: 20), // Extra space at bottom
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number of Trucks Field
          const FormSectionTitle(title: 'Number of Trucks *'),
          const SizedBox(height: 12),
          CustomDropdownField(
            value: _numberOfTrucksController.text,
            hint: 'Select number of trucks',
            items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
            onChanged: (value) {
              setState(() {
                _numberOfTrucksController.text = value ?? '';
                _updateTruckRequirements(int.tryParse(value ?? '0') ?? 0);
              });
            },
          ),

          // Dynamic Truck Requirements
          if (_truckRequirements.isNotEmpty) ...[
            const SizedBox(height: 24),
            const FormSectionTitle(title: 'Truck Requirements *'),
            const SizedBox(height: 12),
            ..._buildTruckRequirementFields(),
          ],

          const SizedBox(height: 24),
          const FormSectionTitle(title: 'Pickup Date & Time *'),
          const SizedBox(height: 8),
          Text(
            'Select the date and time when you need the trucks to arrive for pickup.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectPickupDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.calendar,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickupDateController.text.isEmpty
                          ? 'Select pickup date'
                          : _pickupDateController.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: _pickupDateController.text.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    color: AppColors.textSecondary,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const FormSectionTitle(title: 'Pickup Address *'),
          const SizedBox(height: 8),
          Text(
            'Start typing your address and select from suggestions',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          AddressAutocompleteField(
            controller: _pickupAddressController,
            hint: 'Enter pickup location (e.g., DHA Phase 2, Karachi)',
            prefixIcon: FontAwesomeIcons.locationDot,
            onAddressSelected: (address, coordinates) {
              // Address is already set in the controller
              // Refresh map when address is selected
              setState(() {});
            },
          ),

          const SizedBox(height: 24),
          const FormSectionTitle(title: 'Drop-off Address *'),
          const SizedBox(height: 8),
          Text(
            'Start typing your destination and select from suggestions',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          AddressAutocompleteField(
            controller: _dropOffAddressController,
            hint:
                'Enter destination location (e.g., Gulshan Block 15, Karachi)',
            prefixIcon: FontAwesomeIcons.locationPin,
            onAddressSelected: (address, coordinates) {
              // Address is already set in the controller
              // Refresh map when address is selected
              setState(() {});
            },
          ),

          const SizedBox(height: 24),
          const FormSectionTitle(title: 'Additional Notes'),
          const SizedBox(height: 12),
          TextField(
            controller: _additionalNotesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your cargo, special requirements, etc.',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              filled: true,
              fillColor: AppColors.fieldBackground,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),

          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleInfo,
                  color: AppColors.primary,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Distance will be calculated automatically using Google Maps. Dispatch ID and timestamp will be generated upon submission.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateTrip() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Validate user is logged in
      if (!AuthUserService.isLoggedIn) {
        CustomPopup.showError(
          context,
          'Authentication Required',
          'Please log in to create a trip request.',
        );
        return;
      }

      // Create dispatch request using the truck requirements array
      final result = await DispatchService.createDispatch(
        weight: "Not specified", // Weight field removed as requested
        truckRequirements: _truckRequirements, // Pass the actual truck requirements
        pickupAddress: _pickupAddressController.text.trim(),
        dropoffAddress: _dropOffAddressController.text.trim(),
        additionalNotes: _additionalNotesController.text.trim().isEmpty
            ? null
            : _additionalNotesController.text.trim(),
        pickupDateTime: _selectedPickupDate ?? DateTime.now().add(Duration(hours: 1)), // Now stores full date and time
      );

      if (!mounted) return;

      if (result['success']) {
        final dispatch = result['dispatch'] as DispatchModel;
        _showSuccessPopup(dispatch);
      } else {
        // Show specific error message from the service
        String errorMessage =
            result['message'] ??
            'An error occurred while creating your dispatch request.';

        // Provide helpful tips for common errors
        if (errorMessage.contains('pickup address coordinates')) {
          errorMessage +=
              '\n\nTip: Try selecting an address from the suggestions or be more specific with your location.';
        } else if (errorMessage.contains('drop-off address coordinates')) {
          errorMessage +=
              '\n\nTip: Try selecting an address from the suggestions or be more specific with your location.';
        } else if (errorMessage.contains('internet connection')) {
          errorMessage +=
              '\n\nTip: Please check your internet connection and try again.';
        }

        CustomPopup.showError(
          context,
          'Failed to Create Dispatch',
          errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.showError(
          context,
          'Error',
          'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    // Check truck requirements
    if (_truckRequirements.isEmpty) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Truck Requirements Required',
        subText: 'Please select the number of trucks needed',
      );
      return false;
    }

    // Check number of trucks
    if (_numberOfTrucksController.text.isEmpty) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Number of Trucks Required',
        subText: 'Please select the number of trucks needed',
      );
      return false;
    }

    // Check pickup date
    if (_pickupDateController.text.isEmpty || _selectedPickupDate == null) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Pickup Date Required',
        subText: 'Please select when you need the trucks',
      );
      return false;
    }

    // Check pickup address
    final pickupAddress = _pickupAddressController.text.trim();
    if (pickupAddress.isEmpty) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Pickup Address Required',
        subText: 'Please enter the pickup address',
      );
      return false;
    }

    // Validate pickup address format
    if (pickupAddress.length < 5) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Invalid Pickup Address',
        subText:
            'Please enter a more specific pickup address with area/city name',
      );
      return false;
    }

    // Check dropoff address
    final dropoffAddress = _dropOffAddressController.text.trim();
    if (dropoffAddress.isEmpty) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Drop-off Address Required',
        subText: 'Please enter the drop-off address',
      );
      return false;
    }

    // Validate dropoff address format
    if (dropoffAddress.length < 5) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Invalid Drop-off Address',
        subText:
            'Please enter a more specific drop-off address with area/city name',
      );
      return false;
    }

    // Check if pickup and dropoff are different
    if (pickupAddress.toLowerCase() == dropoffAddress.toLowerCase()) {
      showCustomPopup(
        context,
        graphic: Icon(
          FontAwesomeIcons.triangleExclamation,
          color: AppColors.error,
          size: 48,
        ),
        mainText: 'Different Addresses Required',
        subText: 'Pickup and drop-off addresses must be different',
      );
      return false;
    }

    return true;
  }

  void _showSuccessPopup(DispatchModel dispatch) {
    SuccessPopup.show(
      context,
      title: 'Dispatch Request Created!',
      subtitle:
          'Your dispatch request ${dispatch.dispatchId} has been submitted successfully.\n\nDistance: ${dispatch.formattedDistance}\nStatus: Pending\n\nYou will be notified once a driver is assigned.',
      logoPath: 'assets/images/logo.png',
      icon: FontAwesomeIcons.truck,
      onOkPressed: () {
        Navigator.of(context).pop(); // Close success dialog
        Navigator.of(context).pop(); // Return to previous screen

        // Navigate to Active Trips screen to show the new request
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
        );
      },
    );
  }
}
