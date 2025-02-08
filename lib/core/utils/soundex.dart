class SoundexUtil {
  static String generate(String s) {
    if (s.isEmpty) return '';

    // Convert to uppercase and get first character
    s = s.toUpperCase();
    final firstChar = s[0];

    // Map of characters to soundex codes
    final codes = {
      'A': '',
      'E': '',
      'I': '',
      'O': '',
      'U': '',
      'B': '1',
      'F': '1',
      'P': '1',
      'V': '1',
      'C': '2',
      'G': '2',
      'J': '2',
      'K': '2',
      'Q': '2',
      'S': '2',
      'X': '2',
      'Z': '2',
      'D': '3',
      'T': '3',
      'L': '4',
      'M': '5',
      'N': '5',
      'R': '6',
    };

    // Convert remaining characters to codes
    final remaining = s
        .substring(1)
        .split('')
        .map((c) => codes[c] ?? '')
        .where((code) => code.isNotEmpty)
        .toList();

    // Remove adjacent duplicates
    for (var i = remaining.length - 1; i > 0; i--) {
      if (remaining[i] == remaining[i - 1]) {
        remaining.removeAt(i);
      }
    }

    // Build final soundex code
    final code = firstChar + remaining.join('');
    return ('${code}000').substring(0, 4);
  }
}
