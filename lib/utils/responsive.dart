import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

enum DeviceOrientationType { portrait, landscape }

class Responsive {
  /// Detect device type based on screen width
  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceScreenType.desktop;
    if (width >= 600) return DeviceScreenType.tablet;
    return DeviceScreenType.mobile;
  }

  /// Detect screen orientation
  static DeviceOrientationType getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape
        ? DeviceOrientationType.landscape
        : DeviceOrientationType.portrait;
  }

  /// Responsive padding
  static double padding(BuildContext context) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return 96;
        case DeviceScreenType.tablet:
          return 72;
        case DeviceScreenType.mobile:
          return 24;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return 72;
        case DeviceScreenType.tablet:
          return 56;
        case DeviceScreenType.mobile:
          return 16;
      }
    }
  }

  /// Base font size
  static double fontSize(BuildContext context, {double base = 14}) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 3;
        case DeviceScreenType.tablet:
          return base + 2;
        case DeviceScreenType.mobile:
          return base + 1;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 2;
        case DeviceScreenType.tablet:
          return base + 1;
        case DeviceScreenType.mobile:
          return base;
      }
    }
  }

  static double appBarSize(BuildContext context, {double base = 30}) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 12;
        case DeviceScreenType.tablet:
          return base + 7;
        case DeviceScreenType.mobile:
          return base + 4;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 10;
        case DeviceScreenType.tablet:
          return base + 5;
        case DeviceScreenType.mobile:
          return base;
      }
    }
  }

  static double smallTextSize(BuildContext context, {double base = 11.5}) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 2.5;
        case DeviceScreenType.tablet:
          return base + 1.5;
        case DeviceScreenType.mobile:
          return base + 0.5;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 2;
        case DeviceScreenType.tablet:
          return base + 1;
        case DeviceScreenType.mobile:
          return base;
      }
    }
  }

  static double largeFontSize(BuildContext context, {double base = 15}) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 3;
        case DeviceScreenType.tablet:
          return base + 2;
        case DeviceScreenType.mobile:
          return base + 1;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 2;
        case DeviceScreenType.tablet:
          return base + 1;
        case DeviceScreenType.mobile:
          return base;
      }
    }
  }

  static double spacingBwtView(BuildContext context, {double base = 10}) {
    final device = getDeviceType(context);
    final orientation = getOrientation(context);

    if (orientation == DeviceOrientationType.landscape) {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 12;
        case DeviceScreenType.tablet:
          return base + 6;
        case DeviceScreenType.mobile:
          return base + 3;
      }
    } else {
      switch (device) {
        case DeviceScreenType.desktop:
          return base + 8;
        case DeviceScreenType.tablet:
          return base + 4;
        case DeviceScreenType.mobile:
          return base;
      }
    }
  }

  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == DeviceOrientationType.landscape;
  }
}
