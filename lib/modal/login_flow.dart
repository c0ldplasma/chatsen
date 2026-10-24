import 'package:flutter/material.dart';

import '/components/modal.dart';
import 'oauth_webview.dart';

/// Start a Twitch sign-in in the embedded OAuth webview. Shared by the "add
/// account" tile and the expired-login banner so both stay in sync.
Future<void> showTwitchLogin(BuildContext context) {
  return Modal.show(
    enableDrag: false,
    context: context,
    child: const OAuthWebViewModal(),
  );
}
