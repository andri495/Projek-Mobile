class PlantPreset {
  final int? presetId;
  final int? userId;
  final String namaTanaman;
  final double batasSuhu;
  final double batasKelembaban;

  PlantPreset({
    this.presetId,
    this.userId,
    required this.namaTanaman,
    required this.batasSuhu,
    required this.batasKelembaban,
  });

  Map<String, dynamic> toMap() {
    return {
      if (presetId != null) 'preset_id': presetId,
      'user_id': userId,
      'nama_tanaman': namaTanaman,
      'batas_suhu': batasSuhu,
      'batas_kelembaban': batasKelembaban,
    };
  }

  factory PlantPreset.fromMap(Map<String, dynamic> map) {
    return PlantPreset(
      presetId: map['preset_id'],
      userId: map['user_id'],
      namaTanaman: map['nama_tanaman'],
      batasSuhu: (map['batas_suhu'] as num).toDouble(),
      batasKelembaban: (map['batas_kelembaban'] as num).toDouble(),
    );
  }

  PlantPreset copyWith({
    int? presetId,
    int? userId,
    String? namaTanaman,
    double? batasSuhu,
    double? batasKelembaban,
  }) {
    return PlantPreset(
      presetId: presetId ?? this.presetId,
      userId: userId ?? this.userId,
      namaTanaman: namaTanaman ?? this.namaTanaman,
      batasSuhu: batasSuhu ?? this.batasSuhu,
      batasKelembaban: batasKelembaban ?? this.batasKelembaban,
    );
  }
}
