import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../models/greenhouse.dart';
import '../models/device.dart';
import '../models/automation_rule.dart';
import '../models/sensor_log.dart';
import '../models/activity_log.dart';
import '../models/plant_preset.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  int? _currentUserId;
  String _currentTab = 'beranda';
  bool _isSeeded = false;
  bool _isDarkMode = false;

  // Live data
  User? _user;
  List<Greenhouse> _greenhouses = [];
  List<Device> _devices = [];
  List<AutomationRule> _rules = [];
  List<SensorLog> _sensorLogs = [];
  List<ActivityLog> _activityLogs = [];
  List<PlantPreset> _presets = [];
  SensorLog? _latestSensorLog;

  // Getters
  int? get currentUserId => _currentUserId;
  String get currentTab => _currentTab;
  bool get isSeeded => _isSeeded;
  bool get isDarkMode => _isDarkMode;
  User? get user => _user;
  List<Greenhouse> get greenhouses => _greenhouses;
  Greenhouse? get activeGreenhouse => _greenhouses.isNotEmpty ? _greenhouses.first : null;
  List<Device> get devices => _devices;
  List<AutomationRule> get rules => _rules;
  List<SensorLog> get sensorLogs => _sensorLogs;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<PlantPreset> get presets => _presets;
  SensorLog? get latestSensorLog => _latestSensorLog;

  DatabaseHelper get db => _db;

  Future<void> initialize() async {
    await _db.seedDatabase();
    _isSeeded = true;

    // Listen to DB changes
    _db.onDatabaseChange.listen((table) {
      _refreshData();
    });

    notifyListeners();
  }

  Future<void> login(int userId) async {
    _currentUserId = userId;
    await _refreshData();
    notifyListeners();
  }

  void logout() {
    _currentUserId = null;
    _currentTab = 'beranda';
    _user = null;
    _greenhouses = [];
    _devices = [];
    _rules = [];
    _sensorLogs = [];
    _activityLogs = [];
    _presets = [];
    _latestSensorLog = null;
    notifyListeners();
  }

  void setTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> _refreshData() async {
    if (_currentUserId == null) return;

    _user = await _db.getUserById(_currentUserId!);
    _greenhouses = await _db.getGreenhousesByUserId(_currentUserId!);
    _presets = await _db.getAllPresets();

    if (_greenhouses.isNotEmpty) {
      final ghId = _greenhouses.first.greenhouseId!;
      _devices = await _db.getDevicesByGreenhouseId(ghId);
      _rules = await _db.getRulesByGreenhouseId(ghId);
      _sensorLogs = await _db.getSensorLogs(ghId);
      _activityLogs = await _db.getActivityLogs(ghId);
      _latestSensorLog = await _db.getLatestSensorLog(ghId);
    }

    notifyListeners();
  }

  Future<void> refreshAll() async {
    await _refreshData();
  }

  // ========================
  // Device actions
  // ========================
  Future<void> toggleDevice(Device device) async {
    if (_user == null || activeGreenhouse == null) return;
    final newStatus = device.statusSaatIni == 'on' ? 'off' : 'on';
    await _db.updateDevice(device.deviceId!, {'status_saat_ini': newStatus});

    final firstName = _user!.namaLengkap.split(' ').first;
    await _db.insertActivityLog(ActivityLog(
      greenhouseId: activeGreenhouse!.greenhouseId!,
      userId: _currentUserId!,
      keterangan:
          '$firstName ${newStatus == 'on' ? 'menyalakan' : 'mematikan'} ${device.namaAlat} manual',
      waktuKejadian: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  // ========================
  // Rule actions
  // ========================
  Future<void> toggleRule(int ruleId, bool currentStatus) async {
    await _db.updateRule(ruleId, {'status_aktif': currentStatus ? 0 : 1});
  }

  Future<void> applyPreset(PlantPreset preset) async {
    if (activeGreenhouse == null) return;
    await _db.updateGreenhouse(
      activeGreenhouse!.greenhouseId!,
      {'active_preset_id': preset.presetId},
    );
    final suhuRule = _rules.where((r) => r.parameter == 'suhu').firstOrNull;
    if (suhuRule != null) {
      await _db.updateRule(suhuRule.ruleId!, {'nilai_ambang': preset.batasSuhu});
    }
    final lembabRule = _rules.where((r) => r.parameter == 'kelembaban').firstOrNull;
    if (lembabRule != null) {
      await _db.updateRule(lembabRule.ruleId!, {'nilai_ambang': preset.batasKelembaban});
    }
  }

  Future<void> savePreset({
    required String namaTanaman,
    required double batasSuhu,
    required double batasKelembaban,
    int? editingPresetId,
  }) async {
    if (namaTanaman.trim().isEmpty) return;
    if (editingPresetId != null) {
      await _db.updatePreset(editingPresetId, {
        'nama_tanaman': namaTanaman,
        'batas_suhu': batasSuhu,
        'batas_kelembaban': batasKelembaban,
      });
    } else {
      await _db.insertPreset(PlantPreset(
        userId: _currentUserId,
        namaTanaman: namaTanaman,
        batasSuhu: batasSuhu,
        batasKelembaban: batasKelembaban,
      ));
    }
  }

  Future<void> deletePreset(int presetId) async {
    await _db.deletePreset(presetId);
    if (activeGreenhouse?.activePresetId == presetId) {
      await _db.updateGreenhouse(
        activeGreenhouse!.greenhouseId!,
        {'active_preset_id': null},
      );
    }
  }

  // ========================
  // Greenhouse actions
  // ========================
  Future<void> addGreenhouse(String namaLahan) async {
    if (_currentUserId == null || namaLahan.trim().isEmpty) return;
    final ghId = await _db.insertGreenhouse(Greenhouse(
      userId: _currentUserId!,
      namaLahan: namaLahan,
      lokasi: 'Lokasi Baru',
      mqttTopic: 'sg/gh_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    final kipasId = await _db.insertDevice(Device(
      greenhouseId: ghId,
      namaAlat: 'Kipas Pendingin',
      statusSaatIni: 'off',
      tipeAlat: 'kipas',
    ));
    final embunId = await _db.insertDevice(Device(
      greenhouseId: ghId,
      namaAlat: 'Semprotan Embun',
      statusSaatIni: 'off',
      tipeAlat: 'embun',
    ));
    await _db.insertDevice(Device(
      greenhouseId: ghId,
      namaAlat: 'Pompa Air',
      statusSaatIni: 'off',
      tipeAlat: 'pompa',
    ));

    await _db.insertRule(AutomationRule(
      greenhouseId: ghId,
      parameter: 'suhu',
      kondisi: '>',
      nilaiAmbang: 32.0,
      deviceId: kipasId,
      statusAktif: true,
    ));
    await _db.insertRule(AutomationRule(
      greenhouseId: ghId,
      parameter: 'kelembaban',
      kondisi: '<',
      nilaiAmbang: 60.0,
      deviceId: embunId,
      statusAktif: true,
    ));

    final now = DateTime.now().millisecondsSinceEpoch;
    final rng = DateTime.now().microsecond;
    for (int i = 24; i >= 0; i--) {
      await _db.insertSensorLog(SensorLog(
        greenhouseId: ghId,
        suhu: 25.0 + (rng % 10).toDouble(),
        kelembaban: 50.0 + (rng % 30).toDouble(),
        waktuCatat: now - (i * 3600 * 1000),
      ));
    }

    await _db.insertActivityLog(ActivityLog(
      greenhouseId: ghId,
      userId: _currentUserId!,
      keterangan: 'Lahan $namaLahan berhasil dibuat',
      waktuKejadian: now,
    ));
  }

  Future<void> updateGreenhouse(int greenhouseId, String namaLahanBaru) async {
    if (namaLahanBaru.trim().isEmpty) return;
    await _db.updateGreenhouse(greenhouseId, {'nama_lahan': namaLahanBaru});
  }

  Future<void> deleteGreenhouse(int greenhouseId) async {
    await _db.deleteGreenhouse(greenhouseId);
  }

  // ========================
  // User actions
  // ========================
  Future<void> updateUserPhoto(String photoUrl) async {
    if (_currentUserId == null) return;
    await _db.updateUser(_currentUserId!, {'foto_profil': photoUrl});
  }
}
