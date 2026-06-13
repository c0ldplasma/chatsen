import 'dart:convert';

import 'package:chatsen/api/seventv/seventv_cosmetics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'seventv_emote.dart';

List<SevenTVEmote> _parseGlobalEmotes(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return [
    for (final emote in responseJson['emotes']) SevenTVEmote.fromJson(emote),
  ];
}

List<SevenTVEmote> _parseChannelEmotes(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  if (responseJson['status_code'] == 404) return [];
  return [
    for (final emote in responseJson['emote_set']?['emotes'] ?? []) SevenTVEmote.fromJson(emote),
  ];
}

class SevenTV {
  static Future<List<SevenTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/emote-sets/global'));
    return compute(_parseGlobalEmotes, response.bodyBytes);
  }

  static Future<List<SevenTVEmote>> channelEmotes(String uid) async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/users/twitch/$uid'));
    return compute(_parseChannelEmotes, response.bodyBytes);
  }

  static Future<SevenTVCosmetics> cosmetics() async {
    final response = await http.get(Uri.parse('https://7tv.io/v2/cosmetics?user_identifier=twitch_id'));
    final responseJson = json.decode(utf8.decode(response.bodyBytes));
    return SevenTVCosmetics.fromJson(responseJson);
  }
}
