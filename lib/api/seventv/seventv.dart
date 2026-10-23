import 'package:chatsen/api/seventv/seventv_cosmetics.dart';
import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import 'seventv_emote.dart';

class SevenTV {
  static Future<List<SevenTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/emote-sets/global'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => [for (final emote in json['emotes']) SevenTVEmote.fromJson(emote)]);
  }

  static Future<List<SevenTVEmote>> channelEmotes(String uid) async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/users/twitch/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) {
      if (json['status_code'] == 404) return <SevenTVEmote>[];
      return [for (final emote in json['emote_set']?['emotes'] ?? []) SevenTVEmote.fromJson(emote)];
    });
  }

  static Future<SevenTVCosmetics> cosmetics() async {
    final response = await http.get(Uri.parse('https://7tv.io/v2/cosmetics?user_identifier=twitch_id'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => SevenTVCosmetics.fromJson(json));
  }
}
