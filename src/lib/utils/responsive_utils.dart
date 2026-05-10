import 'dart:math';
import 'package:flutter/material.dart';

/// Unified responsive utilities with both proportional scaling and breakpoint logic.
class ResponsiveUtils {
  final BuildContext context;
  late final Size _screenSize;
  late final double _width;
  late final double _height;
  late final double _diagonal;
  late final Orientation _orientation;
  late final DeviceType _deviceType;
  late final Breakpoint _breakpoint;

  ResponsiveUtils(this.context) {
    _screenSize = MediaQuery.of(context).size;
    _width = _screenSize.width;
    _height = _screenSize.height;
    _diagonal = _calculateDiagonal();
    _orientation = MediaQuery.of(context).orientation;
    _deviceType = _determineDeviceType();
    _breakpoint = _determineBreakpoint();
  }

  double _calculateDiagonal() => sqrt((_width * _width) + (_height * _height));

  DeviceType _determineDeviceType() {
    if (_diagonal < 600) return DeviceType.mobile;
    if (_diagonal < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  Breakpoint _determineBreakpoint() {
    if (_width < 600) return Breakpoint.small;
    if (_width < 900) return Breakpoint.medium;
    if (_width < 1200) return Breakpoint.large;
    return Breakpoint.extraLarge;
  }

  // Getters
  Size get screenSize => _screenSize;
  double get width => _width;
  double get height => _height;
  double get diagonal => _diagonal;
  Orientation get orientation => _orientation;
  DeviceType get deviceType => _deviceType;
  Breakpoint get breakpoint => _breakpoint;
  bool get isMobile => _deviceType == DeviceType.mobile;
  bool get isTablet => _deviceType == DeviceType.tablet;
  bool get isDesktop => _deviceType == DeviceType.desktop;
  bool get isLandscape => _orientation == Orientation.landscape;
  bool get isPortrait => _orientation == Orientation.portrait;
  bool get isSmall => _breakpoint == Breakpoint.small;
  bool get isMedium => _breakpoint == Breakpoint.medium;
  bool get isLarge => _breakpoint == Breakpoint.large;
  bool get isExtraLarge => _breakpoint == Breakpoint.extraLarge;

  // Proportional helpers
  double wp(double percentage) => _width * percentage / 100;
  double hp(double percentage) => _height * percentage / 100;
  double sp(double percentage) => _diagonal * percentage / 100;

  /// Responsive font size with breakpoint modulation.
  double fontSize(double baseSize) {
    const baseWidth = 375.0;
    final scaleFactor = (_width / baseWidth).clamp(0.8, 1.4);
    final breakpointFactor = switch (_breakpoint) {
      Breakpoint.small => 1.0,
      Breakpoint.medium => 1.05,
      Breakpoint.large => 1.1,
      Breakpoint.extraLarge => 1.15,
    };
    return baseSize * scaleFactor * breakpointFactor;
  }

  /// Responsive spacing based on height & breakpoint.
  double spacing(double baseSpacing) {
    const baseHeight = 812.0;
    final scaleFactor = (_height / baseHeight).clamp(0.7, 1.6);
    final breakpointFactor = switch (_breakpoint) {
      Breakpoint.small => 1.0,
      Breakpoint.medium => 1.05,
      Breakpoint.large => 1.12,
      Breakpoint.extraLarge => 1.18,
    };
    return baseSpacing * scaleFactor * breakpointFactor;
  }

  /// Device-type based value selection (diagonal heuristic).
  T deviceValue<T>({required T mobile, T? tablet, T? desktop}) {
    switch (_deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Breakpoint-based value selection (width heuristic).
  T breakpointValue<T>({required T small, T? medium, T? large, T? extraLarge}) {
    switch (_breakpoint) {
      case Breakpoint.extraLarge:
        return extraLarge ?? large ?? medium ?? small;
      case Breakpoint.large:
        return large ?? medium ?? small;
      case Breakpoint.medium:
        return medium ?? small;
      case Breakpoint.small:
        return small;
    }
  }

  /// Adaptive font convenience.
  double adaptiveFont({
    required double small,
    double? medium,
    double? large,
    double? extraLarge,
  }) {
    final chosen = breakpointValue<double>(
      small: small,
      medium: medium ?? small * 1.05,
      large: large ?? (medium ?? small) * 1.05,
      extraLarge: extraLarge ?? (large ?? small) * 1.05,
    );
    return fontSize(chosen);
  }

  /// Grid column suggestion based on breakpoint.
  int gridColumns({int small = 1, int? medium, int? large, int? extraLarge}) {
    return breakpointValue<int>(
      small: small,
      medium: medium ?? (small + 1).clamp(1, small + 2),
      large: large ?? ((medium ?? small + 1) + 1),
      extraLarge: extraLarge ?? ((large ?? small + 2) + 1),
    );
  }

  /// Max content width (useful to constrain long-form text on desktop).
  double get maxContentWidth => breakpointValue<double>(
    small: _width,
    medium: _width * 0.95,
    large: 1000,
    extraLarge: 1200,
  );

  /// Responsive padding convenience.
  EdgeInsets responsivePadding({double horizontal = 16, double vertical = 16}) {
    return EdgeInsets.symmetric(
      horizontal: wp((horizontal / _width) * 100),
      vertical: hp((vertical / _height) * 100),
    );
  }

  /// Safe area helpers.
  EdgeInsets get safeAreaPadding => MediaQuery.of(context).padding;
  double get bottomSafeArea => MediaQuery.of(context).padding.bottom;
  double get topSafeArea => MediaQuery.of(context).padding.top;

  /// LayoutBuilder helper exposing constraints + utils.
  static Widget layoutBuilder({
    required BuildContext context,
    required Widget Function(
      BuildContext ctx,
      BoxConstraints constraints,
      ResponsiveUtils ru,
    )
    builder,
  }) {
    final ru = context.responsive;
    return LayoutBuilder(
      builder: (ctx, constraints) => builder(ctx, constraints, ru),
    );
  }
}

enum DeviceType { mobile, tablet, desktop }

enum Breakpoint { small, medium, large, extraLarge }

extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}
