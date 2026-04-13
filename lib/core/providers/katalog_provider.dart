import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'katalog_provider.g.dart';

/// Tracks the active tab in KatalogScreen (0: Barang, 1: Jasa, 2: Mobil)
@riverpod
class KatalogActiveTab extends _$KatalogActiveTab {
  @override
  int build() => 0;

  void set(int index) => state = index;
}
