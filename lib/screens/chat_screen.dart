import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/live_state.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// One-to-one chat with a friend; new messages arrive live.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});

  final User user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  // Newest first, matching the reversed list view.
  final _messages = <Message>[];
  StreamSubscription<Message>? _sub;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = context.read<LiveState>().messages.listen((m) {
      final partner = widget.user.id;
      if ((m.senderId == partner || m.recipientId == partner) && !_messages.any((x) => x.id == m.id)) {
        setState(() => _messages.insert(0, m));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final page = await context.read<Session>().api.messages(widget.user.id);
      if (mounted) setState(() => _messages..clear()..addAll(page));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await context.read<Session>().api.sendMessage(widget.user.id, body);
      _input.clear();
      if (mounted && !_messages.any((x) => x.id == m.id)) setState(() => _messages.insert(0, m));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.select<Session, String?>((s) => s.me?.id);
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(user: widget.user, radius: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.user.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Birinchi xabarni yozing'))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderId == myId;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: mine ? scheme.primary : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(m.body, style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface)),
                                  const SizedBox(height: 2),
                                  Text(
                                    time.format(m.createdAt.toLocal()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: (mine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Xabar'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
