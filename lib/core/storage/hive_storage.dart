import 'dart:async';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/models.dart';

class HiveStorage {
  static const int _maxCacheSize = 1000;
  static const Duration _compactionInterval = Duration(hours: 6);

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters efficiently
    _registerAdapters();

    // Initialize boxes with optimized settings
    await _initializeBoxes();

    // Setup periodic maintenance
    _setupPeriodicMaintenance();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CardAdapter());
      Hive.registerAdapter(PriceAdapter());
      Hive.registerAdapter(HistoricalPriceAdapter());
    }
  }

  static Future<void> _initializeBoxes() async {
    final boxes = [
      _openBox<Card>('cards'),
      _openBox<Price>('prices'),
      _openBox<Map>('query_cache'),
      _openBox('settings'),
    ];

    await Future.wait(boxes);
  }

  static Future<Box<T>> _openBox<T>(String name) async {
    return Hive.openBox<T>(
      name,
      compactionStrategy: _compactionStrategy,
      crashRecovery: true,
    );
  }

  static bool _compactionStrategy(int entries, int deletedEntries) {
    return deletedEntries > 50 || entries > _maxCacheSize;
  }

  static void _setupPeriodicMaintenance() async {
    while (true) {
      await Future.delayed(_compactionInterval);
      await _compactAllBoxes();
    }
  }

  static Future<void> _compactAllBoxes() async {
    final boxNames = Hive.isBoxOpen('settings')
        ? Hive.box('settings').keys.toList()
        : <dynamic>[];

    for (final name in boxNames) {
      final box = Hive.box(name as String);
      if (box.isOpen) {
        await box.compact();
        talker.debug('Compacted box: $name');
      }
    }
  }
}
