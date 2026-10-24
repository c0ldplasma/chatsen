import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/io.dart';

/// A BetterTTV Pro user's badge, or `null` url when they don't show one.
class BetterTTVProBadge {
  final String userId;
  final String? url;

  BetterTTVProBadge({required this.userId, required this.url});
}

/// Listens to the BetterTTV socket for Pro badges. BetterTTV has no REST
/// endpoint for these: a Pro user's client announces itself when it opens a
/// channel, and the server relays that to everyone listening on the channel.
class BetterTTVSocket {
  final void Function(BetterTTVProBadge badge) onLookupUser;

  BetterTTVSocket({required this.onLookupUser});

  final Set<String> _roomIds = {};
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  void join(String roomId) {
    if (!_roomIds.add(roomId)) return;
    if (_channel == null) {
      _connect();
    } else {
      _send('join_channel', {'name': 'twitch:$roomId'});
    }
  }

  void part(String roomId) {
    if (!_roomIds.remove(roomId)) return;
    _send('part_channel', {'name': 'twitch:$roomId'});
  }

  /// Drop the connection and open a new one. iOS can leave a suspended
  /// socket half-open without ever reporting it, so call this on resume.
  void reconnect() {
    if (_roomIds.isEmpty) return;
    _close();
    _connect();
  }

  void _connect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final channel = IOWebSocketChannel.connect(Uri.parse('wss://sockets.betterttv.net/ws'));
    _channel = channel;
    _subscription = channel.stream.listen(
      _receive,
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: true,
    );
    for (final roomId in _roomIds) {
      _send('join_channel', {'name': 'twitch:$roomId'});
    }
  }

  void _close() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _scheduleReconnect() {
    _close();
    if (_roomIds.isEmpty || _reconnectTimer != null) return;
    final seconds = (1 << _reconnectAttempts).clamp(1, 60);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _connect);
  }

  void _send(String name, Map<String, dynamic> data) {
    _channel?.sink.add(json.encode({'name': name, 'data': data}));
  }

  void _receive(dynamic raw) {
    _reconnectAttempts = 0;
    try {
      final event = json.decode(raw as String);
      if (event['name'] != 'lookup_user') return;
      final data = event['data'] as Map<String, dynamic>;
      final userId = data['providerId'] as String?;
      if (userId == null) return;
      final badge = data['badge'];
      onLookupUser(BetterTTVProBadge(userId: userId, url: badge is Map ? badge['url'] as String? : null));
    } catch (e) {
      log('Couldn\'t parse a BetterTTV socket event: $e');
    }
  }
}
