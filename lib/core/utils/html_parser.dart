import 'package:flutter/material.dart';

class HtmlParser {
  /// Converts HTML text to a list of InlineSpan objects for rich text display
  static List<InlineSpan> parseHtml(String html, TextStyle? baseStyle) {
    final List<InlineSpan> spans = [];
    String currentText = '';
    final List<String> styleStack = [];

    bool isEmphasized() {
      return styleStack.contains('em') || styleStack.contains('i');
    }

    bool isBold() {
      return styleStack.contains('b') || styleStack.contains('strong');
    }

    void addCurrentText() {
      if (currentText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: currentText,
            style: baseStyle?.copyWith(
              fontStyle: isEmphasized() ? FontStyle.italic : null,
              fontWeight: isBold() ? FontWeight.bold : null,
            ),
          ),
        );
        currentText = '';
      }
    }

    int i = 0;
    while (i < html.length) {
      if (html[i] == '<') {
        // Add any text before the tag
        addCurrentText();

        // Find the end of the tag
        final tagEnd = html.indexOf('>', i);
        if (tagEnd == -1) {
          // Invalid HTML, just add the < as text
          currentText += html[i];
          i++;
          continue;
        }

        final tag = html.substring(i + 1, tagEnd).toLowerCase().trim();
        if (tag == 'br' || tag == 'br/' || tag == 'br /') {
          spans.add(const TextSpan(text: '\n'));
        } else if (tag.startsWith('/')) {
          // Closing tag
          final tagName = tag.substring(1);
          if (styleStack.contains(tagName)) {
            styleStack.remove(tagName);
          }
        } else {
          // Opening tag
          final tagName = tag.split(' ')[0]; // Handle tags with attributes
          if (['em', 'i', 'b', 'strong'].contains(tagName)) {
            styleStack.add(tagName);
          }
        }

        i = tagEnd + 1;
      } else {
        // Handle special characters
        if (html.startsWith('&middot;', i)) {
          currentText += ' · ';
          i += '&middot;'.length;
        } else {
          currentText += html[i];
          i++;
        }
      }
    }

    // Add any remaining text
    addCurrentText();

    return spans;
  }
}
