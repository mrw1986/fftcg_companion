// lib/shared/widgets/element_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fftcg_companion/features/cards/domain/models/element_type.dart';

class ElementIcon extends StatelessWidget {
  final ElementType element;
  final double size;
  final bool selected;

  const ElementIcon({
    super.key,
    required this.element,
    this.size = 24.0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? element.color
            : element.color.withAlpha((0.3 * 255).round()),
        shape: BoxShape.circle,
        border: Border.all(
          color: element.color,
          width: 2,
        ),
      ),
      child: Center(
        child: SvgPicture.asset(
          element.icon,
          width: size * 0.6,
          height: size * 0.6,
          colorFilter: ColorFilter.mode(
            selected
                ? Colors.white
                : Colors.white.withAlpha((0.7 * 255).round()),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
