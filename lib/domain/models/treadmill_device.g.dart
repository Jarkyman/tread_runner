// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treadmill_device.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTreadmillDeviceCollection on Isar {
  IsarCollection<TreadmillDevice> get treadmillDevices => this.collection();
}

const TreadmillDeviceSchema = CollectionSchema(
  name: r'TreadmillDevice',
  id: 7156216132445446953,
  properties: {
    r'connectionState': PropertySchema(
      id: 0,
      name: r'connectionState',
      type: IsarType.string,
      enumMap: _TreadmillDeviceconnectionStateEnumValueMap,
    ),
    r'deviceId': PropertySchema(
      id: 1,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'supportsHeartRate': PropertySchema(
      id: 3,
      name: r'supportsHeartRate',
      type: IsarType.bool,
    ),
    r'supportsIncline': PropertySchema(
      id: 4,
      name: r'supportsIncline',
      type: IsarType.bool,
    ),
    r'supportsSpeed': PropertySchema(
      id: 5,
      name: r'supportsSpeed',
      type: IsarType.bool,
    )
  },
  estimateSize: _treadmillDeviceEstimateSize,
  serialize: _treadmillDeviceSerialize,
  deserialize: _treadmillDeviceDeserialize,
  deserializeProp: _treadmillDeviceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _treadmillDeviceGetId,
  getLinks: _treadmillDeviceGetLinks,
  attach: _treadmillDeviceAttach,
  version: '3.1.0+1',
);

int _treadmillDeviceEstimateSize(
  TreadmillDevice object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.connectionState.name.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _treadmillDeviceSerialize(
  TreadmillDevice object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.connectionState.name);
  writer.writeString(offsets[1], object.deviceId);
  writer.writeString(offsets[2], object.name);
  writer.writeBool(offsets[3], object.supportsHeartRate);
  writer.writeBool(offsets[4], object.supportsIncline);
  writer.writeBool(offsets[5], object.supportsSpeed);
}

TreadmillDevice _treadmillDeviceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TreadmillDevice(
    connectionState: _TreadmillDeviceconnectionStateValueEnumMap[
            reader.readStringOrNull(offsets[0])] ??
        TreadmillConnectionState.disconnected,
    deviceId: reader.readString(offsets[1]),
    id: id,
    name: reader.readString(offsets[2]),
    supportsHeartRate: reader.readBoolOrNull(offsets[3]) ?? false,
    supportsIncline: reader.readBoolOrNull(offsets[4]) ?? false,
    supportsSpeed: reader.readBoolOrNull(offsets[5]) ?? true,
  );
  return object;
}

P _treadmillDeviceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_TreadmillDeviceconnectionStateValueEnumMap[
              reader.readStringOrNull(offset)] ??
          TreadmillConnectionState.disconnected) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TreadmillDeviceconnectionStateEnumValueMap = {
  r'disconnected': r'disconnected',
  r'scanning': r'scanning',
  r'connecting': r'connecting',
  r'connected': r'connected',
  r'error': r'error',
};
const _TreadmillDeviceconnectionStateValueEnumMap = {
  r'disconnected': TreadmillConnectionState.disconnected,
  r'scanning': TreadmillConnectionState.scanning,
  r'connecting': TreadmillConnectionState.connecting,
  r'connected': TreadmillConnectionState.connected,
  r'error': TreadmillConnectionState.error,
};

Id _treadmillDeviceGetId(TreadmillDevice object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _treadmillDeviceGetLinks(TreadmillDevice object) {
  return [];
}

void _treadmillDeviceAttach(
    IsarCollection<dynamic> col, Id id, TreadmillDevice object) {
  object.id = id;
}

extension TreadmillDeviceQueryWhereSort
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QWhere> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TreadmillDeviceQueryWhere
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QWhereClause> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterWhereClause> idBetween(
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
}

extension TreadmillDeviceQueryFilter
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QFilterCondition> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateEqualTo(
    TreadmillConnectionState value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateGreaterThan(
    TreadmillConnectionState value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateLessThan(
    TreadmillConnectionState value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateBetween(
    TreadmillConnectionState lower,
    TreadmillConnectionState upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'connectionState',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'connectionState',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'connectionState',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'connectionState',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      connectionStateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'connectionState',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
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

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
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

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      supportsHeartRateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportsHeartRate',
        value: value,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      supportsInclineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportsIncline',
        value: value,
      ));
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterFilterCondition>
      supportsSpeedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportsSpeed',
        value: value,
      ));
    });
  }
}

extension TreadmillDeviceQueryObject
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QFilterCondition> {}

extension TreadmillDeviceQueryLinks
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QFilterCondition> {}

extension TreadmillDeviceQuerySortBy
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QSortBy> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortByConnectionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionState', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortByConnectionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionState', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsHeartRate', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsHeartRate', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsIncline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsIncline', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsInclineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsIncline', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsSpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsSpeed', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      sortBySupportsSpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsSpeed', Sort.desc);
    });
  }
}

extension TreadmillDeviceQuerySortThenBy
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QSortThenBy> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenByConnectionState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionState', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenByConnectionStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectionState', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsHeartRate', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsHeartRate', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsIncline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsIncline', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsInclineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsIncline', Sort.desc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsSpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsSpeed', Sort.asc);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QAfterSortBy>
      thenBySupportsSpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsSpeed', Sort.desc);
    });
  }
}

extension TreadmillDeviceQueryWhereDistinct
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct> {
  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct>
      distinctByConnectionState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectionState',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct>
      distinctBySupportsHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportsHeartRate');
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct>
      distinctBySupportsIncline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportsIncline');
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillDevice, QDistinct>
      distinctBySupportsSpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportsSpeed');
    });
  }
}

extension TreadmillDeviceQueryProperty
    on QueryBuilder<TreadmillDevice, TreadmillDevice, QQueryProperty> {
  QueryBuilder<TreadmillDevice, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TreadmillDevice, TreadmillConnectionState, QQueryOperations>
      connectionStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectionState');
    });
  }

  QueryBuilder<TreadmillDevice, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<TreadmillDevice, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<TreadmillDevice, bool, QQueryOperations>
      supportsHeartRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportsHeartRate');
    });
  }

  QueryBuilder<TreadmillDevice, bool, QQueryOperations>
      supportsInclineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportsIncline');
    });
  }

  QueryBuilder<TreadmillDevice, bool, QQueryOperations>
      supportsSpeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportsSpeed');
    });
  }
}
