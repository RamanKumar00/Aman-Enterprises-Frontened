import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // Using OpenStreetMap Nominatim API (Free, No Key required)
  // IMPORTANT: Respect Usage Policy (1 request/sec max, provide User-Agent)
  
  // Bihar state boundaries (approximate bounding box)
  // Valid state names for Bihar in different formats
  static const List<String> validBiharStates = [
    'bihar',
    'br',
    'बिहार', // Hindi
  ];

  /// Check if a state name belongs to Bihar
  static bool isInBihar(String? stateName) {
    if (stateName == null || stateName.isEmpty) return false;
    return validBiharStates.contains(stateName.toLowerCase().trim());
  }

  /// Get nearby places/landmarks from coordinates
  Future<List<NearbyPlace>> getNearbyPlaces(double latitude, double longitude) async {
    List<NearbyPlace> places = [];
    
    try {
      // Search for nearby POIs (Points of Interest) using Overpass API
      // We'll search for common landmarks within ~500m radius
      final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"](around:500,$latitude,$longitude);
  node["shop"](around:500,$latitude,$longitude);
  node["tourism"](around:500,$latitude,$longitude);
  node["historic"](around:500,$latitude,$longitude);
  node["place"="locality"](around:1000,$latitude,$longitude);
  node["place"="neighbourhood"](around:1000,$latitude,$longitude);
);
out body 15;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
        url,
        headers: {'User-Agent': 'AmanEnterprisesApp/1.0'},
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List? ?? [];
        
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] as String?;
          if (name != null && name.isNotEmpty) {
            String type = tags['amenity'] ?? tags['shop'] ?? tags['tourism'] ?? tags['place'] ?? 'landmark';
            places.add(NearbyPlace(
              name: name,
              type: _formatPlaceType(type),
              latitude: element['lat']?.toDouble() ?? latitude,
              longitude: element['lon']?.toDouble() ?? longitude,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
    }
    
    // If Overpass API fails, try a fallback with Nominatim search
    if (places.isEmpty) {
      places = await _getFallbackNearbyPlaces(latitude, longitude);
    }
    
    // Remove duplicates and limit results
    final uniquePlaces = <String, NearbyPlace>{};
    for (var place in places) {
      uniquePlaces[place.name.toLowerCase()] = place;
    }
    
    return uniquePlaces.values.take(10).toList();
  }

  Future<List<NearbyPlace>> _getFallbackNearbyPlaces(double latitude, double longitude) async {
    List<NearbyPlace> places = [];
    
    try {
      // Use reverse geocoding to get nearby addresses
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&extratags=1&namedetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AmanEnterprisesApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        
        // Add various address components as nearby places
        final placeTypes = ['suburb', 'neighbourhood', 'hamlet', 'village', 'town'];
        for (var type in placeTypes) {
          if (addr[type] != null && addr[type].toString().isNotEmpty) {
            places.add(NearbyPlace(
              name: addr[type],
              type: _formatPlaceType(type),
              latitude: latitude,
              longitude: longitude,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching fallback nearby places: $e');
    }
    
    return places;
  }

  String _formatPlaceType(String type) {
    // Format place type for display
    switch (type.toLowerCase()) {
      case 'hospital':
        return '🏥 Hospital';
      case 'school':
        return '🏫 School';
      case 'college':
        return '🎓 College';
      case 'bank':
        return '🏦 Bank';
      case 'atm':
        return '💳 ATM';
      case 'restaurant':
        return '🍽️ Restaurant';
      case 'cafe':
        return '☕ Cafe';
      case 'pharmacy':
        return '💊 Pharmacy';
      case 'place_of_worship':
        return '🛕 Temple/Mosque';
      case 'temple':
        return '🛕 Temple';
      case 'mosque':
        return '🕌 Mosque';
      case 'church':
        return '⛪ Church';
      case 'petrol_pump':
      case 'fuel':
        return '⛽ Petrol Pump';
      case 'bus_station':
        return '🚌 Bus Station';
      case 'railway_station':
        return '🚂 Railway Station';
      case 'suburb':
        return '📍 Area';
      case 'neighbourhood':
        return '📍 Neighbourhood';
      case 'hamlet':
      case 'village':
        return '🏘️ Village';
      case 'town':
        return '🏙️ Town';
      case 'supermarket':
        return '🛒 Supermarket';
      case 'hotel':
        return '🏨 Hotel';
      case 'park':
        return '🌳 Park';
      case 'police':
        return '👮 Police Station';
      case 'post_office':
        return '📮 Post Office';
      default:
        return '📍 Landmark';
    }
  }
  
  /// Check permissions and get current position
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    } 

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  /// Get address from coordinates (Reverse Geocoding)
  /// Tries local device geocoding first, falls back to OSM Nominatim
  Future<Placemark?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // 1. Try Local Device Geocoding (Fastest, built-in)
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
    } catch (e) {
      debugPrint('Local geocoding failed, trying OSM: $e');
    }
    
    // 2. Fallback to OpenStreetMap API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AmanEnterprisesApp/1.0 (aman@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final addr = data['address'];
          return Placemark(
            name: addr['house_number'] ?? addr['building'] ?? addr['shop'] ?? '',
            street: addr['road'] ?? '',
            subLocality: addr['suburb'] ?? addr['neighbourhood'] ?? '',
            locality: addr['city'] ?? addr['town'] ?? addr['village'] ?? '',
            postalCode: addr['postcode'] ?? '',
            administrativeArea: addr['state'] ?? '',
            country: addr['country'] ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('OSM Reverse Geocoding Error: $e');
    }
    
    return null;
  }

  /// Get place predictions (Search)
  Future<List<Prediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    // Search via OSM Nominatim
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$input&format=json&polygon_geojson=1&addressdetails=1&countrycodes=in&limit=5'
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AmanEnterprisesApp/1.0 (aman@example.com)'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => Prediction.fromOSM(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
    }
    return [];
  }
}

class Prediction {
  final String description;
  final String displayName;
  final double lat;
  final double lng;

  Prediction({
    required this.description,
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  // Mapper for OpenStreetMap response
  factory Prediction.fromOSM(Map<String, dynamic> json) {
    return Prediction(
      description: json['display_name'] ?? '',
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'] ?? '0'),
      lng: double.parse(json['lon'] ?? '0'),
    );
  }
}

/// Model for nearby places/landmarks
class NearbyPlace {
  final String name;
  final String type;
  final double latitude;
  final double longitude;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
  });
}
