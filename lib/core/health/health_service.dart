import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/models/workout_session.dart';

abstract class HealthService {
  Future<bool> requestAuthorization();

  Future<bool> writeWorkout(WorkoutSession session);

  Future<int?> readLatestHeartRate();
}

class HealthServiceFactory {
  static Future<HealthService> create() async {
    if (kIsWeb) {
      return const _NoopHealthService();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return MethodChannelHealthService();
      default:
        return const _NoopHealthService();
    }
  }
}

class MethodChannelHealthService implements HealthService {
  MethodChannelHealthService()
      : _channel =
            const MethodChannel('com.hartvig_solutions.tread_runner/health');

  final MethodChannel _channel;

  @override
  Future<bool> requestAuthorization() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint('Health authorization failed: $error\n$stackTrace');
      return false;
    }
  }

  @override
  Future<bool> writeWorkout(WorkoutSession session) async {
    try {
      final payload = {
        'id': session.id,
        'planId': session.planId,
        'startedAt': session.startedAt.millisecondsSinceEpoch,
        'endedAt': session.endedAt?.millisecondsSinceEpoch,
        'distanceMeters': session.metrics.isNotEmpty
            ? session.metrics.last.distanceMeters
            : null,
      };
      final result = await _channel.invokeMethod<bool>(
        'writeWorkout',
        payload,
      );
      return result ?? false;
    } catch (error, stackTrace) {
      debugPrint('Health writeWorkout failed: $error\n$stackTrace');
      return false;
    }
  }

  @override
  Future<int?> readLatestHeartRate() async {
    try {
      final result =
          await _channel.invokeMethod<int?>('readLatestHeartRate');
      return result;
    } catch (error, stackTrace) {
      debugPrint('Health readLatestHeartRate failed: $error\n$stackTrace');
      return null;
    }
  }
}

class _NoopHealthService implements HealthService {
  const _NoopHealthService();

  @override
  Future<int?> readLatestHeartRate() async => null;

  @override
  Future<bool> requestAuthorization() async => false;

  @override
  Future<bool> writeWorkout(WorkoutSession session) async => false;
}
