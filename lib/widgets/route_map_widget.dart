import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/google_maps_service.dart';

class RouteMapWidget extends StatefulWidget {
  final String? sourceAddress;
  final String? destinationAddress;
  final Map<String, dynamic>? sourceCoordinates;
  final Map<String, dynamic>? destinationCoordinates;
  final double height;
  final bool showRoute;

  const RouteMapWidget({
    super.key,
    this.sourceAddress,
    this.destinationAddress,
    this.sourceCoordinates,
    this.destinationCoordinates,
    this.height = 200,
    this.showRoute = true,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _sourceLatLng;
  LatLng? _destinationLatLng;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceAddress != widget.sourceAddress ||
        oldWidget.destinationAddress != widget.destinationAddress ||
        oldWidget.sourceCoordinates != widget.sourceCoordinates ||
        oldWidget.destinationCoordinates != widget.destinationCoordinates) {
      _setupMap();
    }
  }

  void _setupMap() async {
    setState(() {
      _isLoading = true;
      _markers.clear();
      _polylines.clear();
    });

    try {
      // Get source coordinates
      if (widget.sourceCoordinates != null) {
        _sourceLatLng = LatLng(
          widget.sourceCoordinates!['lat'],
          widget.sourceCoordinates!['lng'],
        );
      } else if (widget.sourceAddress != null &&
          widget.sourceAddress!.isNotEmpty) {
        final sourceCoords = await GoogleMapsService.geocodeAddress(
          widget.sourceAddress!,
        );
        if (sourceCoords != null) {
          _sourceLatLng = LatLng(sourceCoords['lat'], sourceCoords['lng']);
        }
      }

      // Get destination coordinates
      if (widget.destinationCoordinates != null) {
        _destinationLatLng = LatLng(
          widget.destinationCoordinates!['lat'],
          widget.destinationCoordinates!['lng'],
        );
      } else if (widget.destinationAddress != null &&
          widget.destinationAddress!.isNotEmpty) {
        final destCoords = await GoogleMapsService.geocodeAddress(
          widget.destinationAddress!,
        );
        if (destCoords != null) {
          _destinationLatLng = LatLng(destCoords['lat'], destCoords['lng']);
        }
      }

      // Add markers
      if (_sourceLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('source'),
            position: _sourceLatLng!,
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: widget.sourceAddress ?? 'Source',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (_destinationLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLatLng!,
            infoWindow: InfoWindow(
              title: 'Drop-off Location',
              snippet: widget.destinationAddress ?? 'Destination',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      // Get route if both coordinates are available and route is requested
      if (widget.showRoute &&
          _sourceLatLng != null &&
          _destinationLatLng != null) {
        final directions = await GoogleMapsService.getDirections(
          _sourceLatLng!,
          _destinationLatLng!,
        );
        if (directions != null && directions['polyline'] != null) {
          final polylinePoints = GoogleMapsService.decodePolyline(
            directions['polyline'],
          );
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: Colors.blue,
              width: 4,
              patterns: [],
            ),
          );
        }
      }

      // Fit map to show all markers
      if (_controller != null && _markers.isNotEmpty) {
        _fitMapToMarkers();
      }
    } catch (e) {
      print('Error setting up map: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    LatLngBounds bounds;
    if (_markers.length == 1) {
      // Single marker - center and zoom
      final marker = _markers.first;
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
      return;
    }

    // Multiple markers - fit bounds
    final lats = _markers.map((m) => m.position.latitude).toList();
    final lngs = _markers.map((m) => m.position.longitude).toList();

    bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );

    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  24.8607,
                  67.0011,
                ), // Default to Karachi, Pakistan
                zoom: 10,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                if (_markers.isNotEmpty) {
                  _fitMapToMarkers();
                }
              },
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            if (_markers.isEmpty && !_isLoading)
              Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No locations to display',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
