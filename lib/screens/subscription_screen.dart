import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Obuna')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Ishingizni yengillashtiring',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Do\'stlar joylashuvi, cheksiz chat va xarita funksiyalari',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Free plan
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bepul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('• Asosiy xarita'),
                    const Text('• 5 ta do\'st'),
                    const Text('• Cheklangan chat'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Joriy reja'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Premium plan
            GlassContainer(
              opacity: 0.12,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Real-time do\'stlar joylashuvi'),
                    const Text('• Cheksiz do\'stlar'),
                    const Text('• Cheksiz chat'),
                    const Text('• 3D xarita (tez orada)'),
                    const Text('• Telegram bot'),
                    const SizedBox(height: 12),
                    const Text('25 000 so\'m / oy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Payment integration (Click / Payme / Stripe)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('To\'lov tizimi keyinroq ulanadi')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Obuna bo\'lish'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
