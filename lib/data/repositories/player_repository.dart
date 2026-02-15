import 'package:isar/isar.dart';

import '../isar/models/player.dart';

class PlayerRepository {
  PlayerRepository(this._isar);

  final Isar _isar;

  Future<List<Player>> getAll() async {
    return _isar.players.where().sortByCreatedAt().findAll();
  }

  Stream<List<Player>> watchAll() {
    return _isar.players.where().sortByCreatedAt().watch(fireImmediately: true);
  }

  Future<Player?> getByUuid(String uuid) async {
    return _isar.players.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<Id> add(Player player) => _isar.writeTxn(() async {
        final existing = await _isar.players
            .filter()
            .uuidEqualTo(player.uuid)
            .findFirst();
        if (existing != null) {
          player.id = existing.id;
        }
        return _isar.players.put(player);
      });

  Future<void> update(Player player) => _isar.writeTxn(() async {
        if (player.id == Isar.autoIncrement) {
          final existing = await _isar.players
              .filter()
              .uuidEqualTo(player.uuid)
              .findFirst();
          if (existing != null) {
            player.id = existing.id;
          }
        }
        await _isar.players.put(player);
      });

  Future<bool> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final p = await _isar.players.filter().uuidEqualTo(uuid).findFirst();
        if (p == null) return false;
        await _isar.players.delete(p.id);
        return true;
      });

  Future<List<Player>> getByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];
    final list = <Player>[];
    for (final uuid in uuids) {
      final p = await getByUuid(uuid);
      if (p != null) list.add(p);
    }
    return list;
  }
}
