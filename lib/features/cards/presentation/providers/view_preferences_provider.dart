// lib/features/cards/presentation/providers/view_preferences_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'view_preferences_provider.g.dart';

// Shared enums (can remain here or be moved to a shared location if preferred)
enum ViewType {
  grid,
  list;

  String get icon => switch (this) {
        ViewType.grid => 'grid_view',
        ViewType.list => 'view_list',
      };

  String get label => switch (this) {
        ViewType.grid => 'Grid View',
        ViewType.list => 'List View',
      };
}

enum ViewSize {
  small,
  normal,
  large;

  ViewSize get next => switch (this) {
        ViewSize.small => ViewSize.normal,
        ViewSize.normal => ViewSize.large,
        ViewSize.large => ViewSize.small,
      };

  double get gridPadding => switch (this) {
        ViewSize.small => 4.0,
        ViewSize.normal => 8.0,
        ViewSize.large => 12.0,
      };

  double get gridSpacing => switch (this) {
        ViewSize.small => 4.0,
        ViewSize.normal => 8.0,
        ViewSize.large => 12.0,
      };

  double get listItemHeight => switch (this) {
        ViewSize.small => 64.0,
        ViewSize.normal => 80.0,
        ViewSize.large => 96.0,
      };

  int getColumnCount(double screenWidth) => switch (this) {
        ViewSize.small => screenWidth > 1200
            ? 8
            : screenWidth > 900
                ? 6
                : screenWidth > 600
                    ? 4
                    : 3,
        ViewSize.normal => screenWidth > 1200
            ? 6
            : screenWidth > 900
                ? 4
                : screenWidth > 600
                    ? 3
                    : 2,
        ViewSize.large => screenWidth > 1200
            ? 4
            : screenWidth > 900
                ? 3
                : screenWidth > 600
                    ? 2
                    : 1,
      };
}

// Renamed provider for Cards page preferences
@riverpod
class CardViewPreferences extends _$CardViewPreferences {
  // Use distinct keys for cards preferences
  static const _boxName = 'settings';
  static const _viewTypeKey = 'card_view_type'; // Renamed key
  static const _gridSizeKey = 'card_grid_size'; // Renamed key
  static const _listSizeKey = 'card_list_size'; // Renamed key
  static const _showLabelsKey = 'card_show_labels'; // Renamed key

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
    // Load using the renamed key
    final saved = box?.get(_viewTypeKey, defaultValue: ViewType.grid.name);
    if (saved == null) return ViewType.grid;
    return ViewType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewType.grid,
    );
  }

  ViewSize _loadSize(Box? box, String key) {
    // Load using the specific key passed (e.g., _gridSizeKey, _listSizeKey)
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
    // Save using the renamed key
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
      // Save using the renamed key
      await box.put(_gridSizeKey, newSize.name);
      state = (
        type: state.type,
        gridSize: newSize,
        listSize: state.listSize,
        showLabels: state.showLabels,
      );
    } else {
      final newSize = state.listSize.next;
      // Save using the renamed key
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
    // Save using the renamed key
    await box.put(_showLabelsKey, !state.showLabels);
    state = (
      type: state.type,
      gridSize: state.gridSize,
      listSize: state.listSize,
      showLabels: !state.showLabels,
    );
  }
}
