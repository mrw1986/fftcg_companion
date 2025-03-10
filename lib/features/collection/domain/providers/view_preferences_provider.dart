import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'view_preferences_provider.g.dart';

/// View type enum (grid or list)
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

/// View size enum (small, normal, large)
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

/// Collection view preferences state
class CollectionViewPreferencesState {
  final ViewType type;
  final ViewSize gridSize;
  final ViewSize listSize;
  final bool showLabels;

  const CollectionViewPreferencesState({
    required this.type,
    required this.gridSize,
    required this.listSize,
    required this.showLabels,
  });

  CollectionViewPreferencesState copyWith({
    ViewType? type,
    ViewSize? gridSize,
    ViewSize? listSize,
    bool? showLabels,
  }) {
    return CollectionViewPreferencesState(
      type: type ?? this.type,
      gridSize: gridSize ?? this.gridSize,
      listSize: listSize ?? this.listSize,
      showLabels: showLabels ?? this.showLabels,
    );
  }
}

/// Provider for collection view preferences
@riverpod
class CollectionViewPreferences extends _$CollectionViewPreferences {
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
  CollectionViewPreferencesState build() {
    final box = _getBox();
    if (box == null) {
      return const CollectionViewPreferencesState(
        type: ViewType.grid,
        gridSize: ViewSize.normal,
        listSize: ViewSize.normal,
        showLabels: true,
      );
    }

    final viewType = _loadViewType(box);
    final gridSize = _loadSize(box, _gridSizeKey);
    final listSize = _loadSize(box, _listSizeKey);
    final showLabels = box.get(_showLabelsKey, defaultValue: true) as bool;

    return CollectionViewPreferencesState(
      type: viewType,
      gridSize: gridSize,
      listSize: listSize,
      showLabels: showLabels,
    );
  }

  ViewType _loadViewType(Box box) {
    final saved = box.get(_viewTypeKey, defaultValue: ViewType.grid.name);
    return ViewType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewType.grid,
    );
  }

  ViewSize _loadSize(Box box, String key) {
    final saved = box.get(key, defaultValue: ViewSize.normal.name);
    return ViewSize.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewSize.normal,
    );
  }

  Future<void> toggleViewType() async {
    final box = await _openBox();
    final newType = state.type == ViewType.grid ? ViewType.list : ViewType.grid;
    await box.put(_viewTypeKey, newType.name);
    state = state.copyWith(type: newType);
  }

  Future<void> cycleGridSize() async {
    final box = await _openBox();
    final newSize = state.gridSize.next;
    await box.put(_gridSizeKey, newSize.name);
    state = state.copyWith(gridSize: newSize);
  }

  Future<void> cycleListSize() async {
    final box = await _openBox();
    final newSize = state.listSize.next;
    await box.put(_listSizeKey, newSize.name);
    state = state.copyWith(listSize: newSize);
  }

  Future<void> toggleLabels() async {
    final box = await _openBox();
    final newShowLabels = !state.showLabels;
    await box.put(_showLabelsKey, newShowLabels);
    state = state.copyWith(showLabels: newShowLabels);
  }
}
