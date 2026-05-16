import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/gauge_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final activeGreenhouse = provider.activeGreenhouse;
    final sensorData = provider.latestSensorLog;
    final devices = provider.devices;

    if (user == null || activeGreenhouse == null) {
      return const _NoGreenhouseView();
    }

    final firstName = user.namaLengkap.split(' ').first;
    final kipas = devices.where((d) => d.tipeAlat == 'kipas').firstOrNull;
    final embun = devices.where((d) => d.tipeAlat == 'embun').firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Greeting
                    Text(
                      'Halo, $firstName!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lahan selector
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.read<AppProvider>().setTab('profil'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF059669)),
                                const SizedBox(width: 6),
                                Text(
                                  'Lahan: ${activeGreenhouse.namaLahan}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('▼', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          _PulsingDot(),
                          const SizedBox(width: 8),
                          const Text(
                            'ALAT: TERHUBUNG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gauges
                    Row(
                      children: [
                        GaugeWidget(
                          value: sensorData?.suhu ?? 0,
                          max: 50,
                          label: 'Suhu Udara',
                          icon: Icons.eco_rounded,
                          color: const Color(0xFF059669),
                          trackColor: const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(width: 16),
                        GaugeWidget(
                          value: sensorData?.kelembaban ?? 0,
                          max: 100,
                          label: 'Lembab Udara',
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF0D9488),
                          trackColor: const Color(0xFFF1F5F9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Alert card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kabar Lahan: Suhu Normal & Aman',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Semua indikator lingkungan berada dalam batas optimal.',
                                  style: TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            label: 'Nyalakan\nKipas',
                            subLabel: 'Manual:\n${kipas?.statusSaatIni == 'on' ? 'Aktif' : 'Nonaktif'}',
                            icon: Icons.air_rounded,
                            isOn: kipas?.statusSaatIni == 'on',
                            activeColor: const Color(0xFF059669),
                            activeBg: const Color(0xFFECFDF5),
                            activeBorder: const Color(0xFF6EE7B7),
                            onTap: kipas != null ? () => provider.toggleDevice(kipas) : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionButton(
                            label: 'Nyalakan\nEmbun',
                            subLabel: 'Manual:\n${embun?.statusSaatIni == 'on' ? 'Aktif' : 'Nonaktif'}',
                            icon: Icons.water_drop_rounded,
                            isOn: embun?.statusSaatIni == 'on',
                            activeColor: const Color(0xFF0D9488),
                            activeBg: const Color(0xFFF0FDFA),
                            activeBorder: const Color(0xFF99F6E4),
                            onTap: embun != null ? () => provider.toggleDevice(embun) : null,
                          ),
                        ),
                      ],
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

class _NoGreenhouseView extends StatelessWidget {
  const _NoGreenhouseView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_rounded, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'Belum ada lahan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Akun Anda tidak memiliki lahan aktif. Silahkan buat akun baru atau masuk dengan akun default.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.eco_rounded, size: 22, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text(
                  'SmartGreen',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF475569)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Menu navigasi akan segera hadir'),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.8 * _anim.value),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool isOn;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.isOn,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOn ? activeBg : Colors.white,
          border: Border.all(
            color: isOn ? activeBorder : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOn ? activeColor.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: isOn ? activeColor : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
