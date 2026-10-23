import 'package:chatsen/components/modal.dart';
import 'package:chatsen/modal/chatters.dart';
import 'package:chatsen/tmi/channel/channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatsen/l10n/app_localizations.dart';

import '../api/chatsen/chatsen_user.dart';
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
  Widget build(BuildContext context) => BlocBuilder<ChannelInfo, ChatsenUser?>(
        bloc: channel.channelInfo,
        builder: (context, state) => ListView(
          shrinkWrap: true,
          children: [
            if (state != null) UserModalHeader(user: state),
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
