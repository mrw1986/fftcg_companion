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

    final result = await showDialog<Color>(
      // Changed return type to Color
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: currentColor,
              onColorChanged: (color) => selectedColor = color,
              enableShadesSelection: false,
              pickersEnabled: const {
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Remove false
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(selectedColor), // Return color instead of true
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Check for null instead of true
      await ref
          .read(themeColorControllerProvider.notifier)
          .setThemeColor(result);
      if (context.mounted) {
        // Add mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme color updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
