import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;

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

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor, {
    bool forceBackground = false,
  }) {
    // Check if this is an element chip
    final elementImagePath = _getElementImagePath(label);
    final textStyle = Theme.of(context).textTheme.labelMedium;
    final fontSize = textStyle?.fontSize ?? 12.0;

    // Scale padding with font size
    final horizontalPadding = fontSize * 0.75; // More horizontal breathing room
    final verticalPadding = fontSize * 0.25;

    // Scale element size with font size
    final elementSize = fontSize * 2; // Double the font size for elements

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: elementImagePath != null && !forceBackground
            ? Colors.transparent
            : backgroundColor,
        borderRadius: BorderRadius.circular(fontSize),
      ),
      child: elementImagePath != null && !forceBackground
          ? Image.asset(
              elementImagePath,
              width: elementSize,
              height: elementSize,
              alignment: Alignment.center,
            )
          : Text(
              label,
              style: textStyle?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
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

    // Get font size for spacing calculation
    final fontSize = Theme.of(context).textTheme.labelMedium?.fontSize ?? 12.0;

    return Wrap(
      spacing: fontSize * 0.5, // Scale spacing with font size
      runSpacing: fontSize * 0.5,
      crossAxisAlignment: WrapCrossAlignment.center,
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
