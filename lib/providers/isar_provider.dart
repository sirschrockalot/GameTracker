import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/isar/isar_schemas.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    isarSchemas,
    directory: dir.path,
    name: 'upward_lineup',
  );
  ref.onDispose(() => isar.close());
  return isar;
});
