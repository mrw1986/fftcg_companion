import 'package:flutter/material.dart';

class HtmlParser {
  /// Converts HTML text to a list of InlineSpan objects for rich text display
  static List<InlineSpan> parseHtml(String html, TextStyle? baseStyle) {
    final List<InlineSpan> spans = [];
    String currentText = '';
    bool isEmphasized = false;

    void addCurrentText() {
      if (currentText.isNotEmpty) {
        spans.add(
          TextSpan(
            text: currentText,
            style: baseStyle?.copyWith(
              fontStyle: isEmphasized ? FontStyle.italic : null,
              fontWeight: isEmphasized ? FontWeight.bold : null,
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

        final tag = html.substring(i + 1, tagEnd).toLowerCase();
        if (tag == 'br' || tag == 'br/' || tag == 'br /') {
          spans.add(const TextSpan(text: '\n'));
        } else if (tag == 'em') {
          isEmphasized = true;
        } else if (tag == '/em') {
          isEmphasized = false;
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
