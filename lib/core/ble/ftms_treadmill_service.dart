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
  static const int _flagAverageSpeed = 0x0002;
  static const int _flagTotalDistance = 0x0004;
  static const int _flagIncline = 0x0008;
  static const int _flagElevationGain = 0x0010;
  static const int _flagInstantaneousPace = 0x0020;
  static const int _flagAveragePace = 0x0040;
  static const int _flagEnergy = 0x0080;
  static const int _flagHeartRate = 0x0100;
  static const int _flagMetabolicEquivalent = 0x0200;
  static const int _flagElapsedTime = 0x0400;
  static const int _flagRemainingTime = 0x0800;
  static const int _flagForceOnBelt = 0x1000;
  static const int _flagPowerOutput = 0x2000;

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
  bool _hasControl = false;

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
    unawaited(_requestControl());
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
    if (data.length < 4) {
      return TreadmillMetrics.zero;
    }

    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    final buffer = ByteData.sublistView(bytes);
    var offset = 0;
    final flags = buffer.getUint16(offset, Endian.little);
    offset += 2;

    double speedKmh = 0;
    double inclinePercent = 0;
    double distanceMeters = 0;
    int heartRate = 0;
    Duration elapsed = Duration.zero;

    bool canRead(int count) => offset + count <= bytes.length;

    if (!canRead(2)) return TreadmillMetrics.zero;
    final rawSpeed = buffer.getUint16(offset, Endian.little);
    offset += 2;
    speedKmh = (rawSpeed / 100.0) * 3.6;

    if ((flags & _flagAverageSpeed) != 0 && canRead(2)) {
      offset += 2;
    }

    if ((flags & _flagTotalDistance) != 0 && canRead(3)) {
      final rawDistance = bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16);
      distanceMeters = rawDistance / 10.0;
      offset += 3;
    }

    if ((flags & _flagIncline) != 0 && canRead(4)) {
      final rawIncline = buffer.getInt16(offset, Endian.little);
      inclinePercent = rawIncline / 10.0;
      offset += 4;
    }

    if ((flags & _flagElevationGain) != 0 && canRead(4)) {
      offset += 4;
    }
    if ((flags & _flagInstantaneousPace) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & _flagAveragePace) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & _flagEnergy) != 0 && canRead(6)) {
      offset += 6;
    }

    if ((flags & _flagHeartRate) != 0 && canRead(1)) {
      heartRate = buffer.getUint8(offset);
      offset += 1;
    }

    if ((flags & _flagMetabolicEquivalent) != 0 && canRead(1)) {
      offset += 1;
    }

    if ((flags & _flagElapsedTime) != 0 && canRead(2)) {
      final seconds = buffer.getUint16(offset, Endian.little);
      elapsed = Duration(seconds: seconds);
      offset += 2;
    }

    if ((flags & _flagRemainingTime) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & _flagForceOnBelt) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & _flagPowerOutput) != 0 && canRead(2)) {
      offset += 2;
    }

    return TreadmillMetrics(
      elapsed: elapsed,
      speedKmh: speedKmh,
      inclinePercent: inclinePercent,
      distanceMeters: distanceMeters,
      heartRate: heartRate,
    );
  }

  @override
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    await _metricsSubscription?.cancel();
    _hasControl = false;
    _connectionStateController.add(TreadmillConnectionState.disconnected);
  }

  @override
  Stream<TreadmillMetrics> listenToMetrics() {
    return _metricsController.stream;
  }

  @override
  Future<void> setIncline(double valuePercent) async {
    if (_controlPointCharacteristicRef == null) return;
    await _requestControl();
    final clamped = valuePercent.clamp(-15, 15).toDouble();
    final raw = (clamped * 10).round();
    final payload = Uint8List(3)
      ..[0] = 0x03
      ..buffer.asByteData().setInt16(1, raw, Endian.little);
    await _writeControlPoint(payload);
  }

  @override
  Future<void> setSpeed(double valueKmh) async {
    if (_controlPointCharacteristicRef == null) return;
    await _requestControl();
    final clamped = valueKmh.clamp(0, 25).toDouble();
    final raw = ((clamped / 3.6) * 100).round();
    final payload = Uint8List(3)
      ..[0] = 0x02
      ..buffer.asByteData().setUint16(1, raw, Endian.little);
    await _writeControlPoint(payload);
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

  Future<void> _requestControl() async {
    if (_controlPointCharacteristicRef == null || _hasControl) return;
    try {
      await _writeControlPoint(Uint8List.fromList([0x00]));
      _hasControl = true;
    } catch (error, stackTrace) {
      log('FTMS request control failed: $error', stackTrace: stackTrace);
    }
  }

  Future<void> _writeControlPoint(Uint8List payload) async {
    final characteristic = _controlPointCharacteristicRef;
    if (characteristic == null) return;
    await _ble.writeCharacteristicWithResponse(
      characteristic,
      value: payload,
    );
  }
}
