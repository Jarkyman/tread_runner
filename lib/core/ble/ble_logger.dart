import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Tags used when logging BLE related events.
enum BleLogTag {
  scan,
  connect,
  discover,
  ftms,
  control;

  String get label => name.toUpperCase();
}

/// Lightweight logger that keeps FTMS BLE logs tidy and masks sensitive data.
class BleLogger {
  BleLogger({
    this.enabled = true,
    this.maskDeviceIds = true,
    this.printer,
  });

  final bool enabled;
  final bool maskDeviceIds;
  final void Function(String message)? printer;
  final Set<String> _loggedCharacteristics = <String>{};

  void log(
    BleLogTag tag,
    String message, {
    String? deviceId,
  }) {
    if (!enabled) return;
    final buffer = StringBuffer('[${tag.label}] ');
    if (deviceId != null) {
      buffer.write('${_mask(deviceId)} ');
    }
    buffer.write(message);
    final line = buffer.toString();
    developer.log(line, name: 'BLE');
    (printer ?? debugPrint)(line);
  }

  /// Logs the fact that a characteristic was discovered once per session.
  void logCharacteristic({
    required BleLogTag tag,
    required Uuid serviceId,
    required Uuid characteristicId,
    String? deviceId,
  }) {
    if (!enabled) return;
    final key = '${serviceId.toString()}::${characteristicId.toString()}';
    if (_loggedCharacteristics.contains(key)) return;
    _loggedCharacteristics.add(key);
    log(
      tag,
      'Characteristic ${characteristicId.toString()} in service ${serviceId.toString()}',
      deviceId: deviceId,
    );
  }

  String _mask(String input) {
    if (!maskDeviceIds || input.length <= 4) {
      return input;
    }
    final prefix = input.substring(0, 4);
    final suffix = input.substring(input.length - 2);
    return '$prefix…$suffix';
  }
}
