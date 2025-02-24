import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/utils/html_parser.dart';

class CardDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  // Border radius constants
  static const double _roundedSquareBorderRadius = 4.0;
  static const double _circularBorderRadius = 12.5;
  static const double _iconSize = 25.0;
  // Icon spacing constants
  static const double _iconMarginH = 1.0; // Minimal margin for tight spacing
  static const double _iconMarginV = 1.0;
  static const double _iconSpacing = 2.0; // Tighter spacing between icons

  // Text size constants
  static const double _baseFontSize = 14.0;
  static const double _specialFontSize = 16.0;
  static const double _minScaleFactor = 0.8;
  static const double _maxScaleFactor = 1.2;

  double _getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scaleFactor = width / 400; // Base width for scaling
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
    );
  }

  List<InlineSpan> _parseDescription(
      BuildContext context, TextStyle baseStyle, double scaleFactor) {
    final List<InlineSpan> spans = [];
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
          // Get the text before [S] tag for special ability name
          final abilityName = text.substring(0, i - currentText.length).trim();
          if (abilityName.isNotEmpty) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Text(
                abilityName,
                style: TextStyle(
                  color: const Color(0xFFFF8800),
                  fontWeight: FontWeight.bold,
                  fontSize: _specialFontSize * scaleFactor,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
                ),
              ),
            ));
            currentText = '';
          }
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
              padding: const EdgeInsets.only(left: 3, right: 10),
              child: Text(
                'EX BURST',
                style: TextStyle(
                  color: const Color(0xFF332A9D),
                  fontWeight: FontWeight.bold,
                  fontSize: _baseFontSize *
                      1.2 *
                      scaleFactor, // Slightly larger than base
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Arial Black',
                  height: 1.1,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
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

    addCurrentText();
    return spans;
  }
}
