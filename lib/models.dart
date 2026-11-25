import 'package:latlong2/latlong.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => (v as num?)?.toDouble();
DateTime _t(Object? v) => DateTime.parse(v as String);
DateTime? _tn(Object? v) => v == null ? null : DateTime.parse(v as String);

class User {
  final String id;
  final String username;
  final String name;
  final String bio;
  final String? avatarUrl;

  const User({required this.id, required this.username, required this.name, this.bio = '', this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        username: j['username'] as String,
        name: j['name'] as String,
        bio: (j['bio'] as String?) ?? '',
        avatarUrl: j['avatarUrl'] as String?,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class Me extends User {
  final String email;
  final bool ghostMode;

  const Me({
    required super.id,
    required super.username,
    required super.name,
    super.bio,
    super.avatarUrl,
    required this.email,
    required this.ghostMode,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: j['id'] as String,
        username: j['username'] as String,
        name: j['name'] as String,
        bio: (j['bio'] as String?) ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        email: j['email'] as String,
        ghostMode: j['ghostMode'] as bool? ?? false,
      );
}

class FriendLocation {
  final String userId;
  final double lat;
  final double lng;
  final double? speed;
  final int? battery;
  final DateTime updatedAt;

  const FriendLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    this.speed,
    this.battery,
    required this.updatedAt,
  });

  LatLng get point => LatLng(lat, lng);

  factory FriendLocation.fromJson(Map<String, dynamic> j) => FriendLocation(
        userId: j['userId'] as String,
        lat: _d(j['lat']),
        lng: _d(j['lng']),
        speed: _dn(j['speed']),
        battery: (j['battery'] as num?)?.toInt(),
        updatedAt: _t(j['updatedAt']),
      );
}

class Friend {
  final User user;
  final FriendLocation? location;
  final bool online;

  const Friend({required this.user, this.location, this.online = false});

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        user: User.fromJson(j),
        location: j['location'] == null ? null : FriendLocation.fromJson(j['location'] as Map<String, dynamic>),
      );

  Friend copyWith({FriendLocation? location, bool? online}) =>
      Friend(user: user, location: location ?? this.location, online: online ?? this.online);
}

class FriendRequest {
  final String id;
  final User user;
  final DateTime createdAt;

  const FriendRequest({required this.id, required this.user, required this.createdAt});

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        id: j['id'] as String,
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        createdAt: _t(j['createdAt']),
      );
}

class TrackPoint {
  final double lat;
  final double lng;
  final DateTime time;
  final double? ele;

  const TrackPoint({required this.lat, required this.lng, required this.time, this.ele});

  LatLng get point => LatLng(lat, lng);

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        't': time.millisecondsSinceEpoch,
        if (ele != null) 'ele': ele,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> j) =>
      TrackPoint(lat: _d(j['lat']), lng: _d(j['lng']), time: _t(j['t']), ele: _dn(j['ele']));
}

class Activity {
  final String id;
  final User user;
  final String type;
  final String title;
  final String description;
  final String visibility;
  final DateTime startedAt;
  final double distanceM;
  final int durationS;
  final int movingTimeS;
  final double elevationGainM;
  final double avgSpeedMps;
  final double maxSpeedMps;
  final List<LatLng> preview;
  final int kudosCount;
  final bool hasKudos;
  final List<TrackPoint>? points;

  const Activity({
    required this.id,
    required this.user,
    required this.type,
    required this.title,
    required this.description,
    required this.visibility,
    required this.startedAt,
    required this.distanceM,
    required this.durationS,
    required this.movingTimeS,
    required this.elevationGainM,
    required this.avgSpeedMps,
    required this.maxSpeedMps,
    required this.preview,
    required this.kudosCount,
    required this.hasKudos,
    this.points,
  });

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        id: j['id'] as String,
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        type: j['type'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        visibility: j['visibility'] as String,
        startedAt: _t(j['startedAt']),
        distanceM: _d(j['distanceM']),
        durationS: (j['durationS'] as num).toInt(),
        movingTimeS: (j['movingTimeS'] as num).toInt(),
        elevationGainM: _d(j['elevationGainM']),
        avgSpeedMps: _d(j['avgSpeedMps']),
        maxSpeedMps: _d(j['maxSpeedMps']),
        preview: ((j['preview'] as List?) ?? const [])
            .map((p) => LatLng(_d((p as List)[0]), _d(p[1])))
            .toList(),
        kudosCount: (j['kudosCount'] as num?)?.toInt() ?? 0,
        hasKudos: j['hasKudos'] as bool? ?? false,
        points: (j['points'] as List?)?.map((p) => TrackPoint.fromJson(p as Map<String, dynamic>)).toList(),
      );

  Activity withKudos(int count, bool has) => Activity(
        id: id,
        user: user,
        type: type,
        title: title,
        description: description,
        visibility: visibility,
        startedAt: startedAt,
        distanceM: distanceM,
        durationS: durationS,
        movingTimeS: movingTimeS,
        elevationGainM: elevationGainM,
        avgSpeedMps: avgSpeedMps,
        maxSpeedMps: maxSpeedMps,
        preview: preview,
        kudosCount: count,
        hasKudos: has,
        points: points,
      );
}

class Totals {
  final int count;
  final double distanceM;
  final int movingTimeS;
  final double elevationGainM;

  const Totals({this.count = 0, this.distanceM = 0, this.movingTimeS = 0, this.elevationGainM = 0});

  factory Totals.fromJson(Map<String, dynamic>? j) => j == null
      ? const Totals()
      : Totals(
          count: (j['count'] as num).toInt(),
          distanceM: _d(j['distanceM']),
          movingTimeS: (j['movingTimeS'] as num).toInt(),
          elevationGainM: _d(j['elevationGainM']),
        );
}

class Stats {
  final Totals week;
  final Totals month;
  final Totals all;

  const Stats({required this.week, required this.month, required this.all});

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        week: Totals.fromJson(j['week'] as Map<String, dynamic>?),
        month: Totals.fromJson(j['month'] as Map<String, dynamic>?),
        all: Totals.fromJson(j['all'] as Map<String, dynamic>?),
      );
}

class GeocodeResult {
  final String name;
  final String displayName;
  final double lat;
  final double lng;

  const GeocodeResult({required this.name, required this.displayName, required this.lat, required this.lng});

  LatLng get point => LatLng(lat, lng);

  factory GeocodeResult.fromJson(Map<String, dynamic> j) => GeocodeResult(
        name: (j['name'] as String?) ?? '',
        displayName: (j['displayName'] as String?) ?? '',
        lat: _d(j['lat']),
        lng: _d(j['lng']),
      );
}

class Place {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final int checkinCount;
  final int? distanceM;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.checkinCount,
    this.distanceM,
  });

  LatLng get point => LatLng(lat, lng);

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        lat: _d(j['lat']),
        lng: _d(j['lng']),
        checkinCount: (j['checkinCount'] as num?)?.toInt() ?? 0,
        distanceM: (j['distanceM'] as num?)?.toInt(),
      );
}

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        recipientId: j['recipientId'] as String,
        body: j['body'] as String,
        createdAt: _t(j['createdAt']),
        readAt: _tn(j['readAt']),
      );
}

class Conversation {
  final User user;
  final Message lastMessage;
  final int unreadCount;

  const Conversation({required this.user, required this.lastMessage, required this.unreadCount});

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        user: User.fromJson(j['user'] as Map<String, dynamic>),
        lastMessage: Message.fromJson(j['lastMessage'] as Map<String, dynamic>),
        unreadCount: (j['unreadCount'] as num).toInt(),
      );
}

class ApiKeyInfo {
  final String id;
  final String name;
  final String prefix;
  final List<String> scopes;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Only set right after creation; the server never returns it again.
  final String? key;

  const ApiKeyInfo({
    required this.id,
    required this.name,
    required this.prefix,
    required this.scopes,
    required this.createdAt,
    this.lastUsedAt,
    this.key,
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> j) => ApiKeyInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        prefix: j['prefix'] as String,
        scopes: (j['scopes'] as List).cast<String>(),
        createdAt: _t(j['createdAt']),
        lastUsedAt: _tn(j['lastUsedAt']),
        key: j['key'] as String?,
      );
}
