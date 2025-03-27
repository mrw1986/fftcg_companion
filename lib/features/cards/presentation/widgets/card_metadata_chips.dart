import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;

// Custom painter for crystal/gem shape with proper border and single color
class CrystalBorderPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;

  CrystalBorderPainter({
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create the crystal path
    final path = Path();
    path.moveTo(width * 0.5, 0); // Top center point
    path.lineTo(width, height * 0.15); // Top right corner - more acute angle
    path.lineTo(width, height * 0.85); // Bottom right corner - more acute angle
    path.lineTo(width * 0.5, height); // Bottom center point
    path.lineTo(0, height * 0.85); // Bottom left corner - more acute angle
    path.lineTo(0, height * 0.15); // Top left corner - more acute angle
    path.close();

    // Fill with background color
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Slightly thicker for better visibility
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for crystal/gem shape with multiple element colors
class MultiElementCrystalPainter extends CustomPainter {
  final List<Color> elementColors;
  final Color borderColor;

  MultiElementCrystalPainter({
    required this.elementColors,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create the crystal path
    final path = Path();
    path.moveTo(width * 0.5, 0); // Top center point
    path.lineTo(width, height * 0.15); // Top right corner - more acute angle
    path.lineTo(width, height * 0.85); // Bottom right corner - more acute angle
    path.lineTo(width * 0.5, height); // Bottom center point
    path.lineTo(0, height * 0.85); // Bottom left corner - more acute angle
    path.lineTo(0, height * 0.15); // Top left corner - more acute angle
    path.close();

    if (elementColors.length == 1) {
      // Single color - fill the entire crystal
      final paint = Paint()
        ..color = elementColors[0]
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else {
      // Multiple colors - divide the crystal into vertical slices
      final numColors = elementColors.length;

      // Define the crystal points for easier reference
      final topCenter = Offset(width * 0.5, 0);
      final topRight = Offset(width, height * 0.15);
      final bottomRight = Offset(width, height * 0.85);
      final bottomCenter = Offset(width * 0.5, height);
      final bottomLeft = Offset(0, height * 0.85);
      final topLeft = Offset(0, height * 0.15);

      // For 2 elements - split vertically
      if (numColors == 2) {
        // Left half
        final leftPath = Path()
          ..moveTo(topCenter.dx, topCenter.dy)
          ..lineTo(topLeft.dx, topLeft.dy)
          ..lineTo(bottomLeft.dx, bottomLeft.dy)
          ..lineTo(bottomCenter.dx, bottomCenter.dy)
          ..close();

        final leftPaint = Paint()
          ..color = elementColors[0]
          ..style = PaintingStyle.fill;
        canvas.drawPath(leftPath, leftPaint);

        // Right half
        final rightPath = Path()
          ..moveTo(topCenter.dx, topCenter.dy)
          ..lineTo(topRight.dx, topRight.dy)
          ..lineTo(bottomRight.dx, bottomRight.dy)
          ..lineTo(bottomCenter.dx, bottomCenter.dy)
          ..close();

        final rightPaint = Paint()
          ..color = elementColors[1]
          ..style = PaintingStyle.fill;
        canvas.drawPath(rightPath, rightPaint);
      }
      // For 3 elements - "Y" configuration
      else if (numColors == 3) {
        // Center point of the crystal
        final centerX = width / 2;
        final centerY = height / 2;

        // Top section
        final topPath = Path()
          ..moveTo(centerX, centerY)
          ..lineTo(topLeft.dx, topLeft.dy)
          ..lineTo(topCenter.dx, topCenter.dy)
          ..lineTo(topRight.dx, topRight.dy)
          ..close();

        final topPaint = Paint()
          ..color = elementColors[0]
          ..style = PaintingStyle.fill;
        canvas.drawPath(topPath, topPaint);

        // Bottom left section
        final bottomLeftPath = Path()
          ..moveTo(centerX, centerY)
          ..lineTo(topLeft.dx, topLeft.dy)
          ..lineTo(bottomLeft.dx, bottomLeft.dy)
          ..lineTo(bottomCenter.dx, bottomCenter.dy)
          ..close();

        final bottomLeftPaint = Paint()
          ..color = elementColors[1]
          ..style = PaintingStyle.fill;
        canvas.drawPath(bottomLeftPath, bottomLeftPaint);

        // Bottom right section
        final bottomRightPath = Path()
          ..moveTo(centerX, centerY)
          ..lineTo(topRight.dx, topRight.dy)
          ..lineTo(bottomRight.dx, bottomRight.dy)
          ..lineTo(bottomCenter.dx, bottomCenter.dy)
          ..close();

        final bottomRightPaint = Paint()
          ..color = elementColors[2]
          ..style = PaintingStyle.fill;
        canvas.drawPath(bottomRightPath, bottomRightPaint);
      }
      // For 4 elements - divide into quadrants (X shape)
      else if (numColors == 4) {
        // Center point of the crystal

        // First fill the entire crystal with a background color
        final bgPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, bgPaint);

        // Calculate the exact center of the crystal
        final centerX = width / 2;
        final centerY = height / 2;

        // Top quadrant (yellow)
        final topPath = Path()
          ..moveTo(centerX, centerY) // Center
          ..lineTo(0, height * 0.15) // Top left corner
          ..lineTo(centerX, 0) // Top center
          ..lineTo(width, height * 0.15) // Top right corner
          ..close();

        final topPaint = Paint()
          ..color = elementColors[0] // Earth (yellow)
          ..style = PaintingStyle.fill;
        canvas.drawPath(topPath, topPaint);

        // Right quadrant (red)
        final rightPath = Path()
          ..moveTo(centerX, centerY) // Center
          ..lineTo(width, height * 0.15) // Top right corner
          ..lineTo(width, height * 0.85) // Bottom right corner
          ..close();

        final rightPaint = Paint()
          ..color = elementColors[1] // Fire (red)
          ..style = PaintingStyle.fill;
        canvas.drawPath(rightPath, rightPaint);

        // Bottom quadrant (blue)
        final bottomPath = Path()
          ..moveTo(centerX, centerY) // Center
          ..lineTo(width, height * 0.85) // Bottom right corner
          ..lineTo(centerX, height) // Bottom center
          ..lineTo(0, height * 0.85) // Bottom left corner
          ..close();

        final bottomPaint = Paint()
          ..color = elementColors[2] // Water (blue)
          ..style = PaintingStyle.fill;
        canvas.drawPath(bottomPath, bottomPaint);

        // Left quadrant (green)
        final leftPath = Path()
          ..moveTo(centerX, centerY) // Center
          ..lineTo(0, height * 0.85) // Bottom left corner
          ..lineTo(0, height * 0.15) // Top left corner
          ..close();

        final leftPaint = Paint()
          ..color = elementColors[3] // Wind (green)
          ..style = PaintingStyle.fill;
        canvas.drawPath(leftPath, leftPaint);
      }
      // For 5+ elements - divide into equal pie slices
      else {
        // Center point of the crystal
        final centerX = width / 2;
        final centerY = height / 2;

        // Calculate angle for each slice
        final angleStep =
            2 * 3.14159265359 / numColors; // Using pi value directly

        for (int i = 0; i < numColors; i++) {
          // Calculate start and end angles for this slice
          final startAngle =
              i * angleStep - 3.14159265359 / 2; // Start from top
          final endAngle = (i + 1) * angleStep - 3.14159265359 / 2;

          // Create a slice path
          final slicePath = Path();
          slicePath.moveTo(centerX, centerY);

          // Calculate points on the crystal edge
          // We'll use a simple approach with straight lines to the edge

          // Start point - from center to edge at startAngle
          final startSin = sin(startAngle);
          final startCos = cos(startAngle);

          // End point - from center to edge at endAngle
          final endSin = sin(endAngle);
          final endCos = cos(endAngle);

          // Find edge points
          Offset startEdge;
          if (startCos > 0) {
            // Right side
            if (startSin > 0) {
              // Bottom right
              startEdge = Offset(width, height * 0.85);
            } else {
              // Top right
              startEdge = Offset(width, height * 0.15);
            }
          } else {
            // Left side
            if (startSin > 0) {
              // Bottom left
              startEdge = Offset(0, height * 0.85);
            } else {
              // Top left
              startEdge = Offset(0, height * 0.15);
            }
          }

          Offset endEdge;
          if (endCos > 0) {
            // Right side
            if (endSin > 0) {
              // Bottom right
              endEdge = Offset(width, height * 0.85);
            } else {
              // Top right
              endEdge = Offset(width, height * 0.15);
            }
          } else {
            // Left side
            if (endSin > 0) {
              // Bottom left
              endEdge = Offset(0, height * 0.85);
            } else {
              // Top left
              endEdge = Offset(0, height * 0.15);
            }
          }

          // Add points to the path
          slicePath.lineTo(startEdge.dx, startEdge.dy);

          // Add intermediate points if needed
          if ((startCos > 0 && endCos < 0) || (startCos < 0 && endCos > 0)) {
            // If the slice crosses from left to right or right to left,
            // we need to add the top or bottom center point
            if (startSin < 0 || endSin < 0) {
              // Top half - add top center
              slicePath.lineTo(width / 2, 0);
            }
            if (startSin > 0 || endSin > 0) {
              // Bottom half - add bottom center
              slicePath.lineTo(width / 2, height);
            }
          }

          slicePath.lineTo(endEdge.dx, endEdge.dy);
          slicePath.close();

          // Fill the slice with the corresponding color
          final paint = Paint()
            ..color = elementColors[i]
            ..style = PaintingStyle.fill;
          canvas.drawPath(slicePath, paint);
        }
      }
    }

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Slightly thicker for better visibility
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom clipper for crystal/gem shape
class CostClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Create a 6-sided crystal shape with longer vertical sides
    // and more acute angles at top and bottom
    path.moveTo(width * 0.5, 0); // Top center point
    path.lineTo(width, height * 0.15); // Top right corner - more acute angle
    path.lineTo(width, height * 0.85); // Bottom right corner - more acute angle
    path.lineTo(width * 0.5, height); // Bottom center point
    path.lineTo(0, height * 0.85); // Bottom left corner - more acute angle
    path.lineTo(0, height * 0.15); // Top left corner - more acute angle
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CardMetadataChips extends StatelessWidget {
  final models.Card card;
  final ColorScheme colorScheme;

  const CardMetadataChips({
    super.key,
    required this.card,
    required this.colorScheme,
  });

  String? _getElementImagePath(String element) {
    // Only return image paths for actual elements
    final validElements = {
      'Fire',
      'Ice',
      'Wind',
      'Earth',
      'Lightning',
      'Water',
      'Light',
      'Dark'
    };

    if (!validElements.contains(element)) {
      return null;
    }

    final elementName = element.toLowerCase();
    return 'assets/images/elements/$elementName.png';
  }

  // Get color for each element based on the requested color values
  Color _getElementColor(String element) {
    switch (element) {
      case 'Fire':
        return const Color(0xFFEA5432); // Fire - #ea5432
      case 'Ice':
        return const Color(0xFF63C7F2); // Ice - #63c7f2
      case 'Wind':
        return const Color(0xFF33B371); // Wind - #33b371
      case 'Earth':
        return const Color(0xFFFDD000); // Earth - #fdd000
      case 'Lightning':
        return const Color(0xFFB077B1); // Lightning - #b077b1
      case 'Water':
        return const Color(0xFF6C9BD2); // Water - #6c9bd2
      case 'Light':
        return const Color(0xFFFFFFFF); // Light - #ffffff
      case 'Dark':
        return const Color(0xFF919192); // Dark - #919192
      default:
        return Colors.purple.shade800; // Default color for unknown elements
    }
  }

  // Get element colors for the card
  List<Color> _getElementColors(List<String> elements) {
    if (elements.isEmpty) {
      return [Colors.purple.shade800]; // Default color if no elements
    }
    return elements.map((element) => _getElementColor(element)).toList();
  }

  // Constants matching card_description_text.dart
  static const double _roundedSquareBorderRadius = 4.0;
  static const double _circularBorderRadius = 12.5;
  static const double _iconSize = 22.0;
  static const double _iconMarginH = 1.0;
  static const double _iconMarginV = 1.0;
  static const double _iconSpacing = 2.0;

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor, {
    bool forceBackground = false,
    bool isCost = false,
  }) {
    // Check if this is an element chip
    final elementImagePath = _getElementImagePath(label);
    final textStyle = Theme.of(context).textTheme.labelMedium;

    // Use consistent sizing with card_description_text.dart
    final elementSize = _iconSize;
    final borderRadius = elementImagePath != null && !forceBackground
        ? _circularBorderRadius
        : _roundedSquareBorderRadius;

    if (elementImagePath != null && !forceBackground) {
      // Element icon
      return Container(
        width: elementSize,
        height: elementSize,
        margin: const EdgeInsets.symmetric(
          horizontal: _iconMarginH,
          vertical: _iconMarginV,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.onSurface,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Image.asset(
          elementImagePath,
          width: elementSize - 2, // Account for border
          height: elementSize - 2,
          alignment: Alignment.center,
        ),
      );
    } else if (isCost) {
      // Cost chip with crystal/gem shape
      final width = elementSize * 1.0;
      final height = elementSize * 1.8;

      // Get element colors from the card
      final elementColors = _getElementColors(card.elements);

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: _iconMarginH,
          vertical: _iconMarginV,
        ),
        width: width,
        height: height,
        child: Stack(
          children: [
            // Background and border using CustomPaint with element colors
            CustomPaint(
              painter: MultiElementCrystalPainter(
                elementColors: elementColors,
                borderColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white // White border in dark mode
                    : Colors.black, // Black border in light mode
              ),
              size: Size(width, height),
            ),
            // Text centered on the shape
            Center(
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: Colors
                      .black, // Black text for better contrast with colored backgrounds
                  fontWeight: FontWeight.bold,
                  fontSize: elementSize * 0.6, // Larger text
                  height: 1.0, // Better vertical centering
                  // Add a subtle shadow for better visibility on light colors
                  shadows: [
                    Shadow(
                      color:
                          Colors.black.withValues(alpha: 0.3), // 0.3 * 255 = 77
                      offset: const Offset(0.5, 0.5),
                      blurRadius: 1.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Text chip
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: _iconMarginH,
          vertical: _iconMarginV,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: colorScheme.onSurface,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          label,
          style: textStyle?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            height: 1.0, // Better vertical centering
            // No shadows to eliminate blur
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elements = card.elements;
    final typeValue = card.cardType;
    final jobValue = card.job;
    final categoryValue = card.displayCategory; // Use displayCategory getter
    final costValue = card.cost?.toString();

    if (elements.isEmpty &&
        typeValue == null &&
        jobValue == null &&
        categoryValue == null &&
        costValue == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing:
          _iconSpacing, // Use consistent spacing with card_description_text.dart
      runSpacing: _iconSpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.start,
      children: [
        if (costValue != null)
          _buildChip(
            context,
            costValue,
            colorScheme.primary,
            colorScheme.onPrimary,
            isCost: true, // Use hexagonal/crystal shape for cost
          ),
        if (typeValue != null)
          _buildChip(
            context,
            typeValue,
            colorScheme.secondaryContainer,
            colorScheme.onSecondaryContainer,
          ),
        if (jobValue != null)
          _buildChip(
            context,
            jobValue,
            colorScheme.tertiaryContainer,
            colorScheme.onTertiaryContainer,
          ),
        if (categoryValue != null)
          _buildChip(
            context,
            categoryValue,
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurfaceVariant,
            forceBackground: true, // Force background for category
          ),
        // Element icons moved to the end
        ...elements.map((element) => _buildChip(
              context,
              element,
              colorScheme.primaryContainer,
              colorScheme.onPrimaryContainer,
            )),
      ],
    );
  }
}
