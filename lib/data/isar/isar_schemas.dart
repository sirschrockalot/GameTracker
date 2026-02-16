import 'package:isar/isar.dart';

import 'models/player.dart';
import 'models/game.dart';
import 'models/team.dart';
import 'models/join_request.dart';
import 'models/schedule_event.dart';

/// List of all Isar collections for [Isar.open].
List<CollectionSchema<dynamic>> get isarSchemas => [
      PlayerSchema,
      GameSchema,
      TeamSchema,
      JoinRequestSchema,
      ScheduleEventSchema,
    ];
