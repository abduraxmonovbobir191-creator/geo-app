import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models.dart';
import '../services/location_service.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'activity_screen.dart';

enum _Phase { idle, recording, paused }

/// Records a run/ride/walk with GPS (Strava-style) and uploads it.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  /// Fixes worse than this many meters are ignored; they make the route zig-zag.
  static const _maxAccuracyM = 30.0;

  final _map = MapController();
  final _distance = const Distance();
  StreamSubscription<Position>? _sub;
  Timer? _ticker;
  _Phase _phase = _Phase.idle;
  String _type = 'run';

  final List<TrackPoint> _points = [];
  double _distanceM = 0;
  // Moving time: total of finished recording stretches plus the current one.
  Duration _elapsedBefore = Duration.zero;
  DateTime? _stretchStart;
  bool _saving = false;

  Duration get _elapsed =>
      _elapsedBefore + (_stretchStart == null ? Duration.zero : DateTime.now().difference(_stretchStart!));

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await LocationService.ensurePermission();
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }
    setState(() {
      _points.clear();
      _distanceM = 0;
      _elapsedBefore = Duration.zero;
    });
    _resume();
  }

  void _resume() {
    _stretchStart = DateTime.now();
    _sub = LocationService.recordStream().listen(_onPosition, onError: (Object e) {
      if (mounted) showError(context, 'GPS xatosi: $e');
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    setState(() => _phase = _Phase.recording);
  }

  void _pause() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _elapsedBefore = _elapsed;
    _stretchStart = null;
    setState(() => _phase = _Phase.paused);
  }

  void _onPosition(Position p) {
    if (_phase != _Phase.recording || p.accuracy > _maxAccuracyM) return;
    final point = TrackPoint(
      lat: p.latitude,
      lng: p.longitude,
      time: p.timestamp,
      ele: p.altitude == 0 ? null : p.altitude,
    );
    setState(() {
      if (_points.isNotEmpty) _distanceM += _distance.distance(_points.last.point, point.point);
      _points.add(point);
    });
    _map.move(point.point, _map.camera.zoom < 15 ? 16 : _map.camera.zoom);
  }

  void _reset() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _points.clear();
      _distanceM = 0;
      _elapsedBefore = Duration.zero;
      _stretchStart = null;
    });
  }

  Future<void> _finish() async {
    _pause();
    if (_points.length < 2) {
      final discard = await _confirm("Yo'l juda qisqa", "GPS nuqtalar yetarli emas. Mashg'ulot o'chirilsinmi?");
      if (discard) _reset();
      return;
    }
    final result = await showModalBottomSheet<_SaveChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SaveSheet(type: _type),
    );
    if (result == null) return; // Back to paused, user can resume.
    if (result.discard) {
      if (await _confirm("O'chirish", "Bu mashg'ulot saqlanmaydi. O'chirilsinmi?")) _reset();
      return;
    }
    await _save(result);
  }

  Future<void> _save(_SaveChoice choice) async {
    setState(() => _saving = true);
    try {
      final activity = await context.read<Session>().api.createActivity(
            type: _type,
            title: choice.title,
            visibility: choice.visibility,
            points: List.of(_points),
          );
      _reset();
      if (!mounted) return;
      showInfo(context, 'Saqlandi!');
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ActivityScreen(activityId: activity.id)));
    } catch (e) {
      // Keep the recording so the user can try again.
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Yo'q")),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ha')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds = _elapsed.inSeconds;
    final speed = seconds > 0 ? _distanceM / seconds : 0.0;
    final line = _points.map((p) => p.point).toList();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: line.isNotEmpty ? line.last : const LatLng(41.3111, 69.2797),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(urlTemplate: AppConfig.tileUrl, userAgentPackageName: AppConfig.packageName),
                    if (line.length >= 2)
                      PolylineLayer(polylines: [Polyline(points: line, strokeWidth: 6, color: scheme.primary)]),
                    if (line.isNotEmpty)
                      MarkerLayer(markers: [
                        Marker(
                          point: line.first,
                          width: 16,
                          height: 16,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle),
                          ),
                        ),
                        Marker(
                          point: line.last,
                          width: 22,
                          height: 22,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ]),
                    const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
                  ],
                ),
                if (_phase == _Phase.idle)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final e in activityTypeNames.entries)
                            ChoiceChip(
                              label: Text(e.value),
                              avatar: Icon(activityIcon(e.key), size: 18),
                              selected: _type == e.key,
                              onSelected: (_) => setState(() => _type = e.key),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatTile(label: 'Vaqt', value: formatDuration(seconds), large: true),
                        StatTile(label: 'Masofa', value: formatDistance(_distanceM), large: true),
                        StatTile(
                          label: _type == 'ride' ? 'Tezlik' : 'Temp',
                          value: _type == 'ride' ? formatSpeed(speed) : formatPace(speed),
                          large: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _controls(scheme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(ColorScheme scheme) {
    if (_saving) return const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator());
    switch (_phase) {
      case _Phase.idle:
        return FilledButton.icon(
          icon: Icon(activityIcon(_type)),
          label: const Text('Boshlash'),
          onPressed: _start,
        );
      case _Phase.recording:
        return FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: scheme.tertiary),
          icon: const Icon(Icons.pause),
          label: const Text("To'xtatib turish"),
          onPressed: _pause,
        );
      case _Phase.paused:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Davom etish'),
                onPressed: _resume,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(icon: const Icon(Icons.flag), label: const Text('Tugatish'), onPressed: _finish),
            ),
          ],
        );
    }
  }
}

IconData activityIcon(String type) => switch (type) {
      'ride' => Icons.directions_bike,
      'walk' => Icons.directions_walk,
      'hike' => Icons.hiking,
      _ => Icons.directions_run,
    };

class _SaveChoice {
  final String? title;
  final String visibility;
  final bool discard;

  const _SaveChoice({this.title, this.visibility = 'friends', this.discard = false});
}

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.type});

  final String type;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  final _title = TextEditingController();
  String _visibility = 'friends';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Mashg'ulotni saqlash", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Nomi', hintText: activityTypeNames[widget.type]),
          ),
          const SizedBox(height: 16),
          Text('Kim ko\'radi', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'public', label: Text('Hamma'), icon: Icon(Icons.public)),
              ButtonSegment(value: 'friends', label: Text("Do'stlar"), icon: Icon(Icons.people)),
              ButtonSegment(value: 'private', label: Text('Faqat men'), icon: Icon(Icons.lock)),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, _SaveChoice(title: _title.text, visibility: _visibility)),
            child: const Text('Saqlash'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, const _SaveChoice(discard: true)),
            child: Text("O'chirish", style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
