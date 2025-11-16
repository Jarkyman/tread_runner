import 'package:flutter_test/flutter_test.dart';
import 'package:tread_runner/domain/models/workout_plan.dart';
import 'package:tread_runner/domain/models/workout_step.dart';
import 'package:tread_runner/features/workout/models/workout_timeline.dart';

void main() {
  group('WorkoutTimeline', () {
    test('creates segments for repeats and distance-based steps', () {
      final plan = WorkoutPlan(
        name: 'Test',
        colorValue: 0,
        initialSteps: [
          WorkoutStep(durationSeconds: 30, targetSpeedKmh: 8),
          WorkoutStep(
            distanceMeters: 400,
            targetSpeedKmh: 12,
            repeatCount: 2,
          ),
        ],
      );

      final timeline = WorkoutTimeline.fromPlan(plan);
      expect(timeline.segments.length, 3);
      expect(timeline.segments[0].duration, const Duration(seconds: 30));
      expect(timeline.segments[1].repeatIndex, 1);
      expect(timeline.segments[1].repeatTotal, 2);
      expect(timeline.segments[2].repeatIndex, 2);
      expect(timeline.segments[2].start, isNot(equals(timeline.segments[1].start)));
    });

    test('currentSegment and segmentProgress respond to elapsed time', () {
      final plan = WorkoutPlan(
        name: 'Intervals',
        colorValue: 0,
        initialSteps: [
          WorkoutStep(durationSeconds: 20),
          WorkoutStep(durationSeconds: 10),
        ],
      );
      final timeline = WorkoutTimeline.fromPlan(plan);

      expect(timeline.currentSegment(const Duration(seconds: 5)),
          timeline.segments[0]);
      expect(timeline.currentSegment(const Duration(seconds: 25)),
          timeline.segments[1]);

      final progress =
          timeline.segmentProgress(0, const Duration(seconds: 10));
      expect(progress, closeTo(0.5, 0.01));
      expect(
        timeline.segmentProgress(1, const Duration(seconds: 25)),
        closeTo(0.5, 0.01),
      );
    });
  });
}
