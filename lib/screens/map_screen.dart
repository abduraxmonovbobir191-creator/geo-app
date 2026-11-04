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
  final List<Map<String, dynamic>> _friends = [
    {'name': 'Ali', 'online': true, 'distance': '120 m'},
    {'name': 'Malika', 'online': true, 'distance': '450 m'},
    {'name': 'Jasur', 'online': false, 'distance': '1.2 km'},
  ];

  @override
  void initState() {
    super.initState();
    _socket.connect(userId: 'user1', name: 'Men');
  }

  void _showFriendsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Do\'stlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._friends.map((f) => ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFF6C63FF), child: Text(f['name'][0])),
                  if (f['online']) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)))),
                ],
              ),
              title: Text(f['name']),
              subtitle: Text(f['distance'], style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map area
          Container(
            color: const Color(0xFF0F0F18),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 100, color: Colors.white12),
                  SizedBox(height: 12),
                  Text('O\'z serveringizdagi 3D xarita', style: TextStyle(color: Colors.white38, fontSize: 16)),
                ],
              ),
            ),
          ),

          // Top search + filter
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Joy yoki do\'st qidirish...', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white70),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // Right side buttons
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: IconButton(icon: const Icon(Icons.layers_outlined), onPressed: () {}),
                ),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: IconButton(icon: const Icon(Icons.my_location), onPressed: () {}),
                ),
              ],
            ),
          ),

          // Bottom friends bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: GlassContainer(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.people)),
                title: const Text('Do\'stlar'),
                subtitle: Text('${_friends.where((f) => f['online']).length} online'),
                trailing: const Icon(Icons.keyboard_arrow_up),
                onTap: _showFriendsSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
