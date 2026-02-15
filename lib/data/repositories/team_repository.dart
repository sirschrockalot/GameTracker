import 'package:isar/isar.dart';

import '../isar/models/team.dart';

class TeamRepository {
  TeamRepository(this._isar);

  final Isar _isar;

  Future<Team?> getByUuid(String uuid) async {
    return _isar.teams.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<List<Team>> getAll() async {
    return _isar.teams.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Team>> watchAll() {
    return _isar.teams.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Future<String> add(Team team) => _isar.writeTxn(() async {
        final existing = await _isar.teams
            .filter()
            .uuidEqualTo(team.uuid)
            .findFirst();
        if (existing != null) {
          team.id = existing.id;
        }
        await _isar.teams.put(team);
        return team.uuid;
      });

  Future<void> update(Team team) => _isar.writeTxn(() async {
        if (team.id == Isar.autoIncrement) {
          final existing = await _isar.teams
              .filter()
              .uuidEqualTo(team.uuid)
              .findFirst();
          if (existing != null) {
            team.id = existing.id;
          }
        }
        await _isar.teams.put(team);
      });

  Future<bool> deleteByUuid(String uuid) => _isar.writeTxn(() async {
        final t = await _isar.teams.filter().uuidEqualTo(uuid).findFirst();
        if (t == null) return false;
        await _isar.teams.delete(t.id);
        return true;
      });
}
