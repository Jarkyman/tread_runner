import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'core/analytics/analytics_consent_cubit.dart';
import 'core/analytics/analytics_service.dart';
import 'core/app/app_status_cubit.dart';
import 'core/ble/connection_cubit.dart';
import 'core/ble/ftms_treadmill_service.dart';
import 'core/ble/mock_treadmill_service.dart';
import 'core/ble/treadmill_service.dart';
import 'core/database/app_database.dart';
import 'core/health/health_service.dart';
import 'core/permissions/ble_permission_handler.dart';
import 'core/preferences/user_preferences_repository.dart';
import 'data/device/device_repository.dart';
import 'data/programs/programs_repository.dart';
import 'data/workout_history/workout_history_repository.dart';
import 'features/dashboard/cubit/dashboard_cubit.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/pre_workout/bloc/pre_workout_cubit.dart';
import 'features/pre_workout/presentation/pre_workout_screen.dart';
import 'features/programs/bloc/programs_bloc.dart';
import 'features/programs/presentation/create_program_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/workout/bloc/workout_bloc.dart';
import 'features/workout/presentation/workout_screen.dart';
import 'features/workout_summary/cubit/workout_summary_cubit.dart';
import 'features/workout_summary/presentation/workout_summary_screen.dart';

const bool _forceMockTreadmillService = bool.fromEnvironment(
  'USE_MOCK_TREADMILL',
  defaultValue: false,
);
const bool _forceRealTreadmillService = bool.fromEnvironment(
  'USE_REAL_TREADMILL',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final useMockTreadmillService = _forceRealTreadmillService
      ? false
      : _forceMockTreadmillService;
  final preferencesRepository =
      await SharedPreferencesUserPreferencesRepository.create();
  final initialConsent = await preferencesRepository.getShareUsageData();
  final analyticsService = await AnalyticsServiceFactory.create(initialConsent);
  final database = await AppDatabase.open();
  final programsRepository = ProgramsRepository(database.isar);
  await programsRepository.seedDefaultsIfNeeded();
  final workoutHistoryRepository = WorkoutHistoryRepository(database.isar);
  final deviceRepository = DeviceRepository(database.isar);
  final healthService = await HealthServiceFactory.create();
  final treadmillService = useMockTreadmillService
      ? MockTreadmillService()
      : FtmsTreadmillService(FlutterReactiveBle());
  final blePermissionHandler = BlePermissionHandler(
    skipPlatformPermissions: useMockTreadmillService,
  );
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
        RepositoryProvider<ProgramsRepository>.value(value: programsRepository),
        RepositoryProvider<WorkoutHistoryRepository>.value(
          value: workoutHistoryRepository,
        ),
        RepositoryProvider<DeviceRepository>.value(value: deviceRepository),
        RepositoryProvider<HealthService>.value(value: healthService),
        RepositoryProvider<TreadmillService>.value(value: treadmillService),
        RepositoryProvider<BlePermissionHandler>.value(
          value: blePermissionHandler,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AnalyticsConsentCubit>.value(
            value: analyticsConsentCubit,
          ),
          BlocProvider<ConnectionCubit>(
            create: (context) => ConnectionCubit(
              context.read<TreadmillService>(),
              context.read<BlePermissionHandler>(),
            ),
          ),
          BlocProvider<AppStatusCubit>(
            create: (context) => AppStatusCubit(
              connectionCubit: context.read<ConnectionCubit>(),
              isMockMode: useMockTreadmillService,
            ),
          ),
          BlocProvider<ProgramsBloc>(
            create: (context) =>
                ProgramsBloc(context.read<ProgramsRepository>())
                  ..add(const ProgramsSubscriptionRequested()),
          ),
          BlocProvider<PreWorkoutCubit>(
            create: (context) => PreWorkoutCubit(
              programsRepository: context.read<ProgramsRepository>(),
            )..loadInitialPlan(),
          ),
          BlocProvider<DashboardCubit>(
            create: (context) =>
                DashboardCubit(context.read<WorkoutHistoryRepository>()),
          ),
          BlocProvider<WorkoutBloc>(
            create: (context) => WorkoutBloc(
              workoutHistoryRepository: context
                  .read<WorkoutHistoryRepository>(),
              treadmillService: context.read<TreadmillService>(),
            ),
          ),
          BlocProvider<WorkoutSummaryCubit>(
            create: (context) => WorkoutSummaryCubit(
              historyRepository: context.read<WorkoutHistoryRepository>(),
              programsRepository: context.read<ProgramsRepository>(),
            ),
          ),
        ],
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
      builder: (context, child) {
        return BlocListener<AppStatusCubit, AppStatusState>(
          listenWhen: (previous, current) =>
              previous.toastId != current.toastId &&
              current.toastMessage != null,
          listener: (context, state) {
            final message = state.toastMessage;
            if (message == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          child: child,
        );
      },
      routes: {
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        PreWorkoutScreen.routeName: (_) => const PreWorkoutScreen(),
        WorkoutScreen.routeName: (_) => const WorkoutScreen(),
        CreateProgramScreen.routeName: (_) => const CreateProgramScreen(),
        WorkoutSummaryScreen.routeName: (_) => const WorkoutSummaryScreen(),
      },
      home: const DashboardScreen(),
    );
  }
}
