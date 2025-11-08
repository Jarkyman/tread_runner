import 'package:isar/isar.dart';

part 'treadmill_device.g.dart';

@collection
class TreadmillDevice {
  TreadmillDevice({
    this.id = Isar.autoIncrement,
    required this.deviceId,
    required this.name,
    this.connectionState = TreadmillConnectionState.disconnected,
    this.supportsSpeed = true,
    this.supportsIncline = false,
    this.supportsHeartRate = false,
  });

  Id id;

  /// Platform identifier returned by BLE scans.
  late String deviceId;

  late String name;

  @Enumerated(EnumType.name)
  TreadmillConnectionState connectionState;

  bool supportsSpeed;
  bool supportsIncline;
  bool supportsHeartRate;
}

enum TreadmillConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}
