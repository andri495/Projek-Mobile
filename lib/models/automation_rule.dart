class AutomationRule {
  final int? ruleId;
  final int greenhouseId;
  final String parameter; // 'suhu' | 'kelembaban'
  final String kondisi; // '>' | '<'
  final double nilaiAmbang;
  final int deviceId;
  final bool statusAktif;

  AutomationRule({
    this.ruleId,
    required this.greenhouseId,
    required this.parameter,
    required this.kondisi,
    required this.nilaiAmbang,
    required this.deviceId,
    required this.statusAktif,
  });

  Map<String, dynamic> toMap() {
    return {
      if (ruleId != null) 'rule_id': ruleId,
      'greenhouse_id': greenhouseId,
      'parameter': parameter,
      'kondisi': kondisi,
      'nilai_ambang': nilaiAmbang,
      'device_id': deviceId,
      'status_aktif': statusAktif ? 1 : 0,
    };
  }

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      ruleId: map['rule_id'],
      greenhouseId: map['greenhouse_id'],
      parameter: map['parameter'],
      kondisi: map['kondisi'],
      nilaiAmbang: (map['nilai_ambang'] as num).toDouble(),
      deviceId: map['device_id'],
      statusAktif: map['status_aktif'] == 1,
    );
  }

  AutomationRule copyWith({
    int? ruleId,
    int? greenhouseId,
    String? parameter,
    String? kondisi,
    double? nilaiAmbang,
    int? deviceId,
    bool? statusAktif,
  }) {
    return AutomationRule(
      ruleId: ruleId ?? this.ruleId,
      greenhouseId: greenhouseId ?? this.greenhouseId,
      parameter: parameter ?? this.parameter,
      kondisi: kondisi ?? this.kondisi,
      nilaiAmbang: nilaiAmbang ?? this.nilaiAmbang,
      deviceId: deviceId ?? this.deviceId,
      statusAktif: statusAktif ?? this.statusAktif,
    );
  }
}
