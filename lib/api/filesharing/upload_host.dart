import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Reports how many of [total] bytes have been handed to the socket.
typedef UploadProgress = void Function(int sent, int total);

/// Why an attempt failed, coarse enough to map to a short user-facing message.
enum UploadFailureKind {
  /// Never got an HTTP response: DNS failure, refused, unreachable, TLS. Every
  /// host failing this way is how "offline" is recognised.
  network,

  /// Stalled mid-upload, no answer after the upload, or the attempt cap.
  timeout,

  /// The host answered with a non-200 status.
  http,

  /// 200, but the body was not a link.
  badResponse,

  unknown,
}

/// Thrown when a host rejects an upload or does not answer in time. Carries the
/// host name so the UI can say which one failed before the chain moves on.
class UploadFailure implements Exception {
  final String hostName;
  final UploadFailureKind kind;

  /// Technical detail, shown only in the "details" dialog.
  final String message;

  final int? statusCode;

  UploadFailure(this.hostName, this.kind, this.message, {this.statusCode});

  @override
  String toString() => '$hostName: $message';
}

/// A file host we can POST an anonymous upload to.
///
/// Implementations differ only in endpoint, field names and how the URL comes
/// back, so the chain in [UploadHosts.chain] can fall through them in order.
abstract class UploadHost {
  /// Shown in the upload chip ("uploading to Litterbox…").
  String get name;

  /// Roughly how long links survive, for the UI to warn about. Null = until the
  /// host decides otherwise.
  Duration? get retention;

  Uri get endpoint;

  /// The multipart field the file goes in.
  String get fileField;

  /// Extra form fields the host expects.
  Map<String, String> get fields => const {};

  /// Most of these hosts answer with the bare URL as plain text; override where
  /// that is not true.
  String parseResponse(String body) => body.trim();

  Future<String> upload(
    String filename,
    Uint8List bytes, {
    required UploadProgress onProgress,
    required http.Client client,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final request = _ProgressMultipartRequest(
      'POST',
      endpoint,
      onProgress: onProgress,
    );
    // Some hosts (notably 0x0.st) reject the default Dart user agent outright.
    request.headers['User-Agent'] = 'Chatsen/2.0 (https://github.com/Chatsen/Chatsen)';
    // Not MultipartFile.fromBytes: that wraps the whole file in a single stream
    // event, so the progress counter jumped straight to 100% and the real
    // transfer happened under "processing". Small chunks let dart:io's socket
    // backpressure pace the stream, so the count follows the actual send.
    request.files.add(http.MultipartFile(fileField, _chunked(bytes), bytes.length, filename: filename));
    request.fields.addAll(fields);

    final http.StreamedResponse response;
    try {
      response = await client.send(request).timeout(timeout);
    } on TimeoutException {
      throw UploadFailure(name, UploadFailureKind.timeout, 'timed out after ${timeout.inSeconds}s');
    } catch (e) {
      throw UploadFailure(name, _classify(e), '$e');
    }

    final String body;
    try {
      body = await response.stream.bytesToString().timeout(timeout);
    } on TimeoutException {
      throw UploadFailure(name, UploadFailureKind.timeout, 'timed out reading the response');
    } catch (e) {
      throw UploadFailure(name, _classify(e), '$e');
    }

    if (response.statusCode != 200) {
      throw UploadFailure(
        name,
        UploadFailureKind.http,
        'HTTP ${response.statusCode}: ${_short(body)}',
        statusCode: response.statusCode,
      );
    }

    final url = parseResponse(body);
    if (!url.startsWith('http')) {
      throw UploadFailure(name, UploadFailureKind.badResponse, 'unexpected response: ${_short(url)}');
    }
    return url;
  }

  /// Anything that means "no usable HTTP response came back" is a network
  /// failure. IOClient rethrows socket errors as a ClientException that
  /// *implements* SocketException, but a connection torn down mid-flight (the
  /// usual airplane-mode case) arrives as an HttpException that it rewraps as
  /// a plain ClientException — so check for that too, or a dropped connection
  /// would read as "unknown" and defeat the offline detection.
  static UploadFailureKind _classify(Object e) {
    if (e is SocketException || e is HandshakeException || e is HttpException || e is http.ClientException) {
      return UploadFailureKind.network;
    }
    return UploadFailureKind.unknown;
  }

  static const int _chunkSize = 64 * 1024;

  /// An async* generator suspends at each yield while its subscriber is paused,
  /// which is what lets the socket throttle it.
  static Stream<List<int>> _chunked(Uint8List bytes) async* {
    for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
      yield Uint8List.sublistView(bytes, offset, min(offset + _chunkSize, bytes.length));
    }
  }

  static String _short(String body) {
    final single = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    return single.length <= 120 ? single : '${single.substring(0, 120)}…';
  }
}

/// catbox.moe's temporary host. Anonymous, but links expire — 72h is its max.
class LitterboxHost extends UploadHost {
  @override
  String get name => 'Litterbox';

  @override
  Duration? get retention => const Duration(hours: 72);

  @override
  Uri get endpoint => Uri.parse('https://litterbox.catbox.moe/resources/internals/api.php');

  @override
  String get fileField => 'fileToUpload';

  @override
  Map<String, String> get fields => const {
        'reqtype': 'fileupload',
        'time': '72h',
      };
}

/// The host Chatterino uploads to by default. Anonymous, no API key.
class NuulsHost extends UploadHost {
  @override
  String get name => 'nuuls';

  @override
  Duration? get retention => null;

  @override
  Uri get endpoint => Uri.parse('https://i.nuuls.com/upload');

  @override
  String get fileField => 'attachment';
}

/// "The Null Pointer". Retention scales with file size (30–365 days).
class NullPointerHost extends UploadHost {
  @override
  String get name => '0x0.st';

  @override
  Duration? get retention => const Duration(days: 30);

  @override
  Uri get endpoint => Uri.parse('https://0x0.st');

  @override
  String get fileField => 'file';
}

class UploadHosts {
  /// Tried in order; each is only reached if the previous one failed outright.
  /// Litterbox stays first so behaviour is unchanged when it is healthy.
  static final List<UploadHost> chain = [
    LitterboxHost(),
    NuulsHost(),
    NullPointerHost(),
  ];
}

/// Counts bytes as the multipart body is drained.
///
/// `package:http` exposes no upload progress, but [http.BaseRequest.finalize]
/// is the single point every byte passes through on its way to the socket, so
/// wrapping it here gives a faithful "sent" count without pulling in `dio`.
/// This counts bytes accepted by the socket, which runs ahead of what the host
/// has received by at most the OS send buffer — hence the UI's indeterminate
/// "processing" state once the count reaches 100%.
class _ProgressMultipartRequest extends http.MultipartRequest {
  final UploadProgress onProgress;

  _ProgressMultipartRequest(
    super.method,
    super.url, {
    required this.onProgress,
  });

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    var sent = 0;

    final stream = byteStream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sent += data.length;
          onProgress(sent, total);
          sink.add(data);
        },
      ),
    );

    return http.ByteStream(stream);
  }
}
