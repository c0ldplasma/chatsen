import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../components/boxlistener.dart';
import '../components/modal.dart';
import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/emote_button_icon.dart';
import '../tmi/client/client.dart';
import '../widgets/chat/emote_picker.dart';
import '../widgets/emote_button_icon_view.dart';
import '/data/settings/chat_settings.dart';
import 'components/modal_header.dart';

class ChatSettingsModal extends StatelessWidget {
  const ChatSettingsModal({super.key});

  // Offer the last opened channel's emotes too, not just global ones.
  Future<void> _pickButtonIcon(BuildContext context) {
    final client = context.read<Client>();
    final lastChannel = Hive.box('Settings').get('lastChannel');
    final channel = client.channels.state.firstWhereOrNull((c) => c.name == lastChannel) ?? client.channels.state.firstOrNull;
    return Modal.show(
      context: context,
      child: Builder(
        builder: (modalContext) => SizedBox(
          height: 420.0,
          child: EmotePicker(
            client: client,
            channel: channel,
            getFieldInput: () => '',
            setFieldInput: (_) {},
            insertFieldInput: (_) {},
            onPickButtonIcon: (emote) async {
              if (await chooseEmoteButtonIcon(modalContext, emote) && modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BoxListener(
        box: Hive.box('Settings'),
        builder: (context, box) {
          final ChatSettings chatSettings = box.get('chatSettings') as ChatSettings;
          return ListView(
            shrinkWrap: true,
            children: [
              ModalHeader(title: AppLocalizations.of(context)!.chatSettings),
              Tile(
                title: AppLocalizations.of(context)!.autocompleteUsersWithAt,
                prefix: const Icon(Icons.alternate_email_outlined),
                suffix: Toggle(
                  value: chatSettings.userAutocompletionWithAt,
                  onChanged: (newValue) {
                    chatSettings.userAutocompletionWithAt = !chatSettings.userAutocompletionWithAt;
                    chatSettings.save();
                  },
                ),
                onTap: () {
                  chatSettings.userAutocompletionWithAt = !chatSettings.userAutocompletionWithAt;
                  chatSettings.save();
                },
              ),
              Tile(
                title: AppLocalizations.of(context)!.autocompleteEmotesWithColon,
                prefix: const Icon(Icons.emoji_emotions_outlined),
                suffix: Toggle(
                  value: chatSettings.emoteAutocompletionWithColon,
                  onChanged: (newValue) {
                    chatSettings.emoteAutocompletionWithColon = !chatSettings.emoteAutocompletionWithColon;
                    chatSettings.save();
                  },
                ),
                onTap: () {
                  chatSettings.emoteAutocompletionWithColon = !chatSettings.emoteAutocompletionWithColon;
                  chatSettings.save();
                },
              ),
              Tile(
                title: AppLocalizations.of(context)!.emoteMenuButton,
                subtitle: EmoteButtonIcon.name ?? 'Kappa',
                prefix: const SizedBox.square(dimension: 24.0, child: Center(child: EmoteButtonIconView())),
                suffix: const Icon(Icons.chevron_right),
                onTap: () => _pickButtonIcon(context),
              ),
              Tile(
                title: AppLocalizations.of(context)!.emoteMenuButtonGrayscale,
                prefix: const Icon(Icons.filter_b_and_w_outlined),
                suffix: Toggle(
                  value: EmoteButtonIcon.grayscale,
                  onChanged: (newValue) => EmoteButtonIcon.setGrayscale(!EmoteButtonIcon.grayscale),
                ),
                onTap: () => EmoteButtonIcon.setGrayscale(!EmoteButtonIcon.grayscale),
              ),
            ],
          );
        },
      );
}
