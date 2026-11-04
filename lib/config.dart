/// Build-time settings. Override with
/// `flutter run --dart-define=API_URL=https://api.example.com`.
class AppConfig {
  /// Default backend address. 10.0.2.2 is the host computer as seen from the Android emulator.
  static const defaultApiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

  /// Map tiles. OpenStreetMap's public tiles are fine for testing; use your own tile server
  /// or a provider (MapTiler, Stadia, ...) before publishing to many users.
  static const tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const packageName = 'uz.nexmap.nex_map';
}
