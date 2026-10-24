// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Sesión iniciada a través de $provider';
  }

  @override
  String get termsOfService => 'Términos del Servicio';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get settings => 'Ajustes';

  @override
  String get expiresNever => 'Nunca expira';

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
    return 'Expira en $time';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get add => 'Añadir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tokenInput => 'Introduzca un token';

  @override
  String get account => 'Cuenta';

  @override
  String get refreshAccount => 'Actualizar la cuenta';

  @override
  String get removeAccount => 'Eliminar la cuenta';

  @override
  String get addAnotherAccount => 'Añadir otra cuenta';

  @override
  String get verifiedUserData => '¡Datos de usuario verificados!';

  @override
  String loggedInAs(String user) {
    return 'Sesión iniciada como $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Se ha producido un error al verificar los datos de usuario:';

  @override
  String get verifyingUserData => 'Verificando datos de usuario...';

  @override
  String get verifiedUserToken => '¡Token de usuario verificado!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Se ha producido un error al verificar el token de usuario:';

  @override
  String get verifyingUserToken => 'Verificando token de usuario...';

  @override
  String get searchForChannels => 'Buscar canales';

  @override
  String get recommendedChannels => 'Canales recomendados';

  @override
  String get popularChannels => 'Canales populares';

  @override
  String get channel => 'Canal';

  @override
  String get leaveChannel => 'Salir del canal';

  @override
  String joinUser(String user) {
    return 'Unirse a $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'La revisión ortográfica falló! Quizás quisiste buscar $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Unirse a $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Enviar mensaje en $channel';
  }

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Apariencia';

  @override
  String get highContrast => 'Contraste alto';

  @override
  String get customCommand => 'Comando personalizado';

  @override
  String get customCommands => 'Comandos personalizados';

  @override
  String get newCustomCommand => 'Nuevo comando personalizado';

  @override
  String get commandTrigger => 'Activador';

  @override
  String get command => 'Comando';

  @override
  String get save => 'Guardar';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get messageAppearance => 'Apariencia del mensaje';

  @override
  String get showTimestamps => 'Mostrar marcas de tiempo';

  @override
  String get compactMessages => 'Mensajes compactos';

  @override
  String get showBadges => 'Show badges';

  @override
  String get messageTrigger => 'Activador de mensaje';

  @override
  String get pattern => 'Patrón';

  @override
  String get mention => 'Mención';

  @override
  String get block => 'Bloquear';

  @override
  String get enableRegex => 'Activar regex';

  @override
  String get caseSensitive => 'Distingue mayúsculas y minúsculas';

  @override
  String get messageTriggers => 'Activadores de mensajes';

  @override
  String get newMessageTrigger => 'Nuevo activador de mensaje';

  @override
  String get reply => 'Responder';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get copyTextSubtitle =>
      'Mantén pulsado para copiar el texto del mensaje con el nombre de usuario';

  @override
  String get deleteMessage => 'Eliminar mensaje';

  @override
  String get mentionUser => 'Mencionar usuario';

  @override
  String get copyMessageId => 'Copiar ID del mensaje';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Activador de usuario';

  @override
  String get userTriggers => 'Activadores de usuarios';

  @override
  String get chatHistory => 'Historial del chat';

  @override
  String get login => 'Iniciar sessión';

  @override
  String get newUserTrigger => 'Nuevo activador de usuario';

  @override
  String get ban => 'Banear';

  @override
  String get unban => 'Desbanear';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Banear usuario temporalmente por $duration';
  }

  @override
  String get chatCleared => 'El chat ha sido borrado';

  @override
  String get permabanned => 'baneado permanentemente';

  @override
  String bannedForDuration(String duration) {
    return 'baneado por $duration';
  }

  @override
  String get replyingTo => 'Respondiendo a';

  @override
  String get blockedMessage => 'Mensaje bloqueado';

  @override
  String get showMessage => 'Mostrar mensaje';

  @override
  String get hideMessage => 'Ocultar mensaje';

  @override
  String get scrollToBottom => 'Ir hasta abajo';

  @override
  String get startUsingTheApp =>
      'Para empezar a utilizar la aplicación, añade una cuenta a continuación.';

  @override
  String get chatSettings => 'Ajustes del Chat';

  @override
  String get autocompleteUsersWithAt => 'Autocompletar usuarios con @';

  @override
  String get autocompleteEmotesWithColon => 'Autocompletar emotes con:';

  @override
  String get language => 'Idioma';

  @override
  String get locale => 'Local';

  @override
  String get systemDefault => 'Utilizar valores por defecto';

  @override
  String get justDefault => 'Por defecto';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get noNotifications =>
      'Alguien, en algún lugar, te mencionará algún día.';

  @override
  String get backgroundNotifications => 'Notificaciones en segundo plano';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Esta opción no está disponible en tu plataforma.';

  @override
  String get optionNotAvailablePaywalled =>
      'Esta opción es sólo para simpatizantes de ColdChat.';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get cache => 'Caché';

  @override
  String get clearCache => 'Borrar caché';

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
