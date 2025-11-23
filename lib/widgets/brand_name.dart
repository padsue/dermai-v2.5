import 'package:flutter/material.dart';

enum BrandNameSize {
  small,
  medium,
  large,
  extraLarge,
  headlineMedium,
}

class BrandName extends StatelessWidget {
  final BrandNameSize size;
  final FontWeight? firstPartWeight;
  final FontWeight? secondPartWeight;
  final bool useSecondaryColor;
  final MainAxisAlignment alignment;

  const BrandName({
    super.key,
    this.size = BrandNameSize.medium,
    this.firstPartWeight,
    this.secondPartWeight,
    this.useSecondaryColor = false,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    TextStyle? getTextStyle() {
      switch (size) {
        case BrandNameSize.small:
          return theme.textTheme.titleLarge;
        case BrandNameSize.medium:
          return theme.textTheme.headlineSmall;
        case BrandNameSize.large:
          return theme.textTheme.displayMedium;
        case BrandNameSize.extraLarge:
          return theme.textTheme.displayLarge;
        case BrandNameSize.headlineMedium:
          return theme.textTheme.headlineMedium;
      }
    }

    final baseStyle = getTextStyle();
    final secondColor = useSecondaryColor
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Text(
          "Derm",
          style: baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: firstPartWeight ?? FontWeight.bold,
          ),
        ),
        Text(
          "AI",
          style: baseStyle?.copyWith(
            color: secondColor,
            fontWeight: secondPartWeight ?? FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
