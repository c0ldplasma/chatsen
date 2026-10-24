import 'package:coldchat/providers/badge_provider.dart';

import '../api/twitch/twitch.dart';
import '../data/twitch/token_data.dart';
import '../data/custom_badge.dart';
import '../data/badge_users.dart';
import '../data/emote.dart';
import 'emote_provider.dart';
import 'provider.dart';

class TwitchProvider extends Provider with EmoteProvider, BadgeProvider {
  /// The token for Helix requests. Badges can't be loaded without one, e.g.
  /// while browsing anonymously.
  final TokenData? Function() tokenData;

  TwitchProvider({TokenData? Function()? tokenData}) : tokenData = tokenData ?? (() => null);

  TokenData get _requireTokenData {
    final data = tokenData();
    if (data?.accessToken == null) throw 'No Twitch login to load badges with';
    return data!;
  }

  @override
  String get name => 'Twitch';

  @override
  String? get description => null;

  @override
  Future<List<CustomBadge>> globalBadges() async {
    final twitchBadges = await Twitch.globalBadges(_requireTokenData);
    return [
      for (final twitchBadgeData in twitchBadges.entries)
        for (final twitchBadgeVersion in twitchBadgeData.value.entries)
          CustomBadge(
            id: '${twitchBadgeData.key}/${twitchBadgeVersion.key}',
            name: twitchBadgeVersion.value.title,
            description: twitchBadgeVersion.value.description,
            mipmap: [
              twitchBadgeVersion.value.imageUrl1x,
              twitchBadgeVersion.value.imageUrl2x,
              twitchBadgeVersion.value.imageUrl4x,
            ],
            provider: this,
          ),
    ];
  }

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async {
    final twitchBadges = await Twitch.channelBadges(_requireTokenData, uid);
    return [
      for (final twitchBadgeData in twitchBadges.entries)
        for (final twitchBadgeVersion in twitchBadgeData.value.entries)
          CustomBadge(
            id: '${twitchBadgeData.key}/${twitchBadgeVersion.key}',
            name: twitchBadgeVersion.value.title,
            description: twitchBadgeVersion.value.description,
            mipmap: [
              twitchBadgeVersion.value.imageUrl1x,
              twitchBadgeVersion.value.imageUrl2x,
              twitchBadgeVersion.value.imageUrl4x,
            ],
            provider: this,
          ),
    ];
  }

  @override
  Future<List<CustomBadge>> userBadges(String uid) async => [];

  @override
  Future<List<BadgeUsers>> globalUserBadges() async => [];

  @override
  Future<List<Emote>> globalEmotes() async => [];

  @override
  Future<List<Emote>> channelEmotes(String uid) async => [];

  @override
  String? emoteUrl(String id) => null;
}
