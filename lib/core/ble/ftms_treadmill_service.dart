import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'treadmill_service.dart';

class FtmsTreadmillService implements TreadmillService {
  FtmsTreadmillService(this._ble);

  static final Uuid _ftmsServiceUuid = Uuid.parse(
    '00001826-0000-1000-8000-00805f9b34fb',
  );
  static final Uuid _treadmillDataCharacteristic = Uuid.parse(
    '00002ACD-0000-1000-8000-00805f9b34fb',
  );
  static final Uuid _indoorBikeDataCharacteristic = Uuid.parse(
    '00002AD2-0000-1000-8000-00805f9b34fb',
  );
  static final Uuid _controlPointCharacteristic = Uuid.parse(
    '00002AD9-0000-1000-8000-00805f9b34fb',
  );
  static final Uuid _featureCharacteristic = Uuid.parse(
    '00002ACC-0000-1000-8000-00805f9b34fb',
  );

  final FlutterReactiveBle _ble;

  final _scanController =
      StreamController<List<TreadmillDeviceInfo>>.broadcast();
  final _connectionStateController =
      StreamController<TreadmillConnectionState>.broadcast();
  final _metricsController = StreamController<TreadmillMetrics>.broadcast();

  final Map<String, TreadmillDeviceInfo> _discoveredDevices = {};

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _metricsSubscription;

  QualifiedCharacteristic? _controlPointCharacteristicRef;

  @override
  Stream<List<TreadmillDeviceInfo>> scan() {
    _connectionStateController.add(TreadmillConnectionState.scanning);
    _discoveredDevices.clear();
    _scanSubscription?.cancel();
    _scanSubscription = _ble
        .scanForDevices(
          withServices: [_ftmsServiceUuid],
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
            _connectionStateController.add(TreadmillConnectionState.error);
          },
        );
    return _scanController.stream;
  }

  Future<QualifiedCharacteristic?> _resolveMetricsCharacteristic(
    String deviceId,
  ) async {
    try {
      await _ble.discoverAllServices(deviceId);
      final services = await _ble.getDiscoveredServices(deviceId);
      final ftmsService = services.firstWhere(
        (service) => service.id == _ftmsServiceUuid,
        orElse: () => throw StateError('FTMS service not found on device'),
      );
      final hasTreadmillData = ftmsService.characteristics.any(
        (char) => char.id == _treadmillDataCharacteristic,
      );
      final hasBikeData = ftmsService.characteristics.any(
        (char) => char.id == _indoorBikeDataCharacteristic,
      );

      if (hasTreadmillData) {
        return QualifiedCharacteristic(
          serviceId: _ftmsServiceUuid,
          characteristicId: _treadmillDataCharacteristic,
          deviceId: deviceId,
        );
      }

      if (hasBikeData) {
        log(
          'Treadmill data characteristic missing. Using Indoor Bike Data (0x2AD2) as fallback.',
        );
        return QualifiedCharacteristic(
          serviceId: _ftmsServiceUuid,
          characteristicId: _indoorBikeDataCharacteristic,
          deviceId: deviceId,
        );
      }

      log('No FTMS metrics characteristic available on device.');
      return null;
    } catch (error, stack) {
      log('Failed to discover FTMS services: $error', stackTrace: stack);
      return null;
    }
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

  @override
  Stream<TreadmillConnectionState> connectionState() {
    return _connectionStateController.stream;
  }

  @override
  Future<void> connect(String deviceId) async {
    await _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectionStateController.add(TreadmillConnectionState.connecting);
    _connectionSubscription = _ble
        .connectToDevice(
          id: deviceId,
          servicesWithCharacteristicsToDiscover: {
            _ftmsServiceUuid: [
              _treadmillDataCharacteristic,
              _indoorBikeDataCharacteristic,
              _controlPointCharacteristic,
              _featureCharacteristic,
            ],
          },
          connectionTimeout: const Duration(seconds: 15),
        )
        .listen(
          (update) {
            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _connectionStateController.add(
                  TreadmillConnectionState.connected,
                );
                _setupCharacteristics(deviceId);
                break;
              case DeviceConnectionState.connecting:
                _connectionStateController.add(
                  TreadmillConnectionState.connecting,
                );
                break;
              case DeviceConnectionState.disconnected:
                _connectionStateController.add(
                  TreadmillConnectionState.disconnected,
                );
                _metricsSubscription?.cancel();
                break;
              case DeviceConnectionState.disconnecting:
                _connectionStateController.add(
                  TreadmillConnectionState.disconnected,
                );
                break;
            }
          },
          onError: (error, stack) {
            log('FTMS connection error: $error', stackTrace: stack);
            _connectionStateController.add(TreadmillConnectionState.error);
          },
        );
  }

  void _setupCharacteristics(String deviceId) {
    _controlPointCharacteristicRef = QualifiedCharacteristic(
      serviceId: _ftmsServiceUuid,
      characteristicId: _controlPointCharacteristic,
      deviceId: deviceId,
    );
    _resolveMetricsCharacteristic(deviceId)
        .then((characteristic) {
          if (characteristic == null) {
            _connectionStateController.add(TreadmillConnectionState.error);
            return;
          }
          _metricsSubscription?.cancel();
          _metricsSubscription = _ble
              .subscribeToCharacteristic(characteristic)
              .listen(
                (data) {
                  final metrics = _parseMetrics(data);
                  _metricsController.add(metrics);
                },
                onError: (error, stack) {
                  log('FTMS metrics error: $error', stackTrace: stack);
                  _connectionStateController.add(
                    TreadmillConnectionState.error,
                  );
                },
              );
        })
        .catchError((error, stack) {
          log(
            'FTMS characteristic resolution failed: $error',
            stackTrace: stack,
          );
          _connectionStateController.add(TreadmillConnectionState.error);
        });
  }

  TreadmillMetrics _parseMetrics(List<int> data) {
    if (data.isEmpty) {
      return TreadmillMetrics.zero;
    }
    // TODO: Implement full FTMS treadmill data parsing. The current implementation
    // emits placeholder values so that downstream widgets can render.
    return TreadmillMetrics(
      elapsed: Duration(seconds: data.isNotEmpty ? data.first : 0),
      speedKmh: 0,
      inclinePercent: 0,
      distanceMeters: 0,
      heartRate: 0,
    );
  }

  @override
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    await _metricsSubscription?.cancel();
    _connectionStateController.add(TreadmillConnectionState.disconnected);
  }

  @override
  Stream<TreadmillMetrics> listenToMetrics() {
    return _metricsController.stream;
  }

  @override
  Future<void> setIncline(double valuePercent) async {
    if (_controlPointCharacteristicRef == null) return;
    // TODO: Encode FTMS incline command.
    log('FTMS set incline -> $valuePercent');
  }

  @override
  Future<void> setSpeed(double valueKmh) async {
    if (_controlPointCharacteristicRef == null) return;
    // TODO: Encode FTMS speed command.
    log('FTMS set speed -> $valueKmh');
  }

  @override
  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _metricsSubscription?.cancel();
    await Future.wait([
      _scanController.close(),
      _connectionStateController.close(),
      _metricsController.close(),
    ]);
  }
}
