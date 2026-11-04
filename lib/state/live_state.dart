import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../services/location_service.dart';
import '../services/realtime.dart';

/// Live data while signed in: friends with their positions and online status, pending
/// friend requests, and sharing our own position (Blink-style).
class LiveState extends ChangeNotifier {
  LiveState(this.api, this.realtime) {
    _subs.add(realtime.events.listen(_onEvent));
    _subs.add(realtime.connectionChanges.listen((_) => notifyListeners()));
  }

  final ApiClient api;
  final Realtime realtime;
  final _subs = <StreamSubscription<dynamic>>[];
  final _battery = Battery();
  StreamSubscription<Position>? _positionSub;

  final Map<String, Friend> _friends = {};
  final Set<String> _online = {};
  List<FriendRequest> incoming = [];
  List<FriendRequest> outgoing = [];
  Position? myPosition;
  String? locationError;
  bool loading = false;

  /// Emits whenever a chat message arrives, for the chat screens.
  final _messages = StreamController<Message>.broadcast();
  Stream<Message> get messages => _messages.stream;

  List<Friend> get friends {
    final list = _friends.values.map((f) => f.copyWith(online: _online.contains(f.user.id))).toList();
    list.sort((a, b) => a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase()));
    return list;
  }

  Friend? friend(String id) => _friends[id]?.copyWith(online: _online.contains(id));

  bool get isSharing => _positionSub != null;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final (list, requests) = await (api.friends(), api.friendRequests()).wait;
      final (inc, out) = requests;
      _friends
        ..clear()
        ..addEntries(list.map((f) => MapEntry(f.user.id, f)));
      incoming = inc;
      outgoing = out;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Starts following our position and sending it to friends.
  Future<void> startSharing() async {
    if (_positionSub != null) return;
    try {
      await LocationService.ensurePermission();
      locationError = null;
    } on LocationUnavailable catch (e) {
      locationError = e.message;
      notifyListeners();
      return;
    }
    _positionSub = LocationService.shareStream().listen(
      _share,
      onError: (Object e) {
        locationError = 'Joylashuvni aniqlab bo\'lmadi';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void stopSharing() {
    _positionSub?.cancel();
    _positionSub = null;
    notifyListeners();
  }

  Future<void> _share(Position p) async {
    myPosition = p;
    notifyListeners();
    int? battery;
    try {
      battery = await _battery.batteryLevel;
    } catch (_) {
      battery = null;
    }
    final payload = <String, dynamic>{
      'lat': p.latitude,
      'lng': p.longitude,
      'accuracy': p.accuracy,
      if (p.speed >= 0) 'speed': p.speed,
      if (p.heading >= 0 && p.heading <= 360) 'heading': p.heading,
      if (battery != null && battery >= 0 && battery <= 100) 'battery': battery,
    };
    if (realtime.isConnected) {
      realtime.sendLocation(payload);
    } else {
      try {
        await api.shareLocation(
          lat: p.latitude,
          lng: p.longitude,
          accuracy: p.accuracy,
          speed: p.speed,
          heading: p.heading,
          battery: battery,
        );
      } on ApiException {
        // Offline: the next position will try again.
      }
    }
  }

  void _onEvent(RealtimeEvent e) {
    final d = e.data;
    switch (e.name) {
      case 'friends:online':
        _online
          ..clear()
          ..addAll((d['userIds'] as List).cast<String>());
      case 'friend:online':
        _online.add(d['userId'] as String);
      case 'friend:offline':
        _online.remove(d['userId'] as String);
      case 'friend:location':
        final loc = FriendLocation.fromJson(d);
        final f = _friends[loc.userId];
        if (f != null) _friends[loc.userId] = f.copyWith(location: loc);
      case 'friend:request' || 'friend:accepted' || 'friend:removed':
        refresh();
        return;
      case 'message:new':
        _messages.add(Message.fromJson(d));
        return;
      default:
        return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _positionSub?.cancel();
    _messages.close();
    super.dispose();
  }
}
