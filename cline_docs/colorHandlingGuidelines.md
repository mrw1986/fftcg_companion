# Color Handling Guidelines

## Modern Color Opacity Handling

### Using `withValues(alpha: value)` Instead of `withAlpha()` and `withOpacity()`

When working with color opacity in our Flutter application, always use the modern `withValues(alpha: value)` approach instead of the older `withAlpha()` or `withOpacity()` methods.

#### Benefits

- Better color handling in wide gamut environments
- More consistent visual appearance across different devices and screens
- More intuitive API with values in the 0.0-1.0 range (rather than 0-255 for withAlpha)
- Future-proof for upcoming Flutter color handling improvements

#### Examples

```dart
// ❌ Don't use withAlpha
color: Colors.black.withAlpha(128); // 50% opacity with 0-255 range

// ❌ Don't use withOpacity
color: Colors.black.withOpacity(0.5); // 50% opacity

// ✅ Use withValues instead
color: Colors.black.withValues(alpha: 0.5); // 50% opacity with 0.0-1.0 range
```

#### Common Alpha Value Conversions

- `withAlpha(51)` → `withValues(alpha: 0.2)` (20% opacity)
- `withAlpha(128)` → `withValues(alpha: 0.5)` (50% opacity)
- `withAlpha(179)` → `withValues(alpha: 0.7)` (70% opacity)
- `withAlpha(204)` → `withValues(alpha: 0.8)` (80% opacity)

## ColorScheme Usage Guidelines

### Avoid Using `surfaceVariant`

When working with our theme's ColorScheme, avoid using `surfaceVariant` as it doesn't provide enough contrast in some scenarios.

#### Alternatives

- For container backgrounds, use `surface` or `primaryContainer` depending on context
- For text on surfaces, use `onSurface` or `onPrimaryContainer` for better readability
- For subtle UI elements, use `surface.withValues(alpha: 0.9)` to create a slight variation

### Preferred ColorScheme Properties

Use these ColorScheme properties for consistent UI:

- `primary`: Main brand color, used for primary actions and key UI elements
- `onPrimary`: Text/icons that appear on primary color
- `primaryContainer`: Used for containers that should stand out but not as prominently as primary
- `onPrimaryContainer`: Text/icons on primaryContainer
- `secondary`: Used for secondary actions and less prominent UI elements
- `onSecondary`: Text/icons on secondary color
- `surface`: Background color for cards and surfaces
- `onSurface`: Text/icons on surface color
- `error`: Used for error states and destructive actions
- `onError`: Text/icons on error color
- `errorContainer`: Used for error containers (like error messages)
- `onErrorContainer`: Text/icons on errorContainer

## Implementation Examples

### Shadows

```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.2),
  blurRadius: 10,
  spreadRadius: 2,
)
```

### Icons with Reduced Opacity

```dart
IconTheme(
  data: IconThemeData(
    color: textColor.withValues(alpha: 0.7)
  ),
  child: icon,
)
```

### Navigation Bar Indicator

```dart
NavigationBar(
  backgroundColor: colorScheme.primary,
  indicatorColor: colorScheme.onPrimary.withValues(alpha: 0.2),
)
```

### Text with Reduced Emphasis

```dart
Text(
  'Secondary text',
  style: TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
  ),
)
```

## Files Updated with Modern Color Handling

The following files have been updated to use the modern `withValues(alpha: value)` approach:

- `lib/core/routing/app_router.dart`
- `lib/features/cards/presentation/pages/cards_page.dart`
- Various UI component files throughout the application

This standardization ensures consistent color handling across our entire application.
