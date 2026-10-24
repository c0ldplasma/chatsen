// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get chatsen => 'ColdChat';

  @override
  String get catsen => 'Catsen';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'S\'ha iniciat la sessió mitjançant $provider';
  }

  @override
  String get termsOfService => 'Condicions del Servei';

  @override
  String get privacyPolicy => 'Política de Privacitat';

  @override
  String get settings => 'Configuració';

  @override
  String get expiresNever => 'No caduca mai';

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
    return 'Caduca en $time';
  }

  @override
  String get close => 'Tanca';

  @override
  String get add => 'Afegeix';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get tokenInput => 'Introdueix el token';

  @override
  String get account => 'Compte';

  @override
  String get refreshAccount => 'Actualitza el compte';

  @override
  String get removeAccount => 'Suprimeix el compte';

  @override
  String get addAnotherAccount => 'Afegeix un compte';

  @override
  String get verifiedUserData => 'Dades d\'usuari verificades!';

  @override
  String loggedInAs(String user) {
    return 'S\'ha iniciat la sessió com $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'S\'ha produït un error en verificar les dades de l\'usuari:';

  @override
  String get verifyingUserData => 'Verificant les dades de l\'usuari...';

  @override
  String get verifiedUserToken => 'Token de l\'usuari verificat!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'S\'ha produït un error en verificar el token de l\'usuari:';

  @override
  String get verifyingUserToken => 'Verificant el token de l\'usuari...';

  @override
  String get searchForChannels => 'Cerca canals';

  @override
  String get recommendedChannels => 'Canals recomanats';

  @override
  String get popularChannels => 'Canals populars';

  @override
  String get channel => 'Canal';

  @override
  String get leaveChannel => 'Deixa el canal';

  @override
  String joinUser(String user) {
    return 'Uneix-te a $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'La revisió ha fallat! Potser has volgut cercar $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Uneix-te a $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Envia missatge en $channel';
  }

  @override
  String get light => 'Clar';

  @override
  String get dark => 'Fosc';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Aparença';

  @override
  String get highContrast => 'Alt contrast';

  @override
  String get customCommand => 'Comanda personalitzada';

  @override
  String get customCommands => 'Comandes personalitzades';

  @override
  String get newCustomCommand => 'Nova comanda personalitzada';

  @override
  String get commandTrigger => 'Activador';

  @override
  String get command => 'Comanda';

  @override
  String get save => 'Desa';

  @override
  String get openInBrowser => 'Obre al navegador';

  @override
  String get messageAppearance => 'Aparença del missatge';

  @override
  String get showTimestamps => 'Mostrar segells de temps';

  @override
  String get compactMessages => 'Missatges compactes';

  @override
  String get showBadges => 'Show badges';

  @override
  String get messageTrigger => 'Activador de missatge';

  @override
  String get pattern => 'Patró';

  @override
  String get mention => 'Menció';

  @override
  String get block => 'Bloquejar';

  @override
  String get enableRegex => 'Activar regex';

  @override
  String get caseSensitive => 'Sensible a majúscules i minúscules';

  @override
  String get messageTriggers => 'Activador de missatge';

  @override
  String get newMessageTrigger => 'Nou activador de missatge';

  @override
  String get reply => 'Respondre';

  @override
  String get copyText => 'Copiar text';

  @override
  String get copyTextSubtitle =>
      'Mantingueu premut per copiar el text del missatge amb el nom d\'usuari';

  @override
  String get deleteMessage => 'Eliminar missatge';

  @override
  String get mentionUser => 'Mencionar l\'usuari';

  @override
  String get copyMessageId => 'Copia l\'identificador del missatge';

  @override
  String get theme => 'Aspecte';

  @override
  String get userTrigger => 'Activador d\'usuari';

  @override
  String get userTriggers => 'Activadors d\'usuari';

  @override
  String get chatHistory => 'Historial de xat';

  @override
  String get login => 'Inici de sessió';

  @override
  String get newUserTrigger => 'Nou activador d\'usuari';

  @override
  String get ban => 'Expulsar';

  @override
  String get unban => 'Cancel·lar Expulsió';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Expulsar temporalment per $duration';
  }

  @override
  String get chatCleared => 'El xat s\'ha esborrat';

  @override
  String get permabanned => 'expulsat indefinitivament';

  @override
  String bannedForDuration(String duration) {
    return 'expulsat per $duration';
  }

  @override
  String get replyingTo => 'Responent a';

  @override
  String get blockedMessage => 'Missatge bloquejat';

  @override
  String get showMessage => 'Mostra el missatge';

  @override
  String get hideMessage => 'Amagar el missatge';

  @override
  String get scrollToBottom => 'Desplaça al final';

  @override
  String get startUsingTheApp =>
      'Per començar a utilitzar l\'aplicació, afegiu un compte a continuació.';

  @override
  String get chatSettings => 'Configuració del xat';

  @override
  String get autocompleteUsersWithAt =>
      'Completa els usuaris automàticament amb @';

  @override
  String get autocompleteEmotesWithColon =>
      'Completa els emotes automàticament amb :';

  @override
  String get language => 'Llenguatge';

  @override
  String get locale => 'Local';

  @override
  String get systemDefault => 'Valors per defecte del sistema';

  @override
  String get justDefault => 'Predeterminat';

  @override
  String get notifications => 'Notificacions';

  @override
  String get noNotifications => 'Algú, en algun lloc, t\'esmentarà algun dia.';

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
