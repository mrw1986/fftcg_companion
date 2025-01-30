// lib/features/cards/presentation/providers/view_size_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'view_size_provider.g.dart';

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

@Riverpod(keepAlive: true)
class ViewSizeController extends _$ViewSizeController {
  static const _viewSizeKey = 'view_size';

  @override
  ViewSize build() {
    final box = Hive.box('settings');
    final saved = box.get(_viewSizeKey, defaultValue: ViewSize.normal.name);
    return ViewSize.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ViewSize.normal,
    );
  }

  Future<void> setViewSize(ViewSize size) async {
    final box = Hive.box('settings');
    await box.put(_viewSizeKey, size.name);
    state = size;
  }
}
