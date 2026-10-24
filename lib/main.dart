import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/notifications_cubit.dart';

import 'package:coldchat/data/custom_command.dart';
import 'package:coldchat/data/message_trigger.dart';
import 'package:coldchat/data/settings/application_appearance.dart';
import 'package:coldchat/data/settings/blocked_message.dart';
import 'package:coldchat/data/settings/blocked_user.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/data/settings/mention_message.dart';
import 'package:coldchat/data/settings/mention_user.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/data/user_trigger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '/data/emote_button_icon.dart';
import '/data/twitch/token_data.dart';
import '/data/twitch/user_data.dart';
import '/data/twitch_account.dart';
import '/data/webview/cookie_data.dart';
import '/app.dart';
import 'data/filesharing/uploaded_media.dart';
import 'tmi/client/client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WakelockPlus.enable();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();
  await EmoteButtonIcon.init();

  Hive.registerAdapter(TwitchAccountAdapter());
  Hive.registerAdapter(TokenDataAdapter());
  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(CookieDataAdapter());
  Hive.registerAdapter(UploadedMediaAdapter());
  Hive.registerAdapter(MessageAppearanceAdapter());
  Hive.registerAdapter(ApplicationAppearanceAdapter());
  Hive.registerAdapter(BlockedMessageAdapter());
  Hive.registerAdapter(BlockedUserAdapter());
  Hive.registerAdapter(MentionMessageAdapter());
  Hive.registerAdapter(MentionUserAdapter());
  Hive.registerAdapter(CustomCommandAdapter());
  Hive.registerAdapter(MessageTriggerAdapter());
  Hive.registerAdapter(UserTriggerAdapter());
  Hive.registerAdapter(ChatSettingsAdapter());

  // Open all Hive boxes concurrently instead of serially to shave startup
  // time off the path before the first frame.
  final boxes = await Future.wait([
    Hive.openBox('TwitchAccounts'),
    Hive.openBox('AccountSettings'),
    Hive.openBox('Settings'),
    Hive.openBox('Channels'),
    Hive.openBox('EmoteBadgeCache'),
    Hive.openBox('SeenMentions'),
    Hive.openBox('MessageTriggers'),
    Hive.openBox('UserTriggers'),
    Hive.openBox('CustomCommands'),
    Hive.openBox('ChatSettings'),
  ]);
  final twitchAccountsBox = boxes[0];
  final accountSettingsBox = boxes[1];
  final settingsBox = boxes[2];
  final channelsBox = boxes[3];
  final emoteBadgeCacheBox = boxes[4];

  // await settingsBox.clear();

  final activeTwitchAccount = twitchAccountsBox.values.firstWhere(
    (element) =>
        accountSettingsBox.get('activeTwitchAccount') == element.tokenData.hash,
    orElse: () => null,
  );

  if (!settingsBox.containsKey('messageAppearance')) {
    await settingsBox.put('messageAppearance', MessageAppearance());
  }
  if (!settingsBox.containsKey('applicationAppearance')) {
    await settingsBox.put('applicationAppearance', ApplicationAppearance());
  }
  if (!settingsBox.containsKey('chatSettings')) {
    await settingsBox.put('chatSettings', ChatSettings());
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<Client>(
          create: (context) => Client(
            twitchAccount: activeTwitchAccount,
            channelsBox: channelsBox,
            cacheBox: emoteBadgeCacheBox,
          ),
        ),
        Provider<NotificationsCubit>(create: (context) => NotificationsCubit()),
        // Above the channel views on purpose: an upload must survive switching
        // tabs and must never be awaited by the composer.
        Provider<UploadQueueCubit>(create: (context) => UploadQueueCubit()),
      ],
      child: const App(),
    ),
  );
}
