import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// One activity with its full route on the map. Pops `true` when it was deleted.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Activity? _activity;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final a = await context.read<Session>().api.activity(widget.activityId);
      if (mounted) setState(() => _activity = a);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mashg'ulotni o'chirish"),
        content: const Text("Bu amalni qaytarib bo'lmaydi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("O'chirish")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.deleteActivity(widget.activityId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _activity;
    final mine = a != null && a.user.id == context.select<Session, String?>((s) => s.me?.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(a?.title ?? "Mashg'ulot"),
        actions: [
          if (mine) IconButton(tooltip: "O'chirish", icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: a == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error.toString()),
                        TextButton(onPressed: _load, child: const Text('Qayta urinish')),
                      ],
                    ),
            )
          : _Body(activity: a),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final line = (a.points ?? const <TrackPoint>[]).map((p) => p.point).toList();
    final route = line.length >= 2 ? line : a.preview;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isRide = a.type == 'ride';

    return ListView(
      children: [
        SizedBox(
          height: 320,
          child: route.length < 2
              ? const Center(child: Icon(Icons.route, size: 48))
              : FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(route),
                      padding: const EdgeInsets.all(32),
                    ),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(urlTemplate: AppConfig.tileUrl, userAgentPackageName: AppConfig.packageName),
                    PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 5, color: scheme.primary)]),
                    MarkerLayer(markers: [
                      _dot(route.first, const Color(0xFF2ECC71)),
                      _dot(route.last, const Color(0xFFE74C3C)),
                    ]),
                    const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(user: a.user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.user.name, style: text.titleMedium),
                        Text('${activityTypeNames[a.type] ?? a.type} · ${formatDateTime(a.startedAt)}', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (a.description.isNotEmpty) ...[const SizedBox(height: 12), Text(a.description)],
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  StatTile(label: 'Masofa', value: formatDistance(a.distanceM)),
                  StatTile(label: 'Harakat vaqti', value: formatDuration(a.movingTimeS)),
                  StatTile(label: 'Umumiy vaqt', value: formatDuration(a.durationS)),
                  StatTile(
                    label: isRide ? "O'rtacha tezlik" : "O'rtacha temp",
                    value: isRide ? formatSpeed(a.avgSpeedMps) : formatPace(a.avgSpeedMps),
                  ),
                  StatTile(label: 'Maks. tezlik', value: formatSpeed(a.maxSpeedMps)),
                  StatTile(label: "Ko'tarilish", value: '${a.elevationGainM.round()} m'),
                ],
              ),
              const SizedBox(height: 8),
              Text('${a.kudosCount} kudos · ${_visibilityLabel(a.visibility)}', style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  static String _visibilityLabel(String visibility) => switch (visibility) {
        'public' => "Hamma ko'radi",
        'private' => "Faqat siz ko'rasiz",
        _ => "Do'stlar ko'radi",
      };

  Marker _dot(LatLng p, Color color) => Marker(
        point: p,
        width: 18,
        height: 18,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
        ),
      );
}
