import 'package:get/get.dart';
import 'package:matricmate/data/database/local_db_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService extends GetxController {
  static Database? _db;
  static DatabaseService get instance => Get.find();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "matricmate.db");

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await DBschema.create(db);
      },
    );
  }
}
