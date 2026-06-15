import 'package:http/http.dart' as http;

import '../json_isolate.dart';

class RecentMessages {
  static Future<List<String>> channel(String channelName) async {
    final response = await http.get(Uri.parse('https://recent-messages.robotty.de/api/v2/recent-messages/$channelName'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => List<String>.from(json['messages']));
  }
}
