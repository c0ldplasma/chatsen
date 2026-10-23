// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get chatsen => 'ColdChat';

  @override
  String get catsen => 'Catsen';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Connecté via $provider';
  }

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get settings => 'Paramètres';

  @override
  String get expiresNever => 'N\'expire jamais';

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
    return 'Expire dans $time';
  }

  @override
  String get close => 'Fermer';

  @override
  String get add => 'Ajouter';

  @override
  String get cancel => 'Annuler';

  @override
  String get tokenInput => 'Entrer un token';

  @override
  String get account => 'Compte';

  @override
  String get refreshAccount => 'Recharger le compte';

  @override
  String get removeAccount => 'Supprimer le compte';

  @override
  String get addAnotherAccount => 'Ajouter un autre compte';

  @override
  String get verifiedUserData => 'Données utilisateur vérifiées!';

  @override
  String loggedInAs(String user) {
    return 'Connecté en tant que $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Une erreur est survenue lors de la vérification des données utilisateur:';

  @override
  String get verifyingUserData => 'Vérification des données utilisateur...';

  @override
  String get verifiedUserToken => 'Token utilisateur vérifié!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Une erreur est survenue lors de la vérification du token utilisateur:';

  @override
  String get verifyingUserToken => 'Vérification du token utilisateur...';

  @override
  String get searchForChannels => 'Rechercher une chaîne';

  @override
  String get recommendedChannels => 'Chaînes recommandées';

  @override
  String get popularChannels => 'Chaînes populaires';

  @override
  String get channel => 'Chaîne';

  @override
  String get leaveChannel => 'Quitter la chaîne';

  @override
  String joinUser(String user) {
    return 'Joindre $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Saisie potentiellement incorrecte ! Essayez-vous de rechercher $username ?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Joindre $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Envoyer un message dans $channel';
  }

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get appearance => 'Apparence';

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get customCommand => 'Commande personnalisée';

  @override
  String get customCommands => 'Commandes personnalisées';

  @override
  String get newCustomCommand => 'New custom command';

  @override
  String get commandTrigger => 'Déclencheur';

  @override
  String get command => 'Commande';

  @override
  String get save => 'Sauvegarder';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get messageAppearance => 'Apparence des messages';

  @override
  String get showTimestamps => 'Afficher l\'heure des messages';

  @override
  String get compactMessages => 'Messages compactes';

  @override
  String get messageTrigger => 'Message trigger';

  @override
  String get pattern => 'Pattern';

  @override
  String get mention => 'Mention';

  @override
  String get block => 'Bloquer';

  @override
  String get enableRegex => 'Enable regex';

  @override
  String get caseSensitive => 'Case sensitive';

  @override
  String get messageTriggers => 'Message triggers';

  @override
  String get newMessageTrigger => 'New message trigger';

  @override
  String get reply => 'Répondre';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get copyTextSubtitle =>
      'Maintenez pour copier le texte du message avec le nom d\'utilisateur';

  @override
  String get deleteMessage => 'Supprimer le message';

  @override
  String get mentionUser => 'Mentionner l\'utilisateur';

  @override
  String get copyMessageId => 'Copier l\'ID du message';

  @override
  String get theme => 'Mode';

  @override
  String get userTrigger => 'User trigger';

  @override
  String get userTriggers => 'User triggers';

  @override
  String get chatHistory => 'Historique du chat';

  @override
  String get login => 'Se connecter';

  @override
  String get newUserTrigger => 'New user trigger';

  @override
  String get ban => 'Bannir';

  @override
  String get unban => 'Débannir';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Bannir temporairement l\'utilisateur pendant $duration';
  }

  @override
  String get chatCleared => 'Le chat a été effacé';

  @override
  String get permabanned => 'permaban';

  @override
  String bannedForDuration(String duration) {
    return 'banni pour $duration';
  }

  @override
  String get replyingTo => 'Répondre à';

  @override
  String get blockedMessage => 'Message bloqué';

  @override
  String get showMessage => 'Voir le message';

  @override
  String get hideMessage => 'Masquer le message';

  @override
  String get scrollToBottom => 'Défiler vers le bas';

  @override
  String get startUsingTheApp =>
      'Pour commencer à utiliser l\'appli, ajoutez un compte ci-dessous.';

  @override
  String get chatSettings => 'Paramètres du chat';

  @override
  String get autocompleteUsersWithAt =>
      'Auto-complétion des noms d\'utilisateurs avec @';

  @override
  String get autocompleteEmotesWithColon => 'Auto-complétion des emotes avec :';

  @override
  String get language => 'Langue';

  @override
  String get locale => 'Locale';

  @override
  String get systemDefault => 'Par défaut';

  @override
  String get justDefault => 'Par défaut';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Quelqu\'un vous mentionnera un jour.';

  @override
  String get backgroundNotifications => 'Notifications en arrière-plan';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'This option is not available on your platform.';

  @override
  String get optionNotAvailablePaywalled =>
      'Cette option est réservée aux supporters de ColdChat.';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Effacer le cache';

  @override
  String get chatters => 'Chatteurs';

  @override
  String lastSeenAgo(String time) {
    return 'Vu il y a $time';
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
