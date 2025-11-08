import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'core/analytics/analytics_consent_cubit.dart';
import 'core/analytics/analytics_service.dart';
import 'core/ble/ftms_treadmill_service.dart';
import 'core/ble/mock_treadmill_service.dart';
import 'core/ble/treadmill_service.dart';
import 'core/database/app_database.dart';
import 'core/preferences/user_preferences_repository.dart';
import 'data/device/device_repository.dart';
import 'data/programs/programs_repository.dart';
import 'data/workout_history/workout_history_repository.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

const bool _useMockTreadmillService =
    bool.fromEnvironment('USE_MOCK_TREADMILL', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferencesRepository =
      await SharedPreferencesUserPreferencesRepository.create();
  final initialConsent = await preferencesRepository.getShareUsageData();
  final analyticsService =
      await AnalyticsServiceFactory.create(initialConsent);
  final database = await AppDatabase.open();
  final programsRepository = ProgramsRepository(database.isar);
  await programsRepository.seedDefaultsIfNeeded();
  final workoutHistoryRepository = WorkoutHistoryRepository(database.isar);
  final deviceRepository = DeviceRepository(database.isar);
  final treadmillService = _useMockTreadmillService
      ? MockTreadmillService()
      : FtmsTreadmillService(FlutterReactiveBle());
  final analyticsConsentCubit = AnalyticsConsentCubit(
    preferencesRepository: preferencesRepository,
    analyticsService: analyticsService,
    initialConsent: initialConsent,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnalyticsService>.value(value: analyticsService),
        RepositoryProvider<UserPreferencesRepository>.value(
          value: preferencesRepository,
        ),
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<ProgramsRepository>.value(
          value: programsRepository,
        ),
        RepositoryProvider<WorkoutHistoryRepository>.value(
          value: workoutHistoryRepository,
        ),
        RepositoryProvider<DeviceRepository>.value(
          value: deviceRepository,
        ),
        RepositoryProvider<TreadmillService>.value(
          value: treadmillService,
        ),
      ],
      child: BlocProvider<AnalyticsConsentCubit>.value(
        value: analyticsConsentCubit,
        child: const TreadRunnerApp(),
      ),
    ),
  );
}

class TreadRunnerApp extends StatefulWidget {
  const TreadRunnerApp({super.key});

  @override
  State<TreadRunnerApp> createState() => _TreadRunnerAppState();
}

class _TreadRunnerAppState extends State<TreadRunnerApp> {
  @override
  void dispose() {
    unawaited(context.read<TreadmillService>().dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreadRunner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      routes: {
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      home: const DashboardScreen(),
    );
  }
}
