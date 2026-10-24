/// A Twitch user from Helix `GET /users`.
class TwitchUser {
  final String id;
  final String login;
  final String displayName;
  final String profileImageUrl;
  final String? offlineImageUrl;

  TwitchUser({
    required this.id,
    required this.login,
    required this.displayName,
    required this.profileImageUrl,
    required this.offlineImageUrl,
  });

  factory TwitchUser.fromJson(Map<String, dynamic> json) => TwitchUser(
        id: json['id'] as String,
        login: json['login'] as String,
        displayName: json['display_name'] as String,
        profileImageUrl: json['profile_image_url'] as String,
        offlineImageUrl: (json['offline_image_url'] as String?)?.isEmpty ?? true ? null : json['offline_image_url'] as String,
      );
}

/// A channel's live stream from Helix `GET /streams`.
class TwitchLiveStream {
  final String title;
  final String gameName;
  final String? gameBoxArtUrl;
  final String thumbnailUrl;
  final int viewerCount;
  final DateTime startedAt;

  TwitchLiveStream({
    required this.title,
    required this.gameName,
    required this.gameBoxArtUrl,
    required this.thumbnailUrl,
    required this.viewerCount,
    required this.startedAt,
  });
}

/// What the user card and the channel header show about a user.
class TwitchProfile {
  final TwitchUser user;

  /// Null when Twitch didn't report it.
  final int? followerCount;

  /// Null when the user isn't live.
  final TwitchLiveStream? stream;

  TwitchProfile({
    required this.user,
    required this.followerCount,
    required this.stream,
  });
}
