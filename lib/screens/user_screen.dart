import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/live_state.dart';
import '../state/session.dart';
import '../widgets/activity_card.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

/// Someone's profile with their visible activities.
class UserScreen extends StatefulWidget {
  const UserScreen({super.key, required this.user});

  final User user;

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<Activity>? _activities;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<Session>().api.userActivities(widget.user.id);
      if (mounted) setState(() => _activities = list);
    } catch (e) {
      if (mounted) {
        setState(() => _activities = []);
        showError(context, e);
      }
    }
  }

  Future<void> _removeFriend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Do'stlardan o'chirilsinmi?"),
        content: Text("${widget.user.name} endi joylashuvingizni ko'rmaydi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("O'chirish")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final live = context.read<LiveState>();
    try {
      await context.read<Session>().api.removeFriend(widget.user.id);
      await live.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isFriend = context.select<LiveState, bool>((l) => l.friend(u.id) != null);
    final text = Theme.of(context).textTheme;
    final activities = _activities;

    return Scaffold(
      appBar: AppBar(
        title: Text('@${u.username}'),
        actions: [
          if (isFriend)
            PopupMenuButton<String>(
              onSelected: (_) => _removeFriend(),
              itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text("Do'stlardan o'chirish"))],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Avatar(user: u, radius: 44)),
            const SizedBox(height: 12),
            Text(u.name, textAlign: TextAlign.center, style: text.headlineSmall),
            if (u.bio.isNotEmpty) Text(u.bio, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (isFriend)
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Xabar yozish'),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(user: u))),
              ),
            const SizedBox(height: 16),
            Text("Mashg'ulotlar", style: text.titleMedium),
            const SizedBox(height: 8),
            if (activities == null)
              const Center(child: CircularProgressIndicator())
            else if (activities.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Ko'rinadigan mashg'ulotlar yo'q")))
            else
              for (final a in activities)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: ActivityCard(key: ValueKey(a.id), activity: a)),
          ],
        ),
      ),
    );
  }
}
