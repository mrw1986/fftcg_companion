import 'package:flutter/material.dart';

/// A custom painter that draws a mask over the corners of a rectangle.
/// This is used to create rounded corners on images that have white corners.
class CornerMaskPainter extends CustomPainter {
  final Color backgroundColor;
  final double cornerRadius;

  CornerMaskPainter({
    required this.backgroundColor,
    this.cornerRadius = 9.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Draw top-left corner
    final topLeftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(cornerRadius, 0)
      ..arcToPoint(
        Offset(0, cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(topLeftPath, paint);

    // Draw top-right corner
    final topRightPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..arcToPoint(
        Offset(size.width, cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(topRightPath, paint);

    // Draw bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(cornerRadius, size.height)
      ..arcToPoint(
        Offset(0, size.height - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(bottomLeftPath, paint);

    // Draw bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(CornerMaskPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

/// A widget that applies a corner mask to its child.
class CornerMaskWidget extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double cornerRadius;

  const CornerMaskWidget({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.cornerRadius = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        CustomPaint(
          painter: CornerMaskPainter(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }
}
