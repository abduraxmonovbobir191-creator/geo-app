import 'package:intl/intl.dart';

/// "850 m" below a kilometer, "12.35 km" above.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

/// "5:07" for minutes:seconds, "1:02:09" with hours.
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Running pace as "5:00 /km"; "-" when not moving.
String formatPace(double? speedMps) {
  if (speedMps == null || speedMps <= 0.3) return '-';
  final secondsPerKm = (1000 / speedMps).round();
  return '${formatDuration(secondsPerKm)} /km';
}

/// Speed in km/h, for rides.
String formatSpeed(double speedMps) => '${(speedMps * 3.6).toStringAsFixed(1)} km/soat';

String formatDateTime(DateTime time) => DateFormat('dd.MM.yyyy HH:mm').format(time.toLocal());

/// "hozir", "5 daq oldin", "3 soat oldin", "2 kun oldin" or a date.
String formatAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'hozir';
  if (diff.inHours < 1) return '${diff.inMinutes} daq oldin';
  if (diff.inDays < 1) return '${diff.inHours} soat oldin';
  if (diff.inDays < 7) return '${diff.inDays} kun oldin';
  return DateFormat('dd.MM.yyyy').format(time.toLocal());
}

const activityTypeNames = {
  'run': 'Yugurish',
  'ride': 'Velosiped',
  'walk': 'Piyoda',
  'hike': 'Sayohat',
};
