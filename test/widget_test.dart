import 'package:flutter_test/flutter_test.dart';
import 'package:nex_map/models.dart';
import 'package:nex_map/utils/format.dart';

void main() {
  group('format', () {
    test('distance', () {
      expect(formatDistance(850.4), '850 m');
      expect(formatDistance(12345), '12.35 km');
    });

    test('duration', () {
      expect(formatDuration(307), '5:07');
      expect(formatDuration(3729), '1:02:09');
    });

    test('pace', () {
      expect(formatPace(1000 / 300), '5:00 /km');
      expect(formatPace(0), '-');
      expect(formatPace(null), '-');
    });

    test('ago', () {
      final now = DateTime(2026, 1, 1, 12);
      expect(formatAgo(now.subtract(const Duration(seconds: 20)), now: now), 'hozir');
      expect(formatAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 daq oldin');
      expect(formatAgo(now.subtract(const Duration(hours: 3)), now: now), '3 soat oldin');
    });
  });

  group('models', () {
    test('activity from API JSON', () {
      final a = Activity.fromJson({
        'id': 'a1',
        'user': {'id': 'u1', 'username': 'ali', 'name': 'Ali Valiyev', 'bio': '', 'avatarUrl': null},
        'type': 'run',
        'title': 'Run',
        'description': '',
        'visibility': 'friends',
        'startedAt': '2026-01-01T06:00:00.000Z',
        'distanceM': 5000,
        'durationS': 1500,
        'movingTimeS': 1490,
        'elevationGainM': 12.5,
        'avgSpeedMps': 3.35,
        'maxSpeedMps': 4.1,
        'preview': [
          [41.3, 69.2],
          [41.31, 69.21],
        ],
        'kudosCount': 2,
        'hasKudos': false,
      });
      expect(a.distanceM, 5000.0);
      expect(a.preview.length, 2);
      expect(a.user.initials, 'AV');
      expect(a.withKudos(3, true).kudosCount, 3);
    });

    test('track point JSON uses unix milliseconds', () {
      final p = TrackPoint(lat: 41.3, lng: 69.2, time: DateTime.utc(2026, 1, 1), ele: 450);
      expect(p.toJson(), {'lat': 41.3, 'lng': 69.2, 't': DateTime.utc(2026, 1, 1).millisecondsSinceEpoch, 'ele': 450});
    });
  });
}
