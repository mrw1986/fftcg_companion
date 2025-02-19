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
    // Get the current theme's text color
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;

    // Create a base style that ensures text is visible in both themes
    final effectiveBaseStyle = (baseStyle ?? const TextStyle()).copyWith(
      color: defaultTextColor,
      height: 1.5,
    );

    return RichText(
      text: TextSpan(
        children: _parseDescription(context, effectiveBaseStyle),
      ),
    );
  }

  List<InlineSpan> _parseDescription(
      BuildContext context, TextStyle baseStyle) {
    // First, parse HTML tags
    final htmlSpans = HtmlParser.parseHtml(text, baseStyle);

    // Then process special tokens within each text span
    final List<InlineSpan> finalSpans = [];

    for (final span in htmlSpans) {
      if (span is TextSpan) {
        // Ensure the text color is preserved when processing special tokens
        final spanStyle = (span.style ?? baseStyle).copyWith(
          color: span.style?.color ?? baseStyle.color,
        );
        finalSpans
            .addAll(_processSpecialTokens(context, span.text ?? '', spanStyle));
      } else {
        finalSpans.add(span);
      }
    }

    return finalSpans;
  }

  List<InlineSpan> _processSpecialTokens(
      BuildContext context, String text, TextStyle? style) {
    final List<InlineSpan> spans = [];
    final RegExp tokenPattern = RegExp(r'\[([^\]]+)\]|EX BURST|([^[]+)');
    String pendingSpecialAbility = '';
    bool hasSpecialAbility = false;

    void addSpecialAbility() {
      if (hasSpecialAbility && pendingSpecialAbility.isNotEmpty) {
        spans.add(
          TextSpan(
            text: pendingSpecialAbility.trim(),
            style: const TextStyle(
              color: Color(0xFFFF8800), // #f80
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
        pendingSpecialAbility = '';
        hasSpecialAbility = false;
      }
    }

    final matches = tokenPattern.allMatches(text);
    for (final match in matches) {
      final token = match.group(0);
      if (token == null) continue;

      if (token == 'EX BURST') {
        addSpecialAbility();
        spans.add(
          TextSpan(
            text: token,
            style: const TextStyle(
              color: Color(0xFF332A9D),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontFamily: 'Arial Black',
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
        spans.add(const TextSpan(text: ' '));
      } else if (token.startsWith('[') && token.endsWith(']')) {
        final content = token.substring(1, token.length - 1);

        if (content == 'S') {
          addSpecialAbility();
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 25,
                height: 25,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        style?.color ?? Theme.of(context).colorScheme.onSurface,
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
            ),
          );
          spans.add(const TextSpan(text: ' '));
        } else if (content == 'Dull') {
          addSpecialAbility();
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    style?.color ?? Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/description/dull.png',
                    width: 25,
                    height: 25,
                  ),
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' '));
        } else if (content == 'C') {
          addSpecialAbility();
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Image.asset(
                  'assets/images/description/crystal.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' '));
        } else if (RegExp(r'^[RIGYPUX]$').hasMatch(content)) {
          addSpecialAbility();
          final element = switch (content) {
            'R' => 'fire',
            'I' => 'ice',
            'G' => 'wind',
            'Y' => 'earth',
            'P' => 'lightning',
            'U' => 'water',
            _ => 'fire',
          };
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Image.asset(
                  'assets/images/elements/$element.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' '));
        } else if (RegExp(r'^[0-9X]$').hasMatch(content)) {
          addSpecialAbility();
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 25,
                height: 25,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        style?.color ?? Theme.of(context).colorScheme.onSurface,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Center(
                  child: Text(
                    content,
                    style: TextStyle(
                      color: style?.color ??
                          Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' '));
        }
      } else {
        if (hasSpecialAbility) {
          pendingSpecialAbility += token;
        } else {
          final nextMatch =
              matches.skipWhile((m) => m != match).skip(1).firstOrNull;
          if (nextMatch != null && nextMatch.group(0) == '[S]') {
            hasSpecialAbility = true;
            pendingSpecialAbility = token;
          } else {
            addSpecialAbility();
            spans.add(
              TextSpan(
                text: token,
                style: style,
              ),
            );
          }
        }
      }
    }

    addSpecialAbility();
    return spans;
  }
}
