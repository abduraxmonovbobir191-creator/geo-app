import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassContainer(
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foydalanuvchi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Obuna: Free', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.card_membership),
                title: const Text('Obuna'),
                subtitle: const Text('Premium ga o\'ting'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Sozlamalar'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
