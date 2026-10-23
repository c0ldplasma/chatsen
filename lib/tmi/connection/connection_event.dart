import 'package:equatable/equatable.dart';

import '/data/twitch_account.dart';

class ConnectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectionConnect extends ConnectionEvent {
  final TwitchAccount twitchAccount;

  ConnectionConnect(this.twitchAccount);

  @override
  List<Object?> get props => [twitchAccount, ...super.props];
}

class ConnectionDisconnect extends ConnectionEvent {}

/// The account's access token is no longer usable (expired locally, rejected by
/// /oauth2/validate, or refused by TMI during the handshake). Puts the
/// connection into [ConnectionInvalidCredentials] and stops the reconnect loop:
/// retrying a dead token can only fail again, and Twitch has no refresh token
/// for the implicit-grant flow, so only a fresh sign-in can recover.
class ConnectionCredentialsRejected extends ConnectionEvent {
  final TwitchAccount twitchAccount;

  ConnectionCredentialsRejected(this.twitchAccount);

  @override
  List<Object?> get props => [twitchAccount, ...super.props];
}

class ConnectionReconnect extends ConnectionEvent {
  final TwitchAccount? twitchAccount;

  ConnectionReconnect({
    this.twitchAccount,
  });

  @override
  List<Object?> get props => [twitchAccount, ...super.props];
}
