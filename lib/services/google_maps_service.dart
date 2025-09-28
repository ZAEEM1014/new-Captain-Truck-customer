import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapsService {
  // Get API key from environment variables
  static String get API_KEY =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';

  static const String PLACES_BASE_URL =
      'https://maps.googleapis.com/maps/api/place';
  static const String GEOCODING_BASE_URL =
      'https://maps.googleapis.com/maps/api/geocode';
  static const String DIRECTIONS_BASE_URL =
      'https://maps.googleapis.com/maps/api/directions';

  // Get place suggestions for address autocomplete
  static Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String query, {
    double? currentLat,
    double? currentLng,
  }) async {
    if (query.isEmpty) return [];

    try {
      print('🔍 Searching for places with query: $query');
      print('🔑 Using API key: ${API_KEY.substring(0, 10)}...');


    String url =
      '$PLACES_BASE_URL/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$API_KEY'
      '&components=country:CA'
      '&types=address'
      '&language=en'
      '&strictbounds'
      '&sessiontoken=${DateTime.now().millisecondsSinceEpoch}'
      '&limit=10'; // Request more suggestions if supported

      // Add location bias if current location is available
      if (currentLat != null && currentLng != null) {
        url += '&location=$currentLat,$currentLng';
        url += '&radius=50000'; // 50km radius
        print('📍 Using location bias: $currentLat, $currentLng');
      }

      print('🌐 Request URL: ${url.replaceAll(API_KEY, 'API_KEY_HIDDEN')}');

      final response = await http.get(Uri.parse(url));

      print('📱 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Response data status: ${data['status']}');

        if (data['status'] == 'OK') {
          final predictions = List<Map<String, dynamic>>.from(
            data['predictions'],
          );
          print('🎯 Found ${predictions.length} suggestions');

          // Alberta service area cities
          final List<String> albertaCities = [
            'Calgary', 'Edmonton', 'Lethbridge', 'Red Deer', 'Grande Prairie',
            'Medicine Hat', 'St. Albert', 'Banff', 'Brooks', 'Fort McMurray',
            'Strathmore', 'Cochrane', 'Okotoks', 'High River', 'Crossfield'
          ];

          // Group suggestions by city and highways, and keep max for each
          final List<Map<String, dynamic>> citySuggestions = [];
          final List<Map<String, dynamic>> highwaySuggestions = [];
          final int maxPerCity = 5;
          final int maxHighway = 10;
          final Map<String, int> cityCounts = {};
          int highwayCount = 0;

          for (final p in predictions) {
            final desc = (p['description'] ?? '').toString();
            // Highways Canada-wide
            if ((desc.contains('Hwy') || desc.contains('Trans-Canada') || desc.contains('AB-')) && highwayCount < maxHighway) {
              highwaySuggestions.add(p);
              highwayCount++;
              continue;
            }
            // Alberta cities
            for (final city in albertaCities) {
              if (desc.contains(city + ',')) {
                cityCounts[city] = (cityCounts[city] ?? 0) + 1;
                if (cityCounts[city]! <= maxPerCity) {
                  citySuggestions.add(p);
                }
                break;
              }
            }
          }

          final filtered = [...citySuggestions, ...highwaySuggestions];
          print('🎯 Filtered to ${filtered.length} Alberta/corridor suggestions (max per city/highway)');
          return filtered;
        } else {
          print('❌ API returned error status: ${data['status']}');
          if (data['error_message'] != null) {
            print('❌ Error message: ${data['error_message']}');
          }
        }
      }
      return [];
    } catch (e) {
      print('💥 Error fetching place suggestions: $e');
      return [];
    }
  }

  // Get coordinates from place ID
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url =
          '$PLACES_BASE_URL/details/json'
          '?place_id=$placeId'
          '&fields=geometry,formatted_address'
          '&key=$API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return {
            'lat': location['lat'],
            'lng': location['lng'],
            'address': data['result']['formatted_address'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }

  // Geocode address to coordinates
  static Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      print('🌍 Geocoding address: $address');

      final url =
          '$GEOCODING_BASE_URL/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$API_KEY';

      print('🔗 Geocoding URL: ${url.replaceAll(API_KEY, 'API_KEY_HIDDEN')}');

      final response = await http.get(Uri.parse(url));

      print('📍 Geocoding response status: ${response.statusCode}');
      print('📍 Geocoding response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📍 Geocoding status: ${data['status']}');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final result = {
            'lat': location['lat'],
            'lng': location['lng'],
            'formatted_address': data['results'][0]['formatted_address'],
          };
          print('✅ Geocoding successful: $result');
          return result;
        } else {
          print(
            '❌ Geocoding failed: ${data['status']} - ${data['error_message'] ?? 'No error message'}',
          );
        }
      } else {
        print('❌ Geocoding HTTP error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ Error geocoding address: $e');
      return null;
    }
  }

  // Get directions between two points
  static Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url =
          '$DIRECTIONS_BASE_URL/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$API_KEY';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return {
            'distance': leg['distance']['text'],
            'distance_value': leg['distance']['value'], // in meters
            'duration': leg['duration']['text'],
            'duration_value': leg['duration']['value'], // in seconds
            'polyline': route['overview_polyline']['points'],
            'bounds': route['bounds'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  // Calculate distance in kilometers
  static double calculateDistanceInKm(int distanceInMeters) {
    return distanceInMeters / 1000.0;
  }

  // Decode polyline points for route display
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
