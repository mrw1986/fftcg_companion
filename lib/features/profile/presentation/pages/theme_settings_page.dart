import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeColor = ref.watch(themeColorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme mode section
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

          // Theme color section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme Color',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.onSurface.withAlpha(31),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _showColorPickerDialog(
                                context, ref, themeColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Predefined schemes section
                  Text(
                    'Predefined Schemes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Grid of predefined schemes
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: FlexScheme.values.length,
                    itemBuilder: (context, index) {
                      final scheme = FlexScheme.values[index];
                      final schemeColors = brightness == Brightness.light
                          ? FlexColor.schemes[scheme]?.light ??
                              FlexColor.schemes[FlexScheme.material]!.light
                          : FlexColor.schemes[scheme]?.dark ??
                              FlexColor.schemes[FlexScheme.material]!.dark;

                      return InkWell(
                        onTap: () {
                          ref
                              .read(themeColorControllerProvider.notifier)
                              .setThemeColor(schemeColors.primary);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: schemeColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.onSurface.withAlpha(31),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Tooltip(
                              message: scheme.name,
                              child: Icon(
                                Icons.palette,
                                color: ColorScheme.fromSeed(
                                  seedColor: schemeColors.primary,
                                  brightness: brightness,
                                ).onPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(179), // 0.7 * 255 ≈ 179
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(179), // 0.7 * 255 ≈ 179
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPickerDialog(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) async {
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;

    // Define custom colors
    final Map<ColorSwatch<Object>, String> customSwatches = {
      ColorTools.createPrimarySwatch(const Color(0xFF6200EE)): 'Purple',
      ColorTools.createPrimarySwatch(const Color(0xFF3700B3)): 'Deep Purple',
      ColorTools.createPrimarySwatch(const Color(0xFF03DAC6)): 'Teal',
      ColorTools.createPrimarySwatch(const Color(0xFF018786)): 'Dark Teal',
      ColorTools.createPrimarySwatch(const Color(0xFFB00020)): 'Red',
      ColorTools.createPrimarySwatch(const Color(0xFF0063C5)): 'Blue',
      ColorTools.createPrimarySwatch(const Color(0xFF009688)): 'Green',
    };

    Color selectedColor = await showColorPickerDialog(
      context,
      currentColor,
      title: Text('Select Theme Color',
          style: Theme.of(context).textTheme.titleLarge),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 4,
      wheelDiameter: 165,
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: customSwatches,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      actionButtons: const ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: true,
      ),
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 320,
        maxWidth: 320,
      ),
    );

    if (selectedColor != currentColor) {
      // Apply a minimum brightness for dark mode and maximum for light mode
      final luminance = selectedColor.computeLuminance();
      Color safeColor = selectedColor;

      if (isLightMode && luminance > 0.9) {
        // If too light in light mode, adjust to a safer color
        safeColor = HSLColor.fromColor(selectedColor)
            .withLightness(0.7) // Reduce lightness to ensure readability
            .toColor();
      } else if (!isLightMode && luminance < 0.1) {
        // If too dark in dark mode, adjust to a safer color
        safeColor = HSLColor.fromColor(selectedColor)
            .withLightness(0.3) // Increase lightness to ensure readability
            .toColor();
      }

      await ref
          .read(themeColorControllerProvider.notifier)
          .setThemeColor(safeColor);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: safeColor != selectedColor
                ? const Text('Theme color adjusted for better readability')
                : const Text('Theme color updated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
