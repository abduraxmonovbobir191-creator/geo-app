import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool _connected = false;

  void connect({required String userId, required String name}) {
    if (_connected) return;

    socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      _connected = true;
      print('Connected to backend');
      socket.emit('join', {'userId': userId, 'name': name});
    });

    socket.onDisconnect((_) {
      _connected = false;
      print('Disconnected');
    });
  }

  void updateLocation(String userId, double lat, double lng) {
    if (!_connected) return;
    socket.emit('location:update', {'userId': userId, 'lat': lat, 'lng': lng});
  }

  void sendMessage(String from, String to, String text) {
    if (!_connected) return;
    socket.emit('chat:message', {'from': from, 'to': to, 'text': text});
  }

  void onLocationUpdate(Function(dynamic) callback) {
    socket.on('location:update', callback);
  }

  void onChatMessage(Function(dynamic) callback) {
    socket.on('chat:message', callback);
  }

  void dispose() {
    socket.dispose();
  }
}
