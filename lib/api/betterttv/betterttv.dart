import 'package:chatsen/api/betterttv/betterttv_badge.dart';
import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import '/api/betterttv/betterttv_emote.dart';
import 'betterttv_user.dart';

class BetterTTV {
  static Future<List<BetterTTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/emotes/global'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => [for (final emote in json) BetterTTVEmote.fromJson(emote)]);
  }

  static Future<BetterTTVUser?> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/users/twitch/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => json['id'] == null ? null : BetterTTVUser.fromJson(json));
  }

  static Future<List<BetterTTVBadge>> badges() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/badges'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => [for (final badge in json) BetterTTVBadge.fromJson(badge)]);
  }
}
