import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder (3D style)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.public, size: 120, color: Colors.white10),
            ),
          ),

          // Address overlay
          Positioned(
            top: 60,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DEXKONOBOD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('ulitsa, 32', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 18),
                    const SizedBox(width: 4),
                    const Text('+12 \u00b0C', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('3591 qadam \u00b7 1 joy'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right buttons
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                _circleBtn(Icons.my_location),
                const SizedBox(height: 12),
                _circleBtn(Icons.star),
                const SizedBox(height: 12),
                _circleBtn(Icons.sports_esports),
              ],
            ),
          ),

          // Bottom left button
          Positioned(
            left: 20,
            bottom: 120,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.public, size: 20),
                    SizedBox(width: 8),
                    Text('Mening dunyoim'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
