import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:chatsen/api/twitch/twitch.dart';
import 'package:chatsen/providers/dankchat.dart';
import 'package:chatsen/providers/emojis.dart';
import 'package:chatsen/providers/twitch.dart';
import 'package:chatsen/tmi/badges.dart';
import 'package:chatsen/tmi/channel/channel_message.dart';
import 'package:chatsen/tmi/client/client_listener.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/custom_badge.dart';
import '../../data/badge_users.dart';
import '../../data/emote.dart';
import '../../providers/badge_provider.dart';
import '../../providers/chatsen.dart';
import '../../providers/emote_provider.dart';
import '../cache.dart';
import '../channel/messages/channel_message_ban.dart';
import '../channel/messages/channel_message_notice.dart';
import '../emotes.dart';
import '../user_badges.dart';
import '/providers/betterttv.dart';
import '/api/recentmessages/recentmessages.dart';
import '/tmi/channel/channel_event.dart';
import '/tmi/channel/channel_state.dart';
import '/tmi/connection/connection_state.dart';
import '/data/twitch_account.dart';
import '/tmi/connection/connection.dart';
import '/tmi/connection/connection_event.dart';
import '/irc/message.dart' as irc;
import '/providers/provider.dart';
import '/providers/frankerfacez.dart';
import '/providers/seventv.dart';
import '/tmi/channel/messages/channel_message_chat.dart';
import 'client_channels.dart';

class Client {
  Connection receiver = Connection();
  Connection transmitter = Connection();
  List<String> blockedUserIds = [];

  List<Provider> providers = [
    ChatsenProvider(),
    SevenTVProvider(),
    BetterTTVProvider(),
    FrankerFaceZProvider(),
    DankChatProvider(),
    TwitchProvider(),
    EmojiProvider(),
  ];

  late ClientChannels channels;
  EmoteBadgeCache? cache;

  List<ClientListener> listeners = [];

  Emotes twitchUserEmotes = Emotes();
  Emotes globalEmotes = Emotes();
  Badges globalBadges = Badges();
  Emotes emojis = Emotes();
  UserBadges globalUserBadges = UserBadges();

  Client({
    TwitchAccount? twitchAccount,
    required Box channelsBox,
    Box? cacheBox,
  }) {
    channels = ClientChannels(
      this,
      channelsBox: channelsBox,
    );

    if (cacheBox != null) {
      cache = EmoteBadgeCache(box: cacheBox, providers: providers);
      _hydrateGlobalsFromCache();
    }

    // Twitch IRC allows ~20 JOIN commands per 10 seconds for normal users.
    // Stay well under the limit: 4 channels every 2s = 2/s.
    const joinBatchSize = 4;
    Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (receiver.state is ConnectionConnected) {
          final channelsToJoin = channels.state.where((channel) => channel.state is ChannelDisconnected).take(joinBatchSize).toList();
          if (channelsToJoin.isEmpty) return;
          for (final channel in channelsToJoin) {
            channel.add(ChannelJoin(receiver, transmitter));
          }
          receiver.send('JOIN ${channelsToJoin.map((e) => e.name).join(',')}');
        }
      },
    );

    receiver.onReceive = receive;
    transmitter.onReceive = receive;
    receiver.onStateChange = stateChange;

    if (twitchAccount != null) connectAs(twitchAccount);

    refreshGlobalEmotes();
    refreshGlobalBadges();
    refreshGlobalUserBadges();
  }

  void _hydrateGlobalsFromCache() {
    final c = cache;
    if (c == null) return;
    final emotes = c.loadEmotes(EmoteBadgeCache.globalEmotesKey);
    if (emotes.isNotEmpty) globalEmotes.change(emotes);
    final badges = c.loadBadges(EmoteBadgeCache.globalBadgesKey);
    if (badges.isNotEmpty) globalBadges.change(badges);
    final userBadges = c.loadUserBadges(EmoteBadgeCache.globalUserBadgesKey);
    if (userBadges.isNotEmpty) globalUserBadges.change(userBadges);
  }

  Future<void> refreshGlobalEmotes() async {
    final emoteProviders = providers.whereType<EmoteProvider>();
    final results = await Future.wait(
      emoteProviders.map((emoteProvider) async {
        try {
          return await emoteProvider.globalEmotes();
        } catch (e) {
          log('Couldn\'t get ${emoteProvider.name} global emotes');
          return <Emote>[];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    globalEmotes.change(merged);
    cache?.saveEmotes(EmoteBadgeCache.globalEmotesKey, merged);
  }

  Future<void> refreshGlobalBadges() async {
    final badgeProviders = providers.whereType<BadgeProvider>();
    final results = await Future.wait(
      badgeProviders.map((badgeProvider) async {
        try {
          return await badgeProvider.globalBadges();
        } catch (e) {
          log('Couldn\'t get ${badgeProvider.name} global badges');
          return <CustomBadge>[];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    globalBadges.change(merged);
    cache?.saveBadges(EmoteBadgeCache.globalBadgesKey, merged);
  }

  Future<void> refreshGlobalUserBadges() async {
    final badgeProviders = providers.whereType<BadgeProvider>();
    final results = await Future.wait(
      badgeProviders.map((badgeProvider) async {
        try {
          return await badgeProvider.globalUserBadges();
        } catch (e) {
          log('Couldn\'t get ${badgeProvider.name} global user badges');
          return <BadgeUsers>[];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    globalUserBadges.change(merged);
    cache?.saveUserBadges(EmoteBadgeCache.globalUserBadgesKey, merged);
  }

  Future<void> connectAs(TwitchAccount twitchAccount) async {
    receiver.add(ConnectionConnect(twitchAccount));
    transmitter.add(ConnectionConnect(twitchAccount));
  }

  Future<void> stateChange(Connection connection, Change<ConnectionState> change) async {
    // final matchingChannels = channels.state.where((channel) => channel.state is ChannelStateWithConnection && (channel.state as ChannelStateWithConnection).receiver == this);
    for (final channel in channels.state) {
      channel.add(ChannelPart());
    }
  }

  Future<void> receive(Connection connection, irc.Message event) async {
    switch (event.command) {
      case '001':
        if (connection.state is ConnectionConnecting) {
          final stateTwitchAccount = (connection.state as ConnectionConnecting).twitchAccount;
          connection.emit(ConnectionConnected(
            stateTwitchAccount,
            blockedUserIds: stateTwitchAccount.tokenData.accessToken == null ? [] : await Twitch.blockedUsers(stateTwitchAccount.tokenData),
          ));
        }
        break;
      case 'GLOBALUSERSTATE':
        try {
          if (connection.state is ConnectionStateWithCredentials) {
            final stateTwitchAccount = (connection.state as ConnectionStateWithCredentials).twitchAccount;
            final emotes = await Twitch.emoteSets(stateTwitchAccount.tokenData, event.tags['emote-sets']?.split(',') ?? []);
            twitchUserEmotes.change([
              for (final emote in emotes)
                Emote(
                  id: emote.id,
                  mipmap: emote.images.values.toList(),
                  name: emote.name,
                  provider: providers.firstWhere((element) => element.name == 'Twitch'),
                ),
            ]);
          }
        } catch (e) {
          log('Couldn\'t get twitch user emotes');
        }
        break;
      case 'JOIN':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        final credentials = channel.state is ChannelStateWithConnection ? (channel.state as ChannelStateWithConnection).receiver.twitchAccount : null;
        if (credentials == null) {
          break;
        }

        final loginSource = event.prefix?.split('!').first;
        if (loginSource == credentials.tokenData.login) {
          channel.add(ChannelConnect());
          channel.pendingHistory = RecentMessages.channel(channel.name.substring(1)).catchError((_) => <String>[]);
        }
        break;
      case 'USERNOTICE':
      case 'PRIVMSG':
        if (event.command == 'USERNOTICE') log(event.raw);

        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        ChannelMessage message = ChannelMessageChat(
          message: event,
          dateTime: DateTime.fromMillisecondsSinceEpoch(int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch),
          channel: channel,
        );

        for (final listener in listeners) {
          listener.onMessageReceived(message);
        }

        channel.channelMessages.add(message);
        break;
      case 'ROOMSTATE':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        channel.id = event.tags['room-id'];
        await channel.refresh();

        final pending = channel.pendingHistory;
        if (pending != null) {
          channel.pendingHistory = null;
          final history = await pending;
          for (final message in history) {
            final ircMessage = irc.Message.fromEvent(message);
            if (ircMessage.command == 'ROOMSTATE') continue;
            receive(connection, ircMessage);
          }
        }
        break;
      case 'CLEARCHAT':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        channel.channelMessages.add(
          ChannelMessageBan(
            message: event,
            dateTime: DateTime.fromMillisecondsSinceEpoch(int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch),
            channel: channel,
          ),
        );
        break;
      case 'NOTICE':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        if (event.tags['msg-id'] == 'msg_channel_suspended') {
          channel.add(ChannelSuspend());
        }

        channel.channelMessages.add(
          ChannelMessageNotice(
            message: event,
            dateTime: DateTime.fromMillisecondsSinceEpoch(int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch),
            channel: channel,
          ),
        );
        break;
      default:
        log(event.raw);
        break;
    }
  }
}
