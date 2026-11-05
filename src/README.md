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
   cd src
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

### Living labs and amenities

The homepage fetches living labs from the authenticated `/livinglabs/` endpoint.
Weather and straight-line distances use the midpoint of each area's geographic
bounds, not a park entrance or walking route. The user's choice is saved locally.
Without location permission, manual selection remains available and distance is
shown as unavailable. For simulator testing, set its simulated location to
Eindhoven (51.4416, 5.4697); real devices use their own reported location.

The map loads `assets/data/amenities/zuid_kennemerland.json` and
`assets/data/amenities/kempenbroek.json`. Each is a list of objects with `type`,
`name`, `latitude` and `longitude`. IDs are generated from park, type and
coordinates. Keep a type's spelling consistent. Supported types have dedicated
icons. Advisors can propose new types in the private editor, but each new type
must first be added to the app's category list with its own icon and colour.
There is no generic-pin fallback. Do not bundle JSON containing unsupported
types: it will fail validation rather than display an arbitrary pin. There is no server
sync: validate returned corrections, replace the relevant bundled JSON and rebuild.

The 61 Zuid-Kennemerland points were imported on 2026-10-24 from
[Bezoek Nationaal Park Zuid-Kennemerland 2025](https://www.google.com/maps/d/viewer?mid=1yhMuEPiDde25OETu9NBjBm6LQzxy3U8).
Names and coordinates are preserved; boundaries and construction shapes are
excluded. Advisor verification is still pending.

**KempenBroek currently contains five deliberately fictional sample toilets.**
Their `Voorbeeldtoilet` names identify them as examples. At the project owner's
request they have no `example` flag and behave like ordinary navigable points.
These are demonstration data, not verified facilities. Replace their names and
coordinates with the living lab's approved data before a public release. Issue
#74 remains open. The private HTML review editor and review copies are not part
of this repository or the app build.

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
