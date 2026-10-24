import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coldchat/widgets/chat/emote_picker.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../components/dark_bar.dart';
import '../components/modal.dart';
import '../components/surface.dart';
import '../components/tile.dart';
import '../data/custom_command.dart';
import '../data/filesharing/upload_queue_cubit.dart';
import '../data/filesharing/upload_task.dart';
import '../data/emote.dart';
import '../data/settings/chat_settings.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import 'chat/upload_queue_bar.dart';
import 'chat_view.dart';
import 'emoji_glyph.dart';
import 'emote_button_icon_view.dart';

import 'package:collection/collection.dart';

class ChannelView extends StatefulWidget {
  final Channel channel;

  const ChannelView({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelView> createState() => ChannelViewState();

  static ChannelViewState? of(BuildContext context) => context.findAncestorStateOfType<ChannelViewState>();
}

enum AutocompletionType {
  emote,
  user,
  customCommand,
}

class AutocompletionItem {
  final Widget? prefix;
  final String title;
  final String? subtitle;
  final Function()? onTap;
  final Function()? onLongPress;
  final Widget? shortened;
  final AutocompletionType type;

  AutocompletionItem({
    this.prefix,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.shortened,
    required this.type,
  });
}

class ChannelViewState extends State<ChannelView> {
  final FocusNode textFocusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  bool spamming = false;
  bool emoteKeyboard = false;
  // The emote menu is open to choose the button's emote (long-press on it).
  bool pickingButtonIcon = false;
  ChannelMessageChat? replyChannelMessageChat;
  StreamSubscription<UploadTask>? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    // Insert finished uploads into this channel's composer only; other tabs
    // ignore them.
    _uploadSubscription = context.read<UploadQueueCubit>().completed.listen((task) {
      if (!mounted || task.channelName != widget.channel.name) return;
      final url = task.url;
      if (url != null) insertUploadedUrl(url);
    });
    if (Platform.isAndroid && !_lostPhotoChecked) {
      _lostPhotoChecked = true;
      recoverLostPhoto();
    }
  }

  // Android may kill the app while the camera is in front. The photo is then
  // handed back on the next launch, once, so only the first view asks for it.
  static bool _lostPhotoChecked = false;

  Future<void> recoverLostPhoto() async {
    final queue = context.read<UploadQueueCubit>();
    final response = await ImagePicker().retrieveLostData();
    final photo = response.file;
    if (photo == null) return;
    unawaited(queue.uploadFile(
      path: photo.path,
      filename: photo.name,
      channelName: widget.channel.name,
    ));
  }

  void setReplyChannelMessageChat(ChannelMessageChat? channelMessageChat) {
    setState(() {
      replyChannelMessageChat = channelMessageChat;
    });
  }

  Future<void> sendMessage() async {
    // TODO: Implement reactions here

    var text = textEditingController.text;

    final textSplits = text.trim().split(' ');
    if (textSplits.isNotEmpty) {
      final customCommands = Hive.box('CustomCommands').values.cast<CustomCommand>();
      final customCommand = customCommands.firstWhereOrNull((element) => textSplits.first.toLowerCase() == element.trigger.toLowerCase());
      if (customCommand != null) {
        text = customCommand.command;
        text = text.replaceAllMapped(
          RegExp(r'{\d*}'),
          (match) {
            final matchText = match.group(0) ?? '{}';
            final matchContent = matchText.substring(1, matchText.length - 1);
            final index = int.tryParse(matchContent);
            if (index != null && index < textSplits.length && index > 0) {
              return textSplits[index];
            }
            return '';
          },
        );
        text = text.replaceAllMapped(
          RegExp(r'{\d*\+}'),
          (match) {
            final matchText = match.group(0) ?? '{+}';
            final matchContent = matchText.substring(1, matchText.length - 2);
            final index = int.tryParse(matchContent);
            if (index != null && index < textSplits.length && index > 0) {
              return textSplits.skip(index).join(' ');
            }
            return '';
          },
        );
      }
    }

    widget.channel.send(text, tags: {
      if (replyChannelMessageChat != null) 'reply-parent-msg-id': replyChannelMessageChat!.id,
    });

    setReplyChannelMessageChat(null);

    textEditingController.clear();
  }

  /// Pick files and hand them to the global upload queue.
  ///
  /// Deliberately does not await the uploads: the composer stays usable, the
  /// progress chips above it report state, and each URL is inserted when it
  /// actually arrives. The old version awaited every upload inline, snapshotted
  /// the text beforehand and wrote that snapshot back afterwards — which threw
  /// away anything typed in the meantime and showed nothing while it ran.
  Future<void> pickAndUploadFiles() async {
    await Modal.show(
      context: context,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tile(
              title: AppLocalizations.of(context)!.takePhoto,
              prefix: const Icon(Icons.photo_camera_outlined),
              onTap: () {
                Navigator.of(context).pop();
                takeAndUploadPhoto();
              },
            ),
            Tile(
              title: AppLocalizations.of(context)!.chooseFromLibrary,
              prefix: const Icon(Icons.photo_library_outlined),
              onTap: () {
                Navigator.of(context).pop();
                pickAndUploadFromLibrary();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takeAndUploadPhoto() async {
    final queue = context.read<UploadQueueCubit>();
    final XFile? photo;
    try {
      // imageQuality makes the plugin re-encode to JPEG, so an iPhone's HEIC
      // capture arrives in a format every upload host and browser accepts.
      photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    } catch (e) {
      // Camera access denied or no camera on this device.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cameraUnavailable)));
      return;
    }
    if (photo == null) return;

    unawaited(queue.uploadFile(
      path: photo.path,
      filename: photo.name,
      channelName: widget.channel.name,
    ));
  }

  Future<void> pickAndUploadFromLibrary() async {
    final queue = context.read<UploadQueueCubit>();
    // Picks several files; an empty list means the user cancelled.
    final files = await FilePicker.pickFiles(
      type: Platform.isIOS ? FileType.image : FileType.any,
    );

    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      unawaited(queue.uploadFile(
        path: path,
        filename: file.name,
        channelName: widget.channel.name,
      ));
    }
  }

  /// Drop [url] where the caret is, preserving whatever has been typed since
  /// the upload started, and leave the caret after it ready for more text.
  void insertUploadedUrl(String url) {
    final text = textEditingController.text;
    final selection = textEditingController.selection;
    final at = selection.isValid ? selection.end : text.length;

    final needsLeadingSpace = at > 0 && !text.substring(0, at).endsWith(' ');
    final insertion = '${needsLeadingSpace ? ' ' : ''}$url ';
    final updated = text.replaceRange(selection.isValid ? selection.start : at, at, insertion);

    textEditingController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: (selection.isValid ? selection.start : at) + insertion.length),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _uploadSubscription?.cancel();
    textEditingController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  List<AutocompletionItem> getAutocompletionItems() {
    if (textEditingController.text.split(' ').last.length < 2) return [];
    final currentSearch = textEditingController.text.split(' ').last.toLowerCase();

    final chatSettings = Hive.box('Settings').get('chatSettings') as ChatSettings;

    final matchingEmotes = (widget.channel.channelEmotes.state + widget.channel.client.globalEmotes.state + widget.channel.client.twitchUserEmotes.state).where((emote) {
      return (chatSettings.emoteAutocompletionWithColon ? currentSearch.startsWith(':') : true) && ':${emote.name}:'.toLowerCase().contains(currentSearch);
    }).toList();
    // Emotes whose name starts with the search go first, then the ones that
    // only match further into the name. Stable, so each group keeps its order.
    final emotePrefix = currentSearch.startsWith(':') ? currentSearch : ':$currentSearch';
    bool startsWithSearch(Emote emote) => ':${emote.name}:'.toLowerCase().startsWith(emotePrefix);
    final sortedEmotes = [
      ...matchingEmotes.where(startsWithSearch),
      ...matchingEmotes.whereNot(startsWithSearch),
    ];

    final chatters = widget.channel.recentChatters;
    final matchingChatters = chatters.where((chatter) {
      return (chatSettings.userAutocompletionWithAt ? currentSearch.startsWith('@') : true) && '@${chatter.login}'.toLowerCase().contains(currentSearch);
    });

    return [
      for (final user in matchingChatters)
        AutocompletionItem(
          type: AutocompletionType.user,
          prefix: const Icon(Icons.person_outline_rounded),
          shortened: Text(
            '@${user.displayName ?? user.login}',
            style: TextStyle(color: user.color, fontWeight: FontWeight.bold),
          ),
          title: user.displayName ?? user.login!,
          subtitle: user.login,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${user.login} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
      for (final customCommand in Hive.box('CustomCommands').values.cast<CustomCommand>().where((element) => element.trigger.toLowerCase().startsWith(textEditingController.text.toLowerCase())))
        AutocompletionItem(
          type: AutocompletionType.customCommand,
          prefix: const Icon(Icons.keyboard_command_key_rounded),
          shortened: Text(customCommand.trigger),
          title: customCommand.trigger,
          subtitle: customCommand.command,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${customCommand.trigger} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
      for (final emote in sortedEmotes)
        AutocompletionItem(
          type: AutocompletionType.emote,
          prefix: EmoteGlyph(emote: emote, size: 24.0, image: () => CachedNetworkImage(imageUrl: emote.mipmap.last, width: 24.0, height: 24.0)),
          shortened: EmoteGlyph(emote: emote, size: 24.0, image: () => CachedNetworkImage(imageUrl: emote.mipmap.last, width: 24.0, height: 24.0)),
          title: emote.name,
          subtitle: emote.provider.name,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${emote.code ?? emote.name} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              final currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            child: ChatView(
              padding: MediaQuery.of(context).viewPadding,
              channel: widget.channel,
            ),
          ),
          // child: Container(),
        ),
        DarkBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                UploadQueueBar(channelName: widget.channel.name),
                if (replyChannelMessageChat != null)
                  Surface(
                    type: SurfaceType.error,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                child: Text(AppLocalizations.of(context)!.replyingTo),
                              ),
                              ChatMessage(message: replyChannelMessageChat!),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: Surface(
                            onTap: () => setReplyChannelMessageChat(null),
                            borderRadius: BorderRadius.circular(40.0),
                            // type: SurfaceType.error,
                            child: const Icon(Icons.close_outlined),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                      ],
                    ),
                  ),
                Surface(
                  type: SurfaceType.secondary,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 56.0 * 4.5),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      children: [
                        for (final autocompletionItem in getAutocompletionItems())
                          Tile(
                            onTap: autocompletionItem.onTap,
                            onLongPress: autocompletionItem.onLongPress,
                            prefix: autocompletionItem.prefix,
                            title: autocompletionItem.title,
                            subtitle: autocompletionItem.subtitle,
                          ),
                      ],
                    ),
                  ),
                ),
                // Surface(
                //   type: SurfaceType.tertiary,
                //   child: SizedBox(
                //     height: 56.0,
                //     child: ListView(
                //       padding: EdgeInsets.zero,
                //       scrollDirection: Axis.horizontal,
                //       children: [
                //         for (final autocompletionItem in getAutocompletionItems())
                //           InkWell(
                //             onTap: autocompletionItem.onTap,
                //             onLongPress: autocompletionItem.onLongPress,
                //             child: ConstrainedBox(
                //               constraints: BoxConstraints(minWidth: 56.0),
                //               child: Padding(
                //                 padding: const EdgeInsets.all(12.0),
                //                 child: autocompletionItem.shortened,
                //               ),
                //             ),
                //             // title: autocompletionItem.title,
                //             // subtitle: autocompletionItem.subtitle,
                //           ),
                //       ],
                //     ),
                //   ),
                // ),
                // if (textEditingController.text.split(' ').last.length >= 2 && (widget.channel.channelEmotes.state + widget.channel.client.globalEmotes.state).any((emote) => emote.name.toLowerCase().contains(textEditingController.text.split(' ').last.toLowerCase())))
                //   Ink(
                //     color: Theme.of(context).colorScheme.secondaryContainer,
                //     child: SizedBox(
                //       height: 32.0 + 24.0,
                //       child: ListView(
                //         scrollDirection: Axis.horizontal,
                //         children: [
                //           for (final emote in (widget.channel.channelEmotes.state + widget.channel.client.globalEmotes.state).where((emote) => emote.name.toLowerCase().contains(textEditingController.text.split(' ').last.toLowerCase())))
                //             Tooltip(
                //               message: emote.name,
                //               child: InkWell(
                //                 onTap: () {
                //                   final splits = textEditingController.text.split(' ');
                //                   splits.removeLast();
                //                   splits.add('${emote.code ?? emote.name} ');
                //                   textEditingController.text = splits.join(' ');
                //                   textEditingController.selection = TextSelection.fromPosition(
                //                     TextPosition(
                //                       offset: textEditingController.text.length,
                //                     ),
                //                   );
                //                   setState(() {});
                //                 },
                //                 child: Padding(
                //                   padding: const EdgeInsets.all(12.0),
                //                   child: Image.network(
                //                     emote.mipmap.last,
                //                   ),
                //                 ),
                //               ),
                //             ),
                //         ],
                //       ),
                //     ),
                //   ),

                SizedBox(
                  height: 48.0,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: pickAndUploadFiles,
                        child: const SizedBox(
                          width: 48.0,
                          height: 48.0,
                          child: Icon(
                            Icons.photo_size_select_actual_outlined,
                          ),
                        ),
                      ),
                      // const Separator(axis: Axis.vertical),
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          focusNode: textFocusNode,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            hintText: AppLocalizations.of(context)!.sendMessageIn(widget.channel.name), //'Send message in ',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (text) {
                            sendMessage();
                            textFocusNode.requestFocus();
                          },
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            emoteKeyboard = !emoteKeyboard;
                            pickingButtonIcon = false;
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            emoteKeyboard = true;
                            pickingButtonIcon = true;
                          });
                        },
                        child: const SizedBox(
                          width: 48.0,
                          height: 48.0,
                          child: Center(
                            child: EmoteButtonIconView(),
                          ),
                        ),
                      ),
                      // const Separator(axis: Axis.vertical),
                      InkWell(
                        onTap: () => sendMessage(),
                        onLongPress: () {
                          setState(() {
                            spamming = !spamming;
                          });
                        },
                        child: SizedBox(
                          width: 48.0,
                          height: 48.0,
                          child: Icon(
                            spamming ? Icons.send_and_archive_outlined : Icons.send_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Slides open and closed like a keyboard instead of popping in. The
                // AnimatedSwitcher keeps the picker mounted while it collapses.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  reverseDuration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    alignment: const Alignment(-1.0, -1.0),
                    child: child,
                  ),
                  child: !emoteKeyboard
                      ? const SizedBox.shrink(key: ValueKey(false))
                      : SizedBox(
                          key: const ValueKey(true),
                          height: 350.0,
                          child: EmotePicker(
                            client: widget.channel.client,
                            channel: widget.channel,
                            onPickButtonIcon: pickingButtonIcon
                                ? (emote) async {
                                    if (await chooseEmoteButtonIcon(context, emote) && mounted) {
                                      setState(() {
                                        emoteKeyboard = false;
                                        pickingButtonIcon = false;
                                      });
                                    }
                                  }
                                : null,
                            getFieldInput: () => textEditingController.text,
                            setFieldInput: (text) async {
                              setState(() {
                                textEditingController.text = text;
                                textEditingController.selection = TextSelection.fromPosition(TextPosition(offset: textEditingController.text.length));
                              });
                            },
                            insertFieldInput: (text) async {
                              setState(() {
                                final cursorPosition = max(0, textEditingController.selection.baseOffset);
                                if (textEditingController.text.isEmpty || cursorPosition >= textEditingController.text.length || textEditingController.text[cursorPosition] != ' ') text = '$text ';
                                if (cursorPosition > 0 && textEditingController.text[cursorPosition - 1] != ' ') text = ' $text';
                                textEditingController.text = textEditingController.text.substring(0, cursorPosition) + text + textEditingController.text.substring(cursorPosition);
                                textEditingController.selection = TextSelection.fromPosition(TextPosition(offset: cursorPosition + text.length));
                              });
                            },
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void addSplit(String? text) {
    if (text == null) return;
    setState(() {
      var splits = textEditingController.text.split(' ');
      splits.add(text);
      splits.removeWhere((element) => element.isEmpty);
      textEditingController.text = splits.join(' ');
      textEditingController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: textEditingController.text.length,
        ),
      );
    });
  }
}
