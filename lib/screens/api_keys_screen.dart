import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/session.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// Lets developers create keys for the public Nex Map API.
class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  List<ApiKeyInfo>? _keys;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final keys = await context.read<Session>().api.apiKeys();
      if (mounted) setState(() => _keys = keys);
    } catch (e) {
      if (mounted) {
        setState(() => _keys = []);
        showError(context, e);
      }
    }
  }

  Future<void> _create() async {
    final name = TextEditingController();
    var write = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Yangi API kalit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nomi (masalan, Telegram bot)')),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: write,
                onChanged: (v) => setLocal(() => write = v ?? false),
                title: const Text("O'zgartirishga ham ruxsat"),
                subtitle: const Text("Yo'q bo'lsa faqat o'qiy oladi"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yaratish')),
          ],
        ),
      ),
    );
    final keyName = name.text.trim();
    name.dispose();
    if (ok != true || keyName.isEmpty || !mounted) return;
    try {
      final key = await context.read<Session>().api.createApiKey(keyName, write ? ['read', 'write'] : ['read']);
      if (!mounted) return;
      await _showNewKey(key.key!);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _showNewKey(String key) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Kalitingiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Uni hozir nusxalab saqlang: keyin qayta ko'rsatilmaydi."),
              const SizedBox(height: 12),
              SelectableText(key, style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: key));
                if (context.mounted) showInfo(context, 'Nusxalandi');
              },
              child: const Text('Nusxalash'),
            ),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Saqladim')),
          ],
        ),
      );

  Future<void> _revoke(ApiKeyInfo k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${k.name}" o\'chirilsinmi?'),
        content: const Text('Bu kalitni ishlatayotgan dasturlar ishlamay qoladi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("O'chirish")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Session>().api.revokeApiKey(k.id);
      _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    final server = context.select<Session, String>((s) => s.serverUrl);
    return Scaffold(
      appBar: AppBar(title: const Text('API kalitlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yangi kalit'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nex Map API', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    "Boshqa dasturlar (bot, sayt, soat) sizning nomingizdan Nex Map bilan ishlashi uchun kalit yarating "
                    "va har bir so'rovga X-API-Key sarlavhasi bilan qo'shing.",
                  ),
                  const SizedBox(height: 8),
                  SelectableText('Hujjat: $server/docs', style: const TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (keys == null)
            const Center(child: CircularProgressIndicator())
          else if (keys.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("Hali kalitlar yo'q")))
          else
            for (final k in keys)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: Text(k.name),
                  subtitle: Text(
                    '${k.prefix}… · ${k.scopes.join(', ')}\n'
                    '${k.lastUsedAt != null ? 'Oxirgi ishlatilgan: ${formatAgo(k.lastUsedAt!)}' : 'Hali ishlatilmagan'}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(tooltip: "O'chirish", icon: const Icon(Icons.delete_outline), onPressed: () => _revoke(k)),
                ),
              ),
        ],
      ),
    );
  }
}
