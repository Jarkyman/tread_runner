import 'dart:math';

import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_step.dart';

class WorkoutTimeline {
  WorkoutTimeline(this.segments);

  factory WorkoutTimeline.fromPlan(WorkoutPlan plan) {
    final segments = <WorkoutTimelineSegment>[];
    var cursor = Duration.zero;
    for (final step in plan.steps) {
      final repeats = max(1, step.repeatCount ?? 1);
      for (var i = 0; i < repeats; i++) {
        final duration = estimateWorkoutStepDuration(step);
        segments.add(
          WorkoutTimelineSegment(
            step: step,
            start: cursor,
            end: cursor + duration,
            repeatIndex: i + 1,
            repeatTotal: repeats,
          ),
        );
        cursor += duration;
      }
    }
    return WorkoutTimeline(segments);
  }

  final List<WorkoutTimelineSegment> segments;

  WorkoutTimelineSegment? currentSegment(Duration elapsed) {
    for (final segment in segments) {
      if (elapsed < segment.end) {
        return segment;
      }
    }
    return segments.isEmpty ? null : segments.last;
  }

  double segmentProgress(int index, Duration elapsed) {
    if (index >= segments.length) return 0;
    final segment = segments[index];
    if (elapsed >= segment.end) return 1;
    if (elapsed <= segment.start) return 0;
    final total = segment.duration.inMilliseconds;
    if (total == 0) return 0;
    final elapsedMs = elapsed.inMilliseconds - segment.start.inMilliseconds;
    return (elapsedMs / total).clamp(0, 1);
  }
}

class WorkoutTimelineSegment {
  WorkoutTimelineSegment({
    required this.step,
    required this.start,
    required this.end,
    required this.repeatIndex,
    required this.repeatTotal,
  });

  final WorkoutStep step;
  final Duration start;
  final Duration end;
  final int repeatIndex;
  final int repeatTotal;

  Duration get duration => end - start;
}

Duration estimateWorkoutStepDuration(WorkoutStep step) {
  if (step.durationSeconds != null && step.durationSeconds! > 0) {
    return Duration(seconds: step.durationSeconds!);
  }
  if (step.distanceMeters != null && step.targetSpeedKmh != null) {
    final metersPerSecond = (step.targetSpeedKmh! * 1000) / 3600;
    if (metersPerSecond > 0) {
      return Duration(
        seconds: max(1, (step.distanceMeters! / metersPerSecond).round()),
      );
    }
  }
  return const Duration(minutes: 1);
}
