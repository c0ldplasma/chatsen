import 'dart:developer';

import 'package:coldchat/api/twitch/twitch.dart';
import 'package:flutter/material.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import 'package:provider/provider.dart';

import '../api/twitch/twitch_profile.dart';
import '../tmi/client/client.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../widgets/chat_view.dart';
import 'components/user_modal_header.dart';

class UserModal extends StatefulWidget {
  final String login;
  final Channel? channel;

  const UserModal({
    super.key,
    required this.login,
    this.channel,
  });

  @override
  State<UserModal> createState() => _UserModalState();
}

class _UserModalState extends State<UserModal> {
  late final Future<TwitchProfile?> future;

  Channel? get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    // Profiles come from Helix, which needs a login. Without one the panel
    // still shows the user's messages.
    final tokenData = (channel?.client ?? context.read<Client>()).apiTokenData;
    future = tokenData == null ? Future.value(null) : Twitch.profile(tokenData, widget.login).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TwitchProfile?>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<TwitchProfile?> snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final profile = snapshot.data;
          return ListView(
            shrinkWrap: true,
            children: [
              if (loading || profile != null) UserModalHeader(profile: profile, name: widget.login),
              if (channel != null && profile != null)
                Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Row(
                    children: [
                      Tooltip(
                        message: AppLocalizations.of(context)!.ban,
                        child: IconButton(
                          icon: const Icon(
                            Icons.block_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            try {
                              await Twitch.ban(
                                channel!.client.transmitter.twitchAccount!.tokenData,
                                broadcasterId: channel!.id!,
                                moderatorId: channel!.client.transmitter.twitchAccount!.tokenData.userId!,
                                userId: profile.user.id,
                              );
                            } catch (e) {
                              log('$e');
                              // channel.channelMessages.add(ChannelMessageNotice(message: message, dateTime: dateTime))
                            }
                            // channel?.send('/ban ${snapshot.data!.login}'),
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (final time in {
                                  '1s': const Duration(seconds: 1),
                                  '30s': const Duration(seconds: 30),
                                  '1m': const Duration(minutes: 1),
                                  '5m': const Duration(minutes: 5),
                                  '30m': const Duration(minutes: 30),
                                  '1h': const Duration(hours: 1),
                                  '1d': const Duration(days: 1),
                                  '1w': const Duration(days: 7),
                                }.entries)
                                  Tooltip(
                                    message: AppLocalizations.of(context)!.timeoutUserForDuration(time.value.toString().split('.').first),
                                    child: TextButton(
                                      child: Text(time.key),
                                      onPressed: () async {
                                        try {
                                          await Twitch.ban(
                                            channel!.client.transmitter.twitchAccount!.tokenData,
                                            broadcasterId: channel!.id!,
                                            moderatorId: channel!.client.transmitter.twitchAccount!.tokenData.userId!,
                                            userId: profile.user.id,
                                            duration: time.value.inSeconds,
                                          );
                                        } catch (e) {
                                          log('$e');
                                          // channel.channelMessages.add(ChannelMessageNotice(message: message, dateTime: dateTime))
                                        }
                                        // channel?.send('/timeout ${snapshot.data!.login} ${time.value.inSeconds}'),
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: AppLocalizations.of(context)!.unban,
                        child: IconButton(
                          icon: const Icon(
                            Icons.block_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            try {
                              await Twitch.unban(
                                channel!.client.transmitter.twitchAccount!.tokenData,
                                broadcasterId: channel!.id!,
                                moderatorId: channel!.client.transmitter.twitchAccount!.tokenData.userId!,
                                userId: profile.user.id,
                              );
                            } catch (e) {
                              log('$e');
                              // channel.channelMessages.add(ChannelMessageNotice(message: message, dateTime: dateTime))
                            }
                            // channel?.send('/unban ${snapshot.data!.login}');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (channel != null)
                SizedBox(
                  width: double.infinity,
                  height: 350.0,
                  child: ChatView(
                    channel: channel!,
                    filter: (message) {
                      if (message is! ChannelMessageChat) return false;
                      // TODO: change when proper user storage is done
                      return message.message.prefix?.split('!').first == widget.login;
                    },
                  ),
                ),
            ],
          );
        },
      );
}
