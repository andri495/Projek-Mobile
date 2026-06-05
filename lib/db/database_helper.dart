import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/greenhouse.dart';
import '../models/device.dart';
import '../models/automation_rule.dart';
import '../models/sensor_log.dart';
import '../models/activity_log.dart';
import '../models/plant_preset.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Stream controllers for live query simulation
  final _changeController = StreamController<String>.broadcast();
  Stream<String> get onDatabaseChange => _changeController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_green.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_lengkap TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT,
        peran TEXT NOT NULL,
        foto_profil TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE greenhouses (
        greenhouse_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama_lahan TEXT NOT NULL,
        lokasi TEXT NOT NULL,
        mqtt_topic TEXT NOT NULL,
        active_preset_id INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE devices (
        device_id INTEGER PRIMARY KEY AUTOINCREMENT,
        greenhouse_id INTEGER NOT NULL,
        nama_alat TEXT NOT NULL,
        status_saat_ini TEXT NOT NULL,
        tipe_alat TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE automation_rules (
        rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
        greenhouse_id INTEGER NOT NULL,
        parameter TEXT NOT NULL,
        kondisi TEXT NOT NULL,
        nilai_ambang REAL NOT NULL,
        device_id INTEGER NOT NULL,
        status_aktif INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE sensor_logs (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        greenhouse_id INTEGER NOT NULL,
        suhu REAL NOT NULL,
        kelembaban REAL NOT NULL,
        waktu_catat INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
        greenhouse_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        keterangan TEXT NOT NULL,
        waktu_kejadian INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_presets (
        preset_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        nama_tanaman TEXT NOT NULL,
        batas_suhu REAL NOT NULL,
        batas_kelembaban REAL NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // plant_presets already created in onCreate for version 2
    }
  }

  void _notifyChange(String table) {
    _changeController.add(table);
  }

  // ========================
  // SEED DATABASE
  // ========================
  Future<void> seedDatabase() async {
    final db = await database;
    final rng = Random();

    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    ) ?? 0;

    if (userCount == 0) {
      final userId = await db.insert('users', {
        'nama_lengkap': 'Budi Santoso',
        'email': 'budi@example.com',
        'password': 'password123',
        'peran': 'Pemilik Lahan',
        'foto_profil': 'https://i.pravatar.cc/150?u=budi',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final greenhouseId = await db.insert('greenhouses', {
        'user_id': userId,
        'nama_lahan': 'Rumah Kaca A (Melon)',
        'lokasi': 'Lembang',
        'mqtt_topic': 'sg/gh1',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final kipasId = await db.insert('devices', {
        'greenhouse_id': greenhouseId,
        'nama_alat': 'Kipas Pendingin',
        'status_saat_ini': 'on',
        'tipe_alat': 'kipas',
      });
      final embunId = await db.insert('devices', {
        'greenhouse_id': greenhouseId,
        'nama_alat': 'Semprotan Embun',
        'status_saat_ini': 'off',
        'tipe_alat': 'embun',
      });
      await db.insert('devices', {
        'greenhouse_id': greenhouseId,
        'nama_alat': 'Pompa Air',
        'status_saat_ini': 'off',
        'tipe_alat': 'pompa',
      });

      await db.insert('automation_rules', {
        'greenhouse_id': greenhouseId,
        'parameter': 'suhu',
        'kondisi': '>',
        'nilai_ambang': 32.0,
        'device_id': kipasId,
        'status_aktif': 1,
      });
      await db.insert('automation_rules', {
        'greenhouse_id': greenhouseId,
        'parameter': 'kelembaban',
        'kondisi': '<',
        'nilai_ambang': 60.0,
        'device_id': embunId,
        'status_aktif': 1,
      });

      // Seed 24 hours of sensor logs
      final now = DateTime.now().millisecondsSinceEpoch;
      for (int i = 24; i >= 0; i--) {
        await db.insert('sensor_logs', {
          'greenhouse_id': greenhouseId,
          'suhu': 25.0 + rng.nextDouble() * 10.0,
          'kelembaban': 50.0 + rng.nextDouble() * 30.0,
          'waktu_catat': now - (i * 3600 * 1000),
        });
      }
      // Target specific current value
      await db.insert('sensor_logs', {
        'greenhouse_id': greenhouseId,
        'suhu': 28.0,
        'kelembaban': 70.0,
        'waktu_catat': now + 1000,
      });

      // Seed activity logs
      await db.insert('activity_logs', {
        'greenhouse_id': greenhouseId,
        'user_id': userId,
        'keterangan': 'Sistem menyalakan kipas pendingin (Suhu capai 32°C)',
        'waktu_kejadian': now - (2 * 3600 * 1000),
      });
      await db.insert('activity_logs', {
        'greenhouse_id': greenhouseId,
        'user_id': userId,
        'keterangan': 'Pak Budi menyalakan pompa irigasi manual',
        'waktu_kejadian': now - (5 * 3600 * 1000),
      });
      await db.insert('activity_logs', {
        'greenhouse_id': greenhouseId,
        'user_id': userId,
        'keterangan': 'Sistem mematikan kipas pendingin (Suhu turun 28°C)',
        'waktu_kejadian': now - (8 * 3600 * 1000),
      });
    }

    final presetCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM plant_presets'),
    ) ?? 0;

    if (presetCount == 0) {
      await db.insert('plant_presets', {
        'user_id': null,
        'nama_tanaman': 'Preset Melon',
        'batas_suhu': 32.0,
        'batas_kelembaban': 60.0,
      });
    }
  }

  // ========================
  // USER METHODS
  // ========================
  Future<User?> getUserById(int userId) async {
    final db = await database;
    final maps = await db.query('users', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    _notifyChange('users');
    return id;
  }

  Future<void> updateUser(int userId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('users', values, where: 'user_id = ?', whereArgs: [userId]);
    _notifyChange('users');
  }

  // ========================
  // GREENHOUSE METHODS
  // ========================
  Future<List<Greenhouse>> getGreenhousesByUserId(int userId) async {
    final db = await database;
    final maps = await db.query('greenhouses', where: 'user_id = ?', whereArgs: [userId]);
    return maps.map((m) => Greenhouse.fromMap(m)).toList();
  }

  Future<int> insertGreenhouse(Greenhouse gh) async {
    final db = await database;
    final id = await db.insert('greenhouses', gh.toMap());
    _notifyChange('greenhouses');
    return id;
  }

  Future<void> updateGreenhouse(int greenhouseId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('greenhouses', values, where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    _notifyChange('greenhouses');
  }

  Future<void> deleteGreenhouse(int greenhouseId) async {
    final db = await database;
    await db.delete('greenhouses', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    // Also delete associated devices, rules, logs, etc if needed. Or keep it simple.
    // Let's cascade delete related entities to avoid orphans
    await db.delete('devices', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    await db.delete('automation_rules', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    await db.delete('sensor_logs', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    await db.delete('activity_logs', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    _notifyChange('greenhouses');
  }

  // ========================
  // DEVICE METHODS
  // ========================
  Future<List<Device>> getDevicesByGreenhouseId(int greenhouseId) async {
    final db = await database;
    final maps = await db.query('devices', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    return maps.map((m) => Device.fromMap(m)).toList();
  }

  Future<int> insertDevice(Device device) async {
    final db = await database;
    final id = await db.insert('devices', device.toMap());
    _notifyChange('devices');
    return id;
  }

  Future<void> updateDevice(int deviceId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('devices', values, where: 'device_id = ?', whereArgs: [deviceId]);
    _notifyChange('devices');
  }

  // ========================
  // AUTOMATION RULE METHODS
  // ========================
  Future<List<AutomationRule>> getRulesByGreenhouseId(int greenhouseId) async {
    final db = await database;
    final maps = await db.query('automation_rules', where: 'greenhouse_id = ?', whereArgs: [greenhouseId]);
    return maps.map((m) => AutomationRule.fromMap(m)).toList();
  }

  Future<int> insertRule(AutomationRule rule) async {
    final db = await database;
    final id = await db.insert('automation_rules', rule.toMap());
    _notifyChange('automation_rules');
    return id;
  }

  Future<void> updateRule(int ruleId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('automation_rules', values, where: 'rule_id = ?', whereArgs: [ruleId]);
    _notifyChange('automation_rules');
  }

  // ========================
  // SENSOR LOG METHODS
  // ========================
  Future<SensorLog?> getLatestSensorLog(int greenhouseId) async {
    final db = await database;
    final maps = await db.query(
      'sensor_logs',
      where: 'greenhouse_id = ?',
      whereArgs: [greenhouseId],
      orderBy: 'waktu_catat DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SensorLog.fromMap(maps.first);
  }

  Future<List<SensorLog>> getSensorLogs(int greenhouseId) async {
    final db = await database;
    final maps = await db.query(
      'sensor_logs',
      where: 'greenhouse_id = ?',
      whereArgs: [greenhouseId],
      orderBy: 'waktu_catat ASC',
    );
    return maps.map((m) => SensorLog.fromMap(m)).toList();
  }

  Future<int> insertSensorLog(SensorLog log) async {
    final db = await database;
    final id = await db.insert('sensor_logs', log.toMap());
    _notifyChange('sensor_logs');
    return id;
  }

  // ========================
  // ACTIVITY LOG METHODS
  // ========================
  Future<List<ActivityLog>> getActivityLogs(int greenhouseId) async {
    final db = await database;
    final maps = await db.query(
      'activity_logs',
      where: 'greenhouse_id = ?',
      whereArgs: [greenhouseId],
      orderBy: 'waktu_kejadian DESC',
    );
    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }

  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;
    final id = await db.insert('activity_logs', log.toMap());
    _notifyChange('activity_logs');
    return id;
  }

  // ========================
  // PLANT PRESET METHODS
  // ========================
  Future<List<PlantPreset>> getAllPresets() async {
    final db = await database;
    final maps = await db.query('plant_presets');
    return maps.map((m) => PlantPreset.fromMap(m)).toList();
  }

  Future<int> insertPreset(PlantPreset preset) async {
    final db = await database;
    final id = await db.insert('plant_presets', preset.toMap());
    _notifyChange('plant_presets');
    return id;
  }

  Future<void> updatePreset(int presetId, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('plant_presets', values, where: 'preset_id = ?', whereArgs: [presetId]);
    _notifyChange('plant_presets');
  }

  Future<void> deletePreset(int presetId) async {
    final db = await database;
    await db.delete('plant_presets', where: 'preset_id = ?', whereArgs: [presetId]);
    _notifyChange('plant_presets');
  }

  void dispose() {
    _changeController.close();
  }
}
