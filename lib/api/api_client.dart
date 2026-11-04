import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models.dart';

class ApiException implements Exception {
  final int status;
  final String code;
  final String message;

  const ApiException(this.status, this.code, this.message);

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Thin wrapper over the Nex Map REST API (see the backend's /docs).
class ApiClient {
  ApiClient({required this.baseUrl, this.token, http.Client? client}) : _http = client ?? http.Client();

  final String baseUrl;
  String? token;
  final http.Client _http;

  /// Called when the server rejects the token, so the app can sign out.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _send(String method, String path, {Map<String, Object?>? query, Object? body}) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 20)));
    } on TimeoutException {
      throw const ApiException(0, 'timeout', 'Server javob bermadi. Internetni tekshiring.');
    } on SocketException {
      throw const ApiException(0, 'offline', "Serverga ulanib bo'lmadi. Internet yoki server manzilini tekshiring.");
    } on http.ClientException {
      throw const ApiException(0, 'offline', "Serverga ulanib bo'lmadi. Internet yoki server manzilini tekshiring.");
    }

    final text = utf8.decode(response.bodyBytes);
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    final error = decoded is Map<String, dynamic> ? decoded['error'] as Map<String, dynamic>? : null;
    final exception = ApiException(
      response.statusCode,
      (error?['code'] as String?) ?? 'error',
      _friendlyMessage(response.statusCode, error),
    );
    if (exception.isUnauthorized && token != null) onUnauthorized?.call();
    throw exception;
  }

  String _friendlyMessage(int status, Map<String, dynamic>? error) {
    final details = error?['details'] as List?;
    if (details != null && details.isNotEmpty) {
      final first = details.first as Map<String, dynamic>;
      return '${first['field']}: ${first['message']}';
    }
    if (status == 429) return "Juda ko'p so'rov. Biroz kuting.";
    if (status >= 500) return 'Serverda xatolik. Keyinroq urinib ko\'ring.';
    return (error?['message'] as String?) ?? 'Xatolik ($status)';
  }

  Future<Map<String, dynamic>> _json(String method, String path, {Map<String, Object?>? query, Object? body}) async =>
      (await _send(method, path, query: query, body: body)) as Map<String, dynamic>;

  List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) =>
      (json[key] as List).cast<Map<String, dynamic>>();

  // Auth

  Future<(String, Me)> login(String login, String password) async {
    final j = await _json('POST', '/v1/auth/login', body: {'login': login, 'password': password});
    return (j['token'] as String, Me.fromJson(j['user'] as Map<String, dynamic>));
  }

  Future<(String, Me)> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final j = await _json('POST', '/v1/auth/register',
        body: {'name': name, 'username': username, 'email': email, 'password': password});
    return (j['token'] as String, Me.fromJson(j['user'] as Map<String, dynamic>));
  }

  // Me

  Future<Me> me() async => Me.fromJson(await _json('GET', '/v1/me'));

  Future<Me> updateMe(Map<String, Object?> changes) async => Me.fromJson(await _json('PATCH', '/v1/me', body: changes));

  Future<bool> shareLocation({
    required double lat,
    required double lng,
    double? accuracy,
    double? speed,
    double? heading,
    int? battery,
  }) async {
    final j = await _json('PUT', '/v1/me/location', body: {
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null && speed >= 0) 'speed': speed,
      if (heading != null && heading >= 0 && heading <= 360) 'heading': heading,
      if (battery != null) 'battery': battery,
    });
    return j['shared'] as bool;
  }

  Future<Stats> stats() async => Stats.fromJson(await _json('GET', '/v1/me/stats'));

  // Users and friends

  Future<List<User>> searchUsers(String q) async =>
      _list(await _json('GET', '/v1/users/search', query: {'q': q}), 'users').map(User.fromJson).toList();

  Future<List<Friend>> friends() async =>
      _list(await _json('GET', '/v1/friends'), 'friends').map(Friend.fromJson).toList();

  Future<(List<FriendRequest>, List<FriendRequest>)> friendRequests() async {
    final j = await _json('GET', '/v1/friends/requests');
    return (
      _list(j, 'incoming').map(FriendRequest.fromJson).toList(),
      _list(j, 'outgoing').map(FriendRequest.fromJson).toList(),
    );
  }

  Future<String> sendFriendRequest(String userId) async =>
      (await _json('POST', '/v1/friends/requests', body: {'userId': userId}))['status'] as String;

  Future<void> acceptFriendRequest(String requestId) => _send('POST', '/v1/friends/requests/$requestId/accept');

  Future<void> deleteFriendRequest(String requestId) => _send('DELETE', '/v1/friends/requests/$requestId');

  Future<void> removeFriend(String userId) => _send('DELETE', '/v1/friends/$userId');

  // Activities

  Future<Activity> createActivity({
    required String type,
    String? title,
    String visibility = 'friends',
    required List<TrackPoint> points,
  }) async =>
      Activity.fromJson(await _json('POST', '/v1/activities', body: {
        'type': type,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'visibility': visibility,
        'points': points.map((p) => p.toJson()).toList(),
      }));

  Future<List<Activity>> feed({DateTime? before}) async => _list(
        await _json('GET', '/v1/activities', query: {'before': before?.toUtc().toIso8601String()}),
        'activities',
      ).map(Activity.fromJson).toList();

  Future<List<Activity>> userActivities(String userId, {DateTime? before}) async => _list(
        await _json('GET', '/v1/users/$userId/activities', query: {'before': before?.toUtc().toIso8601String()}),
        'activities',
      ).map(Activity.fromJson).toList();

  Future<Activity> activity(String id) async => Activity.fromJson(await _json('GET', '/v1/activities/$id'));

  Future<void> deleteActivity(String id) => _send('DELETE', '/v1/activities/$id');

  Future<(int, bool)> setKudos(String activityId, bool give) async {
    final j = await _json(give ? 'POST' : 'DELETE', '/v1/activities/$activityId/kudos');
    return ((j['kudosCount'] as num).toInt(), j['hasKudos'] as bool);
  }

  // Map

  Future<List<GeocodeResult>> geocode(String q, {double? lat, double? lng}) async => _list(
        await _json('GET', '/v1/geocode/search', query: {'q': q, 'lat': lat, 'lng': lng, 'lang': 'uz'}),
        'results',
      ).map(GeocodeResult.fromJson).toList();

  Future<List<Place>> nearbyPlaces(double lat, double lng, {int radius = 3000}) async => _list(
        await _json('GET', '/v1/places/nearby', query: {'lat': lat, 'lng': lng, 'radius': radius}),
        'places',
      ).map(Place.fromJson).toList();

  Future<Place> createPlace({required String name, required String category, required double lat, required double lng}) async =>
      Place.fromJson(await _json('POST', '/v1/places', body: {'name': name, 'category': category, 'lat': lat, 'lng': lng}));

  Future<void> checkIn(String placeId) => _send('POST', '/v1/places/$placeId/checkins');

  // Messages

  Future<List<Conversation>> conversations() async =>
      _list(await _json('GET', '/v1/messages/conversations'), 'conversations').map(Conversation.fromJson).toList();

  Future<List<Message>> messages(String userId, {String? before}) async =>
      _list(await _json('GET', '/v1/messages/$userId', query: {'before': before}), 'messages')
          .map(Message.fromJson)
          .toList();

  Future<Message> sendMessage(String userId, String body) async =>
      Message.fromJson(await _json('POST', '/v1/messages/$userId', body: {'body': body}));

  // Developer API keys

  Future<List<ApiKeyInfo>> apiKeys() async =>
      _list(await _json('GET', '/v1/api-keys'), 'apiKeys').map(ApiKeyInfo.fromJson).toList();

  Future<ApiKeyInfo> createApiKey(String name, List<String> scopes) async =>
      ApiKeyInfo.fromJson(await _json('POST', '/v1/api-keys', body: {'name': name, 'scopes': scopes}));

  Future<void> revokeApiKey(String id) => _send('DELETE', '/v1/api-keys/$id');
}
