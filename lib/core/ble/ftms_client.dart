import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_logger.dart';
import 'ftms_constants.dart';
import 'treadmill_service.dart';

/// Units FTMS devices can use for instantaneous speed.
enum FtmsSpeedUnit {
  /// Instantaneous speed encoded as 0.1 km/h.
  kmhTenths,

  /// Instantaneous speed encoded as 0.01 km/h.
  kmhHundredths,

  /// Instantaneous speed encoded as 0.01 m/s.
  metersPerSecondHundredths;

  double decodeToKmh(int raw) {
    switch (this) {
      case FtmsSpeedUnit.kmhTenths:
        return raw / 10.0;
      case FtmsSpeedUnit.kmhHundredths:
        return raw / 100.0;
      case FtmsSpeedUnit.metersPerSecondHundredths:
        final metersPerSecond = raw / 100.0;
        return metersPerSecond * 3.6;
    }
  }

  int encodeFromKmh(double kmh) {
    switch (this) {
      case FtmsSpeedUnit.kmhTenths:
        return (kmh * 10).round();
      case FtmsSpeedUnit.kmhHundredths:
        return (kmh * 100).round();
      case FtmsSpeedUnit.metersPerSecondHundredths:
        final metersPerSecond = kmh / 3.6;
        return (metersPerSecond * 100).round();
    }
  }

  String get description {
    switch (this) {
      case FtmsSpeedUnit.kmhTenths:
        return '0.1 km/h';
      case FtmsSpeedUnit.kmhHundredths:
        return '0.01 km/h';
      case FtmsSpeedUnit.metersPerSecondHundredths:
        return '0.01 m/s';
    }
  }
}

/// Supported speed range reported by FTMS.
class SpeedRange {
  const SpeedRange._({
    required this.minRaw,
    required this.maxRaw,
    required this.stepRaw,
    this.isFallback = false,
  });

  factory SpeedRange.fromBytes(List<int> value) {
    final byteData = _byteDataFrom(value, minLength: 6);
    return SpeedRange._(
      minRaw: byteData.getUint16(0, Endian.little),
      maxRaw: byteData.getUint16(2, Endian.little),
      stepRaw: byteData.getUint16(4, Endian.little),
    );
  }

  factory SpeedRange.fromKmh({
    required FtmsSpeedUnit unit,
    required double minKmh,
    required double maxKmh,
    required double stepKmh,
  }) {
    return SpeedRange._(
      minRaw: unit.encodeFromKmh(minKmh),
      maxRaw: unit.encodeFromKmh(maxKmh),
      stepRaw: math.max(1, unit.encodeFromKmh(stepKmh)),
      isFallback: true,
    );
  }

  static SpeedRange fallback(FtmsSpeedUnit unit) => SpeedRange.fromKmh(
        unit: unit,
        minKmh: 1,
        maxKmh: 16,
        stepKmh: 0.1,
      );

  final int minRaw;
  final int maxRaw;
  final int stepRaw;
  final bool isFallback;

  double minKmh(FtmsSpeedUnit unit) => unit.decodeToKmh(minRaw);

  double maxKmh(FtmsSpeedUnit unit) => unit.decodeToKmh(maxRaw);

  double stepKmh(FtmsSpeedUnit unit) => unit.decodeToKmh(stepRaw);

  double clamp(double kmh, FtmsSpeedUnit unit) =>
      kmh.clamp(minKmh(unit), maxKmh(unit)).toDouble();
}

/// Supported incline range reported by FTMS (0.1% resolution).
class InclineRange {
  const InclineRange({
    required this.minPercent,
    required this.maxPercent,
    required this.stepPercent,
  });

  factory InclineRange.fromBytes(List<int> value) {
    final byteData = _byteDataFrom(value, minLength: 6);
    final min = byteData.getInt16(0, Endian.little) / 10.0;
    final max = byteData.getInt16(2, Endian.little) / 10.0;
    final step = byteData.getUint16(4, Endian.little) / 10.0;
    return InclineRange(
      minPercent: min,
      maxPercent: max,
      stepPercent: step,
    );
  }

  static const fallback = InclineRange(
    minPercent: -5,
    maxPercent: 15,
    stepPercent: 0.5,
  );

  final double minPercent;
  final double maxPercent;
  final double stepPercent;

  double clamp(double percent) =>
      percent.clamp(minPercent, maxPercent).toDouble();
}

/// FTMS treadmill data flags.
class FtmsTreadmillDataFlag {
  FtmsTreadmillDataFlag._();

  static const averageSpeed = 0x0002;
  static const totalDistance = 0x0004;
  static const incline = 0x0008;
  static const elevationGain = 0x0010;
  static const instantaneousPace = 0x0020;
  static const averagePace = 0x0040;
  static const totalEnergy = 0x0080;
  static const heartRate = 0x0100;
  static const metabolicEquivalent = 0x0200;
  static const elapsedTime = 0x0400;
  static const remainingTime = 0x0800;
  static const forceOnBelt = 0x1000;
  static const powerOutput = 0x2000;
}

/// Parses FTMS treadmill data frames into the domain model.
class FtmsMetricDecoder {
  const FtmsMetricDecoder({
    this.speedUnit = FtmsSpeedUnit.kmhTenths,
  });

  final FtmsSpeedUnit speedUnit;

  TreadmillMetrics parse(List<int> frame) {
    if (frame.length < 4) {
      return TreadmillMetrics.zero;
    }
    final data = frame is Uint8List ? frame : Uint8List.fromList(frame);
    final buffer = ByteData.sublistView(data);
    var offset = 0;

    bool canRead(int length) => offset + length <= buffer.lengthInBytes;
    final flags = buffer.getUint16(offset, Endian.little);
    offset += 2;

    if (!canRead(2)) {
      return TreadmillMetrics.zero;
    }

    final rawSpeed = buffer.getUint16(offset, Endian.little);
    offset += 2;

    final speedKmh = speedUnit.decodeToKmh(rawSpeed);
    double distance = 0;
    double inclinePercent = 0;
    int heartRate = 0;
    Duration elapsed = Duration.zero;

    if ((flags & FtmsTreadmillDataFlag.averageSpeed) != 0 && canRead(2)) {
      offset += 2;
    }

    if ((flags & FtmsTreadmillDataFlag.totalDistance) != 0 && canRead(3)) {
      final rawDistance = buffer.getUint8(offset) |
          (buffer.getUint8(offset + 1) << 8) |
          (buffer.getUint8(offset + 2) << 16);
      distance = rawDistance / 10.0;
      offset += 3;
    }

    if ((flags & FtmsTreadmillDataFlag.incline) != 0 && canRead(4)) {
      final rawIncline = buffer.getInt16(offset, Endian.little);
      inclinePercent = rawIncline / 10.0;
      offset += 4; // skip ramp angle that follows incline
    }

    if ((flags & FtmsTreadmillDataFlag.elevationGain) != 0 && canRead(4)) {
      offset += 4;
    }
    if ((flags & FtmsTreadmillDataFlag.instantaneousPace) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & FtmsTreadmillDataFlag.averagePace) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & FtmsTreadmillDataFlag.totalEnergy) != 0 && canRead(6)) {
      offset += 6;
    }

    if ((flags & FtmsTreadmillDataFlag.heartRate) != 0 && canRead(1)) {
      heartRate = buffer.getUint8(offset);
      offset += 1;
    }

    if ((flags & FtmsTreadmillDataFlag.metabolicEquivalent) != 0 &&
        canRead(1)) {
      offset += 1;
    }

    if ((flags & FtmsTreadmillDataFlag.elapsedTime) != 0 && canRead(2)) {
      final seconds = buffer.getUint16(offset, Endian.little);
      elapsed = Duration(seconds: seconds);
      offset += 2;
    }

    if ((flags & FtmsTreadmillDataFlag.remainingTime) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & FtmsTreadmillDataFlag.forceOnBelt) != 0 && canRead(2)) {
      offset += 2;
    }
    if ((flags & FtmsTreadmillDataFlag.powerOutput) != 0 && canRead(2)) {
      offset += 2;
    }

    return TreadmillMetrics(
      elapsed: elapsed,
      speedKmh: speedKmh,
      inclinePercent: inclinePercent,
      distanceMeters: distance,
      heartRate: heartRate,
    );
  }
}

/// BLE client responsible for FTMS interactions.
class FtmsClient {
  FtmsClient(
    this._ble, {
    BleLogger? logger,
    this.controlResponseTimeout = const Duration(seconds: 5),
  }) : _logger = logger ?? BleLogger() {
    // Listening once ensures iOS sets up the event channel before we initiate
    // device connections, preventing "No event channel set up" warnings.
    _bleConnectionUpdates = _ble.connectedDeviceStream.listen((_) {});
  }

  final FlutterReactiveBle _ble;
  final BleLogger _logger;
  final Duration controlResponseTimeout;

  FtmsSpeedUnit _speedUnit = FtmsSpeedUnit.kmhTenths;

  late final StreamController<TreadmillMetrics> _metricsController =
      StreamController<TreadmillMetrics>.broadcast(
    onListen: _flushPendingMetric,
  );
  TreadmillMetrics? _pendingMetric;

  Stream<TreadmillMetrics> get metrics => _metricsController.stream;

  final StreamController<DeviceConnectionState> _connectionEventController =
      StreamController<DeviceConnectionState>.broadcast();

  Stream<DeviceConnectionState> get connectionEvents =>
      _connectionEventController.stream;

  bool _loggedFirstMetric = false;

  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<ConnectionStateUpdate>? _bleConnectionUpdates;
  StreamSubscription<List<int>>? _treadmillSubscription;
  StreamSubscription<List<int>>? _controlPointSubscription;

  QualifiedCharacteristic? _treadmillCharacteristic;
  QualifiedCharacteristic? _controlPointCharacteristic;
  QualifiedCharacteristic? _speedRangeCharacteristic;
  QualifiedCharacteristic? _inclineRangeCharacteristic;
  QualifiedCharacteristic? _featureCharacteristic;
  Uint8List? _featureFlags;
  Uuid? _currentServiceId;

  SpeedRange? _speedRange;
  InclineRange? _inclineRange;
  bool _inclineControlDisabled = false;

  String? _deviceId;
  bool _hasControl = false;
  Completer<void>? _connectionCompleter;
  Completer<FtmsControlPointResponse>? _pendingControlResponse;
  Future<void> _controlChain = Future<void>.value();
  Future<void> Function()? _stopScanCallback;
  int? _lastSpeedRaw;
  int? _lastInclineRaw;

  bool get isConnected =>
      _connectionSubscription != null &&
      _deviceId != null &&
      _treadmillCharacteristic != null;

  void registerScanStopper(Future<void> Function()? stopScan) {
    _stopScanCallback = stopScan;
  }

  Future<void> connect(String deviceId) async {
    await _stopScanIfNeeded();
    _logger.log(BleLogTag.connect, 'FTMS client connect($deviceId)');
    if (isConnected && _deviceId == deviceId) {
      return;
    }

    await disconnect();

    _deviceId = deviceId;
    _logger.log(BleLogTag.connect, 'Connecting', deviceId: deviceId);
    _connectionCompleter = Completer<void>();
    _connectionSubscription = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 15),
          servicesWithCharacteristicsToDiscover: {
            FtmsConstants.service: [
              FtmsConstants.treadmillData,
              FtmsConstants.indoorBikeData,
              FtmsConstants.controlPoint,
              FtmsConstants.fitnessMachineFeature,
              FtmsConstants.fitnessMachineStatus,
              FtmsConstants.trainingStatus,
              FtmsConstants.supportedSpeedRange,
              FtmsConstants.supportedInclineRange,
            ],
          },
        )
        .listen(
          (update) async {
            _connectionEventController.add(update.connectionState);
            switch (update.connectionState) {
              case DeviceConnectionState.connecting:
                _logger.log(BleLogTag.connect, 'Connecting…', deviceId: deviceId);
                break;
              case DeviceConnectionState.connected:
                _logger.log(BleLogTag.connect, 'Connected', deviceId: deviceId);
                await _handleConnected(deviceId);
                break;
              case DeviceConnectionState.disconnecting:
              case DeviceConnectionState.disconnected:
                _logger.log(BleLogTag.connect, 'Disconnected', deviceId: deviceId);
                await _handleDisconnection();
                break;
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _logger.log(
              BleLogTag.connect,
              'Connection error: $error',
              deviceId: deviceId,
            );
            _connectionEventController.add(DeviceConnectionState.disconnected);
            if (!(_connectionCompleter?.isCompleted ?? true)) {
              _connectionCompleter!.completeError(error, stackTrace);
            }
          },
        );

    return _connectionCompleter!.future;
  }

  Future<void> disconnect() async {
    _logger.log(BleLogTag.connect, 'Disconnect requested', deviceId: _deviceId);
    await _connectionSubscription?.cancel();
    await _handleDisconnection();
  }

  Future<SpeedRange> readSpeedRange() async {
    final cached = _speedRange;
    if (cached != null && !cached.isFallback) {
      return cached;
    }
    final characteristic = _speedRangeCharacteristic;
    if (characteristic == null) {
      final fallback = SpeedRange.fallback(_speedUnit);
      _speedRange = fallback;
      return fallback;
    }
    final value = await _ble.readCharacteristic(characteristic);
    final range = SpeedRange.fromBytes(value);
    _speedRange = range;
    _updateSpeedUnit(logChange: false);
    return range;
  }

  Future<InclineRange> readInclineRange() async {
    final characteristic = _inclineRangeCharacteristic;
    if (characteristic == null) {
      return InclineRange.fallback;
    }
    final value = await _ble.readCharacteristic(characteristic);
    final range = InclineRange.fromBytes(value);
    _inclineRange = range;
    return range;
  }

  Future<void> requestControl() async {
    if (_hasControl) {
      return;
    }
    await _sendControlCommand(
      FtmsControlPointOpcode.requestControl,
      [FtmsControlPointOpcode.requestControl.code],
    );
    _hasControl = true;
  }

  Future<void> startOrResume() async {
    await requestControl();
    await _sendControlCommand(
      FtmsControlPointOpcode.startOrResume,
      [FtmsControlPointOpcode.startOrResume.code],
    );
  }

  Future<void> stop() async {
    await requestControl();
    await _sendControlCommand(
      FtmsControlPointOpcode.stop,
      [FtmsControlPointOpcode.stop.code, 0x01],
    );
  }

  Future<void> setTargetSpeed(double kmh) async {
    await requestControl();
    final range = _speedRange ?? await readSpeedRange();
    final clamped = range.clamp(kmh, _speedUnit);
    final raw = _speedUnit.encodeFromKmh(clamped);
    if (_lastSpeedRaw != null && _lastSpeedRaw == raw) {
      _logger.log(
        BleLogTag.control,
        'Skipping speed command, already at ${clamped.toStringAsFixed(1)} km/h',
        deviceId: _deviceId,
      );
      return;
    }
    final payload = Uint8List(3)
      ..[0] = FtmsControlPointOpcode.setTargetSpeed.code
      ..buffer.asByteData().setUint16(1, raw, Endian.little);
    _logger.log(
      BleLogTag.control,
      'Target speed ${clamped.toStringAsFixed(1)} km/h '
      '(raw=${_formatRaw(raw)}, unit=${_speedUnit.description})',
      deviceId: _deviceId,
    );
    await _sendControlCommand(
      FtmsControlPointOpcode.setTargetSpeed,
      payload,
    );
    _lastSpeedRaw = raw;
  }

  Future<void> setTargetIncline(double percent) async {
    if (_inclineControlDisabled) {
      _logger.log(
        BleLogTag.control,
        'Skipping incline control (disabled)',
        deviceId: _deviceId,
      );
      return;
    }
    await requestControl();
    final range = _inclineRange ?? await readInclineRange();
    final clamped = range.clamp(percent);
    final raw = (clamped * 10).round();
    if (_lastInclineRaw != null && _lastInclineRaw == raw) {
      _logger.log(
        BleLogTag.control,
        'Skipping incline command, already at ${clamped.toStringAsFixed(1)} %',
        deviceId: _deviceId,
      );
      return;
    }
    final payload = Uint8List(3)
      ..[0] = FtmsControlPointOpcode.setTargetIncline.code
      ..buffer.asByteData().setInt16(1, raw, Endian.little);
    _logger.log(
      BleLogTag.control,
      'Target incline ${clamped.toStringAsFixed(1)} % (raw=${_formatRaw(raw)})',
      deviceId: _deviceId,
    );
    try {
      await _sendControlCommand(
        FtmsControlPointOpcode.setTargetIncline,
        payload,
      );
      _lastInclineRaw = raw;
    } on FtmsControlPointException catch (error) {
      _disableInclineControl(error.message);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _metricsController.close();
    await _connectionEventController.close();
    await _bleConnectionUpdates?.cancel();
  }

  Future<void> _stopScanIfNeeded() async {
    final stopper = _stopScanCallback;
    _stopScanCallback = null;
    if (stopper != null) {
      _logger.log(BleLogTag.scan, 'Stopping active scan before connect');
      await stopper();
    }
  }

  Future<void> _handleConnected(String deviceId) async {
    try {
      _logger.log(BleLogTag.connect, 'Discovering FTMS services on $deviceId');
      await _onConnected(deviceId);
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter!.complete();
      }
    } catch (error, stackTrace) {
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter!.completeError(error, stackTrace);
      }
    } finally {
      _logger.log(BleLogTag.connect, 'Service discovery finished for $deviceId');
      _connectionCompleter = null;
    }
  }

  Future<void> _onConnected(String deviceId) async {
    await _ble.discoverAllServices(deviceId);
    final services = await _ble.getDiscoveredServices(deviceId);
    final ftmsService = _selectFtmsService(services);
    if (ftmsService == null) {
      final availableServices = services
          .map(
            (service) =>
                '\'${service.id}\'(${service.characteristics.length})',
          )
          .join(', ');
      throw StateError(
        'FTMS service not found on $deviceId. Found: $availableServices',
      );
    }
    _currentServiceId = ftmsService.id;
    if (!_matchesUuid(ftmsService.id, FtmsConstants.service)) {
      _logger.log(
        BleLogTag.discover,
        'Using service ${ftmsService.id} as FTMS container',
        deviceId: deviceId,
      );
    }
    _logger.log(
      BleLogTag.discover,
      'Found ${ftmsService.characteristics.length} FTMS characteristics',
      deviceId: deviceId,
    );

    for (final characteristic in ftmsService.characteristics) {
      _logger.logCharacteristic(
        tag: BleLogTag.discover,
        serviceId: ftmsService.id,
        characteristicId: characteristic.id,
        deviceId: deviceId,
      );
    }

    final hasTreadmillData = ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.treadmillData),
    );
    final hasIndoorBikeData = ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.indoorBikeData),
    );
    if (!hasTreadmillData && !hasIndoorBikeData) {
      throw StateError(
        'No FTMS metrics characteristic (0x2ACD/0x2AD2) available',
      );
    }

    final hasControlPoint = ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.controlPoint),
    );
    if (!hasControlPoint) {
      throw StateError('Control Point characteristic (0x2AD9) unavailable');
    }

    final metricCharacteristicId = hasTreadmillData
        ? FtmsConstants.treadmillData
        : FtmsConstants.indoorBikeData;
    if (!hasTreadmillData) {
      _logger.log(
        BleLogTag.ftms,
        'Treadmill Data missing, using Indoor Bike Data (0x2AD2) instead',
        deviceId: deviceId,
      );
    }

    _treadmillCharacteristic = _qualified(deviceId, metricCharacteristicId);
    _controlPointCharacteristic =
        _qualified(deviceId, FtmsConstants.controlPoint);

    if (ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.fitnessMachineFeature),
    )) {
      _featureCharacteristic =
          _qualified(deviceId, FtmsConstants.fitnessMachineFeature);
    } else {
      _featureCharacteristic = null;
    }

    if (ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.supportedSpeedRange),
    )) {
      _speedRangeCharacteristic =
          _qualified(deviceId, FtmsConstants.supportedSpeedRange);
    }

    if (ftmsService.characteristics.any(
      (char) => _matchesUuid(char.id, FtmsConstants.supportedInclineRange),
    )) {
      _inclineRangeCharacteristic =
          _qualified(deviceId, FtmsConstants.supportedInclineRange);
    }

    await _startTreadmillNotifications();
    await _startControlPointIndications();
    await _primeStaticCharacteristics();
  }

  Service? _selectFtmsService(List<Service> services) {
    for (final service in services) {
      final chars = service.characteristics.map((c) => c.id.toString()).join(', ');
      _logger.log(
        BleLogTag.discover,
        'Service ${service.id} chars: [$chars]',
        deviceId: _deviceId,
      );
    }
    for (final service in services) {
      if (_matchesUuid(service.id, FtmsConstants.service)) {
        return service;
      }
    }
    bool hasFtmsChars(Service service) {
      return service.characteristics.any(
        (char) =>
            _matchesUuid(char.id, FtmsConstants.treadmillData) ||
            _matchesUuid(char.id, FtmsConstants.indoorBikeData) ||
            _matchesUuid(char.id, FtmsConstants.controlPoint),
      );
    }

    for (final service in services) {
      if (hasFtmsChars(service)) {
        return service;
      }
    }

    return null;
  }

  QualifiedCharacteristic _qualified(String deviceId, Uuid characteristicId) {
    return QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: _currentServiceId ?? FtmsConstants.service,
      characteristicId: characteristicId,
    );
  }

  Future<void> _startTreadmillNotifications() async {
    final characteristic = _treadmillCharacteristic;
    if (characteristic == null) {
      throw StateError('No treadmill data characteristic resolved');
    }

    await _treadmillSubscription?.cancel();
    _logger.log(BleLogTag.ftms, 'Subscribing to treadmill data');
    _treadmillSubscription = _ble
        .subscribeToCharacteristic(characteristic)
        .listen(_handleTreadmillData, onError: (Object error, StackTrace stack) {
      _logger.log(BleLogTag.ftms, 'Metrics stream error: $error');
    });
  }

  Future<void> _startControlPointIndications() async {
    final characteristic = _controlPointCharacteristic;
    if (characteristic == null) {
      throw StateError('No control point characteristic resolved');
    }
    await _controlPointSubscription?.cancel();
    _logger.log(BleLogTag.control, 'Enabling control point indications');
    _controlPointSubscription =
        _ble.subscribeToCharacteristic(characteristic).listen(
      _handleControlPointData,
      onError: (Object error, StackTrace stack) {
        _logger.log(BleLogTag.control, 'Control point indication error: $error');
      },
    );
  }

  Future<void> _primeStaticCharacteristics() async {
    await _primeFeatureFlags();
    await _primeSpeedRange();
    await _primeInclineRange();
    _updateSpeedUnit();
  }

  Future<void> _primeFeatureFlags() async {
    final featureCharacteristic = _featureCharacteristic;
    if (featureCharacteristic == null) return;
    try {
      final value = await _ble.readCharacteristic(featureCharacteristic);
      _applyFeatureFlags(value);
    } catch (error) {
      _logger.log(
        BleLogTag.ftms,
        'Failed to read Fitness Machine Feature: $error',
        deviceId: _deviceId,
      );
    }
  }

  Future<void> _primeSpeedRange() async {
    if (_speedRangeCharacteristic == null) {
      _speedRange ??= SpeedRange.fallback(_speedUnit);
      return;
    }
    try {
      await readSpeedRange();
      final range = _speedRange;
      if (range != null) {
        _logger.log(
          BleLogTag.ftms,
          'Supported speed range '
          '${range.minKmh(_speedUnit).toStringAsFixed(1)}-'
          '${range.maxKmh(_speedUnit).toStringAsFixed(1)} km/h',
          deviceId: _deviceId,
        );
      }
    } catch (error) {
      _logger.log(
        BleLogTag.ftms,
        'Failed to read Supported Speed Range: $error',
        deviceId: _deviceId,
      );
      _speedRange ??= SpeedRange.fallback(_speedUnit);
    }
  }

  Future<void> _primeInclineRange() async {
    if (_inclineRangeCharacteristic == null) {
      _inclineRange ??= InclineRange.fallback;
      return;
    }
    try {
      final range = await readInclineRange();
      _logger.log(
        BleLogTag.ftms,
        'Supported incline range '
        '${range.minPercent.toStringAsFixed(1)}-'
        '${range.maxPercent.toStringAsFixed(1)} %',
        deviceId: _deviceId,
      );
      if (range.maxPercent == 0 && range.minPercent == 0) {
        _disableInclineControl('Device reports no incline capability');
      }
    } catch (error) {
      _logger.log(
        BleLogTag.ftms,
        'Failed to read Supported Incline Range: $error',
        deviceId: _deviceId,
      );
    }
  }

  void _updateSpeedUnit({bool logChange = true}) {
    final resolved = _resolveSpeedUnit();
    if (resolved == _speedUnit) {
      return;
    }
    _speedUnit = resolved;
    if ((_speedRange?.isFallback ?? false)) {
      _speedRange = SpeedRange.fallback(_speedUnit);
    }
    if (logChange) {
      _logger.log(
        BleLogTag.ftms,
        'Using ${_speedUnit.description} for speed encoding',
        deviceId: _deviceId,
      );
    }
  }

  FtmsSpeedUnit _resolveSpeedUnit() {
    final featureUnit = _speedUnitFromFeatureFlags();
    if (featureUnit != null) {
      return featureUnit;
    }
    final rangeUnit = _speedUnitFromRange();
    if (rangeUnit != null) {
      return rangeUnit;
    }
    return FtmsSpeedUnit.kmhTenths;
  }

  FtmsSpeedUnit? _speedUnitFromFeatureFlags() {
    // TODO: parse meters-per-second hint once devices that expose it are tested.
    return null;
  }

  FtmsSpeedUnit? _speedUnitFromRange() {
    final range = _speedRange;
    if (range == null || range.isFallback) {
      return null;
    }
    if (range.maxRaw >= 1000 || range.stepRaw >= 10) {
      return FtmsSpeedUnit.kmhHundredths;
    }
    final tenthsMax = FtmsSpeedUnit.kmhTenths.decodeToKmh(range.maxRaw);
    final metersMax =
        FtmsSpeedUnit.metersPerSecondHundredths.decodeToKmh(range.maxRaw);
    final tenthsScore = _scoreMaxSpeed(tenthsMax);
    final metersScore = _scoreMaxSpeed(metersMax);
    if (metersScore + 3 < tenthsScore) {
      return FtmsSpeedUnit.metersPerSecondHundredths;
    }
    if (tenthsScore + 3 < metersScore) {
      return FtmsSpeedUnit.kmhTenths;
    }
    return null;
  }

  double _scoreMaxSpeed(double maxKmh) {
    if (maxKmh <= 0) return double.infinity;
    if (maxKmh < 5) return 20 + (5 - maxKmh);
    if (maxKmh > 35) return 20 + (maxKmh - 35);
    return (maxKmh - 20).abs();
  }

  void _applyFeatureFlags(List<int> data) {
    _featureFlags = data is Uint8List ? data : Uint8List.fromList(data);
    _logger.log(
      BleLogTag.ftms,
      'Feature flags read (${data.length} bytes): ${_formatHex(_featureFlags!)}',
      deviceId: _deviceId,
    );
    _updateSpeedUnit(logChange: false);
  }

  Future<void> _handleDisconnection() async {
    await _treadmillSubscription?.cancel();
    await _controlPointSubscription?.cancel();
    _connectionSubscription = null;
    _treadmillSubscription = null;
    _controlPointSubscription = null;
    _treadmillCharacteristic = null;
    _controlPointCharacteristic = null;
    _featureCharacteristic = null;
    _featureFlags = null;
    _speedRangeCharacteristic = null;
    _inclineRangeCharacteristic = null;
    _speedRange = null;
    _inclineRange = null;
    _inclineControlDisabled = false;
    _lastSpeedRaw = null;
    _lastInclineRaw = null;
    _speedUnit = FtmsSpeedUnit.kmhTenths;
    _hasControl = false;
    _loggedFirstMetric = false;
    _currentServiceId = null;
    _failPendingControlResponse(
      FtmsControlPointException('Disconnected before response'),
    );
    _logger.log(BleLogTag.connect, 'Cleaned up after disconnect');
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter!
          .completeError(StateError('Disconnected before setup completed'));
    }
    _connectionCompleter = null;
    _deviceId = null;
    _controlChain = Future<void>.value();
  }

  void _handleTreadmillData(List<int> value) {
    final metrics = FtmsMetricDecoder(speedUnit: _speedUnit).parse(value);
    _pendingMetric = metrics;
    if (_metricsController.hasListener) {
      _metricsController.add(metrics);
      _pendingMetric = null;
    }
    if (!_loggedFirstMetric) {
      _logger.log(
        BleLogTag.ftms,
        'First metrics received: ${metrics.speedKmh.toStringAsFixed(1)} km/h, '
        '${metrics.inclinePercent.toStringAsFixed(1)} %',
        deviceId: _deviceId,
      );
      _loggedFirstMetric = true;
    }
  }

  void _flushPendingMetric() {
    final pending = _pendingMetric;
    if (pending != null) {
      _metricsController.add(pending);
      _pendingMetric = null;
    }
  }

  void _handleControlPointData(List<int> data) {
    final response = FtmsControlPointResponse.parse(data);
    final completer = _pendingControlResponse;
    if (completer != null && !completer.isCompleted) {
      _logger.log(
        BleLogTag.control,
        'Control point response ${response.request.name} -> '
        '${response.result.description}',
        deviceId: _deviceId,
      );
      completer.complete(response);
      _pendingControlResponse = null;
    } else {
      _logger.log(
        BleLogTag.control,
        'Unexpected control point indication: $response',
        deviceId: _deviceId,
      );
    }
  }

  Future<void> _sendControlCommand(
    FtmsControlPointOpcode opcode,
    List<int> payload,
  ) {
    _logger.log(
      BleLogTag.control,
      'Sending ${opcode.name} (${payload.length} bytes)',
      deviceId: _deviceId,
    );
    final execution =
        _controlChain.then((_) => _writeAndAwaitResponse(opcode, payload));
    _controlChain = execution.catchError((_) {});
    return execution;
  }

  Future<void> _writeAndAwaitResponse(
    FtmsControlPointOpcode opcode,
    List<int> payload,
  ) async {
    final characteristic = _controlPointCharacteristic;
    if (characteristic == null) {
      throw FtmsControlPointException('No control point characteristic found');
    }
    final completer = Completer<FtmsControlPointResponse>();
    _pendingControlResponse = completer;
    try {
      await _ble.writeCharacteristicWithResponse(
        characteristic,
        value: payload,
      );
    } catch (error) {
      _failPendingControlResponse(error);
      rethrow;
    }
    late final FtmsControlPointResponse response;
    try {
      response = await completer.future.timeout(
        controlResponseTimeout,
        onTimeout: () {
          throw FtmsControlPointException(
            'Timed out waiting for ${opcode.name} response',
          );
        },
      );
    } finally {
      _pendingControlResponse = null;
    }
    if (response.request != opcode) {
      throw FtmsControlPointException(
        'Unexpected response ${response.request} for opcode ${opcode.name}',
      );
    }
    if (response.result != FtmsControlPointResultCode.success) {
      _hasControl = false;
      _logger.log(
        BleLogTag.control,
        'Control command ${opcode.name} failed: ${response.result.description}',
        deviceId: _deviceId,
      );
      throw FtmsControlPointException(response.result.description);
    }
  }

  void _failPendingControlResponse(Object error) {
    final completer = _pendingControlResponse;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
    _pendingControlResponse = null;
  }

  void _disableInclineControl(String reason) {
    if (_inclineControlDisabled) {
      return;
    }
    _inclineControlDisabled = true;
    _logger.log(
      BleLogTag.control,
      'Incline control disabled: $reason',
      deviceId: _deviceId,
    );
  }

  String _formatHex(List<int> data) {
    final buffer = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(data[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  String _formatRaw(int value) =>
      '0x${value.toRadixString(16).padLeft(4, '0')}';

  bool _matchesUuid(Uuid actual, Uuid expected) {
    final actualStr = _normalizeUuid(actual.toString().toLowerCase());
    final expectedStr = _normalizeUuid(expected.toString().toLowerCase());
    return actualStr == expectedStr;
  }

  String _normalizeUuid(String value) {
    const bluetoothBase = '-0000-1000-8000-00805f9b34fb';
    if (value.length == 36 && value.endsWith(bluetoothBase)) {
      return value.substring(4, 8).padLeft(4, '0');
    }
    if (value.length == 4 || value.length == 8) {
      return value.substring(value.length - 4).padLeft(4, '0');
    }
    return value;
  }
}

enum FtmsControlPointOpcode {
  requestControl(0x00),
  setTargetSpeed(0x02),
  setTargetIncline(0x03),
  startOrResume(0x07),
  stop(0x08);

  const FtmsControlPointOpcode(this.code);

  final int code;

  static FtmsControlPointOpcode? fromCode(int value) {
    for (final opcode in FtmsControlPointOpcode.values) {
      if (opcode.code == value) {
        return opcode;
      }
    }
    return null;
  }
}

/// Result code defined by FTMS Response Code procedure.
enum FtmsControlPointResultCode {
  success(0x01, 'Success'),
  opCodeNotSupported(0x02, 'Op code not supported'),
  controlNotPermitted(0x03, 'Control not permitted'),
  invalidParameter(0x04, 'Invalid parameter'),
  operationFailed(0x05, 'Operation failed'),
  controlAlreadyGranted(0x06, 'Control already granted'),
  tooManyOperators(0x07, 'Too many operators'),
  unknown(0xFF, 'Unknown result');

  const FtmsControlPointResultCode(this.code, this.description);

  final int code;
  final String description;

  static FtmsControlPointResultCode fromCode(int value) {
    for (final result in FtmsControlPointResultCode.values) {
      if (result.code == value) {
        return result;
      }
    }
    return FtmsControlPointResultCode.unknown;
  }
}

class FtmsControlPointResponse {
  FtmsControlPointResponse({
    required this.request,
    required this.result,
  });

  factory FtmsControlPointResponse.parse(List<int> value) {
    if (value.length < 3) {
      throw FtmsControlPointException('Invalid control point response');
    }
    if (value[0] != _responseCode) {
      throw FtmsControlPointException('Unexpected opcode ${value[0]}');
    }
    final requestOpcode = FtmsControlPointOpcode.fromCode(value[1]);
    if (requestOpcode == null) {
      throw FtmsControlPointException('Unknown request opcode ${value[1]}');
    }
    final result = FtmsControlPointResultCode.fromCode(value[2]);
    return FtmsControlPointResponse(request: requestOpcode, result: result);
  }

  static const int _responseCode = 0x80;

  final FtmsControlPointOpcode request;
  final FtmsControlPointResultCode result;

  @override
  String toString() =>
      'FtmsControlPointResponse(request: ${request.name}, result: ${result.description})';
}

class FtmsControlPointException implements Exception {
  FtmsControlPointException(this.message);

  final String message;

  @override
  String toString() => 'FtmsControlPointException($message)';
}

ByteData _byteDataFrom(
  List<int> data, {
  required int minLength,
}) {
  if (data.length < minLength) {
    throw ArgumentError(
      'Characteristic value should be at least $minLength bytes, got ${data.length}',
    );
  }
  final list = data is Uint8List ? data : Uint8List.fromList(data);
  return ByteData.sublistView(list);
}
