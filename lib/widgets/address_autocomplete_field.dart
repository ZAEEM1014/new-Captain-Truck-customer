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

  void _showSuggestions() {
    _hideSuggestions();

    final customAddress = widget.controller.text.trim();
    final showCustomOption =
        customAddress.isNotEmpty &&
        !suggestions.any((s) => s['description'] == customAddress);

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
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  ...suggestions.map(
                    (suggestion) => ListTile(
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
                        widget.controller.text =
                            suggestion['description'] ?? '';
                        _hideSuggestions();
                        setState(() {
                          suggestions = [];
                        });
                        if (placeId != null &&
                            placeId.toString().startsWith('fallback_')) {
                          widget.onAddressSelected?.call(
                            suggestion['description'] ?? '',
                            null,
                          );
                        } else {
                          final placeDetails =
                              await GoogleMapsService.getPlaceDetails(placeId);
                          widget.onAddressSelected?.call(
                            suggestion['description'] ?? '',
                            placeDetails,
                          );
                        }
                        focusNode.unfocus();
                      },
                    ),
                  ),
                  if (showCustomOption)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.edit_location_alt,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      title: Text(
                        'Use "$customAddress"',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        widget.onAddressSelected?.call(customAddress, null);
                        _hideSuggestions();
                        setState(() {
                          suggestions = [];
                        });
                        focusNode.unfocus();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry!);
  }

  void _clearSuggestions() {
    setState(() {
      suggestions = [];
    });
    _hideSuggestions();
  }

  void _showFallbackSuggestions(String query) {
    if (query.length < 3) return;
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

  void _hideSuggestions() {
    overlayEntry?.remove();
    overlayEntry = null;
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
          onChanged: (value) async {
            if (value.trim().isEmpty) {
              setState(() {
                suggestions = [];
                isLoading = false;
              });
              _hideSuggestions();
              return;
            }
            setState(() {
              isLoading = true;
            });
            try {
              final results = await GoogleMapsService.getPlaceSuggestions(
                value,
              );
              if (mounted) {
                setState(() {
                  suggestions = results;
                  isLoading = false;
                });
                if (suggestions.isNotEmpty) {
                  _showSuggestions();
                } else {
                  _showFallbackSuggestions(value);
                }
              }
            } catch (e) {
              setState(() {
                isLoading = false;
                suggestions = [];
              });
              _showFallbackSuggestions(value);
            }
          },
        ),
      ),
    );
  }
}
