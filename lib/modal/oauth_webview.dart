
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../components/modal.dart';
import 'components/modal_header.dart';
import 'verify_token.dart';

// 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36',
// await webViewController.runJavaScript('document.cookie = "$_savedCookies"');

/// ColdChat's own Twitch app (dev.twitch.tv console). Public client, implicit
/// grant: the client id isn't a secret, it's part of every login URL.
const String twitchClientId = 'y05nqtxmuntv88n98uhfz4sfpr0u17';

/// Registered redirect URL. Never actually loaded: [_OAuthWebViewModalState]
/// intercepts the navigation and reads the token from the URL fragment. If that
/// ever failed, the request would go to the phone itself, not to a server.
// Must match the console entry exactly, including the trailing slash.
const String _redirectUri = 'https://localhost/';

class OAuthWebViewModal extends StatefulWidget {
  const OAuthWebViewModal({super.key});

  @override
  State<OAuthWebViewModal> createState() => _OAuthWebViewModalState();
}

class _OAuthWebViewModalState extends State<OAuthWebViewModal> {
  WebViewController? _webViewController;
  late final WebViewCookieManager cookieManager = WebViewCookieManager();

  /// Twitch redirects to `https://localhost/#access_token=…` on success and to
  /// `https://localhost/?error=…` when the user declines.
  void _handleRedirect(Uri uri) {
    final accessToken = Uri.splitQueryString(uri.fragment)['access_token'];
    final error = uri.queryParameters['error'];
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    if (accessToken == null) {
      // Declining is a deliberate choice; anything else is a failure the user
      // should see instead of the sheet just closing. A dialog, because a snack
      // bar would sit behind the account sheet that is still open.
      if (error != null && error != 'access_denied') {
        showDialog<void>(
          context: navigator.context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.loginFailed),
            content: Text(uri.queryParameters['error_description'] ?? error),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      }
      return;
    }

    Modal.show(
      context: context,
      child: VerifyTokenModal(
        token: accessToken,
        cookies: null,
      ),
    );
  }

  void setup() async {
    // ignore: prefer_interpolation_to_compose_strings
    final url = 'https://id.twitch.tv/oauth2/authorize?client_id=$twitchClientId&redirect_uri=${Uri.encodeComponent(_redirectUri)}&response_type=token&scope=' +
        [
          // Chat
          'chat:edit',
          'chat:read',
          'channel:moderate',
          'channel:read:redemptions',
          'moderator:manage:automod',
          'channel:manage:broadcast',

          // Whispers
          'whispers:read',
          'whispers:edit',

          // Sub emotes
          'user_subscriptions',

          // Blocked users
          'user_blocks_edit',
          'user_blocks_read',
          'user:read:blocked_users',
          'user:manage:blocked_users',

          // Raid
          'channel_editor', // Raids

          // Run ads
          // 'channel_commercial',
          // 'channel:edit:commercial',

          // To create clips
          // 'clips:edit',

          // Follows, no longer working
          // 'user_follows_edit',
          // 'user:edit:follows',
        ].join('%20');

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    await cookieManager.clearCookies();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          // URLs aren't logged: the final redirect carries the access token.
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme != 'https' || uri.host != 'localhost') {
              return NavigationDecision.navigate;
            }
            _handleRedirect(uri);
            return NavigationDecision.prevent;
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('Error occurred on page: ${error.response?.statusCode}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // openDialog(request);
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(url));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    setState(() {
      _webViewController = controller;
    });
  }

  @override
  void initState() {
    super.initState();
    setup();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        children: [
          if (_webViewController != null) WebViewWidget(controller: _webViewController!),
          const ModalHeader(),
        ],
      ),
    );
  }
}
