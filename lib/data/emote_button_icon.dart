import 'dart:io';
import 'dart:ui' as ui;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../providers/emojis.dart';
import 'emote.dart';

/// The emote shown on the button that opens the emote menu. Defaults to Kappa.
///
/// Image emotes are downloaded once and kept in the app's support directory,
/// so the button survives the emote being removed from its provider, the
/// image cache being cleared, and being offline. Emojis are stored as text.
class EmoteButtonIcon {
  static const String iconKey = 'emoteButtonIcon';
  static const String grayscaleKey = 'emoteButtonGrayscale';

  static Box get _box => Hive.box('Settings');

  // Resolved once at startup so the button can build synchronously. Only file
  // names are stored: the absolute container path changes between iOS
  // installs and updates.
  static Directory? _directory;

  static Future<void> init() async {
    _directory = Directory('${(await getApplicationSupportDirectory()).path}/emote_button');
  }

  static bool get grayscale => _box.get(grayscaleKey, defaultValue: false) as bool;
  static Future<void> setGrayscale(bool value) => _box.put(grayscaleKey, value);

  /// The saved image, or null for an emoji or the default Kappa.
  static File? get file {
    final name = (_box.get(iconKey) as Map?)?['file'] as String?;
    if (name == null || _directory == null) return null;
    final file = File('${_directory!.path}/$name');
    return file.existsSync() ? file : null;
  }

  static String? get emoji => (_box.get(iconKey) as Map?)?['emoji'] as String?;

  static String? get name => (_box.get(iconKey) as Map?)?['name'] as String?;

  /// Downloads [emote] and makes it the button. Throws if it can't be
  /// downloaded or isn't a decodable image; the current button is kept then.
  static Future<void> set(Emote emote) async {
    if (emote.provider is EmojiProvider && emote.code != null) {
      final previous = file;
      await _box.put(iconKey, {'name': emote.name, 'emoji': emote.code});
      _deleteQuietly(previous);
      return;
    }

    final response = await http.get(Uri.parse(emote.mipmap.last)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(emote.mipmap.last));
    }
    // Make sure it's an image before replacing the current button with it.
    final codec = await ui.instantiateImageCodec(response.bodyBytes);
    codec.dispose();

    // A fresh name each time: Image.file caches by path, so overwriting the
    // same file would keep showing the old emote.
    final directory = _directory!;
    await directory.create(recursive: true);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${_extension(response, emote.mipmap.last)}';
    await File('${directory.path}/$fileName').writeAsBytes(response.bodyBytes, flush: true);

    final previous = file;
    await _box.put(iconKey, {'name': emote.name, 'file': fileName});
    _deleteQuietly(previous);
  }

  static Future<void> reset() async {
    final previous = file;
    await _box.delete(iconKey);
    _deleteQuietly(previous);
  }

  static String _extension(http.Response response, String url) {
    final type = response.headers['content-type'] ?? '';
    if (type.contains('gif')) return '.gif';
    if (type.contains('webp')) return '.webp';
    if (type.contains('png')) return '.png';
    final path = Uri.parse(url).path;
    final dot = path.lastIndexOf('.');
    return dot != -1 && path.length - dot <= 5 ? path.substring(dot) : '';
  }

  static void _deleteQuietly(File? file) {
    file?.delete().catchError((_) => file);
  }
}
