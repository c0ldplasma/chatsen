import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:chatsen/tmi/channel/channel_chatters.dart';

import '/api/chatsen/chatsen.dart';
import '/data/custom_badge.dart';
import '/data/emote.dart';
import '../cache.dart';
import '../client/client.dart';
import '../emotes.dart';
import '/tmi/channel/channel_event.dart';
import '/tmi/channel/channel_message.dart';
import '/tmi/channel/channel_messages.dart';
import '/tmi/channel/channel_state.dart';
import '/tmi/channel/messages/channel_message_event.dart';
import '/tmi/channel/messages/channel_message_state_change.dart';
import '/providers/badge_provider.dart';
import '/providers/emote_provider.dart';
import '/tmi/badges.dart';
import '/tmi/channel/channel_info.dart';
import 'messages/channel_message_chat.dart';

class Channel extends Bloc<ChannelEvent, ChannelState> {
  Client client;
  String? id;
  String name;
  Timer? suspensionTimer;
  ChannelMessages channelMessages = ChannelMessages();
  List<String> pendingHistoryCached = const [];
  bool recentMessagesFetched = false;
  bool recentMessagesEverFetched = false;
  bool joinPriority = false;
  bool joinBackfillDone = false;
  Emotes channelEmotes = Emotes();
  Badges channelBadges = Badges();
  ChannelInfo channelInfo = ChannelInfo();
  ChannelChatters channelChatters = ChannelChatters();

  // O(1) lookup maps for message building, rebuilt lazily and invalidated when
  // the underlying emote/badge sets change. Avoids concatenating the channel +
  // global lists and linear-scanning them for every word of every message.
  Map<String, Emote>? _emoteLookup;
  Map<String, CustomBadge>? _badgeLookup;
  StreamSubscription? _channelEmotesSub;
  StreamSubscription? _channelBadgesSub;
  StreamSubscription? _globalEmotesSub;
  StreamSubscription? _globalBadgesSub;

  // Global emotes/badges take lower precedence than channel ones (a channel
  // emote with the same code wins), matching the previous channel-first
  // concatenation + firstWhere behavior.
  Map<String, Emote> get emoteLookup {
    final cached = _emoteLookup;
    if (cached != null) return cached;
    final map = <String, Emote>{};
    for (final e in client.globalEmotes.state) {
      map[e.code ?? e.name] = e;
    }
    for (final e in channelEmotes.state) {
      map[e.code ?? e.name] = e;
    }
    return _emoteLookup = map;
  }

  Map<String, CustomBadge> get badgeLookup {
    final cached = _badgeLookup;
    if (cached != null) return cached;
    final map = <String, CustomBadge>{};
    for (final b in client.globalBadges.state) {
      map[b.id] = b;
    }
    for (final b in channelBadges.state) {
      map[b.id] = b;
    }
    return _badgeLookup = map;
  }

  Channel({
    required this.client,
    required this.name,
  }) : super(ChannelDisconnected()) {
    _channelEmotesSub = channelEmotes.stream.listen((_) => _emoteLookup = null);
    _channelBadgesSub = channelBadges.stream.listen((_) => _badgeLookup = null);
    _globalEmotesSub = client.globalEmotes.stream.listen((_) => _emoteLookup = null);
    _globalBadgesSub = client.globalBadges.stream.listen((_) => _badgeLookup = null);
    // Hydrate channel emotes/badges from disk immediately on construction —
    // keyed by channel login, which (unlike the room id) is known before
    // ROOMSTATE arrives. This ensures history messages built early (e.g. via
    // the chat view's eager recent-messages fetch) already resolve third
    // party emotes instead of rendering them as plain text until the network
    // refresh lands.
    _hydrateFromCache();

    on<ChannelJoin>((event, emit) async {
      emit(ChannelConnecting(receiver: event.receiver, transmitter: event.transmitter));
    });

    on<ChannelPart>((event, emit) async {
      // Reset the lazy-fetch + post-join-backfill latches so the next JOIN
      // pulls fresh recent-messages instead of trusting the snapshot we
      // already drained before the disconnect.
      recentMessagesFetched = false;
      joinBackfillDone = false;
      emit(ChannelDisconnected());
    });

    on<ChannelConnect>((event, emit) async {
      if (state is! ChannelStateWithConnection) {
        return;
      }

      final realState = state as ChannelStateWithConnection;
      emit(ChannelConnected(receiver: realState.receiver, transmitter: realState.transmitter));
    });

    on<ChannelBan>((event, emit) async {
      if (state is! ChannelStateWithConnection) {
        return;
      }

      final realState = state as ChannelStateWithConnection;
      emit(ChannelBanned(receiver: realState.receiver, transmitter: realState.transmitter));
    });

    on<ChannelTimeout>((event, emit) async {
      if (state is! ChannelStateWithConnection) {
        return;
      }

      final realState = state as ChannelStateWithConnection;
      emit(ChannelBanned(receiver: realState.receiver, transmitter: realState.transmitter));
      suspensionTimer = Timer(event.duration, () {
        emit(realState);
      });
      // emit(ChannelConnected(receiver: realState.receiver, transmitter: realState.transmitter));
    });

    on<ChannelSuspend>((event, emit) async {
      if (state is! ChannelStateWithConnection) {
        return;
      }

      final realState = state as ChannelStateWithConnection;
      emit(ChannelSuspended(receiver: realState.receiver, transmitter: realState.transmitter));
    });
  }

  @override
  Future<void> close() {
    _channelEmotesSub?.cancel();
    _channelBadgesSub?.cancel();
    _globalEmotesSub?.cancel();
    _globalBadgesSub?.cancel();
    return super.close();
  }

  ChannelMessage? _currentStatusMessage;

  void _replaceStatusMessage(ChannelMessage message) {
    final previous = _currentStatusMessage;
    _currentStatusMessage = message;
    channelMessages.replace(previous, message);
  }

  @override
  void onEvent(ChannelEvent event) {
    // ChannelMessageEvent renders as an empty Container in the chat view, so
    // swapping the current status line for an event would briefly collapse
    // the status row to zero height and cause a visible jump. Skip event
    // entries entirely — the resulting state change below is what we show.
    super.onEvent(event);
  }

  @override
  void onChange(Change<ChannelState> change) {
    suspensionTimer?.cancel();
    suspensionTimer = null;

    _replaceStatusMessage(ChannelMessageStateChange(channel: this, change: change, dateTime: DateTime.now()));
    super.onChange(change);
  }

  Future<void> send(
    String message, {
    Map<String, String>? tags,
  }) async {
    if (state is! ChannelStateWithConnection) {
      return;
    }

    if (tags?.isEmpty == true) tags = null;

    var ircMessageToSend = 'PRIVMSG $name :$message';
    if (tags != null) {
      ircMessageToSend = '@${tags.entries.map((entry) => '${entry.key}=${entry.value}').join(';')} $ircMessageToSend';
    }

    final replacement = String.fromCharCodes(Runes('\u{e0002}'));
    final zeroWidthJoiner = String.fromCharCodes(Runes('\u{200d}'));
    message = message.replaceAll(replacement, zeroWidthJoiner);

    final realState = state as ChannelStateWithConnection;
    realState.transmitter.send(ircMessageToSend);
  }

  Future<void> refresh() async {
    // Capture the signature BEFORE hydrating: messages may have already been
    // built against an empty emote set (e.g. the chat view eagerly inserts
    // history before ROOMSTATE). If we sampled after hydrate, an empty->cache
    // jump would be invisible and — when the network returns the same set as
    // the cache — the rebuild would be skipped, leaving those early messages
    // showing emote codes as plain text.
    final before = _emoteBadgeSignature();

    _hydrateFromCache();

    final emotesFuture = refreshEmotes();
    final badgesFuture = refreshBadges();
    final refreshChannelFuture = refreshChannelUser();
    final refreshChattersFuture = refreshChannelChatters();

    await Future.wait([emotesFuture, badgesFuture]);

    if (_emoteBadgeSignature() != before) {
      await _rebuildMessages();
    }

    await Future.wait([refreshChannelFuture, refreshChattersFuture]);
  }

  String _emoteBadgeSignature() {
    final emotes = channelEmotes.state.map((e) => e.id).join(',');
    final badges = channelBadges.state.map((b) => b.id).join(',');
    return '${channelEmotes.state.length}:$emotes|${channelBadges.state.length}:$badges';
  }

  // Rebuild already-rendered chat messages in small batches, yielding to the
  // event loop between them so a large backlog doesn't block scrolling for a
  // second or two while emote/badge data is reapplied.
  Future<void> _rebuildMessages() async {
    final messages = channelMessages.state.whereType<ChannelMessageChat>().toList();
    var processed = 0;
    for (final message in messages) {
      message.build();
      if (++processed % 20 == 0) await Future.delayed(Duration.zero);
    }
    channelMessages.emit([...channelMessages.state]);
  }

  Future<void> refreshEmotes() async {
    if (id == null) throw 'invalid channel id';

    final emoteProviders = client.providers.whereType<EmoteProvider>();
    final results = await Future.wait(
      emoteProviders.map((emoteProvider) async {
        try {
          return await emoteProvider.channelEmotes(id!);
        } catch (e) {
          log('Couldn\'t get ${emoteProvider.name} channel emotes for $name ($id)');
          return <Emote>[];
        }
      }),
    );

    final merged = [for (final list in results) ...list];
    channelEmotes.emit(merged);
    final cache = client.cache;
    if (cache != null) cache.saveEmotes(cache.channelEmotesKey(_cacheKey), merged);
  }

  Future<void> refreshBadges() async {
    if (id == null) throw 'invalid channel id';

    final badgeProviders = client.providers.whereType<BadgeProvider>();
    final results = await Future.wait(
      badgeProviders.map((badgeProvider) async {
        try {
          return await badgeProvider.channelBadges(id!);
        } catch (e) {
          log('Couldn\'t get ${badgeProvider.name} channel badges for $name ($id)');
          return <CustomBadge>[];
        }
      }),
    );

    final merged = [for (final list in results) ...list];
    channelBadges.emit(merged);
    final cache = client.cache;
    if (cache != null) cache.saveBadges(cache.channelBadgesKey(_cacheKey), merged);
  }

  String get _cacheKey => name.replaceFirst('#', '').toLowerCase();

  void _hydrateFromCache() {
    final cache = client.cache;
    if (cache == null) return;
    if (channelEmotes.state.isEmpty) {
      final cached = cache.loadEmotes(cache.channelEmotesKey(_cacheKey));
      if (cached.isNotEmpty) channelEmotes.emit(cached);
    }
    if (channelBadges.state.isEmpty) {
      final cached = cache.loadBadges(cache.channelBadgesKey(_cacheKey));
      if (cached.isNotEmpty) channelBadges.emit(cached);
    }
  }

  Future<void> refreshChannelUser() async {
    try {
      channelInfo.emit(await Chatsen.user(name.replaceFirst('#', '')));
    } catch (e) {
      log('Couldn\'t get channel info for $name');
    }
  }

  Future<void> refreshChannelChatters() async {
    try {
      channelChatters.emit((await Chatsen.userWithViewers(name.replaceFirst('#', ''))).channel?.chatters);
    } catch (e) {
      log('Couldn\'t get channel chatters for $name');
    }
  }
}
