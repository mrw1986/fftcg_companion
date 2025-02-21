# Current Task

## Objective

Improve card text processing and filtering functionality

## Context

Several issues have been identified with text processing and filtering:

1. Case-sensitive "EX Burst" processing
2. Limited HTML tag support in card descriptions
3. Text being stripped from descriptions (specifically card name references)
4. Special ability name formatting issues
5. Filter collection usage optimization

## Implementation Plan

### 1. Case-Insensitive EX Burst Processing

- Location: lib/features/cards/presentation/widgets/card_description_text.dart
- Current: Using exact match 'EX BURST'
- Change: Update RegExp pattern to be case-insensitive
- Impact: More reliable EX Burst styling across all cards

### 2. Enhanced HTML Tag Support

- Location: lib/core/utils/html_parser.dart
- Current: Limited support for em, b, br tags
- Changes:
  - Add support for `<strong>` tags
  - Add support for `<em>` tags
  - Ensure proper handling of `<br>` tags
  - Add support for nested tags
- Impact: More accurate rendering of card text formatting

### 3. Card Name Reference Fix

- Location: lib/features/cards/presentation/widgets/card_description_text.dart
- Current: Card name references being stripped
- Changes:
  - Update text processing to preserve [Card Name (X)] format
  - Ensure proper styling of card name references
- Impact: Complete and accurate card text display

### 4. Special Ability Name Formatting

- Location: lib/features/cards/presentation/widgets/card_description_text.dart
- Current: Inconsistent special ability formatting
- Changes:
  - Enhance detection of special abilities before [S]
  - Apply consistent styling:
    - Color: #f80
    - Margin: 0 3px 0 0
    - Font weight: 700
    - Font size: 20px
    - Font style: italic
    - Text shadow: 0 0 2px #fff
- Impact: Consistent and visually appealing special ability display

### 5. Filter Collection Optimization

- Location: Multiple files
  - lib/features/cards/presentation/providers/filter_provider.dart
  - lib/features/cards/presentation/widgets/filter_dialog.dart
- Current: Mixed usage of card documents and filter collection
- Changes:
  - Update filter dialog to use new filters collection
  - Maintain card document fields for actual filtering
  - Implement new filter documents structure:
    - filters.cardType
    - filters.category
    - filters.cost
    - filters.elements
    - filters.power
    - filters.rarity
    - filters.set
- Impact: More efficient and maintainable filtering system

## Next Steps

1. Implement case-insensitive EX Burst processing
2. Enhance HTML parser with additional tag support
3. Fix card name reference preservation
4. Update special ability formatting
5. Optimize filter collection usage

## Related Tasks from Roadmap

- [x] Card database with sorting options
- [x] Advanced filtering system
- [ ] Improve text processing and display

## Testing Strategy

1. Test HTML parsing with various tag combinations
2. Verify case-insensitive EX Burst detection
3. Confirm card name references are preserved
4. Check special ability formatting consistency
5. Validate filter collection changes

## Future Considerations

- Monitor performance impact of enhanced text processing
- Consider caching processed text for frequently viewed cards
- Plan for additional HTML tag support if needed
