import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/location_service.dart';
import '../state/live_state.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/map_layers.dart';
import 'chat_screen.dart';

/// Main map: you, your friends live (Blink-style), places and address search (Yandex-style).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.onOpenFriends});

  final VoidCallback onOpenFriends;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _tashkent = LatLng(41.3111, 69.2797);

  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<GeocodeResult> _results = [];
  bool _searching = false;
  GeocodeResult? _picked;
  List<Place> _places = [];
  bool _showPlaces = false;
  bool _centeredOnMe = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(q.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    try {
      final center = _map.camera.center;
      final results = await context.read<Session>().api.geocode(q, lat: center.latitude, lng: center.longitude);
      if (mounted && _search.text.trim() == q) setState(() => _results = results);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickResult(GeocodeResult r) {
    _searchFocus.unfocus();
    setState(() {
      _picked = r;
      _results = [];
      _search.text = r.name.isNotEmpty ? r.name : r.displayName;
    });
    _map.move(r.point, 16);
  }

  void _clearSearch() {
    _search.clear();
    setState(() {
      _results = [];
      _picked = null;
    });
  }

  Future<void> _goToMe() async {
    final live = context.read<LiveState>();
    try {
      final p = live.myPosition ?? await LocationService.current();
      _map.move(LatLng(p.latitude, p.longitude), 16);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _togglePlaces() async {
    if (_showPlaces) {
      setState(() => _showPlaces = false);
      return;
    }
    final c = _map.camera.center;
    try {
      final places = await context.read<Session>().api.nearbyPlaces(c.latitude, c.longitude, radius: 5000);
      setState(() {
        _places = places;
        _showPlaces = true;
      });
      if (places.isEmpty && mounted) {
        showInfo(context, "Yaqin atrofda joy yo'q. Xaritani bosib turib yangi joy qo'shing.");
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _toggleGhost() async {
    final session = context.read<Session>();
    final on = !(session.me?.ghostMode ?? false);
    try {
      await session.setGhostMode(on);
      if (mounted) {
        showInfo(
          context,
          on
              ? "Ghost rejim yoqildi: do'stlar sizni oxirgi joyingizda ko'radi"
              : "Ghost rejim o'chirildi: joylashuvingiz yana yangilanadi",
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _addPlace(LatLng point) async {
    final created = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPlaceSheet(point: point),
    );
    if (created != null && mounted) {
      setState(() {
        _places = [..._places, created];
        _showPlaces = true;
      });
    }
  }

  void _showFriend(Friend f) {
    showModalBottomSheet<void>(context: context, builder: (_) => _FriendSheet(friendId: f.user.id, onShow: (center, zoom) => _map.move(center, zoom)),
    );
  }

  void _showPlace(Place p) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${placeCategoryNames[p.category] ?? p.category} · ${p.checkinCount} check-in'),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.where_to_vote),
                label: const Text('Shu yerdaman (check-in)'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(sheetContext);
                  try {
                    await context.read<Session>().api.checkIn(p.id);
                    messenger.showSnackBar(const SnackBar(content: Text("Check-in qilindi, do'stlaringiz ko'radi")));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveState>();
    final ghost = context.select<Session, bool>((s) => s.me?.ghostMode ?? false);
    final me = live.myPosition;
    final scheme = Theme.of(context).colorScheme;

    // Center on our position the first time we learn it.
    if (me != null && !_centeredOnMe) {
      _centeredOnMe = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _map.move(LatLng(me.latitude, me.longitude), 15));
    }

    final friendsWithLocation = live.friends.where((f) => f.location != null).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _tashkent,
              initialZoom: 12,
              onTap: (_, __) => _searchFocus.unfocus(),
              onLongPress: (_, point) => _addPlace(point),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              baseTileLayer(context),
              if (_showPlaces)
                MarkerLayer(
                  markers: [
                    for (final p in _places)
                      Marker(
                        point: p.point,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showPlace(p),
                          child: CircleAvatar(
                            backgroundColor: scheme.tertiaryContainer,
                            child: Icon(placeIcon(p.category), size: 18, color: scheme.onTertiaryContainer),
                          ),
                        ),
                      ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_picked != null)
                    Marker(
                      point: _picked!.point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_on, size: 44, color: scheme.error),
                    ),
                  for (final f in friendsWithLocation)
                    Marker(
                      point: f.location!.point,
                      width: 64,
                      height: 72,
                      child: GestureDetector(onTap: () => _showFriend(f), child: _FriendMarker(friend: f)),
                    ),
                  if (me != null)
                    Marker(
                      point: LatLng(me.latitude, me.longitude),
                      width: 26,
                      height: 26,
                      child: _MeMarker(ghost: ghost),
                    ),
                ],
              ),
              mapAttribution,
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.surface,
                    child: TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (q) => q.trim().isEmpty ? null : _runSearch(q.trim()),
                      decoration: InputDecoration(
                        hintText: 'Manzil yoki joy qidirish',
                        filled: true,
                        fillColor: scheme.surface,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : (_search.text.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSearch)
                                : null),
                      ),
                    ),
                  ),
                  if (_results.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 6),
                      elevation: 3,
                      color: scheme.surface,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            return ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(r.name.isNotEmpty ? r.name : r.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(r.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () => _pickResult(r),
                            );
                          },
                        ),
                      ),
                    ),
                  if (ghost)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Chip(
                        avatar: const Icon(Icons.visibility_off, size: 18),
                        label: const Text('Ghost rejim yoqilgan'),
                        backgroundColor: scheme.secondaryContainer,
                      ),
                    ),
                  if (live.locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.location_disabled, color: scheme.onErrorContainer),
                          title: Text(live.locationError!, style: TextStyle(color: scheme.onErrorContainer)),
                          trailing: TextButton(onPressed: live.startSharing, child: const Text('Qayta')),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.storefront_outlined,
                  tooltip: 'Yaqin joylar',
                  active: _showPlaces,
                  onPressed: _togglePlaces,
                ),
                const SizedBox(height: 10),
                _MapButton(
                  icon: ghost ? Icons.visibility_off : Icons.visibility_outlined,
                  tooltip: 'Ghost rejim',
                  active: ghost,
                  onPressed: _toggleGhost,
                ),
                const SizedBox(height: 10),
                _MapButton(
                  icon: Icons.people_outline,
                  tooltip: "Do'stlar",
                  onPressed: () => _showFriendsList(friendsWithLocation),
                ),
                const SizedBox(height: 10),
                _MapButton(icon: Icons.my_location, tooltip: 'Mening joyim', onPressed: _goToMe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFriendsList(List<Friend> friends) {
    if (friends.isEmpty) {
      showInfo(context, "Xaritada hali do'stlar yo'q. Do'st qo'shing!");
      widget.onOpenFriends();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in friends)
              ListTile(
                leading: Avatar(user: f.user, online: f.online),
                title: Text(f.user.name),
                subtitle: Text(formatAgo(f.location!.updatedAt)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _map.move(f.location!.point, 16);
                },
              ),
          ],
        ),
      ),
    );
  }
}

const placeCategoryNames = {
  'cafe': 'Kafe',
  'restaurant': 'Restoran',
  'park': 'Park',
  'gym': 'Sport zal',
  'sport': 'Sport maydoni',
  'shop': "Do'kon",
  'school': "O'qish joyi",
  'work': 'Ish',
  'home': 'Uy',
  'other': 'Boshqa',
};

IconData placeIcon(String category) => switch (category) {
      'cafe' => Icons.local_cafe,
      'restaurant' => Icons.restaurant,
      'park' => Icons.park,
      'gym' => Icons.fitness_center,
      'sport' => Icons.sports_soccer,
      'shop' => Icons.shopping_bag,
      'school' => Icons.school,
      'work' => Icons.work,
      'home' => Icons.home,
      _ => Icons.place,
    };

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed, this.active = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: active ? scheme.primary : scheme.surface,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: active ? scheme.onPrimary : scheme.onSurface),
        onPressed: onPressed,
      ),
    );
  }
}

class _MeMarker extends StatelessWidget {
  const _MeMarker({required this.ghost});

  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final color = ghost ? Colors.grey : Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 4)],
      ),
    );
  }
}

class _FriendMarker extends StatelessWidget {
  const _FriendMarker({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final loc = friend.location!;
    final stale = DateTime.now().difference(loc.updatedAt) > const Duration(minutes: 15);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: friend.online ? const Color(0xFF2ECC71) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Opacity(opacity: stale ? 0.6 : 1, child: Avatar(user: friend.user, radius: 22)),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
          child: Text(
            loc.battery != null ? '${loc.battery}%' : friend.user.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _FriendSheet extends StatelessWidget {
  const _FriendSheet({required this.friendId, required this.onShow});

  final String friendId;
  final void Function(LatLng center, double zoom) onShow;

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveState>();
    final f = live.friend(friendId);
    if (f == null) return const SizedBox.shrink();
    final loc = f.location;
    final me = live.myPosition;
    final distance = (loc != null && me != null)
        ? const Distance().distance(LatLng(me.latitude, me.longitude), loc.point)
        : null;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(user: f.user, radius: 28, online: f.online),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.user.name, style: text.titleLarge),
                      Text(
                        f.online ? 'Onlayn' : (loc != null ? 'Oxirgi marta ${formatAgo(loc.updatedAt)}' : 'Oflayn'),
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                if (loc?.battery != null) StatTile(label: 'Batareya', value: '${loc!.battery}%'),
                if (loc?.speed != null) StatTile(label: 'Tezlik', value: formatSpeed(loc!.speed!)),
                if (distance != null) StatTile(label: 'Sizdan', value: formatDistance(distance)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Xabar'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(user: f.user)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (loc != null)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text("Ko'rsatish"),
                      onPressed: () {
                        Navigator.pop(context);
                        onShow(loc.point, 17);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  const _AddPlaceSheet({required this.point});

  final LatLng point;

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _name = TextEditingController();
  String _category = 'other';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final place = await context.read<Session>().api.createPlace(
            name: _name.text.trim(),
            category: _category,
            lat: widget.point.latitude,
            lng: widget.point.longitude,
          );
      if (mounted) Navigator.pop(context, place);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Yangi joy qo'shish", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nomi'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in placeCategoryNames.entries)
                ChoiceChip(
                  avatar: Icon(placeIcon(e.key), size: 18),
                  label: Text(e.value),
                  selected: _category == e.key,
                  onSelected: (_) => setState(() => _category = e.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Saqlash')),
        ],
      ),
    );
  }
}
