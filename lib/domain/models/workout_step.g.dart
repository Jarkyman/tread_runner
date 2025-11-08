// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_step.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WorkoutStepSchema = Schema(
  name: r'WorkoutStep',
  id: 5106081270822803978,
  properties: {
    r'distanceMeters': PropertySchema(
      id: 0,
      name: r'distanceMeters',
      type: IsarType.double,
    ),
    r'durationSeconds': PropertySchema(
      id: 1,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'inclinePercent': PropertySchema(
      id: 2,
      name: r'inclinePercent',
      type: IsarType.double,
    ),
    r'repeatCount': PropertySchema(
      id: 3,
      name: r'repeatCount',
      type: IsarType.long,
    ),
    r'targetSpeedKmh': PropertySchema(
      id: 4,
      name: r'targetSpeedKmh',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 5,
      name: r'type',
      type: IsarType.string,
      enumMap: _WorkoutSteptypeEnumValueMap,
    )
  },
  estimateSize: _workoutStepEstimateSize,
  serialize: _workoutStepSerialize,
  deserialize: _workoutStepDeserialize,
  deserializeProp: _workoutStepDeserializeProp,
);

int _workoutStepEstimateSize(
  WorkoutStep object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _workoutStepSerialize(
  WorkoutStep object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.distanceMeters);
  writer.writeLong(offsets[1], object.durationSeconds);
  writer.writeDouble(offsets[2], object.inclinePercent);
  writer.writeLong(offsets[3], object.repeatCount);
  writer.writeDouble(offsets[4], object.targetSpeedKmh);
  writer.writeString(offsets[5], object.type.name);
}

WorkoutStep _workoutStepDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutStep(
    distanceMeters: reader.readDoubleOrNull(offsets[0]),
    durationSeconds: reader.readLongOrNull(offsets[1]),
    inclinePercent: reader.readDoubleOrNull(offsets[2]),
    repeatCount: reader.readLongOrNull(offsets[3]),
    targetSpeedKmh: reader.readDoubleOrNull(offsets[4]),
    type: _WorkoutSteptypeValueEnumMap[reader.readStringOrNull(offsets[5])] ??
        WorkoutStepType.run,
  );
  return object;
}

P _workoutStepDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (_WorkoutSteptypeValueEnumMap[reader.readStringOrNull(offset)] ??
          WorkoutStepType.run) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _WorkoutSteptypeEnumValueMap = {
  r'warmup': r'warmup',
  r'run': r'run',
  r'recovery': r'recovery',
  r'cooldown': r'cooldown',
  r'hill': r'hill',
};
const _WorkoutSteptypeValueEnumMap = {
  r'warmup': WorkoutStepType.warmup,
  r'run': WorkoutStepType.run,
  r'recovery': WorkoutStepType.recovery,
  r'cooldown': WorkoutStepType.cooldown,
  r'hill': WorkoutStepType.hill,
};

extension WorkoutStepQueryFilter
    on QueryBuilder<WorkoutStep, WorkoutStep, QFilterCondition> {
  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceMeters',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceMeters',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceMeters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceMeters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceMeters',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      distanceMetersBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceMeters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationSeconds',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      durationSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inclinePercent',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inclinePercent',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inclinePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inclinePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inclinePercent',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      inclinePercentBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inclinePercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'repeatCount',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'repeatCount',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      repeatCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetSpeedKmh',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetSpeedKmh',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetSpeedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetSpeedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetSpeedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      targetSpeedKmhBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetSpeedKmh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeEqualTo(
    WorkoutStepType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeGreaterThan(
    WorkoutStepType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeLessThan(
    WorkoutStepType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeBetween(
    WorkoutStepType lower,
    WorkoutStepType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkoutStep, WorkoutStep, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension WorkoutStepQueryObject
    on QueryBuilder<WorkoutStep, WorkoutStep, QFilterCondition> {}
