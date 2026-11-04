import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  const ChatDetailScreen({super.key, required this.name});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _socket = SocketService();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _socket.onChatMessage((data) {
      if (mounted) {
        setState(() => _messages.add(data));
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _socket.sendMessage('user1', 'friend1', text); // demo ids
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['from'] == 'user1';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Color(0xFF6C63FF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
