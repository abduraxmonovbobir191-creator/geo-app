import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.palette), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 20),
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 12),
              const Text('bobirshox24', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GlassContainer(
                child: const ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('O\'zingiz haqingizda yozing'),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 16),
                  SizedBox(width: 4),
                  Text('Toshkent'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Hali do\'stlar yo\'q. Topamizmi?', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                },
                child: const Text('Obuna'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
