import 'package:cached_network_image/cached_network_image.dart';
import 'package:coldchat/components/tile.dart';
import 'package:coldchat/modal/components/modal_header.dart';
import 'package:coldchat/modal/user.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:flutter/material.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import '../api/twitch/twitch.dart';
import '../components/modal.dart';
import '../tmi/user.dart';

class ChattersModal extends StatefulWidget {
  final Channel channel;

  const ChattersModal({
    super.key,
    required this.channel,
  });

  @override
  State<ChattersModal> createState() => _ChattersModalState();
}

class _ChattersModalState extends State<ChattersModal> {
  TextEditingController searchController = TextEditingController();
  late final List<User> chatters = widget.channel.recentChatters;
  Map<String, String> avatarUrls = {};

  @override
  void initState() {
    super.initState();
    loadAvatars();
  }

  /// Profile pictures for the list in one batched Helix request per 100
  /// chatters. Without a login the list shows initials instead.
  Future<void> loadAvatars() async {
    final tokenData = widget.channel.client.apiTokenData;
    if (tokenData == null) return;
    try {
      final users = await Twitch.usersByLogin(tokenData, [for (final chatter in chatters) chatter.login!]);
      if (!mounted) return;
      setState(() => avatarUrls = {for (final user in users) user.login: user.profileImageUrl});
    } catch (_) {
      // Initials are fine when the pictures can't be loaded.
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = searchController.text.toLowerCase();
    return ListView(
      children: [
        ModalHeader(title: AppLocalizations.of(context)!.chatters),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Material(
            borderRadius: BorderRadius.circular(128.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: AppLocalizations.of(context)!.search,
                  isDense: true,
                ),
                onChanged: (text) => setState(() {}),
              ),
            ),
          ),
        ),
        for (final chatter in chatters.where((chatter) => chatter.login!.contains(search) || (chatter.displayName?.toLowerCase().contains(search) ?? false)))
          Tile(
            prefix: CircleAvatar(
              backgroundImage: avatarUrls[chatter.login] == null ? null : CachedNetworkImageProvider(avatarUrls[chatter.login]!),
              child: avatarUrls[chatter.login] == null ? Text((chatter.displayName ?? chatter.login!).characters.first.toUpperCase()) : null,
            ),
            title: chatter.displayName ?? chatter.login!,
            onTap: () {
              Modal.show(
                context: context,
                child: UserModal(
                  login: chatter.login!,
                  channel: widget.channel,
                ),
              );
            },
          ),
      ],
    );
  }
}
