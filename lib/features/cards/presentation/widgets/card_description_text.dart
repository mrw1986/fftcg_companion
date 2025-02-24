import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/utils/html_parser.dart';

class CardDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  // Border radius constants
  static const double _roundedSquareBorderRadius = 4.0;
  static const double _circularBorderRadius = 12.5;
  static const double _iconSize = 25.0;
  static const double _iconMarginH = 3.0;
  static const double _iconMarginV = 2.0;

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
    final effectiveBaseStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: defaultTextColor,
      height: 1.5,
    );

    return Text.rich(
      TextSpan(
        children: _parseDescription(context, effectiveBaseStyle),
      ),
      softWrap: true,
    );
  }

  List<InlineSpan> _parseDescription(
      BuildContext context, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    String currentText = '';
    bool inBrackets = false;
    bool hasSpecialAbility = false;
    String pendingSpecialAbility = '';

    void addCurrentText() {
      if (currentText.isNotEmpty) {
        if (hasSpecialAbility) {
          pendingSpecialAbility += currentText;
        } else {
          spans.addAll(HtmlParser.parseHtml(currentText, baseStyle));
        }
        currentText = '';
      }
    }

    void addSpecialAbility() {
      if (pendingSpecialAbility.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Text(
                pendingSpecialAbility.trim(),
                style: const TextStyle(
                  color: Color(0xFFFF8800),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
                ),
              ),
            ),
          ),
        );
        pendingSpecialAbility = '';
        hasSpecialAbility = false;
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
          if (i + 1 < text.length) {
            hasSpecialAbility = true;
          }
          addSpecialAbility();
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 22 / 14, // line-height: 22px
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
          spans.add(const TextSpan(text: ' '));
        }
        // Handle dull icon
        else if (content == 'Dull') {
          addSpecialAbility();
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
          spans.add(const TextSpan(text: ' '));
        }
        // Handle CP cost ([1], [2], [X], etc.)
        else if (RegExp(r'^\d+$').hasMatch(content) || content == 'X') {
          addSpecialAbility();
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
                child: Text(
                  content,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 22 / 14, // line-height: 22px
                  ),
                ),
              ),
            ),
          ));
          spans.add(const TextSpan(text: ' '));
        }
        // Handle element icons
        else {
          final elementPath = _getElementImagePath(content);
          if (elementPath != null) {
            addSpecialAbility();
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
            spans.add(const TextSpan(text: ' '));
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
                style: const TextStyle(
                  color: Color(0xFF332A9D),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Arial Black',
                  height: 1.1,
                  shadows: [Shadow(color: Colors.white, blurRadius: 2)],
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
    addSpecialAbility();
    return spans;
  }
}
