import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'navigation_provider.dart';

part 'home_provider.g.dart';

/// Provider to toggle search mode in Home screen
final homeSearchActiveProvider = StateProvider<bool>((ref) => false);

@riverpod
class HomeSearchQuery extends _$HomeSearchQuery {
  @override
  String build() {
    // 🔍 Listen to navigation changes to clear search
    ref.listen(navigationProvider, (previous, next) {
      if (next != 0) {
        state = '';
      }
    });
    return '';
  }

  void update(String query) => state = query;
  void clear() => state = '';
}
