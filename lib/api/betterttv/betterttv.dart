import 'dart:convert';

import 'package:chatsen/api/betterttv/betterttv_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/api/betterttv/betterttv_emote.dart';
import 'betterttv_user.dart';

List<BetterTTVEmote> _parseGlobalEmotes(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return [
    for (final emote in responseJson) BetterTTVEmote.fromJson(emote),
  ];
}

BetterTTVUser? _parseUser(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  if (responseJson['id'] == null) return null;
  return BetterTTVUser.fromJson(responseJson);
}

List<BetterTTVBadge> _parseBadges(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return [
    for (final badge in responseJson) BetterTTVBadge.fromJson(badge),
  ];
}

class BetterTTV {
  static Future<List<BetterTTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/emotes/global'));
    return compute(_parseGlobalEmotes, response.bodyBytes);
  }

  static Future<BetterTTVUser?> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/users/twitch/$uid'));
    return compute(_parseUser, response.bodyBytes);
  }

  static Future<List<BetterTTVBadge>> badges() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/badges'));
    return compute(_parseBadges, response.bodyBytes);
  }
}
