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
  bool _deferEmit = false;
  List<ChannelMessage>? _deferredState;

  void beginBulk() {
    _deferEmit = true;
    _deferredState = [...state];
  }

  void endBulk() {
    _deferEmit = false;
    final pending = _deferredState;
    _deferredState = null;
    if (pending == null) return;
    final sorted = sort(pending);
    emit(sorted.length > 1000 ? sorted.sublist(sorted.length - 1000) : sorted);
  }

  void add(ChannelMessage message) {
    if (_deferEmit) {
      final working = _deferredState!;
      if (message is ChannelMessageId && working.whereType<ChannelMessageId>().any((e) => e.id == (message as ChannelMessageId).id)) return;
      working.add(message);
      return;
    }
    if (message is ChannelMessageId && state.whereType<ChannelMessageId>().any((e) => e.id == (message as ChannelMessageId).id)) return;
    emit(
      sort([
        ...state.skip(max(0, state.length - 999)),
        message,
      ]),
    );
  }

  void remove(ChannelMessage message) {
    if (!state.contains(message)) return;
    emit(state.where((m) => m != message).toList());
  }

  /// Atomically swap [previous] for [next] in a single emit so the UI never
  /// observes the intermediate list without either entry (avoids the visible
  /// jump that two separate remove/add emits would cause).
  void replace(ChannelMessage? previous, ChannelMessage next) {
    if (next is ChannelMessageId && state.whereType<ChannelMessageId>().any((e) => e.id == (next as ChannelMessageId).id)) return;
    final without = previous == null ? state : state.where((m) => m != previous);
    emit(sort([
      ...without.skip(max(0, without.length - 999)),
      next,
    ]));
  }
}
