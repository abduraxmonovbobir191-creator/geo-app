import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/socket_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _socket = SocketService();
  final List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    // Demo user (later from Nex ID)
    _socket.connect(userId: 'user1', name: 'Men');

    _socket.onLocationUpdate((data) {
      setState(() {
        final existing = _friends.indexWhere((f) => f['userId'] == data['userId']);
        if (existing >= 0) {
          _friends[existing] = data;
        } else {
          _friends.add(data);
        }
      });
    });

    // Demo location update
    Future.delayed(const Duration(seconds: 2), () {
      _socket.updateLocation('user1', 41.2995, 69.2401); // Tashkent
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFF0F0F18),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Real-time xarita (Socket.io ulangan)', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          // Search
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GlassContainer(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Qidiruv...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ),
          // Friends markers from real-time
          ..._friends.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Positioned(
              top: 150.0 + (i * 80),
              left: 30.0 + (i * 40),
              child: _FriendMarker(name: f['name'] ?? 'Do\'st'),
            );
          }),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                _socket.updateLocation('user1', 41.3, 69.25);
              },
              backgroundColor: const Color(0xFF6C63FF),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendMarker extends StatelessWidget {
  final String name;
  const _FriendMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF6C63FF),
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ],
    );
  }
}
