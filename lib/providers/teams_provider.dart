import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/models/team.dart';
import '../data/repositories/team_repository.dart';
import 'isar_provider.dart';

final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) return Stream.value([]);
  return TeamRepository(isar).watchAll();
});
