import 'package:flutter/material.dart';

/// A widget that displays text with a border using a Stack
class BorderedText extends StatelessWidget {
  /// The text to display
  final String text;

  /// The color of the text fill
  final Color fillColor;

  /// The color of the text stroke/border
  final Color strokeColor;

  /// The width of the stroke/border
  final double strokeWidth;

  /// The text style to apply (excluding color and foreground)
  final TextStyle? style;

  /// Creates a bordered text widget
  const BorderedText({
    super.key,
    required this.text,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 1.5,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle(fontWeight: FontWeight.w500);

    return Stack(
      children: [
        // Stroked text for border
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // Solid text as fill
        Text(
          text,
          style: baseStyle.copyWith(
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

/// Extension method to apply bordered text to a Text widget
extension BorderedTextExtension on Text {
  /// Creates a bordered version of this text widget
  BorderedText bordered({
    Color fillColor = Colors.white,
    Color strokeColor = Colors.black,
    double strokeWidth = 1.5,
  }) {
    return BorderedText(
      text: data ?? '',
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      style: style,
    );
  }
}
