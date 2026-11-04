import 'dart:math' as math;

import 'package:flutter/material.dart';
// latlong2 also exports a `Path` class, which would hide dart:ui's Path used for drawing.
import 'package:latlong2/latlong.dart' show LatLng;

import '../models.dart';

/// Round avatar with the user's initials (and photo when they have one).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.radius = 20, this.online});

  final User user;
  final double radius;

  /// Draws a green dot when true; nothing when null.
  final bool? online;

  static const _palette = [
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFFD81B60),
    Color(0xFF6D4C41),
    Color(0xFF3949AB),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[user.id.hashCode.abs() % _palette.length];
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      foregroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: Text(
        user.initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.8),
      ),
    );
    if (online != true) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.6,
            height: radius * 0.6,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws a route from its preview points, scaled to fit, without loading map tiles.
class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key, required this.points, this.height = 140});

  final List<LatLng> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: points.length < 2
          ? Center(child: Icon(Icons.route, color: scheme.outline))
          : CustomPaint(painter: _RoutePainter(points, scheme.primary), size: Size.infinite),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points, this.color);

  final List<LatLng> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Equirectangular projection with longitude scaled by cos(latitude) keeps shapes right.
    final midLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final kx = math.cos(midLat * math.pi / 180);
    final xs = points.map((p) => p.longitude * kx).toList();
    final ys = points.map((p) => -p.latitude).toList();
    final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    const pad = 16.0;
    final spanX = math.max(maxX - minX, 1e-9), spanY = math.max(maxY - minY, 1e-9);
    final scale = math.min((size.width - 2 * pad) / spanX, (size.height - 2 * pad) / spanY);
    final offX = (size.width - spanX * scale) / 2, offY = (size.height - spanY * scale) / 2;
    Offset at(int i) => Offset(offX + (xs[i] - minX) * scale, offY + (ys[i] - minY) * scale);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(0), 5, Paint()..color = const Color(0xFF2ECC71));
    canvas.drawCircle(at(points.length - 1), 5, Paint()..color = const Color(0xFFE74C3C));
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.points != points || old.color != color;
}

/// A labelled number, e.g. "5.20 km" over "Masofa".
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.large = false});

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 2),
        Text(value, style: (large ? text.headlineMedium : text.titleMedium)?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error.toString())));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
