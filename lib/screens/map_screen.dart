import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (later: MapLibre + own tiles)
          Container(
            color: const Color(0xFF0F0F18),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    '3D Xarita (o\'z server) keyinroq',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Qidiruv...',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Friends markers example (real-time placeholder)
          Positioned(
            top: 180,
            left: 40,
            child: _FriendMarker(name: 'Ali'),
          ),
          Positioned(
            top: 280,
            right: 60,
            child: _FriendMarker(name: 'Malika'),
          ),
          Positioned(
            bottom: 180,
            left: 100,
            child: _FriendMarker(name: 'Jasur', isOnline: true),
          ),

          // My location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {},
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
  final bool isOnline;

  const _FriendMarker({required this.name, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6C63FF),
              child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ],
    );
  }
}
