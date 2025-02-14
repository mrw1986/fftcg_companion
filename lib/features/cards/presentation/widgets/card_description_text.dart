import 'package:flutter/material.dart';

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
    return RichText(
      text: TextSpan(
        children: _parseDescription(context),
      ),
    );
  }

  List<InlineSpan> _parseDescription(BuildContext context) {
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
              height: 1.1, // For better vertical alignment
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
              height: 1.1, // For better vertical alignment
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
        spans.add(const TextSpan(text: ' ')); // Add space after EX BURST
      } else if (token.startsWith('[') && token.endsWith(']')) {
        final content = token.substring(1, token.length - 1);

        if (content == 'S') {
          // If we find [S], the previous text was a special ability
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
                    color: const Color(0xFF111111),
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
                      height: 1.1, // For better vertical alignment
                    ),
                  ),
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' ')); // Add space after [S]
        } else if (content == 'Dull') {
          addSpecialAbility();
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Image.asset(
                  'assets/images/description/dull.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' ')); // Add space after [Dull]
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
          spans.add(const TextSpan(text: ' ')); // Add space after [C]
        } else if (RegExp(r'^[RIGYPUX]$').hasMatch(content)) {
          addSpecialAbility();
          final element = switch (content) {
            'R' => 'fire',
            'I' => 'ice',
            'G' => 'wind',
            'Y' => 'earth',
            'P' => 'lightning',
            'U' => 'water',
            _ => 'fire', // Default to fire, shouldn't happen
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
          spans.add(const TextSpan(text: ' ')); // Add space after element
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
                    color: const Color(0xFF111111),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Center(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.1, // For better vertical alignment
                    ),
                  ),
                ),
              ),
            ),
          );
          spans.add(const TextSpan(text: ' ')); // Add space after number
        }
      } else {
        // Regular text
        if (hasSpecialAbility) {
          // If we're collecting a special ability, keep adding to it
          pendingSpecialAbility += token;
        } else {
          // Check if this text is followed by [S]
          final nextMatch =
              matches.skipWhile((m) => m != match).skip(1).firstOrNull;
          if (nextMatch != null && nextMatch.group(0) == '[S]') {
            // This text is a special ability
            hasSpecialAbility = true;
            pendingSpecialAbility = token;
          } else {
            // Regular text
            addSpecialAbility();
            spans.add(
              TextSpan(
                text: token,
                style: baseStyle?.copyWith(height: 1.5), // Increased line height for readability
              ),
            );
          }
        }
      }
    }

    // Add any remaining special ability
    addSpecialAbility();

    return spans;
  }
}
