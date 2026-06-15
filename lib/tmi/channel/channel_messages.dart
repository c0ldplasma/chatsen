import 'dart:math';

import 'package:bloc/bloc.dart';

import 'channel_message.dart';
import 'messages/channel_message_id.dart';

class ChannelMessages extends Cubit<List<ChannelMessage>> {
  ChannelMessages() : super([]);

  static List<ChannelMessage> sort(List<ChannelMessage> messages) => messages..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  // While deferring, add() mutates the working list without emitting so a
  // bulk history insert produces a single rebuild instead of one per message
  // (which made the chat visibly scroll through every message as it loaded).
  // A companion id set keeps dedup O(1) across a large bulk insert.
  bool _deferEmit = false;
  List<ChannelMessage>? _deferredState;
  Set<String>? _deferredIds;

  bool _containsId(Iterable<ChannelMessage> list, ChannelMessage message) =>
      message is ChannelMessageId && list.whereType<ChannelMessageId>().any((e) => e.id == (message as ChannelMessageId).id);

  void _emitSortedCapped(List<ChannelMessage> messages) {
    final sorted = sort(messages);
    emit(sorted.length > 1000 ? sorted.sublist(sorted.length - 1000) : sorted);
  }

  void beginBulk() {
    _deferEmit = true;
    _deferredState = [...state];
    _deferredIds = state.whereType<ChannelMessageId>().map((e) => e.id).toSet();
  }

  void endBulk() {
    _deferEmit = false;
    final pending = _deferredState;
    _deferredState = null;
    _deferredIds = null;
    if (pending != null) _emitSortedCapped(pending);
  }

  void add(ChannelMessage message) {
    if (_deferEmit) {
      if (message is ChannelMessageId && !_deferredIds!.add((message as ChannelMessageId).id)) return;
      _deferredState!.add(message);
      return;
    }
    if (_containsId(state, message)) return;
    _emitSortedCapped([...state.skip(max(0, state.length - 999)), message]);
  }

  /// Atomically swap [previous] for [next] in a single emit so the UI never
  /// observes the intermediate list without either entry (avoids the visible
  /// jump that two separate remove/add emits would cause).
  void replace(ChannelMessage? previous, ChannelMessage next) {
    if (_containsId(state, next)) return;
    final without = previous == null ? state : state.where((m) => m != previous);
    _emitSortedCapped([...without.skip(max(0, without.length - 999)), next]);
  }
}
