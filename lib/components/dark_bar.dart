import 'package:flutter/material.dart';

/// A bottom bar / input surface that uses theme-derived dark colors (adapting
/// to the selected theme seed) and propagates a matching foreground color to
/// icons and text via [IconTheme] / [DefaultTextStyle].
class DarkBar extends StatelessWidget {
  final Widget child;

  const DarkBar({super.key, required this.child});

  static Color backgroundColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.light ? cs.inverseSurface : cs.surfaceContainerLowest;
  }

  static Color foregroundColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.light ? cs.onInverseSurface : cs.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor(context);
    return Material(
      color: backgroundColor(context),
      child: SafeArea(
        top: false,
        child: IconTheme(
          data: IconThemeData(color: fg),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg),
            child: child,
          ),
        ),
      ),
    );
  }
}
