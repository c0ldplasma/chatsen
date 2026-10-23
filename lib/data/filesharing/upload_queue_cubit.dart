import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../api/filesharing/upload_host.dart';
import 'upload_task.dart';

/// Owns every in-flight upload.
///
/// Lives above the channel views so an upload survives tab switches and the
/// composer never has to await anything: it starts a task, keeps accepting
/// input, and gets the URL handed back through [onUploaded] when the host
/// answers.
class UploadQueueCubit extends Cubit<List<UploadTask>> {
  UploadQueueCubit() : super(const []);

  /// Finished uploads, for the composer to insert at its caret. A broadcast
  /// stream rather than a callback because every open channel tab listens and
  /// filters by [UploadTask.channelName] — a single callback would be
  /// overwritten by whichever tab registered last.
  final StreamController<UploadTask> _completed = StreamController<UploadTask>.broadcast();

  Stream<UploadTask> get completed => _completed.stream;

  static const Duration _stallTimeout = Duration(seconds: 45);
  static const Duration _attemptTimeout = Duration(minutes: 5);

  int _nextId = 0;
  Timer? _stallWatchdog;

  /// Keeps finished-and-dismissed tasks out of the list while leaving failed
  /// ones visible until the user acts on them.
  void _publish() => emit(List.unmodifiable(state));

  List<UploadTask> tasksFor(String channelName) => state.where((task) => task.channelName == channelName).toList();

  Future<void> uploadFile({
    required String path,
    required String filename,
    required String channelName,
  }) async {
    final task = UploadTask(
      id: _nextId++,
      filename: filename,
      path: path,
      size: 0,
      channelName: channelName,
      hostName: UploadHosts.chain.first.name,
    );
    emit([...state, task]);
    _ensureWatchdog();

    final Uint8List bytes;
    try {
      // Async read: readAsBytesSync on the UI isolate janks visibly on
      // anything large, and file pickers happily hand back 100MB videos.
      bytes = await File(path).readAsBytes();
    } catch (e) {
      _fail(task, 'Could not read the file: $e');
      return;
    }

    await _runChain(task, bytes);
  }

  /// Walk the host chain until one succeeds. Only a hard failure moves on —
  /// a cancellation stops everything.
  Future<void> _runChain(UploadTask task, Uint8List bytes) async {
    task.size = bytes.length;
    task.sent = 0;
    task.status = UploadStatus.uploading;
    task.error = null;
    _publish();

    for (var i = 0; i < UploadHosts.chain.length; i++) {
      final host = UploadHosts.chain[i];
      if (task.status == UploadStatus.cancelled) return;

      task.hostName = host.name;
      task.sent = 0;
      task.status = UploadStatus.uploading;
      task.lastProgressAt = DateTime.now();
      final client = http.Client();
      task.client = client;
      _publish();

      try {
        final url = await host.upload(
          task.filename,
          bytes,
          client: client,
          timeout: _attemptTimeout,
          onProgress: (sent, total) {
            if (task.status == UploadStatus.cancelled) return;
            task.sent = sent;
            task.size = total;
            task.lastProgressAt = DateTime.now();
            if (sent >= total && task.status == UploadStatus.uploading) {
              task.status = UploadStatus.processing;
            }
            _publish();
          },
        );

        if (task.status == UploadStatus.cancelled) return;
        task.status = UploadStatus.done;
        task.url = url;
        task.client = null;
        _publish();
        _completed.add(task);
        remove(task);
        return;
      } catch (e) {
        if (task.status == UploadStatus.cancelled) return;
        final message = e is UploadFailure ? e.message : '$e';
        final isLast = i == UploadHosts.chain.length - 1;
        if (isLast) {
          _fail(task, '${host.name}: $message');
        } else {
          // Remember why we moved on so the chip can say "Litterbox failed,
          // trying nuuls…" instead of silently switching hosts.
          task.previousHostError = '${host.name}: $message';
        }
      } finally {
        client.close();
        if (identical(task.client, client)) task.client = null;
      }
    }
  }

  void _fail(UploadTask task, String error) {
    task.status = UploadStatus.failed;
    task.error = error;
    task.client = null;
    _publish();
  }

  Future<void> retry(UploadTask task) async {
    final Uint8List bytes;
    try {
      bytes = await File(task.path).readAsBytes();
    } catch (e) {
      _fail(task, 'Could not read the file: $e');
      return;
    }
    task.previousHostError = null;
    await _runChain(task, bytes);
  }

  void cancel(UploadTask task) {
    task.status = UploadStatus.cancelled;
    task.client?.close();
    task.client = null;
    remove(task);
  }

  void remove(UploadTask task) {
    emit(List.unmodifiable(state.where((element) => element.id != task.id)));
    if (state.isEmpty) {
      _stallWatchdog?.cancel();
      _stallWatchdog = null;
    }
  }

  /// A socket that goes quiet produces no error and no timeout — the request
  /// just hangs. Fail it ourselves so the chip offers a retry instead of
  /// spinning forever.
  void _ensureWatchdog() {
    _stallWatchdog ??= Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      for (final task in state) {
        if (task.status != UploadStatus.uploading) continue;
        if (now.difference(task.lastProgressAt) > _stallTimeout) {
          task.client?.close();
          _fail(task, '${task.hostName}: stalled for ${_stallTimeout.inSeconds}s');
        }
      }
    });
  }

  @override
  Future<void> close() {
    _stallWatchdog?.cancel();
    for (final task in state) {
      task.client?.close();
    }
    _completed.close();
    return super.close();
  }
}
