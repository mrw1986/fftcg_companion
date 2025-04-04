// lib/features/collection/presentation/providers/collection_view_preferences_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart'; // Import shared enums

part 'collection_view_preferences_provider.g.dart';

@riverpod
class CollectionViewPreferences extends _$CollectionViewPreferences {
  // Use distinct keys for collection preferences
  static const _boxName = 'settings';
  static const _viewTypeKey = 'collection_view_type';
  static const _gridSizeKey = 'collection_grid_size';
  static const _listSizeKey = 'collection_list_size';
  static const _showLabelsKey = 'collection_show_labels';

  Box? _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      try {
        return Hive.box(_boxName);
      } catch (e) {
        return null;
      }
    }
    return Hive.box(_boxName);
  }

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  ({ViewType type, ViewSize gridSize, ViewSize listSize, bool showLabels})
      build() {
    final box = _getBox();
    return (
      type: _loadViewType(box),
      gridSize: _loadSize(box, _gridSizeKey),
      listSize: _loadSize(box, _listSizeKey),
      showLabels: box?.get(_showLabelsKey, defaultValue: true) ?? true,
    );
  }

  ViewType _loadViewType(Box? box) {
    final saved = box?.get(_viewTypeKey, defaultValue: ViewType.grid.name);
    if (saved == null) return ViewType.grid;
    return ViewType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewType.grid,
    );
  }

  ViewSize _loadSize(Box? box, String key) {
    final saved = box?.get(key, defaultValue: ViewSize.normal.name);
    if (saved == null) return ViewSize.normal;
    return ViewSize.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewSize.normal,
    );
  }

  Future<void> toggleViewType() async {
    final box = await _openBox();
    final newType = state.type == ViewType.grid ? ViewType.list : ViewType.grid;
    await box.put(_viewTypeKey, newType.name);
    state = (
      type: newType,
      gridSize: state.gridSize,
      listSize: state.listSize,
      showLabels: state.showLabels,
    );
  }

  Future<void> cycleSize() async {
    final box = await _openBox();
    if (state.type == ViewType.grid) {
      final newSize = state.gridSize.next;
      await box.put(_gridSizeKey, newSize.name);
      state = (
        type: state.type,
        gridSize: newSize,
        listSize: state.listSize,
        showLabels: state.showLabels,
      );
    } else {
      final newSize = state.listSize.next;
      await box.put(_listSizeKey, newSize.name);
      state = (
        type: state.type,
        gridSize: state.gridSize,
        listSize: newSize,
        showLabels: state.showLabels,
      );
    }
  }

  Future<void> toggleLabels() async {
    final box = await _openBox();
    await box.put(_showLabelsKey, !state.showLabels);
    state = (
      type: state.type,
      gridSize: state.gridSize,
      listSize: state.listSize,
      showLabels: !state.showLabels,
    );
  }
}
