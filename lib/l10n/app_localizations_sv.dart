// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get chatsen => 'ColdChat';

  @override
  String get catsen => 'Catsen';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Inloggad via $provider';
  }

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get settings => 'Inställningar';

  @override
  String get expiresNever => 'Går aldrig ut';

  @override
  String get loginExpired => 'Login expired';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch rejected the login for $login. Chat stays disconnected until you sign in again.';
  }

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
    return 'Upphör att gälla om $time';
  }

  @override
  String get close => 'Stäng';

  @override
  String get add => 'Lägg till';

  @override
  String get cancel => 'Avbryt';

  @override
  String get tokenInput => 'Tokeninmatning';

  @override
  String get account => 'Konto';

  @override
  String get refreshAccount => 'Uppdatera konto';

  @override
  String get removeAccount => 'Ta bort konto';

  @override
  String get addAnotherAccount => 'Lägg till annat konto';

  @override
  String get verifiedUserData => 'Verifierad användardata!';

  @override
  String loggedInAs(String user) {
    return 'Inloggad som $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Ett fel har uppstått vid verifiering av användardata:';

  @override
  String get verifyingUserData => 'Veriferar användardata...';

  @override
  String get verifiedUserToken => 'Veriferar användar-token!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Ett fel har uppstått med veriferiring vid användar-token:';

  @override
  String get verifyingUserToken => 'Veriferar använder-token...';

  @override
  String get searchForChannels => 'Söker efter kanaler';

  @override
  String get recommendedChannels => 'Rekommenderad kanaler';

  @override
  String get popularChannels => 'Populära kanaler';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Lämna Kanal';

  @override
  String joinUser(String user) {
    return 'Användare $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Stavningsfel misslyckades! Menade du att söka efter $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Delta $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Skicka meddelande i $channel';
  }

  @override
  String get light => 'Ljus';

  @override
  String get dark => 'Mörk';

  @override
  String get system => 'System';

  @override
  String get appearance => 'Utseende';

  @override
  String get highContrast => 'Hög kontrast';

  @override
  String get customCommand => 'Anpassat kommando';

  @override
  String get customCommands => 'Anpassade kommandon';

  @override
  String get newCustomCommand => 'Nytt anpassat kommando';

  @override
  String get commandTrigger => 'Utlösare';

  @override
  String get command => 'Kommandot';

  @override
  String get save => 'Spara';

  @override
  String get openInBrowser => 'Öppna i webbläsare';

  @override
  String get messageAppearance => 'Meddelandets utseende';

  @override
  String get showTimestamps => 'Visa tidsstämpel';

  @override
  String get compactMessages => 'Kompakta meddelanden';

  @override
  String get showBadges => 'Show badges';

  @override
  String get messageTrigger => 'Meddelande utlösare';

  @override
  String get pattern => 'Mönster';

  @override
  String get mention => 'Omnämnande';

  @override
  String get block => 'Blockera';

  @override
  String get enableRegex => 'Aktivera regex';

  @override
  String get caseSensitive => 'Skiftlägeskänslighet';

  @override
  String get messageTriggers => 'Meddelande utlösare';

  @override
  String get newMessageTrigger => 'Nytt meddelande utlösare';

  @override
  String get reply => 'Svara';

  @override
  String get copyText => 'Kopiera text';

  @override
  String get copyTextSubtitle =>
      'Håll för att kopiera meddelandetext med användarnamn';

  @override
  String get deleteMessage => 'Radera meddelande';

  @override
  String get mentionUser => 'Nämn användare';

  @override
  String get copyMessageId => 'Kopiera meddelande-ID';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Utlösare för användare';

  @override
  String get userTriggers => 'Utlösare för användare';

  @override
  String get chatHistory => 'Chatthistorik';

  @override
  String get login => 'Logga in';

  @override
  String get newUserTrigger => 'Ny utlösare för användare';

  @override
  String get ban => 'Bannlys';

  @override
  String get unban => 'Unbanna';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Timeout-användare för $duration';
  }

  @override
  String get chatCleared => 'Chatten var rensad';

  @override
  String get permabanned => 'permabannad';

  @override
  String bannedForDuration(String duration) {
    return 'bannlyst för $duration';
  }

  @override
  String get replyingTo => 'Svarar på';

  @override
  String get blockedMessage => 'Blockerat meddelande';

  @override
  String get showMessage => 'Visa meddelandet';

  @override
  String get hideMessage => 'Dölj meddelanden';

  @override
  String get scrollToBottom => 'Skrolla till botten';

  @override
  String get startUsingTheApp =>
      'För att börja använda appen, lägg till ett konto nedan.';

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
