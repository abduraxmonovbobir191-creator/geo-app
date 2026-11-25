import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'api_keys_screen.dart';
import 'user_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await context.read<Session>().api.stats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      // Stats are optional on this screen; the rest still works offline.
    }
  }

  Future<void> _edit(Me me) async {
    final name = TextEditingController(text: me.name);
    final bio = TextEditingController(text: me.bio);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profilni tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Ism')),
            const SizedBox(height: 12),
            TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: "O'zingiz haqingizda")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Saqlash')),
        ],
      ),
    );
    if (save == true && mounted) {
      try {
        await context.read<Session>().updateProfile(name: name.text.trim(), bio: bio.text.trim());
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    name.dispose();
    bio.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final me = session.me!;
    final text = Theme.of(context).textTheme;
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [IconButton(tooltip: 'Tahrirlash', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(me))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Avatar(user: me, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me.name, style: text.titleLarge),
                      Text('@${me.username}', style: text.bodyMedium),
                      if (me.bio.isNotEmpty) Text(me.bio, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statistika', style: text.titleMedium),
                    const SizedBox(height: 12),
                    if (stats == null)
                      const LinearProgressIndicator()
                    else ...[
                      _totalsRow('Shu hafta', stats.week),
                      const Divider(height: 24),
                      _totalsRow('Oxirgi 4 hafta', stats.month),
                      const Divider(height: 24),
                      _totalsRow('Hammasi', stats.all),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Ghost rejim'),
                    subtitle: const Text("Do'stlar sizni oxirgi joyingizda ko'radi"),
                    value: me.ghostMode,
                    onChanged: (on) async {
                      try {
                        await session.setGhostMode(on);
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_run),
                    title: const Text("Mening mashg'ulotlarim"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => UserScreen(user: me))),
                  ),
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Dasturchilar uchun API'),
                    subtitle: const Text('API kalitlar yaratish'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ApiKeysScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Server'),
                    subtitle: Text(session.serverUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Chiqish'),
              onPressed: session.signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, Totals t) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(label)),
        Expanded(flex: 2, child: StatTile(label: 'Soni', value: '${t.count}')),
        Expanded(flex: 3, child: StatTile(label: 'Masofa', value: formatDistance(t.distanceM))),
        Expanded(flex: 3, child: StatTile(label: 'Vaqt', value: formatDuration(t.movingTimeS))),
      ],
    );
  }
}
