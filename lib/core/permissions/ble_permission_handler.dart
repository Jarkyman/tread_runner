import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum BlePermissionStatus { unknown, granted, denied, permanentlyDenied }

class BlePermissionHandler {
  const BlePermissionHandler();

  Future<BlePermissionStatus> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return BlePermissionStatus.granted;
    }

    final permissions = <Permission>[];
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
      ]);
      permissions.add(Permission.locationWhenInUse);
    } else if (Platform.isIOS) {
      permissions.add(Permission.bluetooth);
    }

    if (permissions.isEmpty) {
      return BlePermissionStatus.granted;
    }

    final results = await permissions.request();

    if (results.values.every((status) => status.isGranted)) {
      return BlePermissionStatus.granted;
    }

    if (results.values.any((status) => status.isPermanentlyDenied)) {
      return BlePermissionStatus.permanentlyDenied;
    }

    return BlePermissionStatus.denied;
  }

  Future<bool> openSystemSettings() {
    return openAppSettings();
  }
}
