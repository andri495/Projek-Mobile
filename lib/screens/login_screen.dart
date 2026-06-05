import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../models/greenhouse.dart';
import '../models/device.dart';
import '../models/automation_rule.dart';
import '../models/sensor_log.dart';
import '../models/activity_log.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _tab = 'masuk'; // 'masuk' | 'daftar'
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String _error = '';
  bool _loading = false;
  bool _googleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = '';
    });

    try {
      // Step 1: Trigger Google account picker
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // pastikan dialog pilih akun selalu muncul
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan
        setState(() => _googleLoading = false);
        return;
      }

      // Step 2: Ambil auth credentials dari Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 3: Sign in ke Firebase
      final fb.UserCredential userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        setState(() => _error = 'Login Google gagal, coba lagi.');
        return;
      }

      if (!mounted) return;
      final provider = context.read<AppProvider>();
      final db = provider.db;

      // Step 4: Cek apakah email sudah ada di DB lokal
      User? existingUser = await db.getUserByEmail(firebaseUser.email ?? '');

      int userId;
      if (existingUser != null) {
        // Akun sudah ada → langsung login
        userId = existingUser.userId!;
      } else {
        // Akun baru → buat dari data Firebase
        final photoUrl = firebaseUser.photoURL ??
            'https://i.pravatar.cc/150?u=${firebaseUser.email}';
        userId = await db.insertUser(User(
          namaLengkap: firebaseUser.displayName ?? 'Pengguna Google',
          email: firebaseUser.email ?? '',
          password: 'firebase_oauth_${firebaseUser.uid}',
          peran: 'Pemilik Lahan',
          fotoProfil: photoUrl,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        // Buat greenhouse default
        final ghId = await db.insertGreenhouse(Greenhouse(
          userId: userId,
          namaLahan: 'Rumah Kaca Pertama',
          lokasi: 'Lembang',
          mqttTopic: 'sg/gh_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
        final kipasId = await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Kipas Pendingin',
          statusSaatIni: 'off',
          tipeAlat: 'kipas',
        ));
        final embunId = await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Semprotan Embun',
          statusSaatIni: 'off',
          tipeAlat: 'embun',
        ));
        await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Pompa Air',
          statusSaatIni: 'off',
          tipeAlat: 'pompa',
        ));
        await db.insertRule(AutomationRule(
          greenhouseId: ghId,
          parameter: 'suhu',
          kondisi: '>',
          nilaiAmbang: 32.0,
          deviceId: kipasId,
          statusAktif: true,
        ));
        await db.insertRule(AutomationRule(
          greenhouseId: ghId,
          parameter: 'kelembaban',
          kondisi: '<',
          nilaiAmbang: 60.0,
          deviceId: embunId,
          statusAktif: true,
        ));
        final now = DateTime.now().millisecondsSinceEpoch;
        for (int i = 24; i >= 0; i--) {
          await db.insertSensorLog(SensorLog(
            greenhouseId: ghId,
            suhu: 25.0 + (DateTime.now().microsecond % 10).toDouble(),
            kelembaban: 50.0 + (DateTime.now().microsecond % 30).toDouble(),
            waktuCatat: now - (i * 3600 * 1000),
          ));
        }
        await db.insertSensorLog(SensorLog(
          greenhouseId: ghId,
          suhu: 28.0,
          kelembaban: 70.0,
          waktuCatat: now + 1000,
        ));
        await db.insertActivityLog(ActivityLog(
          greenhouseId: ghId,
          userId: userId,
          keterangan:
              'Masuk via Google (Firebase): ${firebaseUser.displayName}',
          waktuKejadian: now,
        ));
      }

      // Step 5: Simpan session & login ke app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);
      if (!mounted) return;
      await provider.login(userId);
    } on fb.FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Login Google gagal.';
        if (e.code == 'account-exists-with-different-credential') {
          msg = 'Email ini sudah digunakan dengan metode login lain.';
        } else if (e.code == 'network-request-failed') {
          msg = 'Tidak ada koneksi internet.';
        }
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Login Google gagal: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _error = '';
      _loading = true;
    });

    final provider = context.read<AppProvider>();
    final db = provider.db;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_tab == 'masuk') {
        final user = await db.getUserByEmail(email);
        if (user != null && user.password == password) {
          await provider.login(user.userId!);
        } else {
          setState(() => _error = 'Email atau sandi salah');
        }
      } else {
        // Register
        final existing = await db.getUserByEmail(email);
        if (existing != null) {
          setState(() => _error = 'Email sudah terdaftar');
          return;
        }
        final nama = _namaController.text.trim().isEmpty
            ? 'Pengguna Baru'
            : _namaController.text.trim();

        final newUserId = await db.insertUser(User(
          namaLengkap: nama,
          email: email,
          password: password,
          peran: 'Pemilik Lahan',
          fotoProfil: 'https://i.pravatar.cc/150?u=$email',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        final ghId = await db.insertGreenhouse(Greenhouse(
          userId: newUserId,
          namaLahan: 'Rumah Kaca Baru',
          lokasi: 'Lembang',
          mqttTopic: 'sg/gh_new',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        final kipasId = await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Kipas Pendingin',
          statusSaatIni: 'on',
          tipeAlat: 'kipas',
        ));
        final embunId = await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Semprotan Embun',
          statusSaatIni: 'off',
          tipeAlat: 'embun',
        ));
        await db.insertDevice(Device(
          greenhouseId: ghId,
          namaAlat: 'Pompa Air',
          statusSaatIni: 'off',
          tipeAlat: 'pompa',
        ));

        await db.insertRule(AutomationRule(
          greenhouseId: ghId,
          parameter: 'suhu',
          kondisi: '>',
          nilaiAmbang: 32.0,
          deviceId: kipasId,
          statusAktif: true,
        ));
        await db.insertRule(AutomationRule(
          greenhouseId: ghId,
          parameter: 'kelembaban',
          kondisi: '<',
          nilaiAmbang: 60.0,
          deviceId: embunId,
          statusAktif: true,
        ));

        final now = DateTime.now().millisecondsSinceEpoch;
        for (int i = 24; i >= 0; i--) {
          await db.insertSensorLog(SensorLog(
            greenhouseId: ghId,
            suhu: 25.0 + (DateTime.now().microsecond % 10).toDouble(),
            kelembaban: 50.0 + (DateTime.now().microsecond % 30).toDouble(),
            waktuCatat: now - (i * 3600 * 1000),
          ));
        }
        await db.insertSensorLog(SensorLog(
          greenhouseId: ghId,
          suhu: 28.0,
          kelembaban: 70.0,
          waktuCatat: now + 1000,
        ));

        await db.insertActivityLog(ActivityLog(
          greenhouseId: ghId,
          userId: newUserId,
          keterangan: 'Lahan perlahan dibuat',
          waktuKejadian: now,
        ));

        await provider.login(newUserId);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF047857),
                  Color(0xFF059669),
                  Color(0xFF10B981)
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Logo + branding
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SmartGreen',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Solusi Cerdas Pertanian Modern',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main White Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(isDark),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tab switcher
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgDarker(isDark),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _TabButton(
                                  label: 'Masuk',
                                  isActive: _tab == 'masuk',
                                  onTap: () => setState(() {
                                    _tab = 'masuk';
                                    _error = '';
                                  }),
                                  isDark: isDark,
                                ),
                                _TabButton(
                                  label: 'Daftar',
                                  isActive: _tab == 'daftar',
                                  onTap: () => setState(() {
                                    _tab = 'daftar';
                                    _error = '';
                                  }),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Form Fields
                          if (_tab == 'daftar') ...[
                            _FormField(
                                label: 'Nama Lengkap',
                                isDark: isDark,
                                child: _TextField(
                                  controller: _namaController,
                                  placeholder: 'Misal: Budi Santoso',
                                  keyboardType: TextInputType.name,
                                  icon: Icons.person_outline_rounded,
                                  isDark: isDark,
                                )),
                            const SizedBox(height: 16),
                          ],
                          _FormField(
                              label: 'Alamat E-mail',
                              isDark: isDark,
                              child: _TextField(
                                controller: _emailController,
                                placeholder: 'hello@example.com',
                                keyboardType: TextInputType.emailAddress,
                                icon: Icons.email_outlined,
                                isDark: isDark,
                              )),
                          const SizedBox(height: 16),
                          _FormField(
                            label: 'Kata Sandi',
                            isDark: isDark,
                            trailing: _tab == 'masuk'
                                ? GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Lupa Sandi?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                            child: _PasswordField(
                              controller: _passwordController,
                              showPassword: _showPassword,
                              onToggle: () => setState(
                                  () => _showPassword = !_showPassword),
                              isDark: isDark,
                            ),
                          ),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2).withValues(alpha: isDark ? 0.1 : 1.0),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFFECACA).withValues(alpha: isDark ? 0.2 : 1.0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Color(0xFFEF4444), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          // Submit button
                          _SubmitButton(
                            loading: _loading,
                            label: _tab == 'masuk'
                                ? 'MASUK SEKARANG'
                                : 'BUAT AKUN',
                            onPressed: _handleSubmit,
                          ),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: AppColors.divider(isDark))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'ATAU',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint(isDark),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: AppColors.divider(isDark))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google Sign-In button
                          _GoogleSignInButton(
                            loading: _googleLoading,
                            onPressed: _handleGoogleSignIn,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widgets start here

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _TabButton(
      {required this.label, required this.isActive, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cardBg(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: AppColors.shadow(isDark),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color:
                  isActive ? (isDark ? AppColors.primaryLight : AppColors.primary) : AppColors.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  final bool isDark;

  const _FormField({required this.label, required this.child, this.trailing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted(isDark),
                letterSpacing: 1.0,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final IconData icon;
  final bool isDark;

  const _TextField({
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDark),
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: AppColors.textHint(isDark),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.cardBgLighter(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(icon, color: AppColors.textHint(isDark), size: 20),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool showPassword;
  final VoidCallback onToggle;
  final bool isDark;

  const _PasswordField({
    required this.controller,
    required this.showPassword,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(isDark),
      ),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: TextStyle(
            color: AppColors.textHint(isDark), fontWeight: FontWeight.w500),
        filled: true,
        fillColor: AppColors.cardBgLighter(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: AppColors.textHint(isDark), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: AppColors.textHint(isDark),
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton(
      {required this.loading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF047857), Color(0xFF10B981)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 1.0),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final bool isDark;

  const _GoogleSignInButton({required this.loading, required this.onPressed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(isDark), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(isDark),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    Text(
                      'Lanjutkan dengan Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Logo Google 'G' berwarna menggunakan CustomPainter
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Lingkaran putih sebagai base
    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);

    // Gambar 'G' Google dengan 4 warna
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Biru (kanan atas + kanan bawah)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.52, 1.04, true, paint);

    // Merah (kiri atas)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.62, 1.22, true, paint);

    // Kuning (bawah)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.52, 1.05, true, paint);

    // Hijau (kiri bawah)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.57, 1.05, true, paint);

    // Bar horizontal Google (putih tengah + bar kanan)
    paint.color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTWH(size.width * 0.5, size.height * 0.38,
        size.width * 0.48, size.height * 0.24);
    canvas.drawRect(barRect, paint);

    // Lingkaran putih di tengah untuk efek 'G'
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // Titik tengah kecil berwarna untuk 'G' shaft
    paint.color = const Color(0xFF4285F4);
    final shaftRect = Rect.fromLTWH(size.width * 0.5, size.height * 0.38,
        size.width * 0.47, size.height * 0.24);
    canvas.drawRect(shaftRect, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
