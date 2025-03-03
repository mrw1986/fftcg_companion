import 'package:flutter/material.dart';

/// A custom clipper that clips the corners of a rectangle with a specified radius.
class RoundedCornerClipper extends CustomClipper<Path> {
  final double radius;

  RoundedCornerClipper({this.radius = 8.0});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Top left corner
    path.moveTo(radius, 0);

    // Top right corner
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Bottom right corner
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);

    // Bottom left corner
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Back to top left
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return oldClipper is RoundedCornerClipper && oldClipper.radius != radius;
  }
}
