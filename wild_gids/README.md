# Wild Gids

A Flutter application for reporting and tracking wildlife sightings and interactions.

## Features

- Wildlife sighting reporting with location tracking
- Animal species identification and categorization
- Interactive map with location-based observations
- Questionnaires and damage reporting
- Offline support with data synchronization
- User authentication and profile management

## Prerequisites

- Flutter SDK 3.7.0 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- A `.env` file with required API configuration

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wild_gids
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   - Create a `.env` file in the project root
   - Add required API endpoints and configuration

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

The app uses a `.env` file for backend configuration.
For details on the required keys and their meaning, see `env usage.txt` in the project root.

## Project Structure

- `lib/` - Main application code
  - `screens/` - UI screens
  - `providers/` - State management
  - `models/` - Data models
  - `data_managers/` - API clients and data handling
  - `managers/` - Business logic managers
  - `widgets/` - Reusable UI components
  - `utils/` - Helper functions and utilities
- `test/` - Unit and widget tests
- `integration_test/` - Integration tests
- `assets/` - Images, icons, and other assets

## Testing

Run unit and widget tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test
```

## Building

For Android:
```bash
flutter build apk
```

For iOS:
```bash
flutter build ios
```

## License

See the [LICENSE](LICENSE) file for details.
