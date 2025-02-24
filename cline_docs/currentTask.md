# Current Task

## Objective

Update text processing in card description display to match official style guide

## Context

A comprehensive style guide has been provided detailing exact specifications for:

- Element mappings
- Cost icons
- Special ability formatting
- EX BURST styling

## Implementation Plan

### 1. Element Icon Mappings

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Element handling expects full names instead of single letters
- Missing Crystal element support

Solution:

```dart
Map<String, String> elementMappings = {
  'R': 'Fire',
  'I': 'Ice',
  'G': 'Wind',
  'Y': 'Earth',
  'P': 'Lightning',
  'U': 'Water',
  'C': 'Crystal'
};
```

Impact:

- Correct element icon mapping
- Support for Crystal element
- Consistent icon display

### 2. Cost Icon Styling ([#] or [X])

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Styling doesn't match specification
- Border and text colors need adjustment

Solution:
Update Container styling:

```dart
Container(
  width: 25,
  height: 25,
  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
  decoration: BoxDecoration(
    border: Border.all(color: const Color(0xFF111111), width: 1),
    borderRadius: BorderRadius.circular(12.5),
  ),
  child: Center(
    child: Text(
      content,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 22/14, // line-height: 22px
      ),
    ),
  ),
)
```

### 3. Special [S] Icon Styling

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Border color and styling needs adjustment
- Text alignment needs refinement

Solution:
Update Container styling to match specification:

- Border color: #111
- Perfect circle border radius
- Consistent 22px line height
- Red text color

### 4. Special Ability Text Styling

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Margins need adjustment
- Border should be removed
- Width should be auto

Solution:
Update TextStyle:

```dart
const TextStyle(
  color: Color(0xFFFF8800),
  fontWeight: FontWeight.bold,
  fontSize: 20,
  fontStyle: FontStyle.italic,
  height: 1.1,
  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
)
```

Add margin: EdgeInsets.only(right: 3)

### 5. EX BURST Styling

Location: lib/features/cards/presentation/widgets/card_description_text.dart

Current Issue:

- Margins need adjustment
- Font family needs to be explicitly set

Solution:
Update TextStyle:

```dart
const TextStyle(
  color: Color(0xFF332A9D),
  fontWeight: FontWeight.bold,
  fontSize: 20,
  fontStyle: FontStyle.italic,
  fontFamily: 'Arial Black',
  height: 1.1,
  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
)
```

Add margin: EdgeInsets.only(left: 3, right: 10)

## Testing Strategy

1. Visual Testing
   - Element icon rendering
   - Cost icon styling
   - Special ability text formatting
   - EX BURST appearance
   - Icon alignment and spacing

2. Edge Cases
   - Multiple elements in text
   - Combined special abilities and costs
   - Various text lengths

## Success Criteria

- All icons render according to style guide
- Text styling matches specifications exactly
- Proper spacing and alignment throughout
- Consistent rendering across different card types

## Next Steps

1. Update element mapping implementation
2. Adjust cost icon styling
3. Refine special ability formatting
4. Update EX BURST styling
5. Test with various card texts
