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
import '../channel/channel.dart';
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
import '/tmi/channel/messages/channel_message_id.dart';
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
    // Set up the cache before constructing channels so each Channel can
    // hydrate its emotes/badges from disk in its constructor (channels are
    // created inside ClientChannels). Otherwise the cache is still null when
    // they hydrate and third-party emotes won't resolve until the network
    // refresh lands.
    if (cacheBox != null) {
      cache = EmoteBadgeCache(box: cacheBox, providers: providers);
      _hydrateGlobalsFromCache();
    }

    channels = ClientChannels(
      this,
      channelsBox: channelsBox,
    );

    // Prioritize the channel the user last had open so it lands in the first
    // (larger) JOIN burst and comes up before the rest of the list.
    final lastChannel = Hive.box('Settings').get('lastChannel');
    if (lastChannel is String && lastChannel.isNotEmpty) {
      channels.state.firstWhereOrNull((c) => c.name == lastChannel)?.joinPriority = true;
    }

    // Drain the join queue on a timer as a steady-state fallback, but also
    // trigger an immediate pass as soon as the connection is established
    // (see _joinPass call on the 001 handler) so we don't idle up to 2s
    // waiting for the first tick.
    Timer.periodic(const Duration(seconds: 2), (timer) => _joinPass());

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

  // Twitch IRC allows ~20 JOIN commands per 10 seconds for normal users. The
  // first pass after connecting joins a larger burst so the channels the user
  // cares about come up quickly; steady-state ticks stay conservative.
  bool _firstJoinPass = true;

  // Channels the user has explicitly requested (active chat view) or last had
  // open sort first, so the channel actually being looked at is handled first.
  static int _byJoinPriority(Channel a, Channel b) => a.joinPriority == b.joinPriority ? 0 : (a.joinPriority ? -1 : 1);

  void _joinPass() {
    if (receiver.state is! ConnectionConnected) return;
    final disconnected = channels.state.where((channel) => channel.state is ChannelDisconnected).toList();
    if (disconnected.isEmpty) return;
    disconnected.sort(_byJoinPriority);
    final batchSize = _firstJoinPass ? 12 : 4;
    _firstJoinPass = false;
    final channelsToJoin = disconnected.take(batchSize).toList();
    for (final channel in channelsToJoin) {
      channel.add(ChannelJoin(receiver, transmitter));
    }
    receiver.send('JOIN ${channelsToJoin.map((e) => e.name).join(',')}');
  }

  // Building a ChannelMessageChat is expensive (emote parsing, regex, Hive
  // lookups). Deserialize history newest-first in chunks: the first (smaller)
  // chunk is the newest messages — the ones actually visible at the bottom of
  // the reverse chat list — so they appear almost immediately. Older chunks
  // are added above the viewport afterwards; with reverse:true the bottom
  // anchor doesn't move, so the chat doesn't jump. Yields between chunks keep
  // the UI responsive.
  static const int _historyFirstChunk = 30;
  static const int _historyLaterChunk = 40;

  Future<void> insertHistoryMessages(Connection connection, List<String> messages) async {
    // Parse once, preserving chronological (oldest->newest) order as delivered
    // by the recent-messages endpoint. Skip transient channel-state events:
    // ROOMSTATE, and NOTICE (slow/emote/follower-mode toggles etc.). These
    // describe past room state — replaying them is noise, and because NOTICEs
    // carry no `id` tag they also bypass the id-based dedup below, so each of
    // the three history passes (cached paint, lazy fetch, post-JOIN backfill)
    // would re-add them, producing the duplicate "now in slow mode / no longer
    // in slow mode" spam. USERNOTICE (subs/raids) is intentionally kept.
    final parsed = <irc.Message>[];
    for (final message in messages) {
      final ircMessage = irc.Message.fromEvent(message);
      if (ircMessage.command == 'ROOMSTATE' || ircMessage.command == 'NOTICE') continue;
      parsed.add(ircMessage);
    }
    if (parsed.isEmpty) return;

    // History payloads are single-channel; find it from any chat message.
    final firstChatMessage = parsed.firstWhereOrNull((m) => (m.command == 'PRIVMSG' || m.command == 'USERNOTICE') && m.parameters.isNotEmpty);
    final bulkChannel = firstChatMessage == null ? null : channels.state.firstWhereOrNull((c) => c.name == firstChatMessage.parameters[0]);

    // Snapshot existing ids so we drop duplicates BEFORE building them (the
    // post-JOIN backfill mostly re-sends messages we already have).
    final existingIds = bulkChannel?.channelMessages.state.whereType<ChannelMessageId>().map((e) => e.id).toSet() ?? <String>{};

    // Walk from the end (newest) towards the start (oldest), one chunk per
    // iteration, emitting after each so the newest render first.
    var end = parsed.length;
    var first = true;
    while (end > 0) {
      final size = first ? _historyFirstChunk : _historyLaterChunk;
      first = false;
      final start = (end - size).clamp(0, end);
      final chunk = parsed.sublist(start, end);
      end = start;

      bulkChannel?.channelMessages.beginBulk();
      for (final ircMessage in chunk) {
        final id = ircMessage.tags['id'];
        if (id != null && existingIds.contains(id)) continue;
        if (id != null) existingIds.add(id);
        receive(connection, ircMessage);
      }
      bulkChannel?.channelMessages.endBulk();
      await Future.delayed(Duration.zero);
    }
  }

  /// Lazily fetch recent-messages for [channel] (e.g. when its chat view is
  /// first opened). De-duplication in ChannelMessages.add drops anything
  /// already inserted from the cache.
  Future<void> ensureRecentMessages(Channel channel) async {
    // User is actively looking at this channel — make sure the throttled
    // JOIN scheduler picks it before any other queued channel.
    channel.joinPriority = true;
    if (channel.recentMessagesFetched) return;
    channel.recentMessagesFetched = true;
    channel.recentMessagesEverFetched = true;
    if (!await _fetchAndInsertHistory(channel)) {
      channel.recentMessagesFetched = false;
    }
  }

  /// Pull recent-messages again right after a successful JOIN to backfill
  /// anything that was sent while we were waiting for the JOIN ack — those
  /// PRIVMSGs are not delivered to us by Twitch until we are subscribed.
  Future<void> _backfillAfterJoin(Channel channel) async {
    if (channel.joinBackfillDone) return;
    channel.joinBackfillDone = true;
    if (!await _fetchAndInsertHistory(channel)) {
      channel.joinBackfillDone = false;
    }
  }

  // Fetch recent-messages for [channel], persist them, and insert into the
  // chat. Returns false on failure so callers can reset their latch.
  Future<bool> _fetchAndInsertHistory(Channel channel) async {
    final channelLogin = channel.name.substring(1);
    try {
      final list = await RecentMessages.channel(channelLogin);
      cache?.saveHistory(channelLogin, list);
      await insertHistoryMessages(receiver, list);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Called every time the app returns to the foreground. Actively probes each
  /// socket (PING -> expect a fast reply); only the ones that don't answer are
  /// reconnected. A quick app-switch over a live connection answers instantly
  /// and costs nothing — no needless reconnect — while a socket killed by a
  /// lock/background fails the probe and recovers right away instead of waiting
  /// up to ~70s for the steady-state watchdog. When anything was actually dead,
  /// gap-fill the messages missed while away (parallel, dedup-safe).
  Future<void> onAppResumed() async {
    // A token can expire while the app sits in the background for days, so
    // check before probing: reconnecting with it is pointless and the socket
    // failure would be indistinguishable from a network hiccup.
    final account = receiver.twitchAccount ?? transmitter.twitchAccount;
    if (account != null && account.tokenData.accessToken != null && account.tokenData.isExpired) {
      _rejectCredentials(account);
      return;
    }
    if (receiver.credentialsRejected || transmitter.credentialsRejected) return;
    if (account != null) unawaited(validateCredentials(account));

    final results = await Future.wait([receiver.probeAlive(), transmitter.probeAlive()]);
    final receiverAlive = results[0];
    final transmitterAlive = results[1];
    if (receiverAlive && transmitterAlive) return; // connection still live — nothing to do

    if (!receiverAlive) receiver.forceReconnect();
    if (!transmitterAlive) transmitter.forceReconnect();

    // Visible (active/last) channel first so the chat being looked at fills
    // first; insertHistoryMessages dedups by id, so the later rejoin backfill
    // is a no-op for anything we pull in here.
    final viewed = channels.state.where((channel) => channel.recentMessagesEverFetched).toList()..sort(_byJoinPriority);
    await Future.wait(viewed.map((channel) {
      channel.joinBackfillDone = false;
      return _fetchAndInsertHistory(channel);
    }));
  }

  /// Twitch refuses a bad token with an untagged NOTICE whose text we have to
  /// match; there is no msg-id on these. Only ever sent with target `*` (i.e.
  /// before we are authenticated), which keeps this from matching channel chat.
  static bool _isAuthFailureNotice(irc.Message event) {
    if (event.parameters.isEmpty || event.parameters.first != '*') return false;
    final text = event.parameters.length > 1 ? event.parameters.last.toLowerCase() : '';
    return text.contains('login authentication failed') || text.contains('login unsuccessful') || text.contains('improperly formatted auth');
  }

  void _rejectCredentials(TwitchAccount twitchAccount) {
    receiver.add(ConnectionCredentialsRejected(twitchAccount));
    transmitter.add(ConnectionCredentialsRejected(twitchAccount));
  }

  /// Ask Twitch whether the stored token is still good, and keep [TokenData]
  /// honest about it. On a 401 the login is dead — reject it so the UI can say
  /// so instead of letting the reconnect loop churn silently. Network failures
  /// are ignored: being offline is not proof the token expired.
  Future<void> validateCredentials(TwitchAccount twitchAccount) async {
    final accessToken = twitchAccount.tokenData.accessToken;
    if (accessToken == null) return; // anonymous
    if (twitchAccount.tokenData.isExpired) {
      _rejectCredentials(twitchAccount);
      return;
    }

    try {
      final fresh = await Twitch.validateToken(accessToken);
      // The stored expiresAt is a snapshot from login time and is never touched
      // afterwards; refresh it so the account modal and the local expiry check
      // reflect reality.
      twitchAccount.tokenData.expiresAt = fresh.expiresAt;
      twitchAccount.tokenData.scopes = fresh.scopes;
      try {
        await twitchAccount.save();
      } catch (_) {
        // Not attached to a box (e.g. constructed in-memory) — nothing to persist.
      }
      if (twitchAccount.tokenData.isExpired) _rejectCredentials(twitchAccount);
    } on TwitchTokenInvalidException {
      _rejectCredentials(twitchAccount);
    } catch (e) {
      log('Couldn\'t validate the Twitch token: $e');
    }
  }

  Future<void> connectAs(TwitchAccount twitchAccount) async {
    // Don't even open the socket with a token we already know is dead: the
    // handshake would fail and every channel would be parted with no feedback.
    if (twitchAccount.tokenData.accessToken != null && twitchAccount.tokenData.isExpired) {
      _rejectCredentials(twitchAccount);
      return;
    }

    receiver.add(ConnectionConnect(twitchAccount));
    transmitter.add(ConnectionConnect(twitchAccount));
    // Confirm with Twitch in the background — the local expiry check only
    // catches tokens we know about; a manually revoked one still needs the API.
    unawaited(validateCredentials(twitchAccount));
  }

  Future<void> stateChange(Connection connection, Change<ConnectionState> change) async {
    // final matchingChannels = channels.state.where((channel) => channel.state is ChannelStateWithConnection && (channel.state as ChannelStateWithConnection).receiver == this);
    for (final channel in channels.state) {
      channel.add(ChannelPart());
    }
    // On (re)connect, allow another larger join burst.
    _firstJoinPass = true;
  }

  Future<void> receive(Connection connection, irc.Message event) async {
    switch (event.command) {
      case '001':
        if (connection.state is ConnectionConnecting) {
          final stateTwitchAccount = (connection.state as ConnectionConnecting).twitchAccount;
          // Emit connected immediately so channel joins can start, then fetch
          // the (paginated, slow) blocked-user list in the background and fill
          // it into the live state's mutable list.
          final connectedState = ConnectionConnected(stateTwitchAccount);
          connection.emit(connectedState);
          _joinPass();
          if (stateTwitchAccount.tokenData.accessToken != null) {
            Twitch.blockedUsers(stateTwitchAccount.tokenData).then((ids) {
              connectedState.blockedUserIds.addAll(ids);
            }).catchError((_) {});
          }
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
          final channelLogin = channel.name.substring(1);
          channel.pendingHistoryCached = cache?.loadHistory(channelLogin) ?? const <String>[];
          // If the user opened this channel before we managed to JOIN, pull
          // recent-messages again now that we are actually subscribed — that
          // closes the gap between our pre-JOIN snapshot and live PRIVMSGs.
          if (channel.recentMessagesEverFetched) {
            channel.recentMessagesFetched = true;
            _backfillAfterJoin(channel);
          }
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

        // Paint cached history first using the emotes already hydrated from
        // disk at channel construction, so it shows immediately instead of
        // waiting on the network emote/badge refresh. refresh() then rebuilds
        // only if the network actually changes the emote/badge set.
        final cachedHistory = channel.pendingHistoryCached;
        if (cachedHistory.isNotEmpty) {
          channel.pendingHistoryCached = const [];
          await insertHistoryMessages(connection, cachedHistory);
        }

        await channel.refresh();
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
        // The handshake rejection arrives as `NOTICE * :Login authentication
        // failed` — target `*`, so the channel lookup below finds nothing and
        // used to drop it on the floor while the socket closed and the backoff
        // retried the same dead token forever. Catch it here instead.
        if (_isAuthFailureNotice(event)) {
          final account = connection.twitchAccount;
          if (account != null) _rejectCredentials(account);
          break;
        }

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
