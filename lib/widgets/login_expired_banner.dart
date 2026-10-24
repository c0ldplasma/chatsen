import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../modal/login_flow.dart';
import '../tmi/client/client.dart';
import '../tmi/connection/connection.dart';
import '../tmi/connection/connection_state.dart' as tmi;

/// Surfaces a dead Twitch login. Without it an expired token is invisible:
/// Twitch refuses the handshake, every channel stays parted and the chat just
/// looks empty. Tapping starts a fresh sign-in — implicit-grant tokens have no
/// refresh token, so re-authenticating is the only way back.
class LoginExpiredBanner extends StatelessWidget {
  const LoginExpiredBanner({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<Connection, tmi.ConnectionState>(
        bloc: context.read<Client>().receiver,
        builder: (context, state) {
          if (state is! tmi.ConnectionInvalidCredentials) return const SizedBox.shrink();

          final colorScheme = Theme.of(context).colorScheme;
          return Material(
            color: colorScheme.errorContainer,
            child: InkWell(
              onTap: () => showTwitchLogin(context),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top + 12.0,
                  bottom: 12.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.loginExpired,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                          Text(
                            AppLocalizations.of(context)!.loginExpiredDescription(state.twitchAccount.tokenData.login),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      AppLocalizations.of(context)!.signInAgain,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
