import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:tread_runner/core/ble/ftms_client.dart';
import 'package:tread_runner/core/ble/treadmill_service.dart';

void main() {
  group('SpeedRange', () {
    test('decodes supported range payload', () {
      final bytes = Uint8List.fromList([0x32, 0x00, 0x98, 0x00, 0x0A, 0x00]);
      final range = SpeedRange.fromBytes(bytes);
      expect(range.minKmh(FtmsSpeedUnit.kmhTenths), 5.0);
      expect(range.maxKmh(FtmsSpeedUnit.kmhTenths), 15.2);
      expect(range.stepKmh(FtmsSpeedUnit.kmhTenths), 1.0);
    });
  });

  group('FtmsMetricDecoder', () {
    test('parses treadmill frame with flags', () {
      // Flags: total distance, incline, heart rate, elapsed time.
      final frame = Uint8List.fromList([
        0x0C,
        0x05,
        0x55,
        0x00, // speed 8.5 km/h
        0x39,
        0x30,
        0x00, // distance 1234.5 m
        0x0F,
        0x00,
        0x00,
        0x00, // incline 1.5%
        0x96, // heart rate 150 bpm
        0xC8,
        0x00, // elapsed 200 seconds
      ]);

      final decoder = FtmsMetricDecoder();
      final metrics = decoder.parse(frame);

      expect(metrics.speedKmh, closeTo(8.5, 0.01));
      expect(metrics.distanceMeters, closeTo(1234.5, 0.1));
      expect(metrics.inclinePercent, closeTo(1.5, 0.01));
      expect(metrics.heartRate, 150);
      expect(metrics.elapsed, const Duration(seconds: 200));
    });

    test('returns zero metrics when payload is incomplete', () {
      final decoder = FtmsMetricDecoder();
      expect(decoder.parse(const [0x00]), TreadmillMetrics.zero);
    });
  });
}
