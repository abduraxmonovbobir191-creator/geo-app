import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/realtime.dart';
import '../state/live_state.dart';
import '../state/session.dart';
import 'feed_screen.dart';
import 'friends_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'record_screen.dart';

/// Owns the live connection while signed in. It is placed above the Navigator
/// (MaterialApp.builder), so bottom sheets and pushed screens can read it too.
class SignedInScope extends StatefulWidget {
  const SignedInScope({super.key, required this.child});

  final Widget child;

  @override
  State<SignedInScope> createState() => _SignedInScopeState();
}

class _SignedInScopeState extends State<SignedInScope> with WidgetsBindingObserver {
  late final Realtime _realtime;
  late final LiveState _live;

  @override
  void initState() {
    super.initState();
    final session = context.read<Session>();
    _realtime = Realtime()..connect(session.api.baseUrl, session.api.token!);
    _live = LiveState(session.api, _realtime);
    _live.refresh().catchError((_) {});
    _live.startSharing();
    WidgetsBinding.instance.addObserver(this);
  }

  // Stop sharing location in the background (battery and privacy); resume when reopened.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _live.stopSharing();
    } else if (state == AppLifecycleState.resumed) {
      _live.startSharing();
      _live.refresh().catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _live.dispose();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _realtime),
        ChangeNotifierProvider.value(value: _live),
      ],
      child: widget.child,
    );
  }
}

/// Signed-in app: bottom navigation between the main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final incoming = context.select<LiveState, int>((l) => l.incoming.length);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          MapScreen(onOpenFriends: () => setState(() => _tab = 3)),
          const FeedScreen(),
          const RecordScreen(),
          const FriendsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Xarita'),
          const NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Lenta',
          ),
          const NavigationDestination(
            icon: Icon(Icons.radio_button_checked_outlined),
            selectedIcon: Icon(Icons.radio_button_checked),
            label: 'Yozish',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: incoming > 0,
              label: Text('$incoming'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: const Icon(Icons.people),
            label: "Do'stlar",
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
