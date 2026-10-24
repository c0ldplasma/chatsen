// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get chatsen => 'ColdChat';

  @override
  String get catsen => 'Catsen';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Συνδέθηκε μέσω $provider';
  }

  @override
  String get termsOfService => 'Όροι Χρήσης';

  @override
  String get privacyPolicy => 'Πολιτική Απορρήτου';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get expiresNever => 'Δεν λήγει ποτέ';

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
    return 'Λήγει σε $time';
  }

  @override
  String get close => 'Κλείσιμο';

  @override
  String get add => 'Προσθήκη';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get tokenInput => 'Εισαγωγή token';

  @override
  String get account => 'Λογαριασμός';

  @override
  String get refreshAccount => 'Ανανέωση λογαριασμού';

  @override
  String get removeAccount => 'Αφαίρεση λογαριασμού';

  @override
  String get addAnotherAccount => 'Προσθήκη άλλου λογαριασμού';

  @override
  String get verifiedUserData => 'Επαληθεύτηκαν τα δεδομένα χρήστη!';

  @override
  String loggedInAs(String user) {
    return 'Συνδεθήκατε ως $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Παρουσιάστηκε ένα σφάλμα κατά την επαλήθευση δεδομένων χρήστη:';

  @override
  String get verifyingUserData => 'Επαλήθευση δεδομένων χρήστη...';

  @override
  String get verifiedUserToken => 'Επαληθεύτηκε το token χρήστη!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Παρουσιάστηκε ένα σφάλμα κατά την επαλήθευση του token χρήστη:';

  @override
  String get verifyingUserToken => 'Επαλήθευση token χρήστη...';

  @override
  String get searchForChannels => 'Αναζήτηση για κανάλια';

  @override
  String get recommendedChannels => 'Προτεινόμενα κανάλια';

  @override
  String get popularChannels => 'Δημοφιλή κανάλια';

  @override
  String get channel => 'Κανάλι';

  @override
  String get leaveChannel => 'Αποχώρηση από κανάλι';

  @override
  String joinUser(String user) {
    return 'Συμμετοχή στο $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Ο ορθογραφικός έλεγχος απέτυχε! Μήπως εννοούσατε να αναζητήσετε για $username;';
  }

  @override
  String joinChannelName(String channel) {
    return 'Συμμετοχή στο $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Στείλτε μήνυμα στο $channel';
  }

  @override
  String get light => 'Φωτεινή';

  @override
  String get dark => 'Σκοτεινή';

  @override
  String get system => 'Συστήματος';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get highContrast => 'Υψηλή αντίθεση';

  @override
  String get customCommand => 'Προσαρμοσμένη εντολή';

  @override
  String get customCommands => 'Προσαρμοσμένες εντολές';

  @override
  String get newCustomCommand => 'Νέα προσαρμοσμένη εντολή';

  @override
  String get commandTrigger => 'Συντόμευση';

  @override
  String get command => 'Εντολή';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get openInBrowser => 'Άνοιγμα στον περιηγητή';

  @override
  String get messageAppearance => 'Εμφάνιση μηνύματος';

  @override
  String get showTimestamps => 'Εμφάνιση χρονικών σημείων';

  @override
  String get compactMessages => 'Συμπιεσμένα μηνύματα';

  @override
  String get showBadges => 'Show badges';

  @override
  String get messageTrigger => 'Συντόμευση μηνύματος';

  @override
  String get pattern => 'Μοτίβο';

  @override
  String get mention => 'Επισήμανση';

  @override
  String get block => 'Μπλοκ';

  @override
  String get enableRegex => 'Ενεργοποίηση regex';

  @override
  String get caseSensitive => 'Διάκριση πεζών-κεφαλαίων';

  @override
  String get messageTriggers => 'Συντομεύσεις μηνύματος';

  @override
  String get newMessageTrigger => 'Νέα συντόμευση μηνύματος';

  @override
  String get reply => 'Απάντηση';

  @override
  String get copyText => 'Αντιγραφή κειμένου';

  @override
  String get copyTextSubtitle =>
      'Κρατήστε για αντιγραφή κειμένου μηνύματος με όνομα χρήστη';

  @override
  String get deleteMessage => 'Διαγραφή μηνύματος';

  @override
  String get mentionUser => 'Επισήμανση χρήστη';

  @override
  String get copyMessageId => 'Αντιγραφή ID μηνύματος';

  @override
  String get theme => 'Θέμα';

  @override
  String get userTrigger => 'Συντόμευση χρήστη';

  @override
  String get userTriggers => 'Συντομεύσεις χρήστη';

  @override
  String get chatHistory => 'Ιστορικό συνομιλίας';

  @override
  String get login => 'Σύνδεση';

  @override
  String get newUserTrigger => 'Νέα συντόμευση χρήστη';

  @override
  String get ban => 'Αποκλεισμός';

  @override
  String get unban => 'Άρση αποκλεισμού';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Timeout χρήστη για $duration';
  }

  @override
  String get chatCleared => 'Η συνομιλία εκκαθαρίστηκε';

  @override
  String get permabanned => 'μόνιμα αποκλεισμένος';

  @override
  String bannedForDuration(String duration) {
    return 'αποκλείστηκε για $duration';
  }

  @override
  String get replyingTo => 'Απάντηση σε';

  @override
  String get blockedMessage => 'Μπλοκαρισμένο μήνυμα';

  @override
  String get showMessage => 'Εμφάνιση μηνύματος';

  @override
  String get hideMessage => 'Απόκρυψη μηνύματος';

  @override
  String get scrollToBottom => 'Κύλιση προς τα κάτω';

  @override
  String get startUsingTheApp =>
      'Για να ξεκινήσετε να χρησιμοποιείτε την εφαρμογή, προσθέστε έναν λογαριασμό παρακάτω.';

  @override
  String get chatSettings => 'Ρυθμίσεις συνομιλίας';

  @override
  String get autocompleteUsersWithAt => 'Αυτόματη συμπλήρωση χρηστών με @';

  @override
  String get autocompleteEmotesWithColon => 'Αυτόματη συμπλήρωση emote με :';

  @override
  String get language => 'Γλώσσα';

  @override
  String get locale => 'Γλωσσικές Ρυθμίσεις';

  @override
  String get systemDefault => 'Προεπιλογή συστήματος';

  @override
  String get justDefault => 'Προεπιλεγμένη';

  @override
  String get notifications => 'Ειδοποιήσεις';

  @override
  String get noNotifications => 'Κάποιος, κάπου, θα σας αναφέρει κάποια μέρα.';

  @override
  String get backgroundNotifications => 'Ειδοποιήσεις παρασκηνίου';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Αυτή η επιλογή δεν είναι διαθέσιμη στην πλατφόρμα σας.';

  @override
  String get optionNotAvailablePaywalled =>
      'Αυτή η επιλογή είναι μόνο για υποστηρικτές του ColdChat.';

  @override
  String get clearAll => 'Εκκαθάριση όλων';

  @override
  String get cache => 'Προσωρινή μνήμη';

  @override
  String get clearCache => 'Εκκαθάριση προσωρινής μνήμης';

  @override
  String get chatters => 'Συνομιλητές';

  @override
  String lastSeenAgo(String time) {
    return 'Τελευταία εμφάνιση $time πριν';
  }

  @override
  String get credits => 'Συντελεστές';

  @override
  String get search => 'Αναζήτηση';

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
