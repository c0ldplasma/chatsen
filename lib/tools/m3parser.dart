import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Colors the app's design uses that Material 3 dropped from [ColorScheme].
class AppColors extends ThemeExtension<AppColors> {
  /// The old `ColorScheme.surfaceVariant`. Its replacement,
  /// `surfaceContainerHighest`, is a different tone, so it's kept here to keep
  /// the surfaces that use it looking the same.
  final Color surfaceVariant;

  const AppColors({required this.surfaceVariant});

  /// The `surfaceVariant` that `ColorScheme.fromSeed` used to produce.
  factory AppColors.fromSeed(Color seed, Brightness brightness) {
    final scheme = SchemeTonalSpot(
      sourceColorHct: Hct.fromInt(seed.toARGB32()),
      isDark: brightness == Brightness.dark,
      contrastLevel: 0.0,
    );
    return AppColors(surfaceVariant: Color(MaterialDynamicColors.surfaceVariant.getArgb(scheme)));
  }

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? surfaceVariant}) => AppColors(surfaceVariant: surfaceVariant ?? this.surfaceVariant);

  @override
  AppColors lerp(AppColors? other, double t) => other == null ? this : AppColors(surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!);
}

class M3Parser {
  static ThemeData patchTheme(ThemeData baseTheme, {required AppColors appColors}) {
    final newThemeData = baseTheme.copyWith(
      extensions: [appColors],
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'ProductSans',
        bodyColor: baseTheme.colorScheme.onSurface,
        displayColor: baseTheme.colorScheme.onSurface,
        decorationColor: baseTheme.colorScheme.onSurface,
      ),
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: baseTheme.colorScheme.onPrimaryContainer.withValues(alpha: 0.0),
            // width: 2,
            width: 0,
          ),
        ),
        labelColor: baseTheme.colorScheme.onPrimaryContainer,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        hintStyle: (baseTheme.inputDecorationTheme.hintStyle ?? const TextStyle()).copyWith(
          color: baseTheme.colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
        ),
      ),
      switchTheme: baseTheme.switchTheme.copyWith(
        trackColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
        thumbColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
      ),
      checkboxTheme: baseTheme.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.all(baseTheme.colorScheme.primary),
        checkColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return newThemeData;
  }
}
