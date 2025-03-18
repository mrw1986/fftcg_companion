import 'package:flutter/material.dart';

/// A class that represents a navigation destination item
class NavigationDestinationItem {
  final Key key;
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const NavigationDestinationItem({
    required this.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
  });

  NavigationDestination toNavigationDestination(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationDestination(
      key: key,
      icon: IconTheme(
        data: IconThemeData(
            color: colorScheme.onPrimary.withAlpha(179)), // 0.7 * 255 = 179
        child: icon,
      ),
      selectedIcon: IconTheme(
        data: IconThemeData(color: colorScheme.onPrimary),
        child: selectedIcon ?? icon,
      ),
      label: label,
    );
  }
}
