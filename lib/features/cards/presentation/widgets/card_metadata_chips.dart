import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;

// Custom painter for crystal/gem shape with proper border
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

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: _iconMarginH,
          vertical: _iconMarginV,
        ),
        width: width,
        height: height,
        child: Stack(
          children: [
            // Background and border using CustomPaint
            CustomPaint(
              painter: CrystalBorderPainter(
                backgroundColor: Colors.purple.shade800,
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
                  color: Colors.white, // White text to match reference
                  fontWeight: FontWeight.bold,
                  fontSize: elementSize * 0.6, // Larger text
                  height: 1.0, // Better vertical centering
                  // No shadows to eliminate blur
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
        ...elements.map((element) => _buildChip(
              context,
              element,
              colorScheme.primaryContainer,
              colorScheme.onPrimaryContainer,
            )),
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
      ],
    );
  }
}
