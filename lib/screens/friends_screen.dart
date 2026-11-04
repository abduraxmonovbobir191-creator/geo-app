import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Do\'stlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Do\'st qo\'shish'),
              subtitle: const Text('Yangi do\'st so\'rovi'),
              trailing: const Icon(Icons.add),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Hozircha do\'stlar yo\'q', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
