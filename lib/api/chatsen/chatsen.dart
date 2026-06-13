import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'chatsen_badge.dart';
import 'chatsen_user.dart';

ChatsenUser _parseChatsenUser(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return ChatsenUser.fromJson(responseJson);
}

class Chatsen {
  static Future<ChatsenUser> userWithViewers(String login) async {
    final response = await http.get(Uri.parse('https://api.chatsen.app/v1/channel/$login'));
    // Channel payload includes the full chatter list, which can be large for
    // big channels. Decode + map off the UI isolate to avoid scroll jank.
    return compute(_parseChatsenUser, response.bodyBytes);
  }

  static Future<ChatsenUser> user(String login) async {
    final response = await http.get(Uri.parse('https://api.chatsen.app/v1/user/$login'));
    final responseJson = await json.decode(utf8.decode(response.bodyBytes));
    return ChatsenUser.fromJson(responseJson);
  }

  static Future<List<ChatsenBadge>> badges() async {
    final response = await http.get(Uri.parse('https://api.chatsen.app/account/badges')); // https://api.chatsen.app/v1/cosmetics
    final responseJson = await json.decode(utf8.decode(response.bodyBytes));
    return [
      for (final badge in responseJson) ChatsenBadge.fromJson(badge),
    ];
  }
}
