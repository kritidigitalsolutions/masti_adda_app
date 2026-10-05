import 'package:flutter/material.dart';

class WebResponsive {
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 950;
  static const double laptopBreakpoint = 1280;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint &&
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isLaptop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint &&
      MediaQuery.sizeOf(context).width < laptopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= laptopBreakpoint;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static double contentHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= laptopBreakpoint) return 48.0;
    if (width >= tabletBreakpoint) return 32.0;
    if (width >= mobileBreakpoint) return 20.0;
    return 16.0;
  }

  static int gridColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1600) return 6;
    if (width >= 1280) return 5;
    if (width >= 950) return 4;
    if (width >= 650) return 3;
    return 2;
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? laptop;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.laptop,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= WebResponsive.laptopBreakpoint) {
      return desktop;
    } else if (width >= WebResponsive.tabletBreakpoint) {
      return laptop ?? desktop;
    } else if (width >= WebResponsive.mobileBreakpoint) {
      return tablet ?? laptop ?? desktop;
    } else {
      return mobile;
    }
  }
}
