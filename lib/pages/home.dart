import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:chatsen/modal/channel.dart';
import 'package:chatsen/widgets/browser/stream_container.dart';
import 'package:chatsen/widgets/cookies_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../components/dark_bar.dart';
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

/// Lets descendants (the search/stream tiles in [HomeTab]) ask the home page to
/// switch to a channel tab after joining it. Provided via [Provider] from
/// [_HomePageState] so it can drive the manually-managed [TabController].
class HomeTabSwitcher {
  final void Function(String channelName) open;
  const HomeTabSwitcher(this.open);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const String _lastChannelKey = 'lastChannel';

  TabController? _tabController;
  int _lastLength = -1;
  // Always reflects the channel list from the latest build so the tab listener
  // doesn't capture a stale list (the controller is only rebuilt when the
  // length changes, but channels can be swapped/reordered at the same count).
  List<Channel> _channels = const [];

  int _initialIndexFor(List<Channel> channels) {
    final lastName = Hive.box('Settings').get(_lastChannelKey);
    if (lastName is! String || lastName.isEmpty) return 0;
    final idx = channels.indexWhere((c) => c.name == lastName);
    return idx >= 0 ? idx + 1 : 0;
  }

  late final HomeTabSwitcher _switcher = HomeTabSwitcher(_openChannel);

  // Switch to the given channel's tab. Persist it as the last channel first so
  // that if the channel was just added (tab count grows -> controller is
  // recreated with initialIndex), the recreated controller already lands here;
  // for an already-joined channel the post-frame animateTo moves to it.
  void _openChannel(String channelName) {
    Hive.box('Settings').put(_lastChannelKey, channelName);
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        if (!mounted) return;
        final controller = _tabController;
        if (controller == null) return;
        final idx = _channels.indexWhere((c) => c.name == channelName);
        if (idx < 0) return;
        final target = (idx + 1).clamp(0, controller.length - 1);
        if (controller.index != target) controller.animateTo(target);
      });
    });
  }

  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    final index = controller.index;
    final name = index == 0
        ? ''
        : (index - 1 < _channels.length ? _channels[index - 1].name : '');
    Hive.box('Settings').put(_lastChannelKey, name);
  }

  TabController _ensureController(List<Channel> channels) {
    _channels = channels;
    final desiredLength = 1 + channels.length;
    if (_tabController == null || _lastLength != desiredLength) {
      _tabController?.dispose();
      _tabController = TabController(
        length: desiredLength,
        vsync: this,
        initialIndex: _initialIndexFor(channels).clamp(0, desiredLength - 1),
      );
      _tabController!.addListener(_onTabChanged);
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
            return Provider<HomeTabSwitcher>.value(
              value: _switcher,
              child: Scaffold(
                backgroundColor: Platform.isWindows ? Colors.transparent : null,
                appBar: Platform.isWindows ? const MyAppBar() : null,
                extendBody: true,
                extendBodyBehindAppBar: true,
                bottomNavigationBar: DarkBar(
                  child: Builder(builder: (context) {
                    final fg = DarkBar.foregroundColor(context);
                    return TabBar(
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
                    );
                  }),
                ),
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
              ),
            );
          },
        ),
      );
}
