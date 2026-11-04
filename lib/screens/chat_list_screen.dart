import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      {'name': 'Ali', 'last': 'Salom, qayerdasan?', 'time': '12:30'},
      {'name': 'Malika', 'last': 'Xaritada ko\'rishamiz', 'time': '11:15'},
      {'name': 'Jasur', 'last': 'Ok, kelaman', 'time': 'Kecha'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return GlassContainer(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6C63FF),
                child: Text(chat['name']![0]),
              ),
              title: Text(chat['name']!),
              subtitle: Text(chat['last']!, style: const TextStyle(color: Colors.white60)),
              trailing: Text(chat['time']!, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(name: chat['name']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
