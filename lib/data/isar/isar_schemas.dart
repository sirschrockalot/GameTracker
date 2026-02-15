import 'package:isar/isar.dart';

import 'models/player.dart';
import 'models/game.dart';

/// List of all Isar collections for [Isar.open].
List<CollectionSchema<dynamic>> get isarSchemas => [
      PlayerSchema,
      GameSchema,
    ];
