import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _mapController = MapController();
  File? _imageFile;
  Position? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = false;
  bool _useCustomLocation = false;
  List<PlaceSearch> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      setState(() => _isLoading = true);
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_selectedPosition == null) {
        _selectedPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_useCustomLocation) {
      setState(() {
        _selectedPosition = point;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('Please add a photo of the illegal dumping');
      return;
    }
    if (_selectedPosition == null) {
      _showError('Location not available. Please enable location services or set a custom location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.submitReport(
        imageFile: _imageFile!,
        location: _selectedPosition!,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      _showError('Failed to submit report: $e');
    }
  }

  void _selectSearchResult(PlaceSearch place) {
    setState(() {
      _selectedPosition = place.location;
      _searchResults = [];
      _searchController.text = '';
      _mapController.move(_selectedPosition!, 15);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await LocationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      _showError('Error searching for places: $e');
      setState(() => _isSearching = false);
    }
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a place...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            if (value.length >= 3) {
              _searchPlaces(value);
            } else {
              setState(() => _searchResults = []);
            }
          },
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    title: Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(place),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Custom Location'),
            subtitle: Text(_useCustomLocation 
              ? 'Search or tap on the map to set location' 
              : 'Using current location'),
            value: _useCustomLocation,
            onChanged: (bool value) {
              setState(() {
                _useCustomLocation = value;
                if (!value && _currentPosition != null) {
                  _selectedPosition = LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  );
                }
                _searchResults = [];
                _searchController.clear();
              });
            },
          ),
          if (_useCustomLocation) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSearchBar(),
            ),
          ],
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onTap: _onMapTap,
                center: _selectedPosition ?? const LatLng(0, 0),
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecomate',
                ),
                if (_selectedPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition!,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _selectedPosition != null
                ? 'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}\nLong: ${_selectedPosition!.longitude.toStringAsFixed(6)}'
                : 'No location selected',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Illegal Dumping'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLocationSection(),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Card(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                    Text('Tap to add photo'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the illegal dumping situation',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isLoading ? 'Submitting...' : 'Submit Report'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
