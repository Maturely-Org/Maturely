import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 1024;
}

enum AppFormFactor { phone, tablet, desktop }

AppFormFactor formFactorForWidth(double width) {
  if (width >= AppBreakpoints.tablet) return AppFormFactor.desktop;
  if (width >= AppBreakpoints.phone) return AppFormFactor.tablet;
  return AppFormFactor.phone;
}

double adaptivePagePaddingForWidth(double width) {
  final ff = formFactorForWidth(width);
  switch (ff) {
    case AppFormFactor.phone:
      return 16;
    case AppFormFactor.tablet:
      return 20;
    case AppFormFactor.desktop:
      return 24;
  }
}

double adaptiveCardPaddingForWidth(double width) {
  final ff = formFactorForWidth(width);
  switch (ff) {
    case AppFormFactor.phone:
      return 16;
    case AppFormFactor.tablet:
      return 18;
    case AppFormFactor.desktop:
      return 20;
  }
}

double adaptiveGapForWidth(double width) {
  final ff = formFactorForWidth(width);
  switch (ff) {
    case AppFormFactor.phone:
      return 12;
    case AppFormFactor.tablet:
      return 14;
    case AppFormFactor.desktop:
      return 16;
  }
}

int adaptiveGridColumnsForWidth(double width, {int phone = 1, int tablet = 2, int desktop = 3}) {
  final ff = formFactorForWidth(width);
  switch (ff) {
    case AppFormFactor.phone:
      return phone;
    case AppFormFactor.tablet:
      return tablet;
    case AppFormFactor.desktop:
      return desktop;
  }
}

class ResponsiveScaffoldBody extends StatelessWidget {
  final Widget child;
  final EdgeInsets? paddingOverride;

  const ResponsiveScaffoldBody({super.key, required this.child, this.paddingOverride});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pad = paddingOverride ?? EdgeInsets.all(adaptivePagePaddingForWidth(width));
        return Padding(padding: pad, child: child);
      },
    );
  }
}

class ResponsiveWrapRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  const ResponsiveWrapRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
