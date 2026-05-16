class SensorLog {
  final int? logId;
  final int greenhouseId;
  final double suhu;
  final double kelembaban;
  final int waktuCatat;

  SensorLog({
    this.logId,
    required this.greenhouseId,
    required this.suhu,
    required this.kelembaban,
    required this.waktuCatat,
  });

  Map<String, dynamic> toMap() {
    return {
      if (logId != null) 'log_id': logId,
      'greenhouse_id': greenhouseId,
      'suhu': suhu,
      'kelembaban': kelembaban,
      'waktu_catat': waktuCatat,
    };
  }

  factory SensorLog.fromMap(Map<String, dynamic> map) {
    return SensorLog(
      logId: map['log_id'],
      greenhouseId: map['greenhouse_id'],
      suhu: (map['suhu'] as num).toDouble(),
      kelembaban: (map['kelembaban'] as num).toDouble(),
      waktuCatat: map['waktu_catat'],
    );
  }
}
