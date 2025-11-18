import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// FTMS UUID helpers and constants used by the treadmill client.
class FtmsConstants {
  FtmsConstants._();

  /// FTMS primary service UUID (0x1826).
  static final Uuid service = uuidFromShort(0x1826);

  /// Treadmill Data characteristic (0x2ACD) - notify.
  static final Uuid treadmillData = uuidFromShort(0x2ACD);

  /// Indoor Bike Data characteristic (0x2AD2) - notify (fallback metrics).
  static final Uuid indoorBikeData = uuidFromShort(0x2AD2);

  /// Fitness Machine Feature characteristic (0x2ACC) - read.
  static final Uuid fitnessMachineFeature = uuidFromShort(0x2ACC);

  /// Fitness Machine Control Point characteristic (0x2AD9) - write + indicate.
  static final Uuid controlPoint = uuidFromShort(0x2AD9);

  /// Fitness Machine Status characteristic (0x2ADA) - notify.
  static final Uuid fitnessMachineStatus = uuidFromShort(0x2ADA);

  /// Training Status characteristic (0x2AD3) - read + notify.
  static final Uuid trainingStatus = uuidFromShort(0x2AD3);

  /// Supported Speed Range characteristic (0x2AD4) - read.
  static final Uuid supportedSpeedRange = uuidFromShort(0x2AD4);

  /// Supported Incline Range characteristic (0x2AD5) - read.
  static final Uuid supportedInclineRange = uuidFromShort(0x2AD5);

  /// Converts a 16-bit Bluetooth SIG UUID to the 128-bit variant expected by
  /// [flutter_reactive_ble].
  static Uuid uuidFromShort(int shortUuid) {
    return Uuid.parse(to128BitUuid(shortUuid));
  }

  /// Builds the canonical 128-bit FTMS UUID string from a 16-bit definition.
  static String to128BitUuid(int shortUuid) {
    final hex = shortUuid.toRadixString(16).padLeft(4, '0');
    return '0000$hex-0000-1000-8000-00805f9b34fb';
  }
}
