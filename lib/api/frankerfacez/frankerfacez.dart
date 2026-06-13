import 'dart:convert';

import 'package:chatsen/api/frankerfacez/frankerfacez_badges.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/api/frankerfacez/frankerfacez_set.dart';
import 'frankerfacez_user.dart';

FrankerFaceZUser _parseUser(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return FrankerFaceZUser.fromJson(responseJson);
}

List<FrankerFaceZSet> _parseGlobalSets(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return [
    for (final setData in responseJson['sets'].values) FrankerFaceZSet.fromJson(setData),
  ];
}

FrankerFaceZBadges _parseBadges(List<int> bodyBytes) {
  final responseJson = json.decode(utf8.decode(bodyBytes));
  return FrankerFaceZBadges.fromJson(responseJson);
}

class FrankerFaceZ {
  static Future<FrankerFaceZUser> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/room/id/$uid'));
    return compute(_parseUser, response.bodyBytes);
  }

  static Future<List<FrankerFaceZSet>> globalSets() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/set/global'));
    return compute(_parseGlobalSets, response.bodyBytes);
  }

  static Future<FrankerFaceZBadges> badges() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/badges/ids'));
    return compute(_parseBadges, response.bodyBytes);
  }
}
