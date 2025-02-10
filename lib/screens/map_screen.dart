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
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.9),
              title: const Text(
                'Nearby Centers',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                if (_isLoading)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.green[700],
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[700]),
                  onPressed: _currentLocation != null 
                    ? () => fetchWasteCenters(_currentLocation!)
                    : null,
                ),
              ],
            ),
            body: Stack(
              children: [
                _buildMap(_wasteCenters),
                if (_currentLocation != null)
                  Positioned(
                    bottom: 160,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'location',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _mapController.move(_currentLocation!, 15);
                      },
                      child: Icon(Icons.my_location, color: Colors.green[700]),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: _buildCentersList(_wasteCenters),
                  ),
                ),
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Nearby Centers',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const MapScreen(isFullScreen: true),
                              ),
                            );
                          },
                          child: Icon(Icons.fullscreen, color: Colors.green[700]),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ...centers.map((center) => Marker(
                  point: center['location'],
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: center['type'] == 'recycling' ? Colors.green[600] : Colors.red[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      center['type'] == 'recycling' ? Icons.recycling : Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildCentersList(List<Map<String, dynamic>> centers) {
    if (centers.isEmpty) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 28),
              const SizedBox(height: 8),
              Text(
                'No centers found nearby',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: centers.length,
        itemBuilder: (context, index) {
          final center = centers[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openDirections(center['location']),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: center['type'] == 'recycling'
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              center['type'] == 'recycling'
                                  ? Icons.recycling
                                  : Icons.delete,
                              color: center['type'] == 'recycling'
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  center['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Distance: ${center['distance']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Get Directions',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 