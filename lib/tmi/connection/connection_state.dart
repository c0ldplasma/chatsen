import 'package:equatable/equatable.dart';

import '/data/twitch_account.dart';

abstract class ConnectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectionDisconnected extends ConnectionState {}

abstract class ConnectionStateWithCredentials extends ConnectionState {
  final TwitchAccount twitchAccount;

  ConnectionStateWithCredentials(this.twitchAccount);

  @override
  List<Object?> get props => [twitchAccount, ...super.props];
}

class ConnectionConnecting extends ConnectionStateWithCredentials {
  ConnectionConnecting(TwitchAccount credentials) : super(credentials);
}

class ConnectionConnected extends ConnectionStateWithCredentials {
  // Mutable so the (paginated, potentially slow) blocked-user fetch can be
  // populated in the background after the connected state is emitted, without
  // blocking channel joins on it. Not part of Equatable props.
  List<String> blockedUserIds;

  ConnectionConnected(
    TwitchAccount credentials, {
    List<String>? blockedUserIds,
  })  : blockedUserIds = blockedUserIds ?? [],
        super(credentials);
}

class ConnectionReconnecting extends ConnectionStateWithCredentials {
  ConnectionReconnecting(TwitchAccount credentials) : super(credentials);
}

class ConnectionBanned extends ConnectionStateWithCredentials {
  ConnectionBanned(TwitchAccount credentials) : super(credentials);
}

class ConnectionInvalidCredentials extends ConnectionStateWithCredentials {
  ConnectionInvalidCredentials(TwitchAccount credentials) : super(credentials);
}
