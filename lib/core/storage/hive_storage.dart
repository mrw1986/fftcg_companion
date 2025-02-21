import 'dart:async';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/models.dart';

class HiveStorage {
  static const int _maxCacheSize = 1000;
  static const Duration _compactionInterval = Duration(hours: 6);
  static const String _filterCollectionBox = 'filter_collection';

  final Map<String, Box> _boxes = {};

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters efficiently
    _registerAdapters();

    // Initialize boxes with optimized settings
    await _initializeBoxes();

    // Setup periodic maintenance
    _setupPeriodicMaintenance();
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CardAdapter());
      Hive.registerAdapter(PriceAdapter());
      Hive.registerAdapter(HistoricalPriceAdapter());
    }
  }

  Future<void> _initializeBoxes() async {
    final boxes = [
      _openBox<Card>('cards'),
      _openBox<Price>('prices'),
      _openBox<Map>('query_cache'),
      _openBox('settings'),
      _openBox<Map>(_filterCollectionBox),
    ];

    final openedBoxes = await Future.wait(boxes);
    for (final box in openedBoxes) {
      _boxes[box.name] = box;
    }
  }

  Future<Box<T>> _openBox<T>(String name) async {
    return Hive.openBox<T>(
      name,
      compactionStrategy: _compactionStrategy,
      crashRecovery: true,
    );
  }

  bool _compactionStrategy(int entries, int deletedEntries) {
    return deletedEntries > 50 || entries > _maxCacheSize;
  }

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
    final box = _boxes[boxName ?? _filterCollectionBox];
    if (box == null) {
      talker.error('Box not found: ${boxName ?? _filterCollectionBox}');
      return null;
    }
    return box.get(key) as T?;
  }

  Future<void> put<T>(String key, T value, {String? boxName}) async {
    final box = _boxes[boxName ?? _filterCollectionBox];
    if (box == null) {
      talker.error('Box not found: ${boxName ?? _filterCollectionBox}');
      return;
    }
    await box.put(key, value);
  }

  Future<void> delete(String key, {String? boxName}) async {
    final box = _boxes[boxName ?? _filterCollectionBox];
    if (box == null) {
      talker.error('Box not found: ${boxName ?? _filterCollectionBox}');
      return;
    }
    await box.delete(key);
  }

  Future<void> clear({String? boxName}) async {
    final box = _boxes[boxName ?? _filterCollectionBox];
    if (box == null) {
      talker.error('Box not found: ${boxName ?? _filterCollectionBox}');
      return;
    }
    await box.clear();
  }
}
