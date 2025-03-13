import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  // Store the recently used colors
  List<Color> _recentColors = []; // Initialize with empty list

  @override
  void initState() {
    super.initState();
    // Initialize with empty list, will be populated by the color picker
    _loadRecentColors();
  }

  // Load recent colors from storage
  void _loadRecentColors() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _recentColors =
            ref.read(themeColorControllerProvider.notifier).getRecentColors();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeColor = ref.watch(themeColorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Define high contrast text styles
    final TextStyle highContrastStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [Shadow(color: Colors.black, blurRadius: 3)],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        elevation: 0,
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
                  ColorPicker(
                    // Use the current theme color
                    color: themeColor,

                    // Update the theme color when changed
                    onColorChanged: (Color color) {
                      ref
                          .read(themeColorControllerProvider.notifier)
                          .setThemeColor(color);
                    },

                    // Track recently used colors
                    onRecentColorsChanged: (List<Color> colors) {
                      setState(() {
                        _recentColors = colors;
                        ref
                            .read(themeColorControllerProvider.notifier)
                            .saveRecentColors(colors);
                      });
                    },
                    recentColors: _recentColors,

                    // Enable requested features
                    enableShadesSelection: true,
                    enableOpacity: false,
                    enableTonalPalette: true,
                    showMaterialName: true,
                    showColorName: true,
                    showRecentColors: true,

                    // Configure which pickers to show (Primary, Accent, B&W, Wheel)
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: true,
                      ColorPickerType.bw: true,
                      ColorPickerType.wheel: true,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    subheading: Text(
                      'Select color shade',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    tonalSubheading: Text(
                      'Material 3 tonal palette',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    wheelSubheading: Text(
                      'Color wheel',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    recentColorsSubheading: Text(
                      'Recent colors',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),

                    // Configure text styles with high contrast
                    materialNameTextStyle: highContrastStyle,
                    colorNameTextStyle: highContrastStyle,
                    colorCodeTextStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    colorCodePrefixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),

                    // Configure wheel
                    wheelDiameter: 190,
                    wheelWidth: 16,

                    // Configure picker labels
                    pickerTypeLabels: const <ColorPickerType, String>{
                      ColorPickerType.primary: 'Primary',
                      ColorPickerType.accent: 'Accent',
                      ColorPickerType.bw: 'Black & White',
                      ColorPickerType.wheel: 'Wheel',
                    },

                    // Configure max recent colors
                    maxRecentColors: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Use higher contrast colors for text and icons
    final Color textColor = isSelected
        ? colorScheme.primary
        : isDark
            ? Colors.white
            : Colors.black87;

    return InkWell(
      onTap: () {
        ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
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
