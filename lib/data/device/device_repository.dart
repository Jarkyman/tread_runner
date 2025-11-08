import 'package:isar/isar.dart';

import '../../domain/models/treadmill_device.dart';

class DeviceRepository {
  DeviceRepository(this._isar);

  final Isar _isar;

  Stream<List<TreadmillDevice>> watchDevices() {
    return _isar.treadmillDevices.where().watch(fireImmediately: true);
  }

  Future<List<TreadmillDevice>> getDevices() {
    return _isar.treadmillDevices.where().findAll();
  }

  Future<TreadmillDevice?> getDeviceById(Id id) {
    return _isar.treadmillDevices.get(id);
  }

  Future<TreadmillDevice?> getDeviceByBleId(String deviceId) {
    return _isar.treadmillDevices
        .filter()
        .deviceIdEqualTo(deviceId)
        .findFirst();
  }

  Future<Id> saveDevice(TreadmillDevice device) {
    return _isar.writeTxn(() => _isar.treadmillDevices.put(device));
  }

  Future<void> deleteDevice(Id id) {
    return _isar.writeTxn(() => _isar.treadmillDevices.delete(id));
  }
}
