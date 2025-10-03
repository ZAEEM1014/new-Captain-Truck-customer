import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../services/google_maps_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AddressAutocompleteField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final Function(String, Map<String, dynamic>?)? onAddressSelected;

  const AddressAutocompleteField({
    super.key,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.onAddressSelected,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<Map<String, dynamic>> suggestions = [];
  bool isLoading = false;
  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();
  final FocusNode focusNode = FocusNode();

  // Current location variables
  double? currentLat;
  double? currentLng;

  Future<void> _getCurrentLocation() async {
    try {
      Position? position =
          await LocationService.getCurrentLocationWithFallback();
      if (position != null && mounted) {
        setState(() {
          currentLat = position.latitude;
          currentLng = position.longitude;
        });
        print('📍 Current location obtained: $currentLat, $currentLng');
      }
    } catch (e) {
      print('❌ Error getting current location: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    widget.controller.addListener(_onTextChanged);
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _clearSuggestions();
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    focusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  void _hideSuggestions() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.length >= 3) {
      _searchAddresses(query);
    } else {
      setState(() {
        suggestions = [];
      });
      _hideSuggestions();
    }
  }

  void _clearSuggestions() {
    setState(() {
      suggestions = [];
    });
    _hideSuggestions();
  }

  Future<void> _searchAddresses(String query) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      print('🔍 Searching for addresses with query: $query');
      final newSuggestions = await GoogleMapsService.getPlaceSuggestions(
        query,
        currentLat: currentLat,
        currentLng: currentLng,
      );
      print('📍 Got ${newSuggestions.length} address suggestions');

      if (mounted) {
        setState(() {
          suggestions = newSuggestions;
          isLoading = false;
        });

        if (suggestions.isNotEmpty) {
          _showSuggestions();
        } else {
          _hideSuggestions();
          // Show fallback suggestions if API fails
          if (query.length >= 3) {
            print('💡 No suggestions found for: $query');
            _showFallbackSuggestions(query);
          }
        }
      }
    } catch (e) {
      print('❌ Address search error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          suggestions = [];
        });
        _hideSuggestions();

        // Show fallback suggestions instead of error
        _showFallbackSuggestions(query);
      }
    }
  }

  void _showSuggestions() {
    _hideSuggestions();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 64,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      FontAwesomeIcons.locationDot,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    title: Text(
                      suggestion['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      final placeId = suggestion['place_id'];

                      // Set the selected address
                      widget.controller.text = suggestion['description'] ?? '';

                      // Clear suggestions immediately
                      _clearSuggestions();

                      // Handle fallback suggestions differently
                      if (placeId != null &&
                          placeId.toString().startsWith('fallback_')) {
                        // For fallback suggestions, just call the callback without coordinates
                        widget.onAddressSelected?.call(
                          suggestion['description'] ?? '',
                          null, // No coordinates available for fallback
                        );
                      } else {
                        // Get place details with coordinates for real API results
                        final placeDetails =
                            await GoogleMapsService.getPlaceDetails(placeId);

                        // Call the callback with address and coordinates
                        widget.onAddressSelected?.call(
                          suggestion['description'] ?? '',
                          placeDetails,
                        );
                      }

                      // Remove focus to hide keyboard
                      focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  // Removed duplicate _hideSuggestions method

  void _showFallbackSuggestions(String query) {
    if (query.length < 3) return;

    // Common Pakistani cities and areas
    final fallbackSuggestions =
        [
              'Karachi, Pakistan',
              'Lahore, Pakistan',
              'Islamabad, Pakistan',
              'Rawalpindi, Pakistan',
              'Faisalabad, Pakistan',
              'Multan, Pakistan',
              'Gujranwala, Pakistan',
              'Peshawar, Pakistan',
              'Quetta, Pakistan',
              'Sialkot, Pakistan',
              'DHA, Karachi',
              'Gulshan-e-Iqbal, Karachi',
              'Clifton, Karachi',
              'Johar Town, Lahore',
              'DHA, Lahore',
              'Gulberg, Lahore',
              'F-6, Islamabad',
              'F-7, Islamabad',
              'G-9, Islamabad',
              'Daska, Pakistan',
            ]
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (fallbackSuggestions.isNotEmpty && mounted) {
      setState(() {
        suggestions = fallbackSuggestions
            .map(
              (city) => {
                'description': city,
                'place_id': 'fallback_${city.hashCode}',
              },
            )
            .toList();
      });
      _showSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: TextField(
          controller: widget.controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.primary, size: 18)
                : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                if (widget.controller.text.isNotEmpty && !isLoading)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      _clearSuggestions();
                      focusNode.unfocus();
                    },
                  ),
              ],
            ),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            _clearSuggestions();
          },
        ),
      ),
    );
  }
}
