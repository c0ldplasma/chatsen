import 'package:chatsen/api/frankerfacez/frankerfacez_badges.dart';
import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import '/api/frankerfacez/frankerfacez_set.dart';
import 'frankerfacez_user.dart';

class FrankerFaceZ {
  static Future<FrankerFaceZUser> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/room/id/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => FrankerFaceZUser.fromJson(json));
  }

  static Future<List<FrankerFaceZSet>> globalSets() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/set/global'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => [for (final setData in json['sets'].values) FrankerFaceZSet.fromJson(setData)]);
  }

  static Future<FrankerFaceZBadges> badges() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/badges/ids'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => FrankerFaceZBadges.fromJson(json));
  }
}
