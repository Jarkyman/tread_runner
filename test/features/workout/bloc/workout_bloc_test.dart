import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tread_runner/core/analytics/analytics_service.dart';
import 'package:tread_runner/core/ble/treadmill_service.dart';
import 'package:tread_runner/core/utils/ticker.dart';
import 'package:tread_runner/data/workout_history/workout_history_repository.dart';
import 'package:tread_runner/domain/models/workout_plan.dart';
import 'package:tread_runner/domain/models/workout_session.dart';
import 'package:tread_runner/domain/models/workout_step.dart';
import 'package:tread_runner/features/workout/bloc/workout_bloc.dart';

class _MockHistoryRepository extends Mock
    implements WorkoutHistoryRepository {}

class _MockTreadmillService extends Mock implements TreadmillService {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _FakeTicker extends Fake implements Ticker {
  @override
  Stream<int> tick({Duration interval = const Duration(seconds: 1)}) {
    return Stream.periodic(
      const Duration(milliseconds: 10),
      (count) => count + 1,
    ).take(50);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      WorkoutSession(
        startedAt: DateTime.fromMillisecondsSinceEpoch(0),
        samples: const [],
      ),
    );
  });

  group('WorkoutBloc step progression', () {
    late WorkoutHistoryRepository historyRepository;
    late TreadmillService treadmillService;
    late AnalyticsService analyticsService;
    late StreamController<TreadmillMetrics> metricsController;

    setUp(() {
      historyRepository = _MockHistoryRepository();
      treadmillService = _MockTreadmillService();
      analyticsService = _MockAnalyticsService();
      metricsController = StreamController<TreadmillMetrics>.broadcast();
      when(() => treadmillService.listenToMetrics())
          .thenAnswer((_) => metricsController.stream);
      when(() => treadmillService.connectionState())
          .thenAnswer((_) => const Stream.empty());
      when(() => treadmillService.scan()).thenAnswer((_) => const Stream.empty());
      when(() => historyRepository.saveSession(any()))
          .thenAnswer((_) async => 1);
      when(
        () => analyticsService.logWorkoutStarted(
          programId: any<String?>(named: 'programId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => analyticsService.logWorkoutCompleted(
          duration: any(named: 'duration'),
          distanceKm: any(named: 'distanceKm'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await metricsController.close();
    });

    test('applies repeat segments and logs analytics', () async {
      when(() => treadmillService.setSpeed(any()))
          .thenAnswer((_) async {});
      when(() => treadmillService.setIncline(any()))
          .thenAnswer((_) async {});

      final plan = WorkoutPlan(
        name: 'Intervals',
        colorValue: 0,
        initialSteps: [
          WorkoutStep(
            durationSeconds: 30,
            targetSpeedKmh: 8,
            inclinePercent: 1,
          ),
          WorkoutStep(
            durationSeconds: 10,
            targetSpeedKmh: 12,
            inclinePercent: 5,
            repeatCount: 2,
          ),
        ],
      );

      final bloc = WorkoutBloc(
        workoutHistoryRepository: historyRepository,
        treadmillService: treadmillService,
        analyticsService: analyticsService,
        ticker: _FakeTicker(),
      );

      bloc.add(
        WorkoutStarted(
          plan: plan,
          initialSpeedKmh: 8,
          initialInclinePercent: 1,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      verify(() => treadmillService.setSpeed(8))
          .called(greaterThanOrEqualTo(1));
      verify(() => treadmillService.setIncline(1))
          .called(greaterThanOrEqualTo(1));
      metricsController.add(
        const TreadmillMetrics(
          elapsed: Duration.zero,
          speedKmh: 8,
          inclinePercent: 1,
          distanceMeters: 0,
          heartRate: 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      metricsController.add(
        const TreadmillMetrics(
          elapsed: Duration(seconds: 45),
          speedKmh: 12,
          inclinePercent: 5,
          distanceMeters: 400,
          heartRate: 0,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => treadmillService.setSpeed(12)).called(1);
      verify(() => treadmillService.setIncline(5)).called(1);

      bloc.add(const WorkoutStopped());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => historyRepository.saveSession(any())).called(1);
      verify(() => analyticsService.logWorkoutCompleted(
            duration: any(named: 'duration'),
            distanceKm: any(named: 'distanceKm'),
          )).called(1);

      await bloc.close();
    });
  });
}
