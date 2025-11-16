import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ble/connection_cubit.dart' as connection;
import '../permissions/ble_permission_handler.dart';
import '../ble/treadmill_service.dart';

enum AppLifecycleStage {
  initializing,
  ready,
  permissionsRequired,
  scanning,
  connecting,
  connected,
  error,
}

class AppStatusState extends Equatable {
  const AppStatusState({
    required this.stage,
    required this.headline,
    required this.detail,
    required this.isMockMode,
    required this.hasPermissions,
    required this.isScanning,
    required this.isConnecting,
    required this.isConnected,
    required this.activeDevice,
    required this.toastId,
    this.toastMessage,
  });

  factory AppStatusState.initial({required bool isMockMode}) => AppStatusState(
    stage: AppLifecycleStage.initializing,
    headline: 'Starting TreadRunner',
    detail: 'Preparing analytics and treadmill services…',
    isMockMode: isMockMode,
    hasPermissions: false,
    isScanning: false,
    isConnecting: false,
    isConnected: false,
    activeDevice: null,
    toastMessage: null,
    toastId: 0,
  );

  final AppLifecycleStage stage;
  final String headline;
  final String? detail;
  final bool isMockMode;
  final bool hasPermissions;
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final TreadmillDeviceInfo? activeDevice;
  final String? toastMessage;
  final int toastId;

  AppStatusState copyWith({
    AppLifecycleStage? stage,
    String? headline,
    String? detail,
    bool? hasPermissions,
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    TreadmillDeviceInfo? activeDevice,
    bool clearActiveDevice = false,
    String? toastMessage,
    bool clearToast = false,
    int? toastId,
  }) {
    return AppStatusState(
      stage: stage ?? this.stage,
      headline: headline ?? this.headline,
      detail: detail ?? this.detail,
      isMockMode: isMockMode,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      activeDevice: clearActiveDevice
          ? null
          : (activeDevice ?? this.activeDevice),
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      toastId: toastId ?? this.toastId,
    );
  }

  @override
  List<Object?> get props => [
    stage,
    headline,
    detail,
    isMockMode,
    hasPermissions,
    isScanning,
    isConnecting,
    isConnected,
    activeDevice,
    toastMessage,
    toastId,
  ];
}

class AppStatusCubit extends Cubit<AppStatusState> {
  AppStatusCubit({
    required connection.ConnectionCubit connectionCubit,
    required bool isMockMode,
  }) : _connectionCubit = connectionCubit,
       super(AppStatusState.initial(isMockMode: isMockMode)) {
    _syncState(_connectionCubit.state);
    _subscription = _connectionCubit.stream.listen(_syncState);
  }

  final connection.ConnectionCubit _connectionCubit;
  StreamSubscription<connection.ConnectionState>? _subscription;

  void _syncState(connection.ConnectionState connectionState) {
    final nextStage = _deriveStage(connectionState);
    final device =
        connectionState.activeDevice ?? connectionState.lastKnownDevice;
    final toast = _deriveToast(state.stage, nextStage, connectionState, device);
    emit(
      state.copyWith(
        stage: nextStage,
        headline: _headlineForStage(nextStage, connectionState, device),
        detail: _detailForStage(nextStage, connectionState),
        hasPermissions:
            connectionState.permissionStatus == BlePermissionStatus.granted,
        isScanning: connectionState.isScanning,
        isConnecting: nextStage == AppLifecycleStage.connecting,
        isConnected: nextStage == AppLifecycleStage.connected,
        activeDevice: device,
        clearActiveDevice: device == null,
        toastMessage: toast,
        clearToast: toast == null,
        toastId: toast != null ? state.toastId + 1 : state.toastId,
      ),
    );
  }

  AppLifecycleStage _deriveStage(connection.ConnectionState connectionState) {
    if (connectionState.permissionStatus != BlePermissionStatus.granted) {
      return AppLifecycleStage.permissionsRequired;
    }
    switch (connectionState.status) {
      case TreadmillConnectionState.scanning:
        return AppLifecycleStage.scanning;
      case TreadmillConnectionState.connecting:
        return AppLifecycleStage.connecting;
      case TreadmillConnectionState.connected:
        return AppLifecycleStage.connected;
      case TreadmillConnectionState.error:
        return AppLifecycleStage.error;
      case TreadmillConnectionState.disconnected:
        return connectionState.isScanning
            ? AppLifecycleStage.scanning
            : AppLifecycleStage.ready;
    }
  }

  String _headlineForStage(
    AppLifecycleStage stage,
    connection.ConnectionState connectionState,
    TreadmillDeviceInfo? device,
  ) {
    switch (stage) {
      case AppLifecycleStage.permissionsRequired:
        return 'Enable Bluetooth permissions';
      case AppLifecycleStage.scanning:
        return 'Scanning for treadmills';
      case AppLifecycleStage.connecting:
        final name = device?.name ?? '';
        final trimmed = name.trim();
        return 'Connecting to ${trimmed.isNotEmpty ? trimmed : 'treadmill'}';
      case AppLifecycleStage.connected:
        final name = device?.name ?? '';
        final trimmed = name.trim();
        return 'Connected to ${trimmed.isNotEmpty ? trimmed : 'treadmill'}';
      case AppLifecycleStage.error:
        return 'Connection issue';
      case AppLifecycleStage.ready:
        if (device != null) {
          final trimmed = device.name.trim();
          final label = trimmed.isEmpty ? 'Last treadmill' : trimmed;
          return '$label ready';
        }
        return 'Ready when you are';
      case AppLifecycleStage.initializing:
        return 'Starting TreadRunner';
    }
  }

  String? _detailForStage(
    AppLifecycleStage stage,
    connection.ConnectionState state,
  ) {
    switch (stage) {
      case AppLifecycleStage.permissionsRequired:
        return 'Grant Bluetooth access to control your treadmill.';
      case AppLifecycleStage.scanning:
        return 'Make sure the treadmill console is discoverable.';
      case AppLifecycleStage.connecting:
        return 'This can take a few seconds.';
      case AppLifecycleStage.connected:
        return state.isScanning ? 'Discovery paused while connected.' : null;
      case AppLifecycleStage.error:
        return state.errorMessage ?? 'Retry or check the treadmill console.';
      case AppLifecycleStage.ready:
      case AppLifecycleStage.initializing:
        return null;
    }
  }

  String? _deriveToast(
    AppLifecycleStage previousStage,
    AppLifecycleStage nextStage,
    connection.ConnectionState state,
    TreadmillDeviceInfo? device,
  ) {
    if (previousStage == nextStage) return null;
    switch (nextStage) {
      case AppLifecycleStage.connected:
        final name = device?.name ?? '';
        final trimmed = name.trim();
        return trimmed.isNotEmpty
            ? 'Connected to $trimmed'
            : 'Connected to treadmill';
      case AppLifecycleStage.permissionsRequired:
        return 'Bluetooth permission needed to discover treadmills.';
      case AppLifecycleStage.error:
        return state.errorMessage ?? 'Connection failed. Try again.';
      default:
        return null;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
