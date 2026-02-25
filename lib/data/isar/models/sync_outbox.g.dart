// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_outbox.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncOutboxItemCollection on Isar {
  IsarCollection<SyncOutboxItem> get syncOutboxItems => this.collection();
}

const SyncOutboxItemSchema = CollectionSchema(
  name: r'SyncOutboxItem',
  id: 822672468217682389,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'entityType': PropertySchema(
      id: 1,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'lastError': PropertySchema(
      id: 2,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastTriedAt': PropertySchema(
      id: 3,
      name: r'lastTriedAt',
      type: IsarType.dateTime,
    ),
    r'op': PropertySchema(
      id: 4,
      name: r'op',
      type: IsarType.string,
    ),
    r'payloadJson': PropertySchema(
      id: 5,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 6,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'teamId': PropertySchema(
      id: 7,
      name: r'teamId',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 8,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _syncOutboxItemEstimateSize,
  serialize: _syncOutboxItemSerialize,
  deserialize: _syncOutboxItemDeserialize,
  deserializeProp: _syncOutboxItemDeserializeProp,
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
  getId: _syncOutboxItemGetId,
  getLinks: _syncOutboxItemGetLinks,
  attach: _syncOutboxItemAttach,
  version: '3.1.0+1',
);

int _syncOutboxItemEstimateSize(
  SyncOutboxItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityType.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.op.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  bytesCount += 3 + object.teamId.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _syncOutboxItemSerialize(
  SyncOutboxItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.entityType);
  writer.writeString(offsets[2], object.lastError);
  writer.writeDateTime(offsets[3], object.lastTriedAt);
  writer.writeString(offsets[4], object.op);
  writer.writeString(offsets[5], object.payloadJson);
  writer.writeLong(offsets[6], object.retryCount);
  writer.writeString(offsets[7], object.teamId);
  writer.writeString(offsets[8], object.uuid);
}

SyncOutboxItem _syncOutboxItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncOutboxItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.entityType = reader.readString(offsets[1]);
  object.id = id;
  object.lastError = reader.readStringOrNull(offsets[2]);
  object.lastTriedAt = reader.readDateTimeOrNull(offsets[3]);
  object.op = reader.readString(offsets[4]);
  object.payloadJson = reader.readString(offsets[5]);
  object.retryCount = reader.readLong(offsets[6]);
  object.teamId = reader.readString(offsets[7]);
  object.uuid = reader.readString(offsets[8]);
  return object;
}

P _syncOutboxItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncOutboxItemGetId(SyncOutboxItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncOutboxItemGetLinks(SyncOutboxItem object) {
  return [];
}

void _syncOutboxItemAttach(
    IsarCollection<dynamic> col, Id id, SyncOutboxItem object) {
  object.id = id;
}

extension SyncOutboxItemByIndex on IsarCollection<SyncOutboxItem> {
  Future<SyncOutboxItem?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  SyncOutboxItem? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<SyncOutboxItem?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<SyncOutboxItem?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(SyncOutboxItem object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(SyncOutboxItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<SyncOutboxItem> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<SyncOutboxItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension SyncOutboxItemQueryWhereSort
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QWhere> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncOutboxItemQueryWhere
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QWhereClause> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
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

extension SyncOutboxItemQueryFilter
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QFilterCondition> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'entityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'entityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'entityType',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTriedAt',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTriedAt',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTriedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTriedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTriedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      lastTriedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTriedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition> opEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition> opBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'op',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'op',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition> opMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'op',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'op',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      opIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'op',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadJson',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'teamId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'teamId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'teamId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teamId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      teamIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'teamId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidEqualTo(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidGreaterThan(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidLessThan(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidBetween(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidStartsWith(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidEndsWith(
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

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension SyncOutboxItemQueryObject
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QFilterCondition> {}

extension SyncOutboxItemQueryLinks
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QFilterCondition> {}

extension SyncOutboxItemQuerySortBy
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QSortBy> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByLastTriedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByLastTriedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByOp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByOpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByTeamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamId', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      sortByTeamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamId', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension SyncOutboxItemQuerySortThenBy
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QSortThenBy> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByLastTriedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByLastTriedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTriedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByOp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByOpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'op', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByTeamId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamId', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy>
      thenByTeamIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teamId', Sort.desc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension SyncOutboxItemQueryWhereDistinct
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> {
  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByEntityType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByLastError(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct>
      distinctByLastTriedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTriedAt');
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByOp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'op', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByPayloadJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct>
      distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByTeamId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teamId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncOutboxItem, SyncOutboxItem, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension SyncOutboxItemQueryProperty
    on QueryBuilder<SyncOutboxItem, SyncOutboxItem, QQueryProperty> {
  QueryBuilder<SyncOutboxItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncOutboxItem, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SyncOutboxItem, String, QQueryOperations> entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<SyncOutboxItem, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<SyncOutboxItem, DateTime?, QQueryOperations>
      lastTriedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTriedAt');
    });
  }

  QueryBuilder<SyncOutboxItem, String, QQueryOperations> opProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'op');
    });
  }

  QueryBuilder<SyncOutboxItem, String, QQueryOperations> payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<SyncOutboxItem, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<SyncOutboxItem, String, QQueryOperations> teamIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teamId');
    });
  }

  QueryBuilder<SyncOutboxItem, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
