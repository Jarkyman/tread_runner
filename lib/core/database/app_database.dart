import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/treadmill_device.dart';
import '../../domain/models/workout_plan.dart';
import '../../domain/models/workout_session.dart';

class AppDatabase {
  AppDatabase(this.isar);

  final Isar isar;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        WorkoutPlanSchema,
        WorkoutSessionSchema,
        TreadmillDeviceSchema,
      ],
      directory: dir.path,
    );
    return AppDatabase(isar);
  }

  Future<void> close() async {
    if (isar.isOpen) {
      await isar.close();
    }
  }
}
