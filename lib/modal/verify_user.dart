import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '/tmi/client/client.dart';
import '/data/twitch/token_data.dart';
import '/data/twitch/user_data.dart';
import '/data/twitch_account.dart';
import '/api/twitch/twitch.dart';

class VerifyUserModal extends StatefulWidget {
  final TokenData tokenData;
  final String? cookies;

  const VerifyUserModal({
    super.key,
    required this.tokenData,
    required this.cookies,
  });

  @override
  State<VerifyUserModal> createState() => _VerifyUserModalState();
}

class _VerifyUserModalState extends State<VerifyUserModal> {
  late Future<UserData> future;

  @override
  void initState() {
    future = Twitch.userData(widget.tokenData);
    future.then(
      (value) async {
        final twitchAccount = TwitchAccount(
          tokenData: widget.tokenData,
          userData: value,
          cookies: widget.cookies,
        );

        // Keyed by userId@clientId. Signing in again as the same user replaces
        // the stale entry (and its dead expiresAt) — also one stored under a
        // different client id, such as a login from before ColdChat had its
        // own Twitch app.
        final accountsBox = Hive.box('TwitchAccounts');
        final replacedHashes = [
          for (final entry in accountsBox.toMap().entries)
            if (entry.key != widget.tokenData.hash && entry.value is TwitchAccount && (entry.value as TwitchAccount).tokenData.userId == widget.tokenData.userId) entry.key,
        ];
        await accountsBox.deleteAll(replacedHashes);
        await accountsBox.put(widget.tokenData.hash, twitchAccount);

        // Re-login for the account we are already using (or the very first
        // login) should take effect immediately — otherwise the connection sits
        // in ConnectionInvalidCredentials with the old token until an app
        // restart. Adding a *second* account still doesn't steal the session.
        final accountSettingsBox = Hive.box('AccountSettings');
        final activeHash = accountSettingsBox.get('activeTwitchAccount');
        final activeIsGone = activeHash == null || !accountsBox.containsKey(activeHash) || replacedHashes.contains(activeHash);
        if (activeIsGone || activeHash == widget.tokenData.hash) {
          await accountSettingsBox.put('activeTwitchAccount', widget.tokenData.hash);
          if (mounted) await context.read<Client>().connectAs(twitchAccount);
        }

        if (mounted) Navigator.of(context).pop();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<UserData>(
          future: future,
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.hasData) ...[
                  Icon(
                    Icons.check,
                    size: 64.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  // TODO: Display both background and avatar
                  const SizedBox(height: 16.0),
                  Text(AppLocalizations.of(context)!.verifiedUserData),
                  Text(AppLocalizations.of(context)!.loggedInAs(snapshot.data!.displayName)),
                ],
                if (snapshot.hasError) ...[
                  Icon(
                    Icons.block,
                    size: 64.0,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16.0),
                  Text(AppLocalizations.of(context)!.anErrorHasOccuredWhenVerifyingUserData),
                  Text('${snapshot.error}'),
                ],
                if (!snapshot.hasData && !snapshot.hasError) ...[
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: 16.0),
                  Text(AppLocalizations.of(context)!.verifyingUserData),
                ],
              ],
            );
          },
        ),
      );
}
