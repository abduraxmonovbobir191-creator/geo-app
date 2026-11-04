import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chatlar', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_emotions),
                    SizedBox(width: 12),
                    Expanded(child: Text('Menga yozing va xaritada izlarni qidiring')),
                    Icon(Icons.close, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.star)),
                title: const Text('Geo News'),
                subtitle: const Text('Salom, hurmatli... \u00b7 25 sent'),
                trailing: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
