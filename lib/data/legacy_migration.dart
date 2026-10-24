import 'dart:convert';
import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatsen/data/custom_command.dart';
import 'package:chatsen/data/message_trigger.dart';
import 'package:chatsen/data/settings/application_appearance.dart';
import 'package:chatsen/data/settings/chat_settings.dart';
import 'package:chatsen/data/settings/message_appearance.dart';
import 'package:chatsen/data/twitch/token_data.dart';
import 'package:chatsen/data/twitch/user_data.dart';
import 'package:chatsen/data/twitch_account.dart';
import 'package:chatsen/data/user_trigger.dart';

Future<void> importLegacySettings(
  Box twitchAccountsBox,
  Box accountSettingsBox,
  Box settingsBox,
  Box customCommandsBox,
  Box messageTriggersBox,
  Box userTriggersBox,
) async {
  final prefs = await SharedPreferences.getInstance();
  final backupString = prefs.getString('chatsen1backup');

  if (backupString == null || backupString.isEmpty) {
    return;
  }

  try {
    final Map<String, dynamic> backup = jsonDecode(backupString);

    // 1. Settings
    if (backup.containsKey('settings') && backup.containsKey('theme')) {
      final settings = backup['settings'] as Map<String, dynamic>;
      final theme = backup['theme'] as Map<String, dynamic>;

      final appAppearance =
          settingsBox.get('applicationAppearance') as ApplicationAppearance? ??
              ApplicationAppearance();
      appAppearance.themeMode = theme['mode'] ?? 'dark';
      appAppearance.highContrast = theme['highContrast'] ?? false;
      await settingsBox.put('applicationAppearance', appAppearance);

      final msgAppearance =
          settingsBox.get('messageAppearance') as MessageAppearance? ??
              MessageAppearance();
      msgAppearance.timestamps = settings['messageTimestamp'] ?? true;
      msgAppearance.imageEmbeds = settings['messageImagePreview'] ?? true;
      msgAppearance.compact = settings['messageLines'] ?? false;
      await settingsBox.put('messageAppearance', msgAppearance);

      final chatSettings =
          settingsBox.get('chatSettings') as ChatSettings? ?? ChatSettings();
      chatSettings.userAutocompletionWithAt =
          settings['mentionWithAt'] ?? false;
      await settingsBox.put('chatSettings', chatSettings);
    }

    // 2. Accounts
    if (backup.containsKey('accounts')) {
      final accounts = backup['accounts'] as List;
      for (final acc in accounts) {
        if (acc['token'] == null || acc['login'] == null) continue;

        final tokenData = TokenData(
          clientId: acc['clientId'],
          login: acc['login'],
          scopes: [],
          userId: acc['id'],
          expiresAt: null,
          accessToken: acc['token'],
        );

        final twitchAccount = TwitchAccount(
          tokenData: tokenData,
          userData: UserData(
            displayName: acc['login'] ?? '',
            avatarUrl: '',
            offlineUrl: '',
          ),
          cookies: null,
        );

        await twitchAccountsBox.add(twitchAccount);

        if (acc['isActive'] == true) {
          await accountSettingsBox.put('activeTwitchAccount', tokenData.hash);
        }
      }
    }

    // 3. Commands
    if (backup.containsKey('commands')) {
      final commands = backup['commands'] as List;
      for (final cmd in commands) {
        if (cmd['trigger'] == null || cmd['command'] == null) continue;
        await customCommandsBox.add(CustomCommand(
          trigger: cmd['trigger'],
          command: cmd['command'],
        ));
      }
    }

    // 4. Custom Mentions
    if (backup.containsKey('customMentions')) {
      final mentions = backup['customMentions'] as List;
      for (final m in mentions) {
        if (m['pattern'] == null) continue;
        await messageTriggersBox.add(MessageTrigger(
          type: MessageTriggerType.mention.index,
          pattern: m['pattern'],
          enableRegex: m['enableRegex'] ?? false,
          caseSensitive: m['caseSensitive'] ?? false,
          showInMentions: m['showInMentions'] ?? true,
          sendNotification: m['sendNotification'] ?? true,
          playSound: m['playSound'] ?? true,
        ));
      }
    }

    // 5. Blocked Users
    if (backup.containsKey('blockedUsers')) {
      final blocked = backup['blockedUsers'] as List;
      for (final b in blocked) {
        final login = b.toString();
        await userTriggersBox.add(UserTrigger(
          type: UserTriggerType.block.index,
          login: login,
        ));
      }
    }

    // Clear after import so it doesn't run again
    await prefs.remove('chatsen1backup');
  } catch (e) {
    log('Failed to import legacy settings: $e');
  }
}
