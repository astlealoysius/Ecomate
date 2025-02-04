import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<List<PlaceSearch>> searchPlaces(String searchTerm) async {
    if (searchTerm.isEmpty) return [];

    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(searchTerm)}',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List places = json.decode(response.body);
      return places.map((place) => PlaceSearch.fromJson(place)).toList();
    }
    throw Exception('Failed to load places');
  }
}

class PlaceSearch {
  final String displayName;
  final LatLng location;

  PlaceSearch({
    required this.displayName,
    required this.location,
  });

  factory PlaceSearch.fromJson(Map<String, dynamic> json) {
    return PlaceSearch(
      displayName: json['display_name'] as String,
      location: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
    );
  }
}
