class Device {
  final int? deviceId;
  final int greenhouseId;
  final String namaAlat;
  final String statusSaatIni; // 'on' | 'off'
  final String tipeAlat; // 'kipas' | 'embun' | 'pompa'

  Device({
    this.deviceId,
    required this.greenhouseId,
    required this.namaAlat,
    required this.statusSaatIni,
    required this.tipeAlat,
  });

  bool get isOn => statusSaatIni == 'on';

  Map<String, dynamic> toMap() {
    return {
      if (deviceId != null) 'device_id': deviceId,
      'greenhouse_id': greenhouseId,
      'nama_alat': namaAlat,
      'status_saat_ini': statusSaatIni,
      'tipe_alat': tipeAlat,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      deviceId: map['device_id'],
      greenhouseId: map['greenhouse_id'],
      namaAlat: map['nama_alat'],
      statusSaatIni: map['status_saat_ini'],
      tipeAlat: map['tipe_alat'],
    );
  }

  Device copyWith({
    int? deviceId,
    int? greenhouseId,
    String? namaAlat,
    String? statusSaatIni,
    String? tipeAlat,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      greenhouseId: greenhouseId ?? this.greenhouseId,
      namaAlat: namaAlat ?? this.namaAlat,
      statusSaatIni: statusSaatIni ?? this.statusSaatIni,
      tipeAlat: tipeAlat ?? this.tipeAlat,
    );
  }
}
