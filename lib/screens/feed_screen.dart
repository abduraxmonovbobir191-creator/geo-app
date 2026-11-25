import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/session.dart';
import '../widgets/activity_card.dart';

/// Activities from you and your friends, newest first, loaded page by page.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _items = <Activity>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _done = false;
    await _fetch(reset: true);
  }

  Future<void> _loadMore() async {
    if (_loading || _done || _items.isEmpty) return;
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<Session>().api.feed(before: reset ? null : _items.last.startedAt);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page);
        _done = page.length < 20;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lenta')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _items.isEmpty && !_loading
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.directions_run, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    _error?.toString() ?? "Hali mashg'ulotlar yo'q.\n\"Yozish\" bo'limida birinchisini boshlang!",
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) TextButton(onPressed: _refresh, child: const Text('Qayta urinish')),
                ],
              )
            : ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: _items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == _items.length) {
                    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    if (_error != null && _items.isNotEmpty) {
                      return TextButton(onPressed: _loadMore, child: const Text('Yana yuklash'));
                    }
                    return const SizedBox.shrink();
                  }
                  final a = _items[i];
                  return ActivityCard(
                    key: ValueKey(a.id),
                    activity: a,
                    onChanged: (updated) => setState(() {
                      final index = _items.indexWhere((x) => x.id == a.id);
                      if (index < 0) return;
                      if (updated == null) {
                        _items.removeAt(index);
                      } else {
                        _items[index] = updated;
                      }
                    }),
                  );
                },
              ),
      ),
    );
  }
}
