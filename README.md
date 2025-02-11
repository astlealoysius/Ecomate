# EcoMate - AI-Powered Waste Management App

EcoMate is a Flutter-based mobile application that helps users manage waste responsibly by providing AI-powered waste classification, location-based recycling services, and community engagement features.

## Features

### 1. AI Waste Classification
- Take or upload photos of waste items
- Get instant AI-powered classification using Gemini API
- Receive detailed information about:
  - Object identification
  - Waste category (Recyclable/Non-Recyclable/Toxic/Biological)
  - Proper disposal methods
  - Recycling instructions
  - Environmental impact

### 2. Interactive Map
- View nearby waste management facilities
- Real-time location tracking
- Different markers for recycling centers and waste collection points
- Distance information and directions
- Expandable map view with facility details

### 3. Waste Report System
- Report illegal dumping or waste management issues
- Upload photos with location data
- Track report status
- Community-driven waste monitoring

### 4. AI Chat Assistant
- Interactive chat interface powered by Gemini AI
- Get instant answers about waste management
- Learn about recycling best practices
- Receive eco-friendly tips and advice

### 5. Interactive Learning Hub
- Educational videos on waste management and sustainability
- Daily eco-facts to increase environmental awareness
- Interactive quizzes to test knowledge
- Progress tracking for completed lessons
- Engaging content about recycling practices and environmental conservation

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication
  - Realtime Database
- **AI/ML**: Google Gemini API
- **Maps**: OpenStreetMap with flutter_map
- **Location Services**: Geolocator
- **Permissions**: Permission Handler
- **Image Storage**: Cloudinary

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Google Gemini API key
- Firebase project configuration
- Cloudinary account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ecomate.git
```

2. Navigate to the project directory:
```bash
cd ecomate
```

3. Create a `.env` file in the root directory and add your API keys:
```env
GEMINI_API_KEY=your_api_key_here
```

4. Install dependencies:
```bash
flutter pub get
```

5. Set up Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

6. Run the app:
```bash
flutter run
```

### Configuration

#### Android Setup
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS Setup
Add the following keys to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby waste management centers.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to show nearby waste management centers.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture waste images for classification.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to upload waste images for classification.</string>
```

## Project Structure

```
lib/
├── main.dart
├── screens/
│   ├── chat_screen.dart
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── profile_screen.dart
│   └── report_screen.dart
├── services/
│   └── firebase_service.dart
├── theme/
│   └── app_theme.dart
└── utils/
    └── constants.dart
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_generative_ai: ^0.4.6
  image_picker: ^1.0.4
  flutter_dotenv: ^5.1.0
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  permission_handler: ^11.3.0
  http: ^1.2.0
  url_launcher: ^6.2.5
  firebase_core: ^2.32.0
  firebase_storage: ^11.6.0
  firebase_database: ^10.4.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.14.0
  google_fonts: ^6.1.0
  uuid: ^4.2.2
  cloudinary: ^1.0.0
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.