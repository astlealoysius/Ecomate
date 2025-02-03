import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  final bool isFullScreen;
  
  const MapScreen({super.key, this.isFullScreen = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  
  // Updated waste centers function to generate centers around user location
  List<Map<String, dynamic>> getWasteCenters(LatLng? baseLocation) {
    if (baseLocation == null) return [];
    
    // Generate some random nearby points
    return List.generate(5, (index) {
      final lat = baseLocation.latitude + (Random().nextDouble() - 0.5) * 0.01;
      final lng = baseLocation.longitude + (Random().nextDouble() - 0.5) * 0.01;
      
      return {
        'name': index % 2 == 0 ? 'Recycling Center ${index + 1}' : 'Waste Collection ${index + 1}',
        'location': LatLng(lat, lng),
        'type': index % 2 == 0 ? 'recycling' : 'collection',
        'distance': '${(Random().nextDouble() * 2).toStringAsFixed(1)}km'
      };
    });
  }

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
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wasteCenters = getWasteCenters(_currentLocation);
    
    return widget.isFullScreen
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Nearby Centers'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getCurrentLocation,
                )
              ],
            ),
            body: Column(
              children: [
                Expanded(child: _buildMap(wasteCenters)),
                _buildCentersList(wasteCenters),
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
                      _buildMap(wasteCenters),
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
                  TextButton(
                    onPressed: () {
                      // TODO: Implement navigation
                    },
                    child: const Text('Get Directions'),
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