import 'package:http/http.dart' as http;

enum UploadStatus {
  /// Bytes are going out; [UploadTask.progress] is meaningful.
  uploading,

  /// Every byte was written and we are waiting for the host to answer. The
  /// socket buffers, so "100% sent" is not "done" — show this indeterminate.
  processing,

  /// Finished; [UploadTask.url] holds the link.
  done,

  failed,
  cancelled,
}

/// One file on its way to a host. Mutable and short-lived: the queue mutates it
/// in place and notifies listeners, so the chip can rebuild without rebuilding
/// the whole composer.
class UploadTask {
  final int id;
  final String filename;

  /// Kept so a failed upload can be retried without asking the user to pick
  /// the file again.
  final String path;

  int size;

  /// The channel whose composer gets the URL. Uploads stay bound to where they
  /// started so switching tabs mid-upload cannot drop a link into a stranger's
  /// chat.
  final String channelName;

  UploadStatus status = UploadStatus.uploading;
  int sent = 0;

  /// Name of the host currently being tried, for "uploading to Litterbox…".
  String hostName;

  /// Set once a previous host failed and the chain moved on, so the chip can
  /// explain why it is on its second attempt.
  String? previousHostError;

  String? url;
  String? error;

  /// The client for the in-flight attempt; closing it aborts the request.
  http.Client? client;

  /// When the last byte moved, for stall detection.
  DateTime lastProgressAt = DateTime.now();

  /// When every byte was out and we started waiting on the host. Drives both
  /// the elapsed-seconds label and the processing timeout.
  DateTime? processingSince;

  /// Why the watchdog aborted the current attempt, if it did. Closing the
  /// client surfaces as a generic connection error, so the real reason is
  /// recorded here first and preferred when reporting the failure.
  String? abortReason;

  UploadTask({
    required this.id,
    required this.filename,
    required this.path,
    required this.size,
    required this.channelName,
    required this.hostName,
  });

  double? get progress {
    if (status != UploadStatus.uploading) return null;
    if (size <= 0) return null;
    final ratio = sent / size;
    return ratio.isFinite ? ratio.clamp(0.0, 1.0) : null;
  }

  /// Whole seconds spent waiting on the host, or null outside that phase.
  int? get processingSeconds {
    final since = processingSince;
    if (status != UploadStatus.processing || since == null) return null;
    return DateTime.now().difference(since).inSeconds;
  }

  bool get isFinished => status == UploadStatus.done || status == UploadStatus.cancelled;
}
