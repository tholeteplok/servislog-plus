import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'objectbox_provider.dart';
import '../../domain/entities/pelanggan.dart';
import '../../data/repositories/pelanggan_repository.dart';

part 'pelanggan_provider.g.dart';

@riverpod
PelangganRepository pelangganRepository(PelangganRepositoryRef ref) {
  final db = ref.watch(dbProvider);
  return PelangganRepository(db.store.box<Pelanggan>());
}

@riverpod
class PelangganList extends _$PelangganList {
  @override
  List<Pelanggan> build() {
    final repository = ref.watch(pelangganRepositoryProvider);
    return repository.getAll();
  }

  void load() {
    final repository = ref.read(pelangganRepositoryProvider);
    state = repository.getAll();
  }

  void add(Pelanggan pelanggan) {
    final repository = ref.read(pelangganRepositoryProvider);
    repository.save(pelanggan);
    load();
  }

  void remove(int id) {
    final repository = ref.read(pelangganRepositoryProvider);
    // LGK-08 FIX: Gunakan softDelete agar konsisten dengan Transaction dan Sale.
    // Hard delete (repository.remove) merusak relasi di Firestore jika Pelanggan
    // sudah tersinkronisasi ke cloud — data cloud jadi orphan (relasi rusak).
    repository.softDelete(id);
    load();
  }

  void updateSearch(String query) {
    final repository = ref.read(pelangganRepositoryProvider);
    if (query.isEmpty) {
      load();
    } else {
      state = repository.search(query);
    }
  }

  void updateItem(Pelanggan p) {
    final repository = ref.read(pelangganRepositoryProvider);
    repository.save(p);
    load();
  }

  void updatePhoto(int id, String? path) {
    final repository = ref.read(pelangganRepositoryProvider);
    final p = repository.getAll().firstWhere((element) => element.id == id);
    p.photoLocalPath = path;
    repository.save(p);
    load();
  }

  void addItem(Pelanggan p) => add(p);
}
