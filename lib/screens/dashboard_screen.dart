import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final activeGreenhouse = provider.activeGreenhouse;
    final sensorData = provider.latestSensorLog;
    final devices = provider.devices;
    final isDark = provider.isDarkMode;

    if (user == null || activeGreenhouse == null) {
      return const _NoGreenhouseView();
    }

    final firstName = user.namaLengkap.split(' ').first;
    final kipas = devices.where((d) => d.tipeAlat == 'kipas').firstOrNull;
    final embun = devices.where((d) => d.tipeAlat == 'embun').firstOrNull;

    final suhu = sensorData?.suhu ?? 0;
    final kelembaban = sensorData?.kelembaban ?? 0;

    // Determine status
    final bool isNormal =
        suhu <= 35 && suhu >= 15 && kelembaban >= 40 && kelembaban <= 90;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [
          // ── Gradient Header ──
          _GradientHeader(
              firstName: firstName, lahanName: activeGreenhouse.namaLahan),
          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Connection Status ──
                    _ConnectionBadge(isDark: isDark),
                    const SizedBox(height: 20),

                    // ── Sensor Cards Row ──
                    Row(
                      children: [
                        Expanded(
                          child: _SensorCard(
                            value: suhu,
                            unit: '°C',
                            label: 'Suhu Udara',
                            icon: Icons.thermostat_rounded,
                            gradientColors: const [
                              Color(0xFFFF6B6B),
                              Color(0xFFFF8E53)
                            ],
                            bgColor: isDark ? const Color(0xFF3F1919) : const Color(0xFFFFF5F5),
                            max: 50,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SensorCard(
                            value: kelembaban,
                            unit: '%',
                            label: 'Kelembaban',
                            icon: Icons.water_drop_rounded,
                            gradientColors: const [
                              Color(0xFF4FACFE),
                              Color(0xFF00F2FE)
                            ],
                            bgColor: isDark ? const Color(0xFF132F42) : const Color(0xFFF0F9FF),
                            max: 100,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Status Card ──
                    _StatusCard(isNormal: isNormal, isDark: isDark),
                    const SizedBox(height: 22),

                    // ── Quick Actions ──
                    Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Kipas',
                            subtitle: kipas?.statusSaatIni == 'on'
                                ? 'Aktif'
                                : 'Nonaktif',
                            icon: Icons.air_rounded,
                            isOn: kipas?.statusSaatIni == 'on',
                            activeGradient: const [
                              Color(0xFF059669),
                              Color(0xFF34D399)
                            ],
                            onTap: kipas != null
                                ? () => provider.toggleDevice(kipas)
                                : null,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Embun',
                            subtitle: embun?.statusSaatIni == 'on'
                                ? 'Aktif'
                                : 'Nonaktif',
                            icon: Icons.water_drop_rounded,
                            isOn: embun?.statusSaatIni == 'on',
                            activeGradient: const [
                              Color(0xFF0D9488),
                              Color(0xFF5EEAD4)
                            ],
                            onTap: embun != null
                                ? () => provider.toggleDevice(embun)
                                : null,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

// ═══════════════════════════════════════════════════
// Gradient Header
// ═══════════════════════════════════════════════════
class _GradientHeader extends StatelessWidget {
  final String firstName;
  final String lahanName;

  const _GradientHeader({required this.firstName, required this.lahanName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: logo + menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'SmartGreen',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('Menu navigasi akan segera hadir'),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Greeting
              Text(
                'Halo, $firstName! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Lahan selector
              GestureDetector(
                onTap: () => context.read<AppProvider>().setTab('profil'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFFD1FAE5)),
                      const SizedBox(width: 6),
                      Text(
                        lahanName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD1FAE5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: Color(0xFFD1FAE5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Connection Badge
// ═══════════════════════════════════════════════════
class _ConnectionBadge extends StatefulWidget {
  final bool isDark;
  const _ConnectionBadge({required this.isDark});

  @override
  State<_ConnectionBadge> createState() => _ConnectionBadgeState();
}

class _ConnectionBadgeState extends State<_ConnectionBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(widget.isDark),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF10B981).withValues(alpha: 0.4),
                  const Color(0xFF10B981),
                  _anim.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981)
                        .withValues(alpha: 0.5 * _anim.value),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ALAT TERHUBUNG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryBg(widget.isDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Online',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Sensor Card
// ═══════════════════════════════════════════════════
class _SensorCard extends StatelessWidget {
  final double value;
  final String unit;
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final Color bgColor;
  final double max;
  final bool isDark;

  const _SensorCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.bgColor,
    required this.max,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : gradientColors[0].withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: gradientColors[0]),
          ),
          const SizedBox(height: 14),
          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, animValue, __) => Text(
                  '${animValue.round()}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(isDark),
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: gradientColors[0],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, animProgress, __) => Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    color: bgColor,
                  ),
                  FractionallySizedBox(
                    widthFactor: animProgress,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Status Card
// ═══════════════════════════════════════════════════
class _StatusCard extends StatelessWidget {
  final bool isNormal;
  final bool isDark;

  const _StatusCard({required this.isNormal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        isNormal ? const Color(0xFF047857) : const Color(0xFFDC2626);
    final Color lightColor =
        isNormal ? const Color(0xFF10B981) : const Color(0xFFF87171);
    final String title = isNormal
        ? 'Kabar Lahan: Suhu Normal & Aman'
        : 'Peringatan: Parameter Tidak Normal';
    final String subtitle = isNormal
        ? 'Semua indikator lingkungan berada dalam batas optimal.'
        : 'Cek parameter suhu dan kelembaban segera.';
    final IconData statusIcon =
        isNormal ? Icons.check_circle_rounded : Icons.warning_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, lightColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : bgColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Quick Action Card
// ═══════════════════════════════════════════════════
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOn;
  final List<Color> activeGradient;
  final VoidCallback? onTap;
  final bool isDark;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOn,
    required this.activeGradient,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn
                ? activeGradient[0].withValues(alpha: 0.3)
                : AppColors.border(isDark),
            width: 1.5,
          ),
          boxShadow: [
            if (isOn)
              BoxShadow(
                color: activeGradient[0].withValues(alpha: isDark ? 0.2 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppColors.shadow(isDark),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            // Icon with gradient background when ON
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isOn
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: activeGradient,
                      )
                    : null,
                color: isOn ? null : AppColors.cardBgLighter(isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isOn ? Colors.white : AppColors.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isOn ? activeGradient[0] : AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 4),
            // Status pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isOn
                    ? activeGradient[0].withValues(alpha: 0.1)
                    : AppColors.cardBgDarker(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isOn ? activeGradient[0] : AppColors.textSecondary(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// No Greenhouse View
// ═══════════════════════════════════════════════════
class _NoGreenhouseView extends StatelessWidget {
  const _NoGreenhouseView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg(isDark),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.eco_rounded,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum ada lahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Akun Anda tidak memiliki lahan aktif.\nSilahkan buat akun baru atau masuk\ndengan akun default.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted(isDark),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
