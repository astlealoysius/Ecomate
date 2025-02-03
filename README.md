# EcoMate - AI-Powered Waste Management App

EcoMate is a Flutter-based mobile application that helps users manage waste responsibly by providing AI-powered waste classification and location-based recycling services.

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

## Tech Stack

- **Frontend**: Flutter
- **AI/ML**: Google Gemini API
- **Maps**: OpenStreetMap with flutter_map
- **Location Services**: Geolocator
- **Permissions**: Permission Handler

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Google Gemini API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ecomate.git
```

2. Navigate to the project directory:
```bash
cd ecomate
```

3. Create a `.env` file in the root directory and add your Gemini API key:
```env
GEMINI_API_KEY=your_api_key_here
```

4. Install dependencies:
```bash
flutter pub get
```

5. Run the app:
```bash
flutter run
```

### Configuration

#### Android Setup
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS Setup
Add the following keys to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby waste management centers.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location to show nearby waste management centers.</string>
```

## Project Structure

```
lib/
├── screens/
│   ├── map_screen.dart
│   └── home_screen.dart
├── widgets/
│   └── waste_classifier_card.dart
├── utils/
│   └── constants.dart
└── main.dart
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
```

## Features in Development

- [ ] Chat interface for waste management queries
- [ ] Waste collection reminders
- [ ] Illegal dumping reporting system
- [ ] User authentication
- [ ] Offline support
- [ ] Multi-language support

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Gemini API for AI capabilities
- OpenStreetMap for mapping services
- Flutter and Dart teams for the amazing framework

## Resources

For help getting started with Flutter development:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)
```