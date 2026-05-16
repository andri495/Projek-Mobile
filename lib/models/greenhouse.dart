class Greenhouse {
  final int? greenhouseId;
  final int userId;
  final String namaLahan;
  final String lokasi;
  final String mqttTopic;
  final int? activePresetId;
  final int createdAt;

  Greenhouse({
    this.greenhouseId,
    required this.userId,
    required this.namaLahan,
    required this.lokasi,
    required this.mqttTopic,
    this.activePresetId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (greenhouseId != null) 'greenhouse_id': greenhouseId,
      'user_id': userId,
      'nama_lahan': namaLahan,
      'lokasi': lokasi,
      'mqtt_topic': mqttTopic,
      'active_preset_id': activePresetId,
      'created_at': createdAt,
    };
  }

  factory Greenhouse.fromMap(Map<String, dynamic> map) {
    return Greenhouse(
      greenhouseId: map['greenhouse_id'],
      userId: map['user_id'],
      namaLahan: map['nama_lahan'],
      lokasi: map['lokasi'],
      mqttTopic: map['mqtt_topic'],
      activePresetId: map['active_preset_id'],
      createdAt: map['created_at'],
    );
  }

  Greenhouse copyWith({
    int? greenhouseId,
    int? userId,
    String? namaLahan,
    String? lokasi,
    String? mqttTopic,
    int? activePresetId,
    bool clearActivePreset = false,
    int? createdAt,
  }) {
    return Greenhouse(
      greenhouseId: greenhouseId ?? this.greenhouseId,
      userId: userId ?? this.userId,
      namaLahan: namaLahan ?? this.namaLahan,
      lokasi: lokasi ?? this.lokasi,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      activePresetId: clearActivePreset ? null : (activePresetId ?? this.activePresetId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
