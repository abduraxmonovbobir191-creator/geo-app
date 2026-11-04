import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/live_state.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'user_screen.dart';

/// Friends, chats and friend requests.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incoming = context.select<LiveState, int>((l) => l.incoming.length);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Do'stlar"),
          actions: [
            IconButton(
              tooltip: "Do'st qo'shish",
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const UserSearchScreen())),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: "Do'stlar"),
              const Tab(text: 'Chatlar'),
              Tab(child: Badge(isLabelVisible: incoming > 0, label: Text('$incoming'), child: const Text("So'rovlar"))),
            ],
          ),
        ),
        body: const TabBarView(children: [_FriendList(), _Conversations(), _Requests()]),
      ),
    );
  }
}

class _FriendList extends StatelessWidget {
  const _FriendList();

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveState>();
    final friends = live.friends;
    return RefreshIndicator(
      onRefresh: live.refresh,
      child: friends.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.group_add_outlined, size: 64),
                const SizedBox(height: 12),
                Text(
                  live.loading ? 'Yuklanmoqda...' : "Hali do'stlar yo'q.\nYuqoridagi tugma orqali qidirib qo'shing.",
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, i) {
                final f = friends[i];
                final loc = f.location;
                return ListTile(
                  leading: Avatar(user: f.user, online: f.online),
                  title: Text(f.user.name),
                  subtitle: Text(
                    f.online
                        ? 'Onlayn${loc?.battery != null ? ' · ${loc!.battery}%' : ''}'
                        : (loc != null ? 'Joylashuv: ${formatAgo(loc.updatedAt)}' : '@${f.user.username}'),
                  ),
                  trailing: IconButton(
                    tooltip: 'Xabar',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => openChat(context, f.user),
                  ),
                  onTap: () => openUser(context, f.user),
                );
              },
            ),
    );
  }
}

void openChat(BuildContext context, User user) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(user: user)));

void openUser(BuildContext context, User user) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => UserScreen(user: user)));

class _Conversations extends StatefulWidget {
  const _Conversations();

  @override
  State<_Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<_Conversations> {
  List<Conversation>? _items;
  Object? _error;
  StreamSubscription<Message>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    // New messages move a conversation to the top.
    _sub = context.read<LiveState>().messages.listen((_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await context.read<Session>().api.conversations();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return Center(child: _error != null ? Text(_error.toString()) : const CircularProgressIndicator());
    }
    final myId = context.select<Session, String?>((s) => s.me?.id);
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(children: const [SizedBox(height: 120), Center(child: Text("Hali xabarlar yo'q"))])
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final c = items[i];
                final fromMe = c.lastMessage.senderId == myId;
                return ListTile(
                  leading: Avatar(user: c.user),
                  title: Text(c.user.name),
                  subtitle: Text('${fromMe ? 'Siz: ' : ''}${c.lastMessage.body}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: c.unreadCount > 0
                      ? Badge(label: Text('${c.unreadCount}'))
                      : Text(formatAgo(c.lastMessage.createdAt), style: Theme.of(context).textTheme.bodySmall),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(user: c.user)));
                    _load();
                  },
                );
              },
            ),
    );
  }
}

class _Requests extends StatelessWidget {
  const _Requests();

  Future<void> _act(BuildContext context, Future<void> Function() action) async {
    final live = context.read<LiveState>();
    try {
      await action();
      await live.refresh();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveState>();
    final api = context.read<Session>().api;
    if (live.incoming.isEmpty && live.outgoing.isEmpty) {
      return RefreshIndicator(
        onRefresh: live.refresh,
        child: ListView(children: const [SizedBox(height: 120), Center(child: Text("So'rovlar yo'q"))]),
      );
    }
    return RefreshIndicator(
      onRefresh: live.refresh,
      child: ListView(
        children: [
          if (live.incoming.isNotEmpty) const ListTile(dense: true, title: Text('Sizga kelgan')),
          for (final r in live.incoming)
            ListTile(
              leading: Avatar(user: r.user),
              title: Text(r.user.name),
              subtitle: Text('@${r.user.username}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Rad etish',
                    icon: const Icon(Icons.close),
                    onPressed: () => _act(context, () => api.deleteFriendRequest(r.id)),
                  ),
                  IconButton.filled(
                    tooltip: 'Qabul qilish',
                    icon: const Icon(Icons.check),
                    onPressed: () => _act(context, () => api.acceptFriendRequest(r.id)),
                  ),
                ],
              ),
            ),
          if (live.outgoing.isNotEmpty) const ListTile(dense: true, title: Text('Siz yuborgan')),
          for (final r in live.outgoing)
            ListTile(
              leading: Avatar(user: r.user),
              title: Text(r.user.name),
              subtitle: const Text('Javob kutilmoqda'),
              trailing: TextButton(
                onPressed: () => _act(context, () => api.deleteFriendRequest(r.id)),
                child: const Text('Bekor qilish'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Find people by username or name and send friend requests.
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _query = TextEditingController();
  List<User> _results = [];
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    try {
      final results = await context.read<Session>().api.searchUsers(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveState>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Ism yoki foydalanuvchi nomi',
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
          ),
        ),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final u = _results[i];
                final isFriend = live.friend(u.id) != null;
                final sent = live.outgoing.any((r) => r.user.id == u.id);
                return ListTile(
                  leading: Avatar(user: u),
                  title: Text(u.name),
                  subtitle: Text('@${u.username}'),
                  onTap: () => openUser(context, u),
                  trailing: isFriend
                      ? const Text("Do'st")
                      : sent
                          ? const Text('Yuborildi')
                          : FilledButton.tonal(
                              onPressed: () async {
                                try {
                                  final status = await context.read<Session>().api.sendFriendRequest(u.id);
                                  await live.refresh();
                                  if (context.mounted) {
                                    showInfo(context, status == 'accepted' ? "Endi do'stsiz!" : "So'rov yuborildi");
                                  }
                                } catch (e) {
                                  if (context.mounted) showError(context, e);
                                }
                              },
                              child: const Text("Qo'shish"),
                            ),
                );
              },
            ),
    );
  }
}
