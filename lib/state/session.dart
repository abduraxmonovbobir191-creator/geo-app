import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../models.dart';

/// Who is signed in, and the API client configured for them. Persists the token and the
/// server address so the app opens signed in.
class Session extends ChangeNotifier {
  static const _tokenKey = 'token';
  static const _serverKey = 'server_url';

  late SharedPreferences _prefs;
  late ApiClient api;
  Me? me;
  bool ready = false;

  bool get signedIn => api.token != null && me != null;

  /// Has a saved token but could not load the profile (e.g. started offline).
  bool get needsRetry => api.token != null && me == null;
  String get serverUrl => api.baseUrl;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _makeClient(_prefs.getString(_serverKey) ?? AppConfig.defaultApiUrl, _prefs.getString(_tokenKey));
    if (api.token != null) {
      try {
        me = await api.me();
      } on ApiException catch (e) {
        // Offline: keep the token and try again later. Rejected token: sign out.
        if (e.isUnauthorized) await _clearToken();
      }
    }
    ready = true;
    notifyListeners();
  }

  void _makeClient(String baseUrl, String? token) {
    api = ApiClient(baseUrl: baseUrl, token: token)..onUnauthorized = () => signOut();
  }

  Future<void> setServerUrl(String url) async {
    final clean = url.trim();
    await _prefs.setString(_serverKey, clean);
    _makeClient(clean, api.token);
    notifyListeners();
  }

  Future<void> login(String login, String password) async {
    final (token, user) = await api.login(login, password);
    await _signIn(token, user);
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final (token, user) = await api.register(name: name, username: username, email: email, password: password);
    await _signIn(token, user);
  }

  Future<void> _signIn(String token, Me user) async {
    api.token = token;
    me = user;
    await _prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  /// Retries loading the profile when the app started offline.
  Future<void> refreshMe() async {
    me = await api.me();
    notifyListeners();
  }

  Future<void> setGhostMode(bool on) async {
    me = await api.updateMe({'ghostMode': on});
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? bio}) async {
    me = await api.updateMe({if (name != null) 'name': name, if (bio != null) 'bio': bio});
    notifyListeners();
  }

  /// Runs right before the signed-out state is published (the app closes open screens).
  void Function()? beforeSignOut;

  Future<void> signOut() async {
    beforeSignOut?.call();
    await _clearToken();
    me = null;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    api.token = null;
    await _prefs.remove(_tokenKey);
  }
}
