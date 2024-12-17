// tool/generate_assets.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  const String sourceIconPath = 'logo.png';

  try {
    await generateAppAssets(sourceIconPath);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<void> generateAppAssets(String sourceIconPath) async {
  // Load the source image
  final sourceFile = File(sourceIconPath);
  if (!await sourceFile.exists()) {
    stderr.writeln('Error: $sourceIconPath not found');
    exit(1);
  }

  var sourceImage = img.decodeImage(await sourceFile.readAsBytes());
  if (sourceImage == null) {
    stderr.writeln('Error: Could not decode image');
    exit(1);
  }

  // Verify and resize to 1024x1024 if needed
  if (sourceImage.width != 1024 || sourceImage.height != 1024) {
    stderr.writeln('Resizing image to 1024x1024...');
    sourceImage = img.copyResize(sourceImage,
        width: 1024, height: 1024, interpolation: img.Interpolation.linear);
  }

  // Create assets directory
  final assetsDir = Directory('assets/images');
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }

  // Generate all required assets
  final assets = {
    'splash_logo.png': 192,
    'splash_logo_dark.png': 192,
    'splash_logo_android12.png': 192,
    'splash_logo_android12_dark.png': 192,
    'app_icon.png': 1024,
    'app_icon_foreground.png': 1024,
  };

  for (final entry in assets.entries) {
    stderr.writeln('Generating ${entry.key}...');

    final resized = img.copyResize(sourceImage,
        width: entry.value,
        height: entry.value,
        interpolation: img.Interpolation.linear);

    final outputFile = File('${assetsDir.path}/${entry.key}');
    await outputFile.writeAsBytes(img.encodePng(resized));
    stderr.writeln('Created ${entry.key}');
  }

  stderr.writeln('\nAll assets generated successfully in assets/images/');
  stderr.writeln('\nNext steps:');
  stderr.writeln('1. Run: flutter pub run flutter_native_splash:create');
  stderr.writeln('2. Run: flutter pub run flutter_launcher_icons');
}
