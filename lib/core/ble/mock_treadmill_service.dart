import 'dart:async';
import 'dart:math';

import 'treadmill_service.dart';

class MockTreadmillService implements TreadmillService {
  MockTreadmillService({
    Duration tick = const Duration(seconds: 1),
  }) : _tick = tick;

  final Duration _tick;

  final _scanController =
      StreamController<List<TreadmillDeviceInfo>>.broadcast();
  final _connectionStateController =
      StreamController<TreadmillConnectionState>.broadcast();
  final _metricsController = StreamController<TreadmillMetrics>.broadcast();

  Timer? _timer;
  TreadmillMetrics _currentMetrics = TreadmillMetrics.zero;
  double _currentSpeed = 8;
  double _currentIncline = 1;
  bool _connected = false;

  @override
  Stream<List<TreadmillDeviceInfo>> scan() {
    _connectionStateController.add(TreadmillConnectionState.scanning);
    Future.delayed(const Duration(milliseconds: 300), () {
      _scanController.add(
        [
          const TreadmillDeviceInfo(
            id: 'mock-device',
            name: 'Mock Treadmill',
            rssi: -45,
            vendor: 'TreadRunner Simulator',
            features: TreadmillFeatureSupport(
              supportsSpeedControl: true,
              supportsInclineControl: true,
              supportsHeartRate: true,
            ),
          ),
        ],
      );
      _connectionStateController.add(TreadmillConnectionState.disconnected);
    });
    return _scanController.stream;
  }

  @override
  Stream<TreadmillConnectionState> connectionState() {
    return _connectionStateController.stream;
  }

  @override
  Future<void> connect(String deviceId) async {
    _connectionStateController.add(TreadmillConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 500));
    _connected = true;
    _connectionStateController.add(TreadmillConnectionState.connected);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!_connected) return;
      final elapsed = _currentMetrics.elapsed + _tick;
      final distanceMeters =
          _currentMetrics.distanceMeters + (_currentSpeed * 1000 / 3600);
      final heartRate = 135 + Random().nextInt(10);
      _currentMetrics = _currentMetrics.copyWith(
        elapsed: elapsed,
        speedKmh: _currentSpeed,
        inclinePercent: _currentIncline,
        distanceMeters: distanceMeters,
        heartRate: heartRate,
      );
      _metricsController.add(_currentMetrics);
    });
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _timer?.cancel();
    _currentMetrics = TreadmillMetrics.zero;
    _connectionStateController.add(TreadmillConnectionState.disconnected);
  }

  @override
  Stream<TreadmillMetrics> listenToMetrics() {
    return _metricsController.stream;
  }

  @override
  Future<void> setIncline(double valuePercent) async {
    _currentIncline = valuePercent;
  }

  @override
  Future<void> setSpeed(double valueKmh) async {
    _currentSpeed = valueKmh;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await Future.wait([
      _scanController.close(),
      _connectionStateController.close(),
      _metricsController.close(),
    ]);
  }
}
