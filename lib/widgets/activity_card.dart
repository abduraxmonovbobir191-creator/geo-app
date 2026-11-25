import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../screens/activity_screen.dart';
import '../screens/record_screen.dart' show activityIcon;
import '../state/session.dart';
import '../utils/format.dart';
import 'common.dart';

/// Feed item: who, what, key numbers, route preview and kudos.
class ActivityCard extends StatefulWidget {
  const ActivityCard({super.key, required this.activity, this.onChanged});

  final Activity activity;
  final ValueChanged<Activity?>? onChanged;

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late Activity _a = widget.activity;

  @override
  void didUpdateWidget(ActivityCard old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) _a = widget.activity;
  }

  Future<void> _toggleKudos() async {
    final give = !_a.hasKudos;
    final before = _a;
    setState(() => _a = _a.withKudos(_a.kudosCount + (give ? 1 : -1), give));
    try {
      final (count, has) = await context.read<Session>().api.setKudos(_a.id, give);
      if (mounted) setState(() => _a = _a.withKudos(count, has));
      widget.onChanged?.call(_a);
    } catch (e) {
      if (mounted) {
        setState(() => _a = before);
        showError(context, e);
      }
    }
  }

  Future<void> _open() async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ActivityScreen(activityId: _a.id)),
    );
    if (deleted == true) widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.select<Session, String?>((s) => s.me?.id);
    final mine = _a.user.id == myId;
    final text = Theme.of(context).textTheme;
    final isRide = _a.type == 'ride';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(user: _a.user, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_a.user.name, style: text.titleSmall),
                        Text(
                          '${activityTypeNames[_a.type] ?? _a.type} · ${formatAgo(_a.startedAt)}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(activityIcon(_a.type), color: Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 10),
              Text(_a.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Masofa', value: formatDistance(_a.distanceM))),
                  Expanded(
                    child: StatTile(
                      label: isRide ? 'Tezlik' : 'Temp',
                      value: isRide ? formatSpeed(_a.avgSpeedMps) : formatPace(_a.avgSpeedMps),
                    ),
                  ),
                  Expanded(child: StatTile(label: 'Vaqt', value: formatDuration(_a.movingTimeS))),
                ],
              ),
              const SizedBox(height: 12),
              RoutePreview(points: _a.preview),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kudos',
                    onPressed: mine ? null : _toggleKudos,
                    icon: Icon(
                      _a.hasKudos ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                      color: _a.hasKudos ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  Text(_a.kudosCount == 0 ? (mine ? '' : 'Kudos bering') : '${_a.kudosCount} kudos'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
