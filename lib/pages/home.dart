import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:chatsen/components/surface.dart';
import 'package:chatsen/modal/channel.dart';
import 'package:chatsen/widgets/browser/stream_container.dart';
import 'package:chatsen/widgets/cookies_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../components/modal.dart';
import '../modal/chatsen.dart';
import '../tmi/channel/channel.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_channels.dart';
import '../widgets/channel_view.dart';
import '../widgets/home_tab.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: preferredSize.height,
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            InkWell(
              child: SizedBox(
                height: preferredSize.height,
                width: preferredSize.height,
                child: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              onTap: () => appWindow.close(),
            ),
          ],
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight / 2.0);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const String _lastChannelKey = 'lastChannel';

  TabController? _tabController;
  int _lastLength = -1;

  int _initialIndexFor(List<Channel> channels) {
    final lastName = Hive.box('Settings').get(_lastChannelKey);
    if (lastName is! String || lastName.isEmpty) return 0;
    final idx = channels.indexWhere((c) => c.name == lastName);
    return idx >= 0 ? idx + 1 : 0;
  }

  void _onTabChanged(List<Channel> channels) {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    final index = controller.index;
    final name = index == 0 ? '' : (index - 1 < channels.length ? channels[index - 1].name : '');
    Hive.box('Settings').put(_lastChannelKey, name);
  }

  TabController _ensureController(List<Channel> channels) {
    final desiredLength = 1 + channels.length;
    if (_tabController == null || _lastLength != desiredLength) {
      _tabController?.dispose();
      _tabController = TabController(
        length: desiredLength,
        vsync: this,
        initialIndex: _initialIndexFor(channels).clamp(0, desiredLength - 1),
      );
      _tabController!.addListener(() => _onTabChanged(channels));
      _lastLength = desiredLength;
    }
    return _tabController!;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamContainer(
        child: BlocBuilder<ClientChannels, List<Channel>>(
          bloc: context.read<Client>().channels,
          builder: (context, state) {
            final tabController = _ensureController(state);
            return Scaffold(
              backgroundColor: Platform.isWindows ? Colors.transparent : null,
              appBar: Platform.isWindows ? const MyAppBar() : null,
              extendBody: true,
              extendBodyBehindAppBar: true,
              bottomNavigationBar: Builder(builder: (context) {
                final cs = Theme.of(context).colorScheme;
                final isLight = Theme.of(context).brightness == Brightness.light;
                final bg = isLight ? cs.inverseSurface : cs.surfaceContainerLowest;
                final fg = isLight ? cs.onInverseSurface : cs.onSurface;
                return Material(
                  color: bg,
                  child: SafeArea(
                    top: false,
                    child: IconTheme(
                      data: IconThemeData(color: fg),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: fg),
                        child: TabBar(
                          controller: tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: fg,
                          unselectedLabelColor: fg.withOpacity(0.6),
                          indicatorColor: fg,
                          dividerColor: Colors.transparent,
                          tabs: [
                            GestureDetector(
                              onLongPress: () {
                                Modal.show(
                                  context: context,
                                  child: const ChatsenModal(),
                                );
                              },
                              child: const SizedBox(
                                height: 48.0,
                                child: Icon(Icons.home_outlined),
                              ),
                            ),
                            for (final channel in state)
                              GestureDetector(
                                onLongPress: () {
                                  Modal.show(
                                    context: context,
                                    child: ChannelModal(channel: channel),
                                  );
                                },
                                child: SizedBox(
                                  height: 48.0,
                                  child: Center(child: Text(channel.name)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              body: TabBarView(
                controller: tabController,
                children: [
                  const HomeTab(),
                  for (final channel in state)
                    ChannelView(
                      channel: channel,
                    ),
                ],
              ),
            );
          },
        ),
      );
}
