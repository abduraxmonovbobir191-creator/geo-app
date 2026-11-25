/// Build-time settings. Override with
/// `flutter run --dart-define=API_URL=https://api.example.com`.
class AppConfig {
  /// Backend address. For a local server from the Android emulator use
  /// `--dart-define=API_URL=http://10.0.2.2:3000` (10.0.2.2 is the host computer).
  static const defaultApiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api.nexecos.com');

  /// Map tiles from the Nex Map tile server. `{style}` becomes "light" or "dark" and `{r}`
  /// becomes "@2x" on high-density screens.
  static const tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tiles.nexecos.com/styles/{style}/{z}/{x}/{y}{r}.png',
  );

  static const packageName = 'uz.nexmap.nex_map';
}
