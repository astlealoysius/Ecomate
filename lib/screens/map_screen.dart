import 'dart:io';  // Add this for Platform
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';  // Add this for AppColors

class MapScreen extends StatefulWidget {
  final bool isFullScreen;
  
  const MapScreen({super.key, this.isFullScreen = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _wasteCenters = [];
  bool _isLoading = false;
  
  // Replace getWasteCenters with these methods
  Future<void> fetchWasteCenters(LatLng location) async {
    setState(() => _isLoading = true);
    try {
      // Overpass API query for recycling and waste facilities
      final query = """
      [out:json][timeout:25];
      (
        node["amenity"="recycling"](around:5000,${location.latitude},${location.longitude});
        way["amenity"="recycling"](around:5000,${location.latitude},${location.longitude});
        node["waste"="disposal"](around:5000,${location.latitude},${location.longitude});
        way["waste"="disposal"](around:5000,${location.latitude},${location.longitude});
      );
      out body;
      >;
      out skel qt;
      """;

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        setState(() {
          _wasteCenters = elements.where((e) => e['lat'] != null && e['lon'] != null).map((e) {
            final type = e['tags']?['amenity'] == 'recycling' ? 'recycling' : 'collection';
            final name = e['tags']?['name'] ?? 
                        (type == 'recycling' ? 'Recycling Center' : 'Waste Collection');
            
            return {
              'name': name,
              'location': LatLng(e['lat'].toDouble(), e['lon'].toDouble()),
              'type': type,
              'distance': calculateDistance(
                location.latitude, 
                location.longitude,
                e['lat'].toDouble(), 
                e['lon'].toDouble()
              ),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching waste centers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in kilometers
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat/2) * sin(dLat/2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * 
        sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    final d = R * c;
    return '${d.toStringAsFixed(1)}km';
  }

  double _toRad(double deg) => deg * pi / 180;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation!, 15);
        // Fetch real waste centers once we have location
        await fetchWasteCenters(_currentLocation!);
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  Future<void> _openDirections(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;
    
    // Create map URL
    final url = Platform.isIOS
        ? 'https://maps.apple.com/?daddr=$lat,$lng'
        : 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open map application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFullScreen
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Nearby Centers'),
              actions: [
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _currentLocation != null 
                    ? () => fetchWasteCenters(_currentLocation!)
                    : null,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(child: _buildMap(_wasteCenters)),
                _buildCentersList(_wasteCenters),
              ],
            ),
          )
        : Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(isFullScreen: true),
                    ),
                  );
                },
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      _buildMap(_wasteCenters),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MapScreen(isFullScreen: true),
                              ),
                            );
                          },
                          child: const Icon(Icons.fullscreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildMap(List<Map<String, dynamic>> centers) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? const LatLng(1.3521, 103.8198),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecomate',
        ),
        MarkerLayer(
          markers: [
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ...centers.map((center) => Marker(
                  point: center['location'],
                  width: 40,
                  height: 40,
                  child: Icon(
                    center['type'] == 'recycling'
                        ? Icons.recycling
                        : Icons.delete,
                    color: center['type'] == 'recycling'
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildCentersList(List<Map<String, dynamic>> centers) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: centers.length,
        itemBuilder: (context, index) {
          final center = centers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        center['type'] == 'recycling'
                            ? Icons.recycling
                            : Icons.delete,
                        color: center['type'] == 'recycling'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          center['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Distance: ${center['distance']}'),
                  TextButton.icon(
                    onPressed: () => _openDirections(center['location']),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 