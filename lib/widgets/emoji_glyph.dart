import 'package:flutter/material.dart';

import '../data/emote.dart';
import '../providers/emojis.dart';

/// Draws an emote, using the platform's emoji font for emojis (Apple's on
/// iOS, Google's on Android) instead of an image.
class EmoteGlyph extends StatelessWidget {
  final Emote emote;
  final double size;
  final Widget Function() image;

  const EmoteGlyph({
    super.key,
    required this.emote,
    required this.size,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    if (emote.provider is! EmojiProvider || emote.code == null) return image();
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        child: Text(
          emote.code!,
          style: TextStyle(fontSize: size, height: 1.0),
        ),
      ),
    );
  }
}
