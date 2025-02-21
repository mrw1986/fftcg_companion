import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/utils/html_parser.dart';

class CardDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const CardDescriptionText({
    super.key,
    required this.text,
    this.baseStyle,
  });

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
        spans.add(TextSpan(
          text: pendingSpecialAbility.trim(),
          style: const TextStyle(
            color: Color(0xFFFF8800),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontStyle: FontStyle.italic,
            height: 1.1,
            shadows: [Shadow(color: Colors.white, blurRadius: 2)],
          ),
        ));
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

        if (content == 'S') {
          addSpecialAbility();
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: 25,
              height: 25,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: baseStyle.color ??
                      Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12.5),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ));
          spans.add(const TextSpan(text: ' '));
          if (i + 1 < text.length) {
            hasSpecialAbility = true;
          }
        } else if (content.startsWith('Card Name')) {
          spans.add(TextSpan(
            text: currentText,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF332A9D),
            ),
          ));
          spans.add(const TextSpan(text: ' '));
        } else if (content == 'Dull') {
          addSpecialAbility();
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  baseStyle.color ?? Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/description/dull.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ));
          spans.add(const TextSpan(text: ' '));
        }
        currentText = '';
      } else if (!inBrackets &&
          text.substring(i).toLowerCase().startsWith('ex burst')) {
        addCurrentText();
        spans.add(TextSpan(
          text: 'EX BURST',
          style: const TextStyle(
            color: Color(0xFF332A9D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontFamily: 'Arial Black',
            height: 1.1,
            shadows: [Shadow(color: Colors.white, blurRadius: 2)],
          ),
        ));
        spans.add(const TextSpan(text: ' '));
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
