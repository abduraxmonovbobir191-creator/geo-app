import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

/// A server push event, e.g. ("friend:location", {...}).
class RealtimeEvent {
  final String name;
  final Map<String, dynamic> data;

  const RealtimeEvent(this.name, this.data);
}

/// Socket.IO connection to the backend. Screens listen to [events]; the location tracker
/// sends positions with [sendLocation].
class Realtime {
  static const _events = [
    'friends:online',
    'friend:online',
    'friend:offline',
    'friend:location',
    'friend:ghost',
    'friend:request',
    'friend:accepted',
    'friend:removed',
    'friend:checkin',
    'message:new',
    'message:read',
    'activity:kudos',
  ];

  io.Socket? _socket;
  final _controller = StreamController<RealtimeEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;
  Stream<bool> get connectionChanges => _connected.stream;
  bool get isConnected => _socket?.connected ?? false;

  Stream<Map<String, dynamic>> on(String name) =>
      events.where((e) => e.name == name).map((e) => e.data);

  void connect(String baseUrl, String token) {
    disconnect();
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    for (final name in _events) {
      socket.on(name, (data) {
        if (data is Map) _controller.add(RealtimeEvent(name, Map<String, dynamic>.from(data)));
      });
    }
    socket.onConnect((_) => _connected.add(true));
    socket.onDisconnect((_) => _connected.add(false));
    socket.connect();
    _socket = socket;
  }

  void sendLocation(Map<String, dynamic> location) {
    if (isConnected) _socket!.emit('location:update', location);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
    _connected.close();
  }
}
