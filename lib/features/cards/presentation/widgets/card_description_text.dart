import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/utils/html_parser.dart';

class CardDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  // Border radius constants
  static const double _roundedSquareBorderRadius = 4.0;
  static const double _circularBorderRadius = 12.5;
  static const double _iconSize = 22.0; // Reduced from 25.0
  // Icon spacing constants
  static const double _iconMarginH = 1.0; // Minimal margin for tight spacing
  static const double _iconMarginV = 1.0;
  static const double _iconSpacing = 2.0; // Tighter spacing between icons

  // Text size constants
  static const double _baseFontSize = 14.0;
  static const double _specialFontSize = 15.0; // Reduced from 16.0
  static const double _minScaleFactor = 0.8;
  static const double _maxScaleFactor = 1.2;

  double _getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // More responsive scaling based on device width
    // Use a smaller base width for better scaling on smaller devices
    final scaleFactor = width /
        375; // Adjusted from 400 to 375 for better scaling on smaller devices
    return scaleFactor.clamp(_minScaleFactor, _maxScaleFactor);
  }

  const CardDescriptionText({
    super.key,
    required this.text,
    this.baseStyle,
  });

  String? _getElementImagePath(String code) {
    // Map single letter codes to element names
    final elementMappings = {
      'R': 'fire',
      'I': 'ice',
      'G': 'wind',
      'Y': 'earth',
      'P': 'lightning',
      'U': 'water',
      'L': 'light',
      'D': 'dark',
    };

    final elementName = elementMappings[code];
    if (elementName != null) {
      return 'assets/images/elements/$elementName.png';
    }

    // Handle Crystal separately as it's in a different directory
    if (code == 'C') {
      return 'assets/images/description/crystal.png';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;
    final scaleFactor = _getScaleFactor(context);
    final effectiveBaseStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: defaultTextColor,
      height: 1.5,
      fontSize: _baseFontSize * scaleFactor,
    );

    return Text.rich(
      TextSpan(
        children: _parseDescription(context, effectiveBaseStyle, scaleFactor),
      ),
      softWrap: true,
      overflow: TextOverflow.visible, // Ensure text doesn't get cut off
      textScaler: const TextScaler.linear(
          1.0), // Use our custom scaling instead of system scaling
    );
  }

  List<InlineSpan> _parseDescription(
      BuildContext context, TextStyle baseStyle, double scaleFactor) {
    // Process the entire text first to handle line breaks and special formatting
    final processedText = text.replaceAll('<br>', '\n');

    final List<InlineSpan> spans = [];

    // Define the special ability style once to ensure consistency
    final specialAbilityStyle = TextStyle(
      color: const Color(0xFFFF8800),
      fontWeight: FontWeight.bold,
      fontSize: _specialFontSize * scaleFactor,
      fontStyle: FontStyle.italic,
      height: 1.1,
      shadows: const [Shadow(color: Colors.white, blurRadius: 3)],
    );

    // Split the text by line breaks to handle each line separately
    final lines = processedText.split('\n');

    // Process each line
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // Check if this line contains a special ability
      final bool containsSpecialAbility = line.contains('[S]') &&
          (line.contains('<b>') || RegExp(r'\b\w+\s*\[S\]').hasMatch(line));

      if (containsSpecialAbility) {
        // Extract the special ability name
        String abilityName = '';

        // Check for <b>AbilityName</b> pattern
        final RegExp boldAbilityRegex = RegExp(r'<b>([^<]+)</b>');
        final Match? boldMatch = boldAbilityRegex.firstMatch(line);

        if (boldMatch != null && boldMatch.group(1) != null) {
          abilityName = boldMatch.group(1)!;

          // Get the text before the ability
          final int tagStart = line.indexOf('<b>');
          final int tagEnd = line.indexOf('</b>') + 4;
          final String textBeforeAbility = line.substring(0, tagStart);
          final String abilityWithTags = line.substring(tagStart, tagEnd);
          final String textAfterAbility = line.substring(tagEnd);

          // Add text before ability with normal styling
          if (textBeforeAbility.isNotEmpty) {
            spans.addAll(HtmlParser.parseHtml(textBeforeAbility, baseStyle));
          }

          // Add the ability with orange styling
          spans.addAll(HtmlParser.parseHtml(
            abilityWithTags,
            specialAbilityStyle,
          ));

          // Process the rest of the line (after the ability name)
          _processTextWithBrackets(
              context, textAfterAbility, spans, baseStyle, scaleFactor);
        } else {
          // Try to find ability name without HTML tags
          final RegExp plainAbilityRegex = RegExp(r'(\w+)(\s*)\[S\]');
          final Match? plainMatch = plainAbilityRegex.firstMatch(line);

          if (plainMatch != null && plainMatch.group(1) != null) {
            abilityName = plainMatch.group(1)!;
            final int abilityStart = line.indexOf(abilityName);
            final int abilityEnd = abilityStart + abilityName.length;

            // Get the text before the ability
            final String textBeforeAbility = line.substring(0, abilityStart);
            // Include any whitespace between ability name and [S] in the styled text
            final String whitespace = plainMatch.group(2) ?? '';
            final String textAfterAbility =
                line.substring(abilityEnd + whitespace.length);

            // Add text before ability with normal styling
            if (textBeforeAbility.isNotEmpty) {
              spans.addAll(HtmlParser.parseHtml(textBeforeAbility, baseStyle));
            }

            // Add the ability with orange styling
            spans.add(TextSpan(
              text: abilityName,
              style: specialAbilityStyle,
            ));

            // Process the rest of the line
            _processTextWithBrackets(
                context, textAfterAbility, spans, baseStyle, scaleFactor);
          } else {
            // No ability pattern found, process the whole line
            _processTextWithBrackets(
                context, line, spans, baseStyle, scaleFactor);
          }
        }
      } else {
        // Regular line without special ability
        _processTextWithBrackets(context, line, spans, baseStyle, scaleFactor);
      }

      // Add line break if this is not the last line
      if (lineIndex < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  void _processTextWithBrackets(BuildContext context, String text,
      List<InlineSpan> spans, TextStyle baseStyle, double scaleFactor) {
    String currentText = '';
    bool inBrackets = false;

    void addCurrentText() {
      if (currentText.isNotEmpty) {
        spans.addAll(HtmlParser.parseHtml(currentText, baseStyle));
        currentText = '';
      }
    }

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '[') {
        addCurrentText();
        inBrackets = true;
        currentText = '[';
      } else if (char == ']' && inBrackets) {
        currentText += ']';
        inBrackets = false;

        final content = currentText.substring(1, currentText.length - 1);

        // Handle special ability [S] tag
        if (content == 'S') {
          // Add the [S] icon
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: _iconSize,
              height: _iconSize,
              margin: EdgeInsets.symmetric(
                horizontal: _iconMarginH,
                vertical: _iconMarginV,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(_roundedSquareBorderRadius),
              ),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: _baseFontSize * scaleFactor,
                    fontWeight: FontWeight.bold,
                    height: 1.0, // Better centering in container
                  ),
                ),
              ),
            ),
          ));

          // Add spacing after the [S] icon
          spans.add(WidgetSpan(
            child: SizedBox(width: _iconSpacing),
          ));
        }
        // Handle card name references
        else if (content.startsWith('Card Name')) {
          spans.add(TextSpan(
            text: currentText,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF332A9D),
            ),
          ));
          spans.add(WidgetSpan(
            child: SizedBox(width: _iconSpacing),
          ));
        }
        // Handle dull icon
        else if (content == 'Dull') {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: _iconSize,
              height: _iconSize,
              margin: EdgeInsets.symmetric(
                horizontal: _iconMarginH,
                vertical: _iconMarginV,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(_roundedSquareBorderRadius),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/description/dull.png',
                  width: _iconSize,
                  height: _iconSize,
                ),
              ),
            ),
          ));
          spans.add(WidgetSpan(
            child: SizedBox(width: _iconSpacing),
          ));
        }
        // Handle CP cost ([1], [2], [X], etc.)
        else if (RegExp(r'^\d+$').hasMatch(content) || content == 'X') {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: _iconSize,
              height: _iconSize,
              margin: EdgeInsets.symmetric(
                horizontal: _iconMarginH,
                vertical: _iconMarginV,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(_circularBorderRadius),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 1), // Fine-tune vertical centering
                  child: Text(
                    content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _baseFontSize * scaleFactor,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ));
          spans.add(WidgetSpan(
            child: SizedBox(width: _iconSpacing),
          ));
        }
        // Handle element icons
        else {
          final elementPath = _getElementImagePath(content);
          if (elementPath != null) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: _iconSize,
                height: _iconSize,
                margin: EdgeInsets.symmetric(
                  horizontal: _iconMarginH,
                  vertical: _iconMarginV,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(_circularBorderRadius),
                ),
                child: Image.asset(
                  elementPath,
                  width: _iconSize,
                  height: _iconSize,
                ),
              ),
            ));
            spans.add(WidgetSpan(
              child: SizedBox(width: _iconSpacing),
            ));
          }
        }
        currentText = '';
      } else if (!inBrackets &&
          text.substring(i).toLowerCase().startsWith('ex burst')) {
        addCurrentText();
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 3,
                  right: 4), // Reduced right padding to decrease spacing
              child: Text(
                'EX BURST',
                style: TextStyle(
                  color: const Color(0xFF332A9D),
                  fontWeight: FontWeight.bold,
                  fontSize: _specialFontSize *
                      scaleFactor, // Match special ability text size
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Arial Black',
                  height: 1.1,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 3)
                  ], // Increased blur radius for better visibility in dark mode
                ),
              ),
            ),
          ),
        );
        i += 'ex burst'.length - 1;
      } else {
        currentText += char;
      }
    }

    // Add any remaining text
    if (currentText.isNotEmpty) {
      spans.addAll(HtmlParser.parseHtml(currentText, baseStyle));
    }
  }
}
