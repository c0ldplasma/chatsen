import 'dart:convert';
import 'dart:isolate';

/// Decodes [bodyBytes] as UTF-8 JSON and runs [map] over the result on a
/// background isolate, keeping heavy decode + model mapping off the UI thread.
///
/// [map] must be a top-level/static-referencing closure (no capture of
/// non-sendable context) so it can be sent to the worker isolate.
Future<T> decodeJsonInIsolate<T>(List<int> bodyBytes, T Function(dynamic json) map) {
  return Isolate.run(() => map(json.decode(utf8.decode(bodyBytes))));
}
