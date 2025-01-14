// lib/features/cards/domain/models/element_type.dart
import 'package:flutter/material.dart';

enum ElementType {
  fire(
      name: 'Fire',
      color: Color(0xFFFF4444),
      icon: 'assets/icons/elements/fire.svg'),
  ice(
      name: 'Ice',
      color: Color(0xFF44CCFF),
      icon: 'assets/icons/elements/ice.svg'),
  wind(
      name: 'Wind',
      color: Color(0xFF44FF44),
      icon: 'assets/icons/elements/wind.svg'),
  earth(
      name: 'Earth',
      color: Color(0xFFFFAA44),
      icon: 'assets/icons/elements/earth.svg'),
  lightning(
      name: 'Lightning',
      color: Color(0xFFCC44FF),
      icon: 'assets/icons/elements/lightning.svg'),
  water(
      name: 'Water',
      color: Color(0xFF4444FF),
      icon: 'assets/icons/elements/water.svg'),
  light(
      name: 'Light',
      color: Color(0xFFFFFF44),
      icon: 'assets/icons/elements/light.svg'),
  dark(
      name: 'Dark',
      color: Color(0xFF666666),
      icon: 'assets/icons/elements/dark.svg');

  final String name;
  final Color color;
  final String icon;

  const ElementType({
    required this.name,
    required this.color,
    required this.icon,
  });

  static ElementType? fromString(String? value) {
    if (value == null) return null;
    try {
      return ElementType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
