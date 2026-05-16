class User {
  final int? userId;
  final String namaLengkap;
  final String email;
  final String? password;
  final String peran;
  final String fotoProfil;
  final int createdAt;

  User({
    this.userId,
    required this.namaLengkap,
    required this.email,
    this.password,
    required this.peran,
    required this.fotoProfil,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'user_id': userId,
      'nama_lengkap': namaLengkap,
      'email': email,
      'password': password,
      'peran': peran,
      'foto_profil': fotoProfil,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      namaLengkap: map['nama_lengkap'],
      email: map['email'],
      password: map['password'],
      peran: map['peran'],
      fotoProfil: map['foto_profil'],
      createdAt: map['created_at'],
    );
  }

  User copyWith({
    int? userId,
    String? namaLengkap,
    String? email,
    String? password,
    String? peran,
    String? fotoProfil,
    int? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      password: password ?? this.password,
      peran: peran ?? this.peran,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
