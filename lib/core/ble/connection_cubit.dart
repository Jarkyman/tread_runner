import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../permissions/ble_permission_handler.dart';
import 'treadmill_service.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this._treadmillService, this._permissionHandler)
    : super(const ConnectionState.initial()) {
    _connectionSubscription = _treadmillService.connectionState().listen(
      (status) {
        if (status != TreadmillConnectionState.connecting) {
          _connectionTimeoutTimer?.cancel();
        }
        final isConnected = status == TreadmillConnectionState.connected;
        final shouldResetActiveDevice =
            status == TreadmillConnectionState.disconnected ||
            status == TreadmillConnectionState.error;
        emit(
          state.copyWith(
            status: status,
            connectedDeviceId: isConnected
                ? state.connectedDeviceId ?? _pendingDevice?.id
                : null,
            activeDevice: isConnected
                ? state.activeDevice ?? _pendingDevice
                : null,
            lastKnownDevice: isConnected
                ? state.activeDevice ?? _pendingDevice
                : state.lastKnownDevice,
            isScanning: status == TreadmillConnectionState.scanning,
            lastStatusChangeAt: DateTime.now(),
            resetActiveDevice: shouldResetActiveDevice,
          ),
        );
        if (!isConnected &&
            status != TreadmillConnectionState.connecting &&
            status != TreadmillConnectionState.scanning) {
          _pendingDevice = null;
        }
        if (status == TreadmillConnectionState.connected) {
          _resumeScanAfterConnectAttempt = false;
        } else if ((status == TreadmillConnectionState.disconnected ||
                status == TreadmillConnectionState.error) &&
            _resumeScanAfterConnectAttempt) {
          _resumeScanAfterConnectAttempt = false;
          unawaited(startScan());
        }
      },
      onError: (error) {
        _connectionTimeoutTimer?.cancel();
        if (_resumeScanAfterConnectAttempt) {
          _resumeScanAfterConnectAttempt = false;
          unawaited(startScan());
        }
        emit(state.copyWith(status: TreadmillConnectionState.error));
      },
    );
  }

  final TreadmillService _treadmillService;
  final BlePermissionHandler _permissionHandler;
  StreamSubscription<List<TreadmillDeviceInfo>>? _scanSubscription;
  StreamSubscription<TreadmillConnectionState>? _connectionSubscription;
  Timer? _connectionTimeoutTimer;
  bool _resumeScanAfterConnectAttempt = false;
  TreadmillDeviceInfo? _pendingDevice;
  static const Duration _connectionTimeout = Duration(seconds: 30);

  Future<bool> startScan() async {
    emit(state.copyWith(clearError: true));
    final permissionStatus = await _permissionHandler.ensurePermissions();
    if (permissionStatus != BlePermissionStatus.granted) {
      emit(
        state.copyWith(
          permissionStatus: permissionStatus,
          errorMessage:
              permissionStatus == BlePermissionStatus.permanentlyDenied
              ? 'Bluetooth access is disabled. Enable it in system settings.'
              : 'Bluetooth permission is required to scan for treadmills.',
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isScanning: true,
        devices: const [],
        permissionStatus: permissionStatus,
        lastScanStartedAt: DateTime.now(),
      ),
    );
    await _scanSubscription?.cancel();
    _scanSubscription = _treadmillService.scan().listen(
      (devices) {
        emit(
          state.copyWith(
            devices: devices,
            isScanning: false,
            lastStatusChangeAt: DateTime.now(),
          ),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            errorMessage: 'Scan failed',
            isScanning: false,
            status: TreadmillConnectionState.error,
          ),
        );
      },
    );
    return true;
  }

  Future<void> connectToDevice(TreadmillDeviceInfo device) async {
    emit(state.copyWith(clearError: true));
    final permissionStatus = await _permissionHandler.ensurePermissions();
    if (permissionStatus != BlePermissionStatus.granted) {
      emit(
        state.copyWith(
          permissionStatus: permissionStatus,
          errorMessage:
              permissionStatus == BlePermissionStatus.permanentlyDenied
              ? 'Bluetooth access is disabled. Enable it in system settings.'
              : 'Bluetooth permission is required to connect.',
        ),
      );
      return;
    }

    _pendingDevice = device;
    emit(
      state.copyWith(
        connectedDeviceId: device.id,
        activeDevice: device,
        lastKnownDevice: device,
        status: TreadmillConnectionState.connecting,
        clearError: true,
        permissionStatus: permissionStatus,
        lastStatusChangeAt: DateTime.now(),
      ),
    );
    _resumeScanAfterConnectAttempt = true;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      final currentState = state;
      if (currentState.status == TreadmillConnectionState.connecting) {
        emit(
          currentState.copyWith(
            status: TreadmillConnectionState.error,
            errorMessage: 'Connection timed out. Please try again.',
          ),
        );
        unawaited(_treadmillService.disconnect());
      }
    });
    try {
      await _treadmillService.connect(device.id);
    } catch (_) {
      if (_resumeScanAfterConnectAttempt) {
        _resumeScanAfterConnectAttempt = false;
        unawaited(startScan());
      }
      emit(
        state.copyWith(
          status: TreadmillConnectionState.error,
          errorMessage: 'Unable to connect',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await _treadmillService.disconnect();
      _resumeScanAfterConnectAttempt = false;
      _pendingDevice = null;
      emit(
        state.copyWith(
          status: TreadmillConnectionState.disconnected,
          connectedDeviceId: null,
          clearError: true,
          lastStatusChangeAt: DateTime.now(),
          resetActiveDevice: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TreadmillConnectionState.error,
          errorMessage: 'Unable to disconnect',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _connectionTimeoutTimer?.cancel();
    _resumeScanAfterConnectAttempt = false;
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }

  Future<void> openSystemSettings() async {
    await _permissionHandler.openSystemSettings();
  }
}

class ConnectionState extends Equatable {
  const ConnectionState({
    required this.status,
    required this.devices,
    required this.isScanning,
    required this.connectedDeviceId,
    required this.errorMessage,
    required this.permissionStatus,
    this.activeDevice,
    this.lastKnownDevice,
    this.lastScanStartedAt,
    this.lastStatusChangeAt,
  });

  const ConnectionState.initial()
    : this(
        status: TreadmillConnectionState.disconnected,
        devices: const [],
        isScanning: false,
        connectedDeviceId: null,
        errorMessage: null,
        permissionStatus: BlePermissionStatus.unknown,
        activeDevice: null,
        lastKnownDevice: null,
        lastScanStartedAt: null,
        lastStatusChangeAt: null,
      );

  final TreadmillConnectionState status;
  final List<TreadmillDeviceInfo> devices;
  final bool isScanning;
  final String? connectedDeviceId;
  final String? errorMessage;
  final BlePermissionStatus permissionStatus;
  final TreadmillDeviceInfo? activeDevice;
  final TreadmillDeviceInfo? lastKnownDevice;
  final DateTime? lastScanStartedAt;
  final DateTime? lastStatusChangeAt;

  ConnectionState copyWith({
    TreadmillConnectionState? status,
    List<TreadmillDeviceInfo>? devices,
    bool? isScanning,
    String? connectedDeviceId,
    String? errorMessage,
    BlePermissionStatus? permissionStatus,
    TreadmillDeviceInfo? activeDevice,
    bool resetActiveDevice = false,
    TreadmillDeviceInfo? lastKnownDevice,
    bool resetLastKnownDevice = false,
    DateTime? lastScanStartedAt,
    DateTime? lastStatusChangeAt,
    bool clearError = false,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      permissionStatus: permissionStatus ?? this.permissionStatus,
      activeDevice: resetActiveDevice
          ? null
          : (activeDevice ?? this.activeDevice),
      lastKnownDevice: resetLastKnownDevice
          ? null
          : (lastKnownDevice ?? this.lastKnownDevice),
      lastScanStartedAt: lastScanStartedAt ?? this.lastScanStartedAt,
      lastStatusChangeAt: lastStatusChangeAt ?? this.lastStatusChangeAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    devices,
    isScanning,
    connectedDeviceId,
    errorMessage,
    permissionStatus,
    activeDevice,
    lastKnownDevice,
    lastScanStartedAt,
    lastStatusChangeAt,
  ];
}
