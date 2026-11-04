import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationUnavailable implements Exception {
  final String message;

  const LocationUnavailable(this.message);

  @override
  String toString() => message;
}

/// Wraps geolocator with the app's permission flow and settings.
class LocationService {
  /// Asks for permission if needed. Throws [LocationUnavailable] with a message for the user.
  static Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Telefonda joylashuv (GPS) o\'chirilgan. Uni yoqing.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable('Joylashuvga ruxsat berilmadi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Joylashuvga ruxsat sozlamalarda o\'chirilgan. Ilova sozlamalaridan yoqing.');
    }
  }

  static Future<Position> current() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
  }

  /// Positions for sharing with friends: moderate accuracy, every ~20 m.
  static Stream<Position> shareStream() =>
      Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20));

  /// Positions for recording an activity: best accuracy, every ~5 m. On Android a foreground
  /// notification keeps recording while the screen is off.
  static Stream<Position> recordStream() {
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Nex Map',
          notificationText: 'Mashg\'ulot yozilmoqda',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        // Turning this on also needs UIBackgroundModes "location" in ios/Runner/Info.plist,
        // otherwise iOS stops the app. Enable both together when the iOS build is set up.
        allowBackgroundLocationUpdates: false,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
