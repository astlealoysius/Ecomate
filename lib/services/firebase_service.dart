import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary/cloudinary.dart';

class FirebaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _reportsPath = 'reports';
  static final _uuid = Uuid();

  // Initialize Cloudinary
  static final cloudinary = Cloudinary.signedConfig(
    cloudName: 'dtx75nqj5',
    apiKey: '982768945834295',
    apiSecret: '7dE-xQyIksXLu5i7bKn9IaglSmg',
  );

  // Upload image to Cloudinary
  static Future<String> uploadImage(File imageFile) async {
    try {
      debugPrint('Starting Cloudinary upload...');
      
      final response = await cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'illegal_dumping_reports',
      );

      if (response.isSuccessful) {
        debugPrint('Image uploaded successfully to Cloudinary');
        debugPrint('Secure URL: ${response.secureUrl}');
        return response.secureUrl ?? '';
      } else {
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  // Submit report to Firebase Realtime Database
  static Future<String> submitReport({
    required File imageFile,
    required LatLng location,
    required String description,
    String? status = 'pending',
  }) async {
    try {
      // First upload image to Cloudinary
      debugPrint('Step 1: Uploading image to Cloudinary');
      final String imageUrl = await uploadImage(imageFile);
      debugPrint('Image uploaded successfully: $imageUrl');

      // Generate a unique ID for the report
      final String reportId = _uuid.v4();
      debugPrint('Generated report ID: $reportId');

      // Create the report data
      final Map<String, dynamic> report = {
        'id': reportId,
        'imageUrl': imageUrl,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'description': description,
        'status': status,
        'timestamp': ServerValue.timestamp,
      };

      // Save to Firebase Realtime Database
      debugPrint('Step 2: Saving report data to Firebase');
      final DatabaseReference reportRef = _database
          .ref()
          .child(_reportsPath)
          .child(reportId);

      await reportRef.set(report);
      debugPrint('Report data saved successfully');

      return reportId;
    } catch (e) {
      debugPrint('Error submitting report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get all reports
  static Stream<DatabaseEvent> getReports() {
    return _database
        .ref()
        .child(_reportsPath)
        .orderByChild('timestamp')
        .onValue;
  }

  // Update report status
  static Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _database
          .ref()
          .child(_reportsPath)
          .child(reportId)
          .update({'status': status});
      debugPrint('Status updated successfully');
    } catch (e) {
      debugPrint('Error updating status: $e');
      throw Exception('Failed to update status: $e');
    }
  }

  // Convert DatabaseEvent to List of reports
  static List<Map<String, dynamic>> getReportListFromEvent(DatabaseEvent event) {
    final List<Map<String, dynamic>> reports = [];
    
    if (event.snapshot.value != null) {
      try {
        final Map<dynamic, dynamic> values = 
            event.snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          if (value is Map) {
            reports.add(Map<String, dynamic>.from(value));
          }
        });
        debugPrint('Processed ${reports.length} reports');
      } catch (e) {
        debugPrint('Error processing reports: $e');
      }
    }
    
    return reports;
  }
}
