import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chatsen/l10n/app_localizations.dart';

import '/components/separator.dart';
import 'components/modal_header.dart';
import 'verify_token.dart';
import '/components/modal.dart';
import '../data/twitch_account.dart';

class TwitchAccountModal extends StatelessWidget {
  final TwitchAccount twitchAccount;

  const TwitchAccountModal({
    super.key,
    required this.twitchAccount,
  });

  @override
  Widget build(BuildContext context) => ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context)!.account),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                borderRadius: BorderRadius.circular(128.0),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 64.0 * 1.5,
                  height: 64.0 * 1.5,
                  child: twitchAccount.userData != null
                      ? Ink.image(
                          image: CachedNetworkImageProvider(twitchAccount.userData!.avatarUrl),
                        )
                      : const Icon(Icons.question_mark_outlined),
                ),
              ),
            ),
          ),
          SelectableText(
            twitchAccount.userData?.displayName ?? twitchAccount.tokenData.login,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SelectableText(
            '${twitchAccount.tokenData.login}#${twitchAccount.tokenData.userId}',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          const Separator(),
          InkWell(
            onTap: () async {
              Navigator.of(context).pop();

              Modal.show(
                context: context,
                child: VerifyTokenModal(
                  token: '${twitchAccount.tokenData.accessToken}',
                  cookies: twitchAccount.cookies,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.refreshAccount,
                        // style: Theme.of(context).textTheme.subtitle1,
                      ),
                      ExpirationText(twitchAccount: twitchAccount),
                    ],
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await twitchAccount.delete();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Icon(Icons.delete_forever_outlined),
                  ),
                  const SizedBox(width: 16.0),
                  Text(AppLocalizations.of(context)!.removeAccount),
                ],
              ),
            ),
          ),
        ],
      );
}

class ExpirationText extends StatefulWidget {
  const ExpirationText({
    super.key,
    required this.twitchAccount,
  });

  final TwitchAccount twitchAccount;

  @override
  State<ExpirationText> createState() => _ExpirationTextState();
}

class _ExpirationTextState extends State<ExpirationText> {
  late Timer timer;

  @override
  void initState() {
    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer t) => setState(() {}),
    );
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenData = widget.twitchAccount.tokenData;
    // Past expiry the plain countdown just rendered a negative duration
    // ("Expires in -9:07:12"), which reads like a glitch rather than the reason
    // chat stopped working. Call it out instead.
    final expired = tokenData.isExpired;
    return Text(
      expired
          ? AppLocalizations.of(context)!.loginExpired
          : tokenData.expiresAt != null
              ? AppLocalizations.of(context)!.expiresIn('${tokenData.expiresAt?.difference(DateTime.now())}')
              : AppLocalizations.of(context)!.expiresNever,
      style: TextStyle(
        color: expired ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
      ),
      // style: Theme.of(context).textTheme.subtitle2,
    );
  }
}
