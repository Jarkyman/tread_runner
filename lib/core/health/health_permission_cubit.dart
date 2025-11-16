import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../preferences/user_preferences_repository.dart';
import 'health_service.dart';

enum HealthPermissionStatus { unknown, granted, denied, unsupported }

class HealthPermissionState extends Equatable {
  const HealthPermissionState({
    required this.status,
    required this.hasRequested,
    required this.isRequestInProgress,
    required this.supportsPermissions,
  });

  final HealthPermissionStatus status;
  final bool hasRequested;
  final bool isRequestInProgress;
  final bool supportsPermissions;

  HealthPermissionState copyWith({
    HealthPermissionStatus? status,
    bool? hasRequested,
    bool? isRequestInProgress,
    bool? supportsPermissions,
  }) {
    return HealthPermissionState(
      status: status ?? this.status,
      hasRequested: hasRequested ?? this.hasRequested,
      isRequestInProgress: isRequestInProgress ?? this.isRequestInProgress,
      supportsPermissions: supportsPermissions ?? this.supportsPermissions,
    );
  }

  bool get shouldShowFallback =>
      supportsPermissions &&
      hasRequested &&
      status == HealthPermissionStatus.denied;

  @override
  List<Object?> get props => [
        status,
        hasRequested,
        isRequestInProgress,
        supportsPermissions,
      ];
}

class HealthPermissionCubit extends Cubit<HealthPermissionState> {
  HealthPermissionCubit({
    required HealthService healthService,
    required UserPreferencesRepository preferencesRepository,
    required bool isMockMode,
  })  : _healthService = healthService,
        _preferencesRepository = preferencesRepository,
        _isMockMode = isMockMode,
        super(
          HealthPermissionState(
            status: HealthPermissionStatus.unknown,
            hasRequested: false,
            isRequestInProgress: false,
            supportsPermissions: healthService.supportsPermissions,
          ),
        ) {
    _initialize();
  }

  final HealthService _healthService;
  final UserPreferencesRepository _preferencesRepository;
  final bool _isMockMode;
  bool _initialized = false;

  Future<void> _initialize() async {
    final hasRequested =
        await _preferencesRepository.getHasRequestedHealthPermissions();
    final granted =
        await _preferencesRepository.getHealthPermissionsGranted();
    if (!_healthService.supportsPermissions || _isMockMode) {
      emit(
        HealthPermissionState(
          status: HealthPermissionStatus.unsupported,
          hasRequested: true,
          isRequestInProgress: false,
          supportsPermissions: false,
        ),
      );
      _initialized = true;
      return;
    }
    emit(
      state.copyWith(
        hasRequested: hasRequested,
        status: granted
            ? HealthPermissionStatus.granted
            : (hasRequested
                ? HealthPermissionStatus.denied
                : HealthPermissionStatus.unknown),
      ),
    );
    _initialized = true;
  }

  Future<void> requestIfNeededOnSync() async {
    if (!_initialized) {
      await _initialize();
    }
    if (!state.supportsPermissions || _isMockMode) return;
    if (state.status == HealthPermissionStatus.granted) return;
    if (!state.hasRequested) {
      await _requestAuthorization();
    }
  }

  Future<void> retryRequest() async {
    if (!state.supportsPermissions || _isMockMode) return;
    await _requestAuthorization();
  }

  Future<void> _requestAuthorization() async {
    emit(state.copyWith(isRequestInProgress: true));
    try {
      final granted = await _healthService.requestAuthorization();
      await _preferencesRepository.setHasRequestedHealthPermissions(true);
      await _preferencesRepository.setHealthPermissionsGranted(granted);
      emit(
        state.copyWith(
          hasRequested: true,
          status: granted
              ? HealthPermissionStatus.granted
              : HealthPermissionStatus.denied,
          isRequestInProgress: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          hasRequested: true,
          status: HealthPermissionStatus.denied,
          isRequestInProgress: false,
        ),
      );
    }
  }
}
