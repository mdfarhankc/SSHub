import 'package:flutter/material.dart';

abstract final class ServerColors {
  static const palette = <int>[
    0xFF3B82F6,
    0xFF22C55E,
    0xFFEF4444,
    0xFFF59E0B,
    0xFFA855F7,
    0xFF06B6D4,
    0xFFEC4899,
    0xFF14B8A6,
  ];

  static Color resolve(int? value, ColorScheme scheme) =>
      value == null ? scheme.primary : Color(value);
}
