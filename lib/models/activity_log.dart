class ActivityLog {
  final int? activityId;
  final int greenhouseId;
  final int userId;
  final String keterangan;
  final int waktuKejadian;

  ActivityLog({
    this.activityId,
    required this.greenhouseId,
    required this.userId,
    required this.keterangan,
    required this.waktuKejadian,
  });

  Map<String, dynamic> toMap() {
    return {
      if (activityId != null) 'activity_id': activityId,
      'greenhouse_id': greenhouseId,
      'user_id': userId,
      'keterangan': keterangan,
      'waktu_kejadian': waktuKejadian,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      activityId: map['activity_id'],
      greenhouseId: map['greenhouse_id'],
      userId: map['user_id'],
      keterangan: map['keterangan'],
      waktuKejadian: map['waktu_kejadian'],
    );
  }
}
