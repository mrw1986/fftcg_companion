import 'dart:async';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/models.dart';

class HiveStorage {
  // Removed unused constant
  static const Duration _compactionInterval = Duration(hours: 6);
  static const String _filterCollectionBox = 'filter_collection';

  final Map<String, Box> _boxes = {};
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  // In-memory cache to reduce Hive access
  final Map<String, Map<String, dynamic>> _memoryCache = {};

  // Check if a box is available and ready to use
  Future<bool> isBoxAvailable(String boxName) async {
    // Check if we have it in our map
    if (_boxes.containsKey(boxName)) {
      final box = _boxes[boxName];
      if (box != null && box.isOpen) {
        return true;
      }
    }

    // Check if it's open in Hive
    if (Hive.isBoxOpen(boxName)) {
      try {
        // Try to get the box and store it in our map
        final box = Hive.box(boxName);
        _boxes[boxName] = box;
        return true;
      } catch (e) {
        talker.debug('Box $boxName is open but not accessible: $e');
        return false;
      }
    }

    return false;
  }

  // Update memory cache
  void _updateMemoryCache(String boxName, String key, dynamic value) {
    if (value != null) {
      _memoryCache[boxName] ??= {};
      _memoryCache[boxName]![key] = value;
    }
  }

  Future<void> initialize() async {
    // Prevent multiple initialization attempts
    if (_isInitializing) {
      talker.debug('HiveStorage already initializing, waiting for completion');
      return _initCompleter?.future ?? Future.value();
    }

    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      // Check if Hive is already initialized
      try {
        await Hive.initFlutter();
      } catch (e) {
        // Ignore if Hive is already initialized
        talker.debug('Hive may already be initialized: $e');
      }

      // Register adapters
      _registerAdapters();

      // Initialize boxes
      try {
        await _initializeBoxes();
      } catch (boxError) {
        talker.error(
            'Error initializing boxes, will use memory cache only', boxError);
        // Continue with memory cache only
      }

      // Setup periodic maintenance
      _setupPeriodicMaintenance();

      talker.info('HiveStorage initialized successfully');
      _initCompleter?.complete();
    } catch (e, stack) {
      talker.error('Error initializing Hive storage', e, stack);
      // Complete the future anyway to avoid hanging
      _initCompleter?.complete();
    } finally {
      _isInitializing = false;
    }
  }

  // Removed unused methods

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CardAdapter());
      Hive.registerAdapter(PriceAdapter());
      Hive.registerAdapter(HistoricalPriceAdapter());
    }
  }

  Future<void> _initializeBoxes() async {
    try {
      // Check if boxes are already open first and use the correct types
      // Use Map type for 'cards' box to match CardCache
      if (!Hive.isBoxOpen('cards')) {
        _boxes['cards'] = await Hive.openBox<Map>('cards');
      } else {
        _boxes['cards'] = Hive.box<Map>('cards');
      }

      if (!Hive.isBoxOpen('prices')) {
        _boxes['prices'] = await Hive.openBox<Price>('prices');
      } else {
        _boxes['prices'] = Hive.box<Price>('prices');
      }

      if (!Hive.isBoxOpen('query_cache')) {
        _boxes['query_cache'] = await Hive.openBox<Map>('query_cache');
      } else {
        _boxes['query_cache'] = Hive.box<Map>('query_cache');
      }

      if (!Hive.isBoxOpen('settings')) {
        _boxes['settings'] = await Hive.openBox('settings');
      } else {
        _boxes['settings'] = Hive.box('settings');
      }

      if (!Hive.isBoxOpen(_filterCollectionBox)) {
        _boxes[_filterCollectionBox] =
            await Hive.openBox<Map>(_filterCollectionBox);
      } else {
        _boxes[_filterCollectionBox] = Hive.box<Map>(_filterCollectionBox);
      }

      // Log the initialization status
      talker.info('Initialized ${_boxes.length} Hive boxes');
    } catch (e, stack) {
      talker.error('Error initializing boxes', e, stack);
      // Create memory caches for all boxes to ensure app can function
      _memoryCache['cards'] = {};
      _memoryCache['prices'] = {};
      _memoryCache['query_cache'] = {};
      _memoryCache['settings'] = {};
      _memoryCache[_filterCollectionBox] = {};
      talker.info('Created memory caches for all boxes');
      // Let the caller handle the error
      rethrow;
    }
  }

  // Removed unused method

  // Removed unused method

  void _setupPeriodicMaintenance() async {
    while (true) {
      await Future.delayed(_compactionInterval);
      await _compactAllBoxes();
    }
  }

  Future<void> _compactAllBoxes() async {
    for (final box in _boxes.values) {
      if (box.isOpen) {
        await box.compact();
        talker.debug('Compacted box: ${box.name}');
      }
    }
  }

  Future<T?> get<T>(String key, {String? boxName}) async {
    final targetBoxName = boxName ?? _filterCollectionBox;

    // First check if we have a memory cache for this key
    if (_memoryCache.containsKey(targetBoxName) &&
        _memoryCache[targetBoxName]!.containsKey(key)) {
      try {
        final cachedValue = _memoryCache[targetBoxName]![key];
        return cachedValue as T?;
      } catch (e) {
        // Type mismatch, continue to get from box
        talker
            .debug('Memory cache type mismatch for $key in $targetBoxName: $e');
      }
    }

    // Try to get from Hive box if available
    try {
      // Check if the box is open
      if (Hive.isBoxOpen(targetBoxName)) {
        try {
          final box = Hive.box(targetBoxName);
          final value = box.get(key);

          // Cache in memory for faster access next time
          if (value != null) {
            _updateMemoryCache(targetBoxName, key, value);
          }

          return value as T?;
        } catch (e) {
          talker.debug('Error getting value from box: $e');
          // Continue to try our box map
        }
      }

      // Try from our box map
      final box = _boxes[targetBoxName];
      if (box != null && box.isOpen) {
        try {
          final value = box.get(key);

          // Cache in memory for faster access next time
          if (value != null) {
            _updateMemoryCache(targetBoxName, key, value);
          }

          return value as T?;
        } catch (e) {
          talker.debug('Error getting value from box in map: $e');
          // Return null
        }
      }
    } catch (e) {
      talker.debug('Error accessing box $targetBoxName: $e');
    }

    return null;
  }

  Future<void> put<T>(String key, T value, {String? boxName}) async {
    final targetBoxName = boxName ?? _filterCollectionBox;

    // Update memory cache first for immediate access
    _updateMemoryCache(targetBoxName, key, value);

    // Try to put in Hive box if available
    try {
      // Check if the box is open
      if (Hive.isBoxOpen(targetBoxName)) {
        try {
          final box = Hive.box(targetBoxName);
          await box.put(key, value);
          talker.debug(
              'Successfully stored value for key $key in box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error putting value in box: $e');
          // Continue to try our box map
        }
      }

      // Try from our box map
      final box = _boxes[targetBoxName];
      if (box != null && box.isOpen) {
        try {
          await box.put(key, value);
          talker.debug(
              'Successfully stored value for key $key in box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error putting value in box from map: $e');
          // Continue with memory cache only
        }
      }

      // If we get here, we couldn't store in Hive, but we have the memory cache
      talker.info('Using memory cache only for $targetBoxName.$key');
    } catch (e) {
      talker.debug('Error accessing box $targetBoxName: $e');
      // We still have the memory cache, so the app can continue to function
    }
  }

  Future<void> delete(String key, {String? boxName}) async {
    final targetBoxName = boxName ?? _filterCollectionBox;

    // Remove from memory cache first
    if (_memoryCache.containsKey(targetBoxName)) {
      _memoryCache[targetBoxName]?.remove(key);
    }

    // Try to delete from Hive box if available
    try {
      // Check if the box is open
      if (Hive.isBoxOpen(targetBoxName)) {
        try {
          final box = Hive.box(targetBoxName);
          await box.delete(key);
          talker.debug('Successfully deleted key $key from box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error deleting key from box: $e');
          // Continue to try our box map
        }
      }

      // Try from our box map
      final box = _boxes[targetBoxName];
      if (box != null && box.isOpen) {
        try {
          await box.delete(key);
          talker.debug('Successfully deleted key $key from box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error deleting key from box in map: $e');
        }
      }

      // If we get here, we couldn't delete from Hive, but we've removed from memory cache
      talker.info('Removed $key from memory cache for $targetBoxName');
    } catch (e) {
      talker.debug('Error accessing box $targetBoxName: $e');
      // We've already removed from memory cache, so we're good
    }
  }

  Future<void> clear({String? boxName}) async {
    final targetBoxName = boxName ?? _filterCollectionBox;

    // Clear memory cache first
    _memoryCache.remove(targetBoxName);

    // Try to clear Hive box if available
    try {
      // Check if the box is open
      if (Hive.isBoxOpen(targetBoxName)) {
        try {
          final box = Hive.box(targetBoxName);
          await box.clear();
          talker.debug('Successfully cleared box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error clearing box: $e');
          // Continue to try our box map
        }
      }

      // Try from our box map
      final box = _boxes[targetBoxName];
      if (box != null && box.isOpen) {
        try {
          await box.clear();
          talker.debug('Successfully cleared box $targetBoxName');
          return;
        } catch (e) {
          talker.debug('Error clearing box from map: $e');
        }
      }

      // If we get here, we couldn't clear the Hive box, but we've cleared the memory cache
      talker.info('Cleared memory cache for $targetBoxName');
    } catch (e) {
      talker.debug('Error accessing box $targetBoxName: $e');
      // We've already cleared the memory cache, so we're good
    }
  }
}
