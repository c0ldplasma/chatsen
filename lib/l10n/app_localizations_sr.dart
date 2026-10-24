// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Prijavljen preko $provider';
  }

  @override
  String get termsOfService => 'Uslovi Korišćenja';

  @override
  String get privacyPolicy => 'Pravila Privatnosti';

  @override
  String get settings => 'Podešavanja';

  @override
  String get expiresNever => 'Nikad ne ističe';

  @override
  String get loginExpired => 'Login expired';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch rejected the login for $login. Chat stays disconnected until you sign in again.';
  }

  @override
  String get loginFailed => 'Login failed';

  @override
  String get signInAgain => 'Sign in';

  @override
  String uploadingTo(String host) {
    return 'Uploading to $host';
  }

  @override
  String get uploadProcessing => 'Processing…';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get uploadDone => 'Uploaded';

  @override
  String get uploadRetry => 'Retry';

  @override
  String get uploadDismiss => 'Dismiss';

  @override
  String get uploadCancel => 'Cancel upload';

  @override
  String get uploadErrorOffline => 'No internet connection';

  @override
  String uploadErrorTimeout(String host) {
    return '$host is not responding';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host rejected the upload (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host sent an unexpected response';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Couldn\'t connect to $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Couldn\'t read the file';

  @override
  String uploadErrorUnknown(String host) {
    return 'Upload to $host failed';
  }

  @override
  String get uploadErrorDetails => 'Details';

  @override
  String uploadRetryingWith(String host) {
    return 'Retrying with $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Ističe za $time';
  }

  @override
  String get close => 'Zatvori';

  @override
  String get add => 'Dodaj';

  @override
  String get cancel => 'Otkaži';

  @override
  String get tokenInput => 'Unos tokena';

  @override
  String get account => 'Nalog';

  @override
  String get refreshAccount => 'Osveži nalog';

  @override
  String get removeAccount => 'Ukloni nalog';

  @override
  String get addAnotherAccount => 'Dodaj novi nalog';

  @override
  String get verifiedUserData => 'Verifikovani korisnički podaci!';

  @override
  String loggedInAs(String user) {
    return 'Prijavljen/a kao $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Greška se pojavila tokom verifikacije korisničkih podataka:';

  @override
  String get verifyingUserData => 'Verifikovanje korisničkih podataka...';

  @override
  String get verifiedUserToken => 'Verifikovan korisnički token!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Greška se pojavila tokom verifikovanja korisničkog tokena:';

  @override
  String get verifyingUserToken => 'Verifikovanje korisničkog tokena...';

  @override
  String get searchForChannels => 'Potraži kanale';

  @override
  String get recommendedChannels => 'Preporučeni kanali';

  @override
  String get popularChannels => 'Popularni kanali';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Napusti kanal';

  @override
  String joinUser(String user) {
    return 'Pridruži se $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Pravopis neispravan! Da li ste misli da potražite $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Pridruži se $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Pošalji poruku u $channel';
  }

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get appearance => 'Appearance';

  @override
  String get highContrast => 'High contrast';

  @override
  String get customCommand => 'Custom command';

  @override
  String get customCommands => 'Custom commands';

  @override
  String get newCustomCommand => 'New custom command';

  @override
  String get commandTrigger => 'Trigger';

  @override
  String get command => 'Command';

  @override
  String get save => 'Save';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get messageAppearance => 'Message appearance';

  @override
  String get showTimestamps => 'Show timestamps';

  @override
  String get compactMessages => 'Compact messages';

  @override
  String get showBadges => 'Show badges';

  @override
  String get messageTrigger => 'Message trigger';

  @override
  String get pattern => 'Pattern';

  @override
  String get mention => 'Mention';

  @override
  String get block => 'Block';

  @override
  String get enableRegex => 'Enable regex';

  @override
  String get caseSensitive => 'Case sensitive';

  @override
  String get messageTriggers => 'Message triggers';

  @override
  String get newMessageTrigger => 'New message trigger';

  @override
  String get reply => 'Reply';

  @override
  String get copyText => 'Copy text';

  @override
  String get copyTextSubtitle => 'Hold to copy message text with username';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get mentionUser => 'Mention user';

  @override
  String get copyMessageId => 'Copy message ID';

  @override
  String get theme => 'Theme';

  @override
  String get userTrigger => 'User trigger';

  @override
  String get userTriggers => 'User triggers';

  @override
  String get chatHistory => 'Chat history';

  @override
  String get login => 'Login';

  @override
  String get newUserTrigger => 'New user trigger';

  @override
  String get ban => 'Ban';

  @override
  String get unban => 'Unban';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Timeout user for $duration';
  }

  @override
  String get chatCleared => 'Chat was cleared';

  @override
  String get permabanned => 'permabanned';

  @override
  String bannedForDuration(String duration) {
    return 'banned for $duration';
  }

  @override
  String get replyingTo => 'Replying to';

  @override
  String get blockedMessage => 'Blocked message';

  @override
  String get showMessage => 'Show message';

  @override
  String get hideMessage => 'Hide message';

  @override
  String get scrollToBottom => 'Scroll to bottom';

  @override
  String get startUsingTheApp =>
      'To start using the app, add an account below.';

  @override
  String get chatSettings => 'Chat settings';

  @override
  String get autocompleteUsersWithAt => 'Autocomplete users with @';

  @override
  String get autocompleteEmotesWithColon => 'Autocomplete emotes with :';

  @override
  String get language => 'Language';

  @override
  String get locale => 'Locale';

  @override
  String get systemDefault => 'System default';

  @override
  String get justDefault => 'Default';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Someone, somewhere, will mention you someday.';

  @override
  String get backgroundNotifications => 'Background notifications';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'This option is not available on your platform.';

  @override
  String get optionNotAvailablePaywalled =>
      'This option is for ColdChat supporters only.';

  @override
  String get clearAll => 'Clear all';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get chatters => 'Chatters';

  @override
  String lastSeenAgo(String time) {
    return 'Last seen $time ago';
  }

  @override
  String get credits => 'Credits';

  @override
  String get search => 'Search';

  @override
  String get emoteMenuButton => 'Emote menu button';

  @override
  String get emoteMenuButtonGrayscale => 'Show emote menu button in grayscale';

  @override
  String get chooseEmoteMenuButton =>
      'Tap an emote to use it as the emote menu button';

  @override
  String get resetToKappa => 'Reset to Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Couldn\'t download that emote. The button wasn\'t changed.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromLibrary => 'Choose from library';

  @override
  String get cameraUnavailable =>
      'The camera couldn\'t be opened. Check that ColdChat has camera access.';
}
