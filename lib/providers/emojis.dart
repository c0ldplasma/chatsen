import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/emote.dart';
import 'emote_provider.dart';
import 'provider.dart';

class EmojiProvider extends Provider with EmoteProvider {
  @override
  String get name => 'Emoji';

  @override
  String? get description => null;

  @override
  Future<List<Emote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json'));
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as List;
    // Emojis render as text in the platform's emoji font, so only list the
    // ones that font has; anything newer would show as an empty box.
    final supportedKey = Platform.isIOS ? 'has_img_apple' : 'has_img_google';
    // The file is in codepoint order. Use Unicode's order instead (Smileys &
    // Emotion first), with the bare skin tone swatches ("Component") at the end.
    int rank(dynamic entry) => (entry['category'] == 'Component' ? 100000 : 0) + (entry['sort_order'] as int);
    final emojis = responseJson.where((entry) => entry[supportedKey] == true).toList()..sort((a, b) => rank(a).compareTo(rank(b)));
    return [
      for (final emojiData in emojis)
        Emote(
          id: emojiData['unified'],
          code: emojiData['unified'].split('-').map((x) => String.fromCharCode(int.parse(x, radix: 16))).join(),
          name: emojiData['short_name'],
          mipmap: [
            'https://raw.githubusercontent.com/iamcal/emoji-data/master/img-twitter-72/${emojiData['image']}',
          ],
          provider: this,
          category: emojiData['category'],
        ),
    ];
  }

  @override
  Future<List<Emote>> channelEmotes(String uid) async {
    return [];
  }

  @override
  String? emoteUrl(String id) => null;
}
