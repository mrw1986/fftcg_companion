import 'package:flutter/material.dart';

class HtmlParser {
  /// Sanitizes HTML input to prevent XSS attacks
  static String _sanitizeHtml(String html) {
    // For card descriptions, we need minimal sanitization to avoid removing legitimate text
    // Only remove the most dangerous patterns with very specific matching
    final dangerousPatterns = [
      // Only match complete script tags with proper boundaries
      RegExp(r'<script\b[^>]*>.*?</script\s*>',
          caseSensitive: false, dotAll: true),
      RegExp(r'<iframe\b[^>]*>.*?</iframe\s*>',
          caseSensitive: false, dotAll: true),
      RegExp(r'<object\b[^>]*>.*?</object\s*>',
          caseSensitive: false, dotAll: true),
      RegExp(r'<embed\b[^>]*/?>', caseSensitive: false),
      RegExp(r'<form\b[^>]*>.*?</form\s*>', caseSensitive: false, dotAll: true),
      RegExp(r'<input\b[^>]*/?>', caseSensitive: false),
      RegExp(r'<button\b[^>]*>.*?</button\s*>',
          caseSensitive: false, dotAll: true),
      // Only match actual javascript: hrefs within proper a tags
      RegExp(
          r'<a\b[^>]*\bhref\s*=\s*["\x27]\s*javascript:[^"\x27]*["\x27][^>]*>.*?</a\s*>',
          caseSensitive: false,
          dotAll: true),
      // Only match actual event handler attributes within HTML tags (not in text)
      RegExp(r'<[^>]*\bon\w+\s*=\s*["\x27][^"\x27]*["\x27][^>]*>',
          caseSensitive: false),
      // Only match actual style attributes within HTML tags (not in text)
      RegExp(r'<[^>]*\bstyle\s*=\s*["\x27][^"\x27]*["\x27][^>]*>',
          caseSensitive: false),
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
