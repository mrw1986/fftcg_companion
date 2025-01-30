// lib/features/cards/presentation/providers/view_preferences_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'view_preferences_provider.g.dart';

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

@riverpod
class ViewPreferences extends _$ViewPreferences {
  static const _viewTypeKey = 'view_type';
  static const _gridSizeKey = 'grid_size';
  static const _listSizeKey = 'list_size';
  static const _showLabelsKey = 'show_labels';

  @override
  ({ViewType type, ViewSize gridSize, ViewSize listSize, bool showLabels})
      build() {
    final box = Hive.box('settings');
    return (
      type: _loadViewType(box),
      gridSize: _loadSize(box, _gridSizeKey),
      listSize: _loadSize(box, _listSizeKey),
      showLabels: box.get(_showLabelsKey, defaultValue: true),
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
    final box = Hive.box('settings');
    final newType = state.type == ViewType.grid ? ViewType.list : ViewType.grid;
    await box.put(_viewTypeKey, newType.name);
    state = (
      type: newType,
      gridSize: state.gridSize,
      listSize: state.listSize,
      showLabels: state.showLabels,
    );
  }

  Future<void> setGridSize(ViewSize size) async {
    final box = Hive.box('settings');
    await box.put(_gridSizeKey, size.name);
    state = (
      type: state.type,
      gridSize: size,
      listSize: state.listSize,
      showLabels: state.showLabels,
    );
  }

  Future<void> setListSize(ViewSize size) async {
    final box = Hive.box('settings');
    await box.put(_listSizeKey, size.name);
    state = (
      type: state.type,
      gridSize: state.gridSize,
      listSize: size,
      showLabels: state.showLabels,
    );
  }

  Future<void> toggleLabels() async {
    final box = Hive.box('settings');
    await box.put(_showLabelsKey, !state.showLabels);
    state = (
      type: state.type,
      gridSize: state.gridSize,
      listSize: state.listSize,
      showLabels: !state.showLabels,
    );
  }
}
