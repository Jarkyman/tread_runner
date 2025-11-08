// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_metric_sample.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WorkoutMetricSampleSchema = Schema(
  name: r'WorkoutMetricSample',
  id: -4360414268972933706,
  properties: {
    r'distanceMeters': PropertySchema(
      id: 0,
      name: r'distanceMeters',
      type: IsarType.double,
    ),
    r'elapsedSeconds': PropertySchema(
      id: 1,
      name: r'elapsedSeconds',
      type: IsarType.long,
    ),
    r'heartRate': PropertySchema(
      id: 2,
      name: r'heartRate',
      type: IsarType.long,
    ),
    r'inclinePercent': PropertySchema(
      id: 3,
      name: r'inclinePercent',
      type: IsarType.double,
    ),
    r'speedKmh': PropertySchema(
      id: 4,
      name: r'speedKmh',
      type: IsarType.double,
    )
  },
  estimateSize: _workoutMetricSampleEstimateSize,
  serialize: _workoutMetricSampleSerialize,
  deserialize: _workoutMetricSampleDeserialize,
  deserializeProp: _workoutMetricSampleDeserializeProp,
);

int _workoutMetricSampleEstimateSize(
  WorkoutMetricSample object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _workoutMetricSampleSerialize(
  WorkoutMetricSample object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.distanceMeters);
  writer.writeLong(offsets[1], object.elapsedSeconds);
  writer.writeLong(offsets[2], object.heartRate);
  writer.writeDouble(offsets[3], object.inclinePercent);
  writer.writeDouble(offsets[4], object.speedKmh);
}

WorkoutMetricSample _workoutMetricSampleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkoutMetricSample(
    distanceMeters: reader.readDoubleOrNull(offsets[0]),
    elapsedSeconds: reader.readLongOrNull(offsets[1]) ?? 0,
    heartRate: reader.readLongOrNull(offsets[2]),
    inclinePercent: reader.readDoubleOrNull(offsets[3]),
    speedKmh: reader.readDoubleOrNull(offsets[4]),
  );
  return object;
}

P _workoutMetricSampleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension WorkoutMetricSampleQueryFilter on QueryBuilder<WorkoutMetricSample,
    WorkoutMetricSample, QFilterCondition> {
  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      distanceMetersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceMeters',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      distanceMetersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceMeters',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      elapsedSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'elapsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      elapsedSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'elapsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      elapsedSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'elapsedSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      elapsedSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'elapsedSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'heartRate',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'heartRate',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'heartRate',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'heartRate',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'heartRate',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      heartRateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'heartRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      inclinePercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inclinePercent',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      inclinePercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inclinePercent',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
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

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'speedKmh',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'speedKmh',
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speedKmh',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WorkoutMetricSample, WorkoutMetricSample, QAfterFilterCondition>
      speedKmhBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speedKmh',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension WorkoutMetricSampleQueryObject on QueryBuilder<WorkoutMetricSample,
    WorkoutMetricSample, QFilterCondition> {}
