import 'package:flutter/material.dart';

class HtmlParser {
  /// Sanitizes HTML input to prevent XSS attacks
  static String _sanitizeHtml(String html) {
    // Remove potentially dangerous tags and attributes
    final dangerousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
      RegExp(r'<object[^>]*>.*?</object>', caseSensitive: false),
      RegExp(r'<embed[^>]*>.*?</embed>', caseSensitive: false),
      RegExp(r'<form[^>]*>.*?</form>', caseSensitive: false),
      RegExp(r'<input[^>]*>', caseSensitive: false),
      RegExp(r'<button[^>]*>.*?</button>', caseSensitive: false),
      RegExp(
          r'<a[^>]*href\s*=\s*["\x27][^"\x27]*javascript:[^"\x27]*["\x27][^>]*>.*?</a>',
          caseSensitive: false),
      RegExp(r'on\w+\s*=\s*["\x27][^"\x27]*["\x27]', caseSensitive: false),
      RegExp(r'style\s*=\s*["\x27][^"\x27]*["\x27]', caseSensitive: false),
    ];

    String sanitized = html;
    for (final pattern in dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }

    return sanitized;
  }

  /// Converts HTML text to a list of InlineSpan objects for rich text display
  static List<InlineSpan> parseHtml(String html, TextStyle? baseStyle) {
    // Sanitize input first
    final sanitizedHtml = _sanitizeHtml(html);

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
        // Create a proper TextStyle even when baseStyle is null
        final effectiveStyle = (baseStyle ?? const TextStyle()).copyWith(
          fontStyle: isEmphasized() ? FontStyle.italic : null,
          fontWeight: isBold() ? FontWeight.bold : null,
        );

        spans.add(
          TextSpan(
            text: currentText,
            style: effectiveStyle,
          ),
        );
        currentText = '';
      }
    }

    int i = 0;
    while (i < sanitizedHtml.length) {
      if (sanitizedHtml[i] == '<') {
        // Add any text before the tag
        addCurrentText();

        // Find the end of the tag
        final tagEnd = sanitizedHtml.indexOf('>', i);
        if (tagEnd == -1) {
          // Invalid HTML, just add the < as text
          currentText += sanitizedHtml[i];
          i++;
          continue;
        }

        final tag = sanitizedHtml.substring(i + 1, tagEnd).toLowerCase().trim();
        if (tag == 'br' || tag == 'br/' || tag == 'br /') {
          spans.add(const TextSpan(text: '\n'));
        } else if (tag.startsWith('/')) {
          // Closing tag
          final tagName = tag.substring(1);
          if (styleStack.contains(tagName)) {
            styleStack.remove(tagName);
          }
        } else {
          // Opening tag - only allow safe formatting tags
          final tagName = tag.split(' ')[0]; // Handle tags with attributes
          if (['em', 'i', 'b', 'strong'].contains(tagName)) {
            styleStack.add(tagName);
          }
          // Ignore all other tags for security
        }

        i = tagEnd + 1;
      } else {
        // Handle special characters
        if (sanitizedHtml.startsWith('&middot;', i)) {
          currentText += ' · ';
          i += '&middot;'.length;
        } else if (sanitizedHtml.startsWith('&lt;', i)) {
          currentText += '<';
          i += '&lt;'.length;
        } else if (sanitizedHtml.startsWith('&gt;', i)) {
          currentText += '>';
          i += '&gt;'.length;
        } else if (sanitizedHtml.startsWith('&amp;', i)) {
          currentText += '&';
          i += '&amp;'.length;
        } else if (sanitizedHtml.startsWith('&quot;', i)) {
          currentText += '"';
          i += '&quot;'.length;
        } else {
          currentText += sanitizedHtml[i];
          i++;
        }
      }
    }

    // Add any remaining text
    addCurrentText();

    return spans;
  }
}
