import 'package:isar/isar.dart';

import 'models/player.dart';
import 'models/game.dart';
import 'models/team.dart';

/// List of all Isar collections for [Isar.open].
List<CollectionSchema<dynamic>> get isarSchemas => [
      PlayerSchema,
      GameSchema,
      TeamSchema,
    ];
