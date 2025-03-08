import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeColor = ref.watch(themeColorControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (newMode) {
                if (newMode != null) {
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(newMode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Theme Color'),
            trailing: Container(
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
                  onTap: () => _showColorPickerDialog(context, ref, themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPickerDialog(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) async {
    Color selectedColor = currentColor;
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;

    final result = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning about color selection
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Color Selection Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLightMode
                          ? 'Avoid selecting very light colors in light mode as they may make text difficult to read.'
                          : 'Avoid selecting very dark colors in dark mode as they may make text difficult to read.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              // Color picker
              SingleChildScrollView(
                child: ColorPicker(
                  color: currentColor,
                  onColorChanged: (color) {
                    // Check if the color is too dark in dark mode or too light in light mode
                    final luminance = color.computeLuminance();
                    if ((isLightMode && luminance > 0.9) ||
                        (!isLightMode && luminance < 0.1)) {
                      // Show warning but still allow selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isLightMode
                                ? 'This color may be too light for light mode'
                                : 'This color may be too dark for dark mode',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    selectedColor = color;
                  },
                  enableShadesSelection: false,
                  pickersEnabled: const {
                    ColorPickerType.primary: true,
                    ColorPickerType.accent: true,
                    ColorPickerType.wheel: true,
                  },
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedColor),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Apply a minimum brightness for dark mode and maximum for light mode
      final luminance = result.computeLuminance();
      Color safeColor = result;

      if (isLightMode && luminance > 0.9) {
        // If too light in light mode, adjust to a safer color
        safeColor = HSLColor.fromColor(result)
            .withLightness(0.7) // Reduce lightness to ensure readability
            .toColor();
      } else if (!isLightMode && luminance < 0.1) {
        // If too dark in dark mode, adjust to a safer color
        safeColor = HSLColor.fromColor(result)
            .withLightness(0.3) // Increase lightness to ensure readability
            .toColor();
      }

      await ref
          .read(themeColorControllerProvider.notifier)
          .setThemeColor(safeColor);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: safeColor != result
                ? const Text('Theme color adjusted for better readability')
                : const Text('Theme color updated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
