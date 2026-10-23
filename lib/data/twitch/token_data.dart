import 'package:hive/hive.dart';

part 'token_data.g.dart';

@HiveType(typeId: 2)
class TokenData extends HiveObject {
  @HiveField(0)
  String? clientId;

  @HiveField(1)
  String login;

  @HiveField(2)
  List<String> scopes;

  @HiveField(3)
  String? userId;

  @HiveField(4)
  DateTime? expiresAt;

  @HiveField(5)
  String? accessToken;

  TokenData({
    required this.clientId,
    required this.login,
    required this.scopes,
    required this.userId,
    required this.expiresAt,
    required this.accessToken,
  });

  String get hash => '$userId@$clientId';

  /// Whether the access token is past (or within seconds of) its expiry.
  ///
  /// Twitch implicit-grant tokens cannot be refreshed — there is no refresh
  /// token — so an expired token means the user has to sign in again. A small
  /// grace period keeps us from starting a handshake with a token that dies
  /// mid-connection.
  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false; // never expires
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
  }
}
