import 'package:flutter/foundation.dart';

class CacheProvider with ChangeNotifier {
  final Map<String, dynamic> _cachedData =
      {}; // Made final as per best practices

  Map<String, dynamic> get cachedData => Map.unmodifiable(
      _cachedData); // Added unmodifiable to ensure immutability

  void updateCache(String key, dynamic value) {
    _cachedData[key] = value;
    notifyListeners();
  }

  void clearCache() {
    _cachedData.clear();
    notifyListeners();
  }
}
