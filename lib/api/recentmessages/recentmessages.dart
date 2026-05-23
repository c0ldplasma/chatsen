import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<String> _parseRecentMessages(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return List<String>.from(responseJson['messages']);
}

class RecentMessages {
  static Future<List<String>> channel(String channelName) async {
    final response = await http.get(Uri.parse('https://recent-messages.robotty.de/api/v2/recent-messages/$channelName'));
    return compute(_parseRecentMessages, response.bodyBytes);
  }
}
