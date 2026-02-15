// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGameCollection on Isar {
  IsarCollection<Game> get games => this.collection();
}

const GameSchema = CollectionSchema(
  name: r'Game',
  id: -6261407721091271860,
  properties: {
    r'awardsJson': PropertySchema(
      id: 0,
      name: r'awardsJson',
      type: IsarType.string,
    ),
    r'currentQuarter': PropertySchema(
      id: 1,
      name: r'currentQuarter',
      type: IsarType.long,
    ),
    r'presentPlayerIds': PropertySchema(
      id: 2,
      name: r'presentPlayerIds',
      type: IsarType.stringList,
    ),
    r'quarterLineupsJson': PropertySchema(
      id: 3,
      name: r'quarterLineupsJson',
      type: IsarType.string,
    ),
    r'quartersPlayedJson': PropertySchema(
      id: 4,
      name: r'quartersPlayedJson',
      type: IsarType.string,
    ),
    r'quartersTotal': PropertySchema(
      id: 5,
      name: r'quartersTotal',
      type: IsarType.long,
    ),
    r'startedAt': PropertySchema(
      id: 6,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 7,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _gameEstimateSize,
  serialize: _gameSerialize,
  deserialize: _gameDeserialize,
  deserializeProp: _gameDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _gameGetId,
  getLinks: _gameGetLinks,
  attach: _gameAttach,
  version: '3.1.0+1',
);

int _gameEstimateSize(
  Game object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.awardsJson.length * 3;
  bytesCount += 3 + object.presentPlayerIds.length * 3;
  {
    for (var i = 0; i < object.presentPlayerIds.length; i++) {
      final value = object.presentPlayerIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.quarterLineupsJson.length * 3;
  bytesCount += 3 + object.quartersPlayedJson.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _gameSerialize(
  Game object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.awardsJson);
  writer.writeLong(offsets[1], object.currentQuarter);
  writer.writeStringList(offsets[2], object.presentPlayerIds);
  writer.writeString(offsets[3], object.quarterLineupsJson);
  writer.writeString(offsets[4], object.quartersPlayedJson);
  writer.writeLong(offsets[5], object.quartersTotal);
  writer.writeDateTime(offsets[6], object.startedAt);
  writer.writeString(offsets[7], object.uuid);
}

Game _gameDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Game();
  object.awardsJson = reader.readString(offsets[0]);
  object.currentQuarter = reader.readLong(offsets[1]);
  object.id = id;
  object.presentPlayerIds = reader.readStringList(offsets[2]) ?? [];
  object.quarterLineupsJson = reader.readString(offsets[3]);
  object.quartersPlayedJson = reader.readString(offsets[4]);
  object.quartersTotal = reader.readLong(offsets[5]);
  object.startedAt = reader.readDateTime(offsets[6]);
  object.uuid = reader.readString(offsets[7]);
  return object;
}

P _gameDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gameGetId(Game object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gameGetLinks(Game object) {
  return [];
}

void _gameAttach(IsarCollection<dynamic> col, Id id, Game object) {
  object.id = id;
}

extension GameByIndex on IsarCollection<Game> {
  Future<Game?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Game? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Game?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Game?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(Game object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Game object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Game> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Game> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension GameQueryWhereSort on QueryBuilder<Game, Game, QWhere> {
  QueryBuilder<Game, Game, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GameQueryWhere on QueryBuilder<Game, Game, QWhereClause> {
  QueryBuilder<Game, Game, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterWhereClause> uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GameQueryFilter on QueryBuilder<Game, Game, QFilterCondition> {
  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'awardsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'awardsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'awardsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'awardsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> awardsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'awardsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> currentQuarterEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> currentQuarterGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> currentQuarterLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> currentQuarterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentQuarter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'presentPlayerIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'presentPlayerIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'presentPlayerIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'presentPlayerIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'presentPlayerIds',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> presentPlayerIdsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> presentPlayerIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> presentPlayerIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      presentPlayerIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> presentPlayerIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'presentPlayerIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quarterLineupsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quarterLineupsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quarterLineupsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quarterLineupsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quarterLineupsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      quarterLineupsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quarterLineupsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quartersPlayedJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quartersPlayedJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quartersPlayedJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersPlayedJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quartersPlayedJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition>
      quartersPlayedJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quartersPlayedJson',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersTotalEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quartersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quartersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quartersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> quartersTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quartersTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> startedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Game, Game, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension GameQueryObject on QueryBuilder<Game, Game, QFilterCondition> {}

extension GameQueryLinks on QueryBuilder<Game, Game, QFilterCondition> {}

extension GameQuerySortBy on QueryBuilder<Game, Game, QSortBy> {
  QueryBuilder<Game, Game, QAfterSortBy> sortByAwardsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awardsJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByAwardsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awardsJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByCurrentQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuarter', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByCurrentQuarterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuarter', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuarterLineupsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarterLineupsJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuarterLineupsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarterLineupsJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuartersPlayedJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersPlayedJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuartersPlayedJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersPlayedJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuartersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersTotal', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByQuartersTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersTotal', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension GameQuerySortThenBy on QueryBuilder<Game, Game, QSortThenBy> {
  QueryBuilder<Game, Game, QAfterSortBy> thenByAwardsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awardsJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByAwardsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'awardsJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByCurrentQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuarter', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByCurrentQuarterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuarter', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuarterLineupsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarterLineupsJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuarterLineupsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quarterLineupsJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuartersPlayedJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersPlayedJson', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuartersPlayedJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersPlayedJson', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuartersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersTotal', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByQuartersTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quartersTotal', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Game, Game, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension GameQueryWhereDistinct on QueryBuilder<Game, Game, QDistinct> {
  QueryBuilder<Game, Game, QDistinct> distinctByAwardsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'awardsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByCurrentQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentQuarter');
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByPresentPlayerIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'presentPlayerIds');
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByQuarterLineupsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quarterLineupsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByQuartersPlayedJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quartersPlayedJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByQuartersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quartersTotal');
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<Game, Game, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension GameQueryProperty on QueryBuilder<Game, Game, QQueryProperty> {
  QueryBuilder<Game, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Game, String, QQueryOperations> awardsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'awardsJson');
    });
  }

  QueryBuilder<Game, int, QQueryOperations> currentQuarterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentQuarter');
    });
  }

  QueryBuilder<Game, List<String>, QQueryOperations>
      presentPlayerIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'presentPlayerIds');
    });
  }

  QueryBuilder<Game, String, QQueryOperations> quarterLineupsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quarterLineupsJson');
    });
  }

  QueryBuilder<Game, String, QQueryOperations> quartersPlayedJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quartersPlayedJson');
    });
  }

  QueryBuilder<Game, int, QQueryOperations> quartersTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quartersTotal');
    });
  }

  QueryBuilder<Game, DateTime, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<Game, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
