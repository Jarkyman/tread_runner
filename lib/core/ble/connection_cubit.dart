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
        emit(
          state.copyWith(
            status: status,
            connectedDeviceId: status == TreadmillConnectionState.connected
                ? state.connectedDeviceId
                : null,
            isScanning: status == TreadmillConnectionState.scanning,
          ),
        );
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
      ),
    );
    await _scanSubscription?.cancel();
    _scanSubscription = _treadmillService.scan().listen(
      (devices) {
        emit(state.copyWith(devices: devices, isScanning: false));
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

  Future<void> connectToDevice(String deviceId) async {
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

    emit(
      state.copyWith(
        connectedDeviceId: deviceId,
        status: TreadmillConnectionState.connecting,
        clearError: true,
        permissionStatus: permissionStatus,
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
      await _treadmillService.connect(deviceId);
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
      emit(
        state.copyWith(
          status: TreadmillConnectionState.disconnected,
          connectedDeviceId: null,
          clearError: true,
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
  });

  const ConnectionState.initial()
    : this(
        status: TreadmillConnectionState.disconnected,
        devices: const [],
        isScanning: false,
        connectedDeviceId: null,
        errorMessage: null,
        permissionStatus: BlePermissionStatus.unknown,
      );

  final TreadmillConnectionState status;
  final List<TreadmillDeviceInfo> devices;
  final bool isScanning;
  final String? connectedDeviceId;
  final String? errorMessage;
  final BlePermissionStatus permissionStatus;

  ConnectionState copyWith({
    TreadmillConnectionState? status,
    List<TreadmillDeviceInfo>? devices,
    bool? isScanning,
    String? connectedDeviceId,
    String? errorMessage,
    BlePermissionStatus? permissionStatus,
    bool clearError = false,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      permissionStatus: permissionStatus ?? this.permissionStatus,
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
  ];
}
