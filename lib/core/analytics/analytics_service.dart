import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract class AnalyticsService {
  Future<void> setUserConsent(bool enabled);

  Future<void> logScreenView(String name);

  Future<void> logWorkoutStarted({String? programId});

  Future<void> logWorkoutCompleted({
    Duration? duration,
    double? distanceKm,
  });

  Future<void> logDeviceConnected({String? vendor});
}

class AnalyticsServiceFactory {
  static Future<AnalyticsService> create(bool initialConsent) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final firebaseAnalytics = FirebaseAnalytics.instance;
      final service = FirebaseAnalyticsService(firebaseAnalytics);
      await service.setUserConsent(initialConsent);
      return service;
    } catch (error, stackTrace) {
      debugPrint(
        'Firebase Analytics initialization failed: $error\n$stackTrace',
      );
      final noopService = NoopAnalyticsService();
      await noopService.setUserConsent(initialConsent);
      return noopService;
    }
  }
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;
  bool _collectionEnabled = false;

  @override
  Future<void> setUserConsent(bool enabled) async {
    _collectionEnabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logDeviceConnected({String? vendor}) async {
    if (!_collectionEnabled) return;
    await _analytics.logEvent(
      name: 'device_connected',
      parameters: {
        if (vendor != null) 'vendor': vendor,
      },
    );
  }

  @override
  Future<void> logScreenView(String name) async {
    if (!_collectionEnabled) return;
    await _analytics.logScreenView(screenName: name);
  }

  @override
  Future<void> logWorkoutCompleted({
    Duration? duration,
    double? distanceKm,
  }) async {
    if (!_collectionEnabled) return;
    await _analytics.logEvent(
      name: 'workout_completed',
      parameters: {
        if (duration != null) 'duration_seconds': duration.inSeconds,
        if (distanceKm != null) 'distance_km': distanceKm,
      },
    );
  }

  @override
  Future<void> logWorkoutStarted({String? programId}) async {
    if (!_collectionEnabled) return;
    await _analytics.logEvent(
      name: 'workout_started',
      parameters: {
        if (programId != null) 'program_id': programId,
      },
    );
  }
}

class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> logDeviceConnected({String? vendor}) async {}

  @override
  Future<void> logScreenView(String name) async {}

  @override
  Future<void> logWorkoutCompleted({
    Duration? duration,
    double? distanceKm,
  }) async {}

  @override
  Future<void> logWorkoutStarted({String? programId}) async {}

  @override
  Future<void> setUserConsent(bool enabled) async {}
}
