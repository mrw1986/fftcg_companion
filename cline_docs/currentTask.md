# Current Task

## Objective

Fix text processing issues in card description display

## Context

Two issues have been identified in the card description text processing:

1. Special ability text styling
2. Icon spacing and alignment

## Implementation Plan

### 1. Special Ability Text Styling

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Special ability text (text before [S]) needs to be styled with orange color
- Text contains HTML tags that need to be preserved (<br>, <b>)
- Need to correctly identify text before [S] tag

Solution:

- Parse text before [S] tag while preserving HTML formatting
- Apply special styling:

  ```dart
  TextStyle(
    color: Color(0xFFFF8800),
    fontWeight: FontWeight.bold,
    fontSize: 16.0 * scaleFactor,
    fontStyle: FontStyle.italic,
    height: 1.1,
    shadows: [Shadow(color: Colors.white, blurRadius: 2)],
  )
  ```

- Handle line breaks and bold tags properly

Impact:

- Correct special ability text styling
- Preserved HTML formatting
- Proper text flow

### 2. Icon Spacing and Alignment

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Inconsistent spacing between icons
- [S] icon spacing doesn't match other icons
- Cost numbers not properly centered

Solution:

- Use consistent spacing constants:

  ```dart
  static const double _iconMarginH = 1.0; // Minimal margin
  static const double _iconMarginV = 1.0;
  static const double _iconSpacing = 2.0; // Space between icons
  ```

- Use SizedBox for consistent spacing:

  ```dart
  spans.add(WidgetSpan(
    child: SizedBox(width: _iconSpacing),
  ));
  ```

- Add padding for cost number centering:

  ```dart
  padding: const EdgeInsets.only(top: 1)
  ```

Impact:

- Consistent spacing between all icons
- Proper vertical alignment
- Better visual appearance

## Testing Strategy

1. Special Ability Text
   - Test with various HTML tags
   - Verify line break handling
   - Check text styling consistency

2. Icon Spacing
   - Verify consistent spacing between all icons
   - Check vertical alignment
   - Test with different text lengths

## Success Criteria

- Special ability text is correctly styled with preserved HTML formatting
- All icons have consistent spacing and alignment
- Cost numbers are properly centered
- Text scales appropriately with screen size

## Next Steps

1. Update HTML parsing for special ability text
2. Verify line break handling
3. Test with various card descriptions
4. Document HTML tag support
