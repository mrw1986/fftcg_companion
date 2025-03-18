import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';

class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // Get the current theme color from the provider
    // This ensures it's always up-to-date, even when the app starts or cache is cleared
    final themeColor = ref.watch(themeColorControllerProvider);

    // Use the theme color for the AppBar background
    // This creates an interactive experience where the AppBar color changes
    // as the user selects different colors in the picker
    return Scaffold(
      appBar: AppBarFactory.createColoredAppBar(
        context,
        'Theme Settings',
        themeColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeModeButton(
                        context,
                        ThemeMode.system,
                        'System',
                        Icons.brightness_auto,
                        themeMode,
                        ref,
                      ),
                      _buildThemeModeButton(
                        context,
                        ThemeMode.light,
                        'Light',
                        Icons.brightness_5,
                        themeMode,
                        ref,
                      ),
                      _buildThemeModeButton(
                        context,
                        ThemeMode.dark,
                        'Dark',
                        Icons.brightness_3,
                        themeMode,
                        ref,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Color Picker Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Color',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Enhanced Color Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simplified color picker with only Primary and Accent colors
                      ColorPicker(
                        // Use the theme color for interactive changes
                        color: themeColor,

                        // Update the theme color when changed
                        onColorChanged: (Color color) {
                          // Directly update the theme color in the provider
                          // This will trigger a rebuild with the new color
                          ref
                              .read(themeColorControllerProvider.notifier)
                              .setThemeColor(color);
                        },

                        // Enable Material 3 tonal palette
                        enableShadesSelection: true,
                        enableOpacity: false,
                        enableTonalPalette: true,
                        showMaterialName:
                            false, // Hide material name (e.g., "Yellow [500]")
                        showColorName:
                            false, // Hide the default color name to avoid duplication
                        showRecentColors:
                            false, // Hide recent colors as requested

                        // Only show Primary, Accent, and Wheel color pickers
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.primary: true,
                          ColorPickerType.accent: true,
                          ColorPickerType.bw: false,
                          ColorPickerType.wheel:
                              true, // Added wheel picker as requested
                          ColorPickerType.custom: false,
                          ColorPickerType.both: false,
                        },

                        // Configure picker appearance
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        columnSpacing: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 8),

                        // Configure headings
                        heading: Text(
                          'Select color',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        subheading: Text(
                          'Select color shade',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        tonalSubheading: Text(
                          'Tonal palette',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        wheelSubheading: Text(
                          'Color wheel',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),

                        // Configure wheel
                        wheelDiameter: 190,
                        wheelWidth: 16,
                      ),

                      // Display only the color name without prefix and number
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text(
                            ColorTools.nameThatColor(themeColor),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ),

                      // Add a button to apply the selected color
                      const SizedBox(height: 24),
                      Center(
                        child: Material(
                          color:
                              themeColor, // Use the selected color for the button
                          borderRadius: BorderRadius.circular(24),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              // Show a confirmation message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Theme color updated'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color:
                                        _getTextColorForBackground(themeColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Apply Theme Color',
                                    style: TextStyle(
                                      color: _getTextColorForBackground(
                                          themeColor),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to determine text color based on background color
  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();

    // Use white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildThemeModeButton(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    ThemeMode currentMode,
    WidgetRef ref,
  ) {
    final isSelected = currentMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    final themeColor = ref.watch(themeColorControllerProvider);

    // Use higher contrast colors for text and icons
    final Color textColor = isSelected
        ? _getTextColorForBackground(
            themeColor) // Use contrasting text color based on theme color
        : colorScheme
            .onSurface; // Use onSurface for non-selected items for better Material 3 consistency

    return InkWell(
      onTap: () {
        ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor
              : Colors.transparent, // Use theme color for selected state
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? themeColor.withAlpha(200) // Slightly transparent border
                : colorScheme.onSurface.withAlpha(31), // 0.12 * 255 ≈ 31
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 28, // Slightly larger for better visibility
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16, // Slightly larger for better visibility
              ),
            ),
          ],
        ),
      ),
    );
  }
}
