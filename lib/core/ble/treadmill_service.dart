import 'dart:async';

import 'package:equatable/equatable.dart';

abstract class TreadmillService {
  Stream<List<TreadmillDeviceInfo>> scan();

  Stream<TreadmillConnectionState> connectionState();

  Future<void> connect(String deviceId);

  Future<void> disconnect();

  Stream<TreadmillMetrics> listenToMetrics();

  Future<void> setSpeed(double valueKmh);

  Future<void> setIncline(double valuePercent);

  Future<void> dispose();
}

class TreadmillDeviceInfo extends Equatable {
  const TreadmillDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    this.vendor,
    this.features = const TreadmillFeatureSupport(),
  });

  final String id;
  final String name;
  final int rssi;
  final String? vendor;
  final TreadmillFeatureSupport features;

  @override
  List<Object?> get props => [id, name, rssi, vendor, features];

  TreadmillDeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    String? vendor,
    TreadmillFeatureSupport? features,
  }) {
    return TreadmillDeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      vendor: vendor ?? this.vendor,
      features: features ?? this.features,
    );
  }
}

class TreadmillFeatureSupport extends Equatable {
  const TreadmillFeatureSupport({
    this.supportsSpeedControl = true,
    this.supportsInclineControl = true,
    this.supportsHeartRate = true,
  });

  final bool supportsSpeedControl;
  final bool supportsInclineControl;
  final bool supportsHeartRate;

  @override
  List<Object?> get props =>
      [supportsSpeedControl, supportsInclineControl, supportsHeartRate];
}

class TreadmillMetrics extends Equatable {
  const TreadmillMetrics({
    required this.elapsed,
    required this.speedKmh,
    required this.inclinePercent,
    required this.distanceMeters,
    required this.heartRate,
  });

  final Duration elapsed;
  final double speedKmh;
  final double inclinePercent;
  final double distanceMeters;
  final int heartRate;

  TreadmillMetrics copyWith({
    Duration? elapsed,
    double? speedKmh,
    double? inclinePercent,
    double? distanceMeters,
    int? heartRate,
  }) {
    return TreadmillMetrics(
      elapsed: elapsed ?? this.elapsed,
      speedKmh: speedKmh ?? this.speedKmh,
      inclinePercent: inclinePercent ?? this.inclinePercent,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      heartRate: heartRate ?? this.heartRate,
    );
  }

  static const zero = TreadmillMetrics(
    elapsed: Duration.zero,
    speedKmh: 0,
    inclinePercent: 0,
    distanceMeters: 0,
    heartRate: 0,
  );

  @override
  List<Object?> get props =>
      [elapsed, speedKmh, inclinePercent, distanceMeters, heartRate];
}

enum TreadmillConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}
