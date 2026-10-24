import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/io.dart';

import '../../data/twitch_account.dart';
import '/irc/message.dart' as irc;
import 'connection_event.dart';
import '/tmi/log.dart';
import '/tmi/logs.dart';
import 'connection_state.dart';

class Connection extends Bloc<ConnectionEvent, ConnectionState> {
  IOWebSocketChannel? channel;
  StreamSubscription<dynamic>? subscription;
  Function(Connection connection, ConnectionEvent event)? onEventTrigger;
  Function(Connection connection, Change<ConnectionState> change)? onStateChange;
  Function(Connection connection, irc.Message event)? onReceive;
  TwitchAccount? get twitchAccount => (state is ConnectionStateWithCredentials) ? (state as ConnectionStateWithCredentials).twitchAccount : null;
  Logs logs = Logs();

  @override
  void onEvent(ConnectionEvent event) {
    logs.add(Log(data: event));
    onEventTrigger?.call(this, event);
    super.onEvent(event);
  }

  @override
  void onChange(Change<ConnectionState> change) {
    logs.add(Log(data: change));
    onStateChange?.call(this, change);
    super.onChange(change);
  }

  Connection() : super(ConnectionDisconnected()) {
    on<ConnectionConnect>((event, emit) async {
      _lastAccount = event.twitchAccount;
      // A connect with (presumably) fresh credentials clears the auth lock so
      // the watchdog and the backoff can do their job again.
      _credentialsRejected = false;
      emit(ConnectionConnecting(event.twitchAccount));
      await connect(
        nick: event.twitchAccount.tokenData.login,
        pass: event.twitchAccount.tokenData.accessToken != null ? 'oauth:${event.twitchAccount.tokenData.accessToken}' : null,
      );
    });

    on<ConnectionEstablished>((event, emit) => emit(event.state));

    on<ConnectionDisconnect>((event, emit) async {
      await close();
      emit(ConnectionDisconnected());
    });

    on<ConnectionReconnect>((event, emit) async {
      // Never reconnect with credentials Twitch already refused — that is the
      // endless silent retry loop that made an expired login look like a dead
      // chat. Only an explicit ConnectionConnect (i.e. after re-login) resumes.
      if (_credentialsRejected && event.twitchAccount == null) return;
      // Fall back to the last account we connected with so a reconnect still
      // fires even from ConnectionDisconnected (the old guard silently dropped
      // it, leaving the chat stuck forever).
      final account = event.twitchAccount ?? _lastAccount ?? (state is ConnectionStateWithCredentials ? (state as ConnectionStateWithCredentials).twitchAccount : null);
      if (account == null) return;
      add(ConnectionConnect(account));
    });

    on<ConnectionCredentialsRejected>((event, emit) async {
      _credentialsRejected = true;
      _lastAccount = event.twitchAccount;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connectStartedAt = null;
      await cancel();
      emit(ConnectionInvalidCredentials(event.twitchAccount));
    });

    _startWatchdog();
  }

  Future<void> connect({
    String? nick,
    String? pass,
  }) async {
    // Kill any pending backoff reconnect. While the app is suspended iOS freezes
    // the backoff timer; on resume it would thaw and fire a second reconnect
    // that tears down the one we are establishing here, restarting the
    // handshake and making coming back from background feel slow.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectStartedAt = DateTime.now();
    _lastInbound = null;
    _lastPingSentAt = null;
    await cancel();
    channel = IOWebSocketChannel.connect(Uri.parse('wss://irc-ws.chat.twitch.tv:443'));

    subscription = channel?.stream.listen(
      (event) async {
        for (final singleEvent in event.trim().split('\r\n').where((String singleEvent) => singleEvent.isNotEmpty).map((String singleEvent) => singleEvent.trim())) {
          final message = irc.Message.fromEvent(singleEvent);
          receive(message);
        }
      },
      onDone: () => _scheduleReconnect(),
      onError: (error) => _scheduleReconnect(),
      // cancelOnError: true,
    );

    send('CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership');
    if (pass != null) send('PASS $pass');
    send('NICK ${nick ?? 'justinfan6969'}');
  }

  Future<void> send(String message) async {
    try {
      if (channel == null) throw 'not connected';
      logs.add(Log(data: irc.Message.fromEvent(message), outgoing: true));
      channel?.sink.add(message);
    } catch (e) {
      logs.add(Log(data: e));
    }
  }

  // Reconnect backoff: 1, 2, 4, 8, 16s. Reset as soon as any line is received
  // (the socket is alive again). The old 4s fixed delay made coming back from a
  // long background feel slow; the first retry now fires after ~1s. Held in a
  // cancellable timer so connect() (e.g. the forced reconnect on app resume)
  // can pre-empt a frozen/pending backoff instead of racing it.
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Set once the token was refused; blocks the automatic retry paths (socket
  /// close, handshake timeout, liveness watchdog) until a re-login arrives.
  bool _credentialsRejected = false;

  bool get credentialsRejected => _credentialsRejected;

  void _scheduleReconnect() {
    if (_credentialsRejected) return;
    _reconnectTimer?.cancel();
    final seconds = (1 << _reconnectAttempts).clamp(1, 16);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () => add(ConnectionReconnect()));
  }

  // Liveness watchdog. Mobile sockets routinely go half-open (lock screen /
  // pocket suspend, Wi-Fi<->cellular handoff, NAT timeout): the TCP is dead but
  // no FIN/RST arrives, so onDone/onError never fire and the reconnect backoff
  // never starts. Likewise a connect() after wake can open a socket that never
  // receives 001 and never closes, stranding the state at ConnectionConnecting
  // with every channel parted to ChannelDisconnected. This periodic check is
  // the catch-all that detects both and forces a reconnect — and because iOS
  // freezes timers while suspended, it also fires within ~5s of any wake.
  TwitchAccount? _lastAccount;
  DateTime? _connectStartedAt;
  DateTime? _lastInbound;
  DateTime? _lastPingSentAt;
  Timer? _watchdog;

  static const Duration _handshakeTimeout = Duration(seconds: 8);
  static const Duration _inboundTimeout = Duration(seconds: 70);
  static const Duration _pingInterval = Duration(seconds: 60);

  bool get isConnected => state is ConnectionConnected;

  /// Actively check the socket is alive: send a PING and wait briefly for any
  /// inbound line (Twitch answers with PONG almost immediately). This avoids
  /// the false "stale" verdict that silence alone gives — a quiet channel can
  /// legitimately receive nothing for a minute, so absence of traffic is not
  /// proof the socket is dead. A genuinely dead socket produces no reply and we
  /// report not-alive so the caller can reconnect.
  Future<bool> probeAlive({Duration timeout = const Duration(seconds: 3)}) async {
    if (state is! ConnectionConnected) return false;
    final before = _lastInbound;
    send('PING :tmi.twitch.tv');
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (_lastInbound != before) return true;
    }
    return false;
  }

  void forceReconnect() => add(ConnectionReconnect());

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) => _checkLiveness());
  }

  void _checkLiveness() {
    if (isClosed) return;
    if (_credentialsRejected) return;
    final now = DateTime.now();
    if (state is ConnectionConnecting) {
      final started = _connectStartedAt;
      if (started != null && now.difference(started) > _handshakeTimeout) {
        add(ConnectionReconnect());
      }
      return;
    }
    if (state is ConnectionConnected) {
      final last = _lastInbound ?? _connectStartedAt;
      if (last == null) return;
      if (now.difference(last) > _inboundTimeout) {
        add(ConnectionReconnect());
        return;
      }
      // Proactively PING so a dead socket surfaces fast (no inbound -> timeout)
      // instead of waiting up to ~5min for Twitch's own keepalive.
      final lastPing = _lastPingSentAt;
      if (now.difference(last) > _pingInterval && (lastPing == null || now.difference(lastPing) > _pingInterval)) {
        _lastPingSentAt = now;
        send('PING :tmi.twitch.tv');
      }
    }
  }

  Future<void> receive(irc.Message event) async {
    try {
      _reconnectAttempts = 0;
      _lastInbound = DateTime.now();
      logs.add(Log(data: event));
      onReceive?.call(this, event);
      if (event.command == 'PING') {
        await send('PONG :${event.parameters.join(' ')}');
      }
    } catch (e) {
      logs.add(Log(data: e));
    }
  }

  Future<void> cancel() async {
    final oldSubscription = subscription;
    final oldChannel = channel;
    subscription = null;
    channel = null;
    try {
      await oldSubscription?.cancel();
    } catch (_) {}
    // Do NOT await the close: a dead/half-open socket (lock-screen suspend,
    // network handoff) can make sink.close() hang forever. Because the bloc
    // processes events sequentially, an awaited close here would freeze the
    // ConnectionConnect handler and every queued reconnect with it, leaving the
    // chat stuck on ChannelDisconnected. Fire-and-forget instead.
    if (oldChannel != null) unawaited(oldChannel.sink.close().catchError((_) {}));
  }

  @override
  Future<void> close() {
    _watchdog?.cancel();
    _reconnectTimer?.cancel();
    return super.close();
  }
}
