import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_logger.dart';
import 'ftms_client.dart';
import 'ftms_constants.dart';
import 'treadmill_service.dart';

class FtmsTreadmillService implements TreadmillService {
  FtmsTreadmillService(
    FlutterReactiveBle ble, {
    FtmsClient? client,
    BleLogger? logger,
  }) : _ble = ble {
    _logger = logger ?? BleLogger();
    _client = client ?? FtmsClient(ble, logger: _logger);
    _client.registerScanStopper(_stopActiveScan);
    _logger.log(BleLogTag.ftms, 'FTMS treadmill service ready');
    _metricsForwardSubscription = _client.metrics.listen(
      _metricsController.add,
      onError: (error, stackTrace) {
        log('FTMS metrics error: $error', stackTrace: stackTrace);
        _emitConnectionState(
          TreadmillConnectionState.error,
          reason: 'metrics_stream_error: $error',
        );
      },
    );
    _clientConnectionSubscription =
        _client.connectionEvents.listen(_handleClientConnectionChange);
  }

  final FlutterReactiveBle _ble;
  late final FtmsClient _client;
  late final BleLogger _logger;

  final _scanController =
      StreamController<List<TreadmillDeviceInfo>>.broadcast();
  final _connectionStateController =
      StreamController<TreadmillConnectionState>.broadcast();
  final _metricsController = StreamController<TreadmillMetrics>.broadcast();

  final Map<String, TreadmillDeviceInfo> _discoveredDevices = {};

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<TreadmillMetrics>? _metricsForwardSubscription;
  StreamSubscription<DeviceConnectionState>? _clientConnectionSubscription;

  TreadmillConnectionState _lastConnectionState =
      TreadmillConnectionState.disconnected;
  bool _sessionActive = false;
  bool _startingSession = false;

  @override
  Stream<List<TreadmillDeviceInfo>> scan() {
    _emitConnectionState(
      TreadmillConnectionState.scanning,
      reason: 'scan_started',
    );
    _logger.log(BleLogTag.scan, 'Starting FTMS scan');
    _discoveredDevices.clear();
    _scanController.add(const <TreadmillDeviceInfo>[]);
    _scanSubscription?.cancel();
    _scanSubscription = _ble
        .scanForDevices(
          withServices: [FtmsConstants.service],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            _discoveredDevices[device.id] = TreadmillDeviceInfo(
              id: device.id,
              name: device.name.isEmpty ? 'FTMS Device' : device.name,
              rssi: device.rssi,
              vendor: _formatManufacturerData(device.manufacturerData),
              features: const TreadmillFeatureSupport(
                supportsSpeedControl: true,
                supportsInclineControl: true,
                supportsHeartRate: true,
              ),
            );
            _scanController.add(_discoveredDevices.values.toList());
          },
          onError: (error, stack) {
            log('FTMS scan error: $error', stackTrace: stack);
            _emitConnectionState(
              TreadmillConnectionState.error,
              reason: 'scan_error: $error',
            );
          },
        );
    return _scanController.stream;
  }

  @override
  Stream<TreadmillConnectionState> connectionState() {
    return _connectionStateController.stream;
  }

  @override
  Future<void> connect(String deviceId) async {
    await _stopActiveScan();
    _emitConnectionState(
      TreadmillConnectionState.connecting,
      reason: 'connect_requested',
    );
    _logger.log(BleLogTag.connect, 'Connect requested for $deviceId');
    try {
      await _client.connect(deviceId);
    } catch (error, stackTrace) {
      log('FTMS connection error: $error', stackTrace: stackTrace);
      _emitConnectionState(
        TreadmillConnectionState.error,
        reason: 'connect_failure: $error',
      );
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.log(BleLogTag.connect, 'Disconnect requested');
    await _client.disconnect();
    _emitConnectionState(
      TreadmillConnectionState.disconnected,
      reason: 'manual_disconnect',
    );
  }

  @override
  Stream<TreadmillMetrics> listenToMetrics() {
    return _metricsController.stream;
  }

  @override
  Future<void> setIncline(double valuePercent) {
    return _client.setTargetIncline(valuePercent);
  }

  @override
  Future<void> setSpeed(double valueKmh) async {
    await _client.setTargetSpeed(valueKmh);
    if (valueKmh > 0) {
      await _ensureSessionStarted();
    } else {
      _sessionActive = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _stopActiveScan();
    await _metricsForwardSubscription?.cancel();
    await _clientConnectionSubscription?.cancel();
    await _client.dispose();
    await Future.wait([
      _scanController.close(),
      _connectionStateController.close(),
      _metricsController.close(),
    ]);
  }

  Future<void> _stopActiveScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _logger.log(BleLogTag.scan, 'Stopped FTMS scan');
    if (_lastConnectionState == TreadmillConnectionState.scanning) {
      _emitConnectionState(
        TreadmillConnectionState.disconnected,
        reason: 'scan_stopped',
      );
    }
  }

  void _handleClientConnectionChange(DeviceConnectionState state) {
    switch (state) {
      case DeviceConnectionState.connecting:
        _emitConnectionState(
          TreadmillConnectionState.connecting,
          reason: 'device_connecting',
        );
        _logger.log(BleLogTag.connect, 'Device reported connecting');
        break;
      case DeviceConnectionState.connected:
        _emitConnectionState(
          TreadmillConnectionState.connected,
          reason: 'device_connected',
        );
        _logger.log(BleLogTag.connect, 'Device reported connected');
        break;
      case DeviceConnectionState.disconnecting:
      case DeviceConnectionState.disconnected:
        _sessionActive = false;
        _startingSession = false;
        _emitConnectionState(
          TreadmillConnectionState.disconnected,
          reason: 'device_disconnected',
        );
        _logger.log(BleLogTag.connect, 'Device reported disconnected');
        break;
    }
  }

  Future<void> _ensureSessionStarted() async {
    if (_sessionActive || _startingSession) {
      return;
    }
    _startingSession = true;
    try {
      await _client.startOrResume();
      _sessionActive = true;
    } finally {
      _startingSession = false;
    }
  }

  void _emitConnectionState(
    TreadmillConnectionState state, {
    String? reason,
  }) {
    if (_lastConnectionState != state || reason != null) {
      final suffix = reason != null ? ' ($reason)' : '';
      _logger.log(BleLogTag.connect, 'State -> ${state.name}$suffix');
    }
    _lastConnectionState = state;
    _connectionStateController.add(state);
  }

  String? _formatManufacturerData(Uint8List data) {
    if (data.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      buffer.write(data[i].toRadixString(16).padLeft(2, '0'));
      if (i < data.length - 1) {
        buffer.write(':');
      }
    }
    return buffer.toString();
  }
}
