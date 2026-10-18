import 'package:app/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

/// Construtor responsivo que alterna entre renderização móvel e desktop.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  final Widget mobileBody;
  final Widget desktopBody;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < Breakpoints.mobileMax;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= Breakpoints.mobileMax;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.mobileMax) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
