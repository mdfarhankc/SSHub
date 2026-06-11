import 'package:flutter/widgets.dart';

enum DeviceType { mobile, tablet, desktop }

abstract final class Responsive {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static DeviceType deviceTypeOf(BuildContext context) {
    final w = widthOf(context);
    if (w < mobileMaxWidth) return DeviceType.mobile;
    if (w < tabletMaxWidth) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      widthOf(context) < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= tabletMaxWidth;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    switch (deviceTypeOf(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop;
    }
  }
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  DeviceType get deviceType => Responsive.deviceTypeOf(this);

  T responsive<T>({required T mobile, T? tablet, required T desktop}) =>
      Responsive.value(this, mobile: mobile, tablet: tablet, desktop: desktop);
}
