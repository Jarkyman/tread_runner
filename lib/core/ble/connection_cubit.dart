import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'treadmill_service.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this._treadmillService)
      : super(const ConnectionState.initial()) {
    _connectionSubscription = _treadmillService.connectionState().listen(
      (status) {
        emit(
          state.copyWith(
            status: status,
            connectedDeviceId: status == TreadmillConnectionState.connected
                ? state.connectedDeviceId
                : null,
            isScanning: status == TreadmillConnectionState.scanning,
          ),
        );
      },
      onError: (error) {
        emit(state.copyWith(status: TreadmillConnectionState.error));
      },
    );
  }

  final TreadmillService _treadmillService;
  StreamSubscription<List<TreadmillDeviceInfo>>? _scanSubscription;
  StreamSubscription<TreadmillConnectionState>? _connectionSubscription;

  Future<void> startScan() async {
    emit(
      state.copyWith(
        isScanning: true,
        devices: const [],
        clearError: true,
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
  }

  Future<void> connectToDevice(String deviceId) async {
    emit(
      state.copyWith(
        connectedDeviceId: deviceId,
        status: TreadmillConnectionState.connecting,
        clearError: true,
      ),
    );
    try {
      await _treadmillService.connect(deviceId);
    } catch (_) {
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
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}

class ConnectionState extends Equatable {
  const ConnectionState({
    required this.status,
    required this.devices,
    required this.isScanning,
    required this.connectedDeviceId,
    required this.errorMessage,
  });

  const ConnectionState.initial()
      : this(
          status: TreadmillConnectionState.disconnected,
          devices: const [],
          isScanning: false,
          connectedDeviceId: null,
          errorMessage: null,
        );

  final TreadmillConnectionState status;
  final List<TreadmillDeviceInfo> devices;
  final bool isScanning;
  final String? connectedDeviceId;
  final String? errorMessage;

  ConnectionState copyWith({
    TreadmillConnectionState? status,
    List<TreadmillDeviceInfo>? devices,
    bool? isScanning,
    String? connectedDeviceId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, devices, isScanning, connectedDeviceId, errorMessage];
}
