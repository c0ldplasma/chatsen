import 'dart:io';

import 'package:flutter/material.dart';

import '/components/modal.dart';
import 'oauth_webview.dart';
import 'twitch_token_input.dart';

/// Start a Twitch sign-in: the embedded OAuth webview on mobile, a manual token
/// entry everywhere else (no webview available there). Shared by the "add
/// account" tile and the expired-login banner so both stay in sync.
Future<void> showTwitchLogin(BuildContext context) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return Modal.show(
      context: context,
      child: const TwitchTokenInputModal(),
    );
  }

  return Modal.show(
    enableDrag: false,
    context: context,
    child: const OAuthWebViewModal(),
  );
}
