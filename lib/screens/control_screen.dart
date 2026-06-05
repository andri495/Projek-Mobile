import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/device.dart';
import '../widgets/toggle_switch.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String? _toastMessage;

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  IconData _getIcon(String tipe) {
    switch (tipe) {
      case 'kipas':
        return Icons.air_rounded;
      case 'embun':
        return Icons.water_drop_rounded;
      case 'pompa':
        return Icons.opacity_rounded;
      default:
        return Icons.device_hub_rounded;
    }
  }

  List<Color> _getGradient(String tipe, bool isOn) {
    if (!isOn) return [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)];
    switch (tipe) {
      case 'kipas':
        return [const Color(0xFF059669), const Color(0xFF34D399)];
      case 'embun':
        return [const Color(0xFF0D9488), const Color(0xFF5EEAD4)];
      case 'pompa':
        return [const Color(0xFF2563EB), const Color(0xFF60A5FA)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFFA78BFA)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeGreenhouse = provider.activeGreenhouse;
    final devices = provider.devices;

    if (activeGreenhouse == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.sensors_off_rounded,
                    size: 48, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum ada lahan',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──
              _ScreenHeader(
                title: 'Kendali Alat',
                subtitle: 'Kelola perangkat secara manual',
                icon: Icons.tune_rounded,
              ),
              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device summary
                      _DeviceSummaryBar(devices: devices),
                      const SizedBox(height: 20),
                      // Device list
                      ...devices.map((device) => _DeviceCard(
                            device: device,
                            icon: _getIcon(device.tipeAlat),
                            gradient:
                                _getGradient(device.tipeAlat, device.isOn),
                            onToggle: () async {
                              await provider.toggleDevice(device);
                              final newStatus = device.statusSaatIni == 'on'
                                  ? 'dimatikan'
                                  : 'dinyalakan';
                              _showToast(
                                '${device.namaAlat} sedang di$newStatus...',
                              );
                            },
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Toast
          if (_toastMessage != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _Toast(message: _toastMessage!),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Screen Header (shared style)
// ═══════════════════════════════════════════════════
class _ScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
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
// Device Summary Bar
// ═══════════════════════════════════════════════════
class _DeviceSummaryBar extends StatelessWidget {
  final List<Device> devices;

  const _DeviceSummaryBar({required this.devices});

  @override
  Widget build(BuildContext context) {
    final onCount = devices.where((d) => d.isOn).length;
    final totalCount = devices.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: onCount > 0
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.devices_rounded,
              size: 18,
              color: onCount > 0
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$onCount dari $totalCount alat aktif',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: onCount > 0
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              onCount > 0 ? 'Berjalan' : 'Standby',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: onCount > 0
                    ? const Color(0xFF059669)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Device Card
// ═══════════════════════════════════════════════════
class _DeviceCard extends StatelessWidget {
  final Device device;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onToggle;

  const _DeviceCard({
    required this.device,
    required this.icon,
    required this.gradient,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOn
              ? gradient[0].withValues(alpha: 0.2)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          if (isOn)
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Icon with gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isOn
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    )
                  : null,
              color: isOn ? null : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isOn ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.namaAlat,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOn
                        ? gradient[0].withValues(alpha: 0.1)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOn ? '● Sedang Menyala' : '○ Dimatikan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOn ? gradient[0] : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ToggleSwitch(checked: isOn, onChange: onToggle),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Toast
// ═══════════════════════════════════════════════════
class _Toast extends StatelessWidget {
  final String message;

  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_rounded,
                size: 16, color: Color(0xFF34D399)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
