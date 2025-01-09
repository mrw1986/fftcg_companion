// lib/core/storage/hive_storage.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class HiveStorage {
  static Future<void> init() async {
    try {
      talker.debug('Starting Hive initialization');

      final appDir = await getApplicationDocumentsDirectory();
      talker.debug('Using app directory: ${appDir.path}');

      await Hive.initFlutter(appDir.path);
      talker.debug('Hive.initFlutter completed');

      // Register adapters
      talker.debug('Registering Hive adapters');

      if (!Hive.isAdapterRegistered(0)) {
        talker.debug('Registering Card adapter (TypeId: 0)');
        Hive.registerAdapter(CardAdapter());
      }

      if (!Hive.isAdapterRegistered(1)) {
        talker.debug('Registering ExtendedData adapter (TypeId: 1)');
        Hive.registerAdapter(ExtendedDataAdapter());
      }

      if (!Hive.isAdapterRegistered(2)) {
        talker.debug('Registering Price adapter (TypeId: 2)');
        Hive.registerAdapter(PriceAdapter());
      }

      if (!Hive.isAdapterRegistered(3)) {
        talker.debug('Registering PriceData adapter (TypeId: 3)');
        Hive.registerAdapter(PriceDataAdapter());
      }

      if (!Hive.isAdapterRegistered(4)) {
        talker.debug('Registering HistoricalPrice adapter (TypeId: 4)');
        Hive.registerAdapter(HistoricalPriceAdapter());
      }

      if (!Hive.isAdapterRegistered(5)) {
        talker.debug('Registering HistoricalPriceData adapter (TypeId: 5)');
        Hive.registerAdapter(HistoricalPriceDataAdapter());
      }

      talker.debug('Opening Hive boxes');

      // Open boxes with error handling for each box
      try {
        await _openBox<Card>('cards');
        talker.debug('Cards box opened successfully');
      } catch (e, stack) {
        talker.error('Error opening cards box', e, stack);
        await _recreateBox<Card>('cards');
      }

      try {
        await _openBox<Price>('prices');
        talker.debug('Prices box opened successfully');
      } catch (e, stack) {
        talker.error('Error opening prices box', e, stack);
        await _recreateBox<Price>('prices');
      }

      try {
        await _openBox<HistoricalPrice>('historical_prices');
        talker.debug('Historical prices box opened successfully');
      } catch (e, stack) {
        talker.error('Error opening historical_prices box', e, stack);
        await _recreateBox<HistoricalPrice>('historical_prices');
      }

      try {
        await Hive.openBox('settings');
        talker.debug('Settings box opened successfully');
      } catch (e, stack) {
        talker.error('Error opening settings box', e, stack);
        await _recreateBox('settings');
      }

      try {
        await Hive.openBox('cache_metadata');
        talker.debug('Cache metadata box opened successfully');
      } catch (e, stack) {
        talker.error('Error opening cache_metadata box', e, stack);
        await _recreateBox('cache_metadata');
      }

      talker.info('✅ Hive initialization completed successfully');
    } catch (e, stack) {
      talker.error('Critical error during Hive initialization', e, stack);
      await _handleCriticalError();
      rethrow;
    }
  }

  /// Opens a typed box with the given name
  static Future<Box<T>> _openBox<T>(String boxName) async {
    talker.debug('Opening box: $boxName');
    return await Hive.openBox<T>(boxName);
  }

  /// Recreates a box after deleting it
  static Future<void> _recreateBox<T>(String boxName) async {
    talker.warning('Attempting to recreate box: $boxName');
    try {
      await Hive.deleteBoxFromDisk(boxName);
      talker.debug('Deleted corrupted box: $boxName');

      if (T == dynamic) {
        await Hive.openBox(boxName);
      } else {
        await Hive.openBox<T>(boxName);
      }
      talker.info('✅ Successfully recreated box: $boxName');
    } catch (e, stack) {
      talker.error('Failed to recreate box: $boxName', e, stack);
      rethrow;
    }
  }

  /// Handles critical initialization errors
  static Future<void> _handleCriticalError() async {
    talker.warning('Attempting to clean up after critical error');
    try {
      // Close all boxes that might be open
      await Future.wait([
        if (Hive.isBoxOpen('cards')) Hive.box('cards').close(),
        if (Hive.isBoxOpen('prices')) Hive.box('prices').close(),
        if (Hive.isBoxOpen('historical_prices'))
          Hive.box('historical_prices').close(),
        if (Hive.isBoxOpen('settings')) Hive.box('settings').close(),
        if (Hive.isBoxOpen('cache_metadata'))
          Hive.box('cache_metadata').close(),
      ]);
      talker.debug('All boxes closed');

      // Delete all boxes from disk
      await Future.wait([
        Hive.deleteBoxFromDisk('cards'),
        Hive.deleteBoxFromDisk('prices'),
        Hive.deleteBoxFromDisk('historical_prices'),
        Hive.deleteBoxFromDisk('settings'),
        Hive.deleteBoxFromDisk('cache_metadata'),
      ]);
      talker.debug('All boxes deleted from disk');

      talker.info('✅ Critical error cleanup completed');
    } catch (e, stack) {
      talker.error('Failed to clean up after critical error', e, stack);
      // At this point, we can't do much more than log the error
    }
  }

  /// Closes all boxes - useful for cleanup
  static Future<void> closeAllBoxes() async {
    talker.debug('Closing all Hive boxes');
    try {
      await Future.wait([
        if (Hive.isBoxOpen('cards')) Hive.box('cards').close(),
        if (Hive.isBoxOpen('prices')) Hive.box('prices').close(),
        if (Hive.isBoxOpen('historical_prices'))
          Hive.box('historical_prices').close(),
        if (Hive.isBoxOpen('settings')) Hive.box('settings').close(),
        if (Hive.isBoxOpen('cache_metadata'))
          Hive.box('cache_metadata').close(),
      ]);
      talker.info('✅ All boxes closed successfully');
    } catch (e, stack) {
      talker.error('Error closing Hive boxes', e, stack);
      rethrow;
    }
  }
}
