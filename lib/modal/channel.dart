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

class ChannelModal extends StatelessWidget {
  final Channel channel;

  const ChannelModal({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) => BlocBuilder<ChannelInfo, TwitchProfile?>(
        bloc: channel.channelInfo,
        builder: (context, state) => ListView(
          shrinkWrap: true,
          children: [
            if (state != null) UserModalHeader(profile: state),
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
