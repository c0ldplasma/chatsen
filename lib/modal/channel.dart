import 'package:coldchat/components/modal.dart';
import 'package:coldchat/modal/chatters.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import '../api/twitch/twitch_profile.dart';
import '../components/tile.dart';
import '../tmi/channel/channel_info.dart';
import '../tmi/client/client.dart';
import 'components/user_modal_header.dart';

class ChannelModal extends StatefulWidget {
  final Channel channel;

  const ChannelModal({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelModal> createState() => _ChannelModalState();
}

class _ChannelModalState extends State<ChannelModal> {
  Channel get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    // Live status and viewer count change; the header shows the last known
    // profile meanwhile.
    channel.refreshChannelUser();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ChannelInfo, TwitchProfile?>(
        bloc: channel.channelInfo,
        builder: (context, state) => ListView(
          shrinkWrap: true,
          children: [
            UserModalHeader(profile: state, name: channel.name.replaceFirst('#', '')),
            Tile(
              title: AppLocalizations.of(context)!.chatters,
              prefix: const Icon(Icons.people_outline_outlined),
              onTap: () async {
                Modal.show(
                  context: context,
                  child: ChattersModal(channel: channel),
                );
              },
            ),
            Tile(
              title: AppLocalizations.of(context)!.leaveChannel,
              prefix: const Icon(Icons.delete_forever_outlined),
              onTap: () async {
                context.read<Client>().channels.part(channel);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
}
