import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'state/session.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => Session()
        ..beforeSignOut = _closeSignedInScreens
        ..load(),
      child: const NexMapApp(),
    ),
  );
}

final _navigator = GlobalKey<NavigatorState>();
final _routes = _RouteTracker();

/// Screens and sheets opened while signed in read the live state, which goes away on
/// sign-out, so they are removed (without animation) before it does.
void _closeSignedInScreens() {
  final nav = _navigator.currentState;
  if (nav == null) return;
  for (final route in _routes.stack.skip(1).toList().reversed) {
    nav.removeRoute(route);
  }
}

class _RouteTracker extends NavigatorObserver {
  final stack = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) stack[i] = newRoute;
  }
}

class NexMapApp extends StatelessWidget {
  const NexMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final Widget home;
    if (!session.ready) {
      home = const _Splash();
    } else if (session.signedIn) {
      home = const HomeShell();
    } else if (session.needsRetry) {
      home = const _Offline();
    } else {
      home = const AuthScreen();
    }
    return MaterialApp(
      title: 'Nex Map',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      navigatorKey: _navigator,
      navigatorObservers: [_routes],
      // Keyed by user so signing in as someone else starts with fresh live state.
      builder: (context, child) =>
          session.signedIn ? SignedInScope(key: ValueKey(session.me!.id), child: child!) : child!,
      // Keyed so switching between signed-in and signed-out drops the old screens' routes.
      home: KeyedSubtree(key: ValueKey(session.signedIn), child: home),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: NexLogo(size: 72)));
}

class _Offline extends StatefulWidget {
  const _Offline();

  @override
  State<_Offline> createState() => _OfflineState();
}

class _OfflineState extends State<_Offline> {
  bool _busy = false;
  String? _error;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await context.read<Session>().refreshMe();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              Text(_error ?? "Serverga ulanib bo'lmadi", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: _busy ? null : _retry, child: const Text('Qayta urinish')),
              TextButton(onPressed: () => context.read<Session>().signOut(), child: const Text('Chiqish')),
            ],
          ),
        ),
      ),
    );
  }
}
