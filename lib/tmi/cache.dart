import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import '../data/emote.dart';
import '../providers/provider.dart';

/// Lightweight JSON cache for emotes and badges so first-paint after launch
/// or after opening a channel doesn't have to wait on provider HTTP requests.
class EmoteBadgeCache {
  static const String boxName = 'EmoteBadgeCache';

  final Box box;
  final List<Provider> providers;

  EmoteBadgeCache({required this.box, required this.providers});

  Provider? _providerByName(String? name) {
    if (name == null) return null;
    for (final p in providers) {
      if (p.name == name) return p;
    }
    return null;
  }

  Map<String, dynamic> _emoteToJson(Emote e) => {
        'id': e.id,
        'name': e.name,
        'code': e.code,
        'description': e.description,
        'mipmap': e.mipmap,
        'flags': e.flags,
        'provider': e.provider.name,
        'category': e.category,
      };

  Emote? _emoteFromJson(Map<String, dynamic> m) {
    final provider = _providerByName(m['provider'] as String?);
    if (provider == null) return null;
    return Emote(
      id: m['id'] as String,
      name: m['name'] as String,
      code: m['code'] as String?,
      description: m['description'] as String?,
      mipmap: List<String>.from(m['mipmap'] as List),
      flags: (m['flags'] as int?) ?? 0,
      provider: provider,
      category: m['category'] as String?,
    );
  }

  Map<String, dynamic> _badgeToJson(CustomBadge b) => {
        'id': b.id,
        'name': b.name,
        'description': b.description,
        'mipmap': b.mipmap,
        'flags': b.flags,
        'provider': b.provider.name,
      };

  CustomBadge? _badgeFromJson(Map<String, dynamic> m) {
    final provider = _providerByName(m['provider'] as String?);
    if (provider == null) return null;
    return CustomBadge(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      mipmap: List<String>.from(m['mipmap'] as List),
      flags: (m['flags'] as int?) ?? 0,
      provider: provider,
    );
  }

  List<dynamic>? _decode(String key) {
    final raw = box.get(key);
    if (raw is! String) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> _encode(String key, List<Map<String, dynamic>> data) async {
    await box.put(key, json.encode(data));
  }

  List<Emote> loadEmotes(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final emotes = <Emote>[];
    for (final entry in list) {
      if (entry is Map) {
        final e = _emoteFromJson(Map<String, dynamic>.from(entry));
        if (e != null) emotes.add(e);
      }
    }
    return emotes;
  }

  Future<void> saveEmotes(String key, List<Emote> emotes) {
    return _encode(key, emotes.map(_emoteToJson).toList());
  }

  List<CustomBadge> loadBadges(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final badges = <CustomBadge>[];
    for (final entry in list) {
      if (entry is Map) {
        final b = _badgeFromJson(Map<String, dynamic>.from(entry));
        if (b != null) badges.add(b);
      }
    }
    return badges;
  }

  Future<void> saveBadges(String key, List<CustomBadge> badges) {
    return _encode(key, badges.map(_badgeToJson).toList());
  }

  List<BadgeUsers> loadUserBadges(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final entries = <BadgeUsers>[];
    for (final entry in list) {
      if (entry is Map) {
        final badgeMap = entry['badge'];
        if (badgeMap is! Map) continue;
        final badge = _badgeFromJson(Map<String, dynamic>.from(badgeMap));
        if (badge == null) continue;
        entries.add(BadgeUsers(
          badge: badge,
          users: List<String>.from(entry['users'] as List? ?? const []),
        ));
      }
    }
    return entries;
  }

  Future<void> saveUserBadges(String key, List<BadgeUsers> entries) {
    return _encode(
      key,
      entries
          .map((entry) => {
                'badge': _badgeToJson(entry.badge),
                'users': entry.users,
              })
          .toList(),
    );
  }

  String channelEmotesKey(String channelId) => 'channelEmotes:$channelId';
  String channelBadgesKey(String channelId) => 'channelBadges:$channelId';
  static const String globalEmotesKey = 'globalEmotes';
  static const String globalBadgesKey = 'globalBadges';
  static const String globalUserBadgesKey = 'globalUserBadges';
}
