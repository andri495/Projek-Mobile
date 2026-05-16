import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../widgets/toggle_switch.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifEnabled = true;
  String _tempFormat = 'Celcius';
  String? _toastMessage;
  bool _showGHModal = false;
  bool _showAddModal = false;
  final _lahanController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _lahanController.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final provider = context.read<AppProvider>();
      // Store file path as foto_profil URL
      await provider.updateUserPhoto(picked.path);
      _showToast('Foto profil berhasil diperbarui');
    }
  }

  Future<void> _addLahan() async {
    if (_lahanController.text.trim().isEmpty) return;
    setState(() => _isAdding = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.addGreenhouse(_lahanController.text.trim());
      _lahanController.clear();
      setState(() => _showAddModal = false);
      _showToast('Lahan baru berhasil ditambahkan');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final greenhouses = provider.greenhouses;

    if (user == null) return const Scaffold(backgroundColor: Colors.white, body: SizedBox.shrink());

    final isNetworkPhoto = user.fotoProfil.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _AppHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16)],
                              ),
                              child: ClipOval(
                                child: isNetworkPhoto
                                    ? Image.network(user.fotoProfil, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _AvatarFallback(user.namaLengkap))
                                    : Image.file(File(user.fotoProfil), fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _AvatarFallback(user.namaLengkap)),
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF059669),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.circle, color: Colors.white, size: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.namaLengkap, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(
                        user.peran.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 32),

                      // Menu sections
                      _MenuSection(title: 'KELOLA LAHAN', children: [
                        _MenuItem(icon: Icons.show_chart_rounded, label: 'Daftar Rumah Kaca', onTap: () => setState(() => _showGHModal = true)),
                        _MenuItem(icon: Icons.add_circle_outline_rounded, label: 'Tambah Lahan Baru',
                            iconColor: const Color(0xFF059669), onTap: () => setState(() => _showAddModal = true)),
                      ]),
                      const SizedBox(height: 20),

                      _MenuSection(title: 'PENGATURAN APLIKASI', children: [
                        _MenuItem(
                          icon: Icons.notifications_rounded, label: 'Notifikasi & Peringatan',
                          onTap: () => setState(() => _notifEnabled = !_notifEnabled),
                          trailing: ToggleSwitch(checked: _notifEnabled, onChange: () => setState(() => _notifEnabled = !_notifEnabled)),
                        ),
                        _MenuItem(
                          icon: Icons.settings_rounded, label: 'Format Suhu (°C / °F)',
                          onTap: () => setState(() => _tempFormat = _tempFormat == 'Celcius' ? 'Fahrenheit' : 'Celcius'),
                          trailing: Text(_tempFormat, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      _MenuSection(title: 'BANTUAN', children: [
                        _MenuItem(icon: Icons.info_outline_rounded, label: 'Panduan Penggunaan',
                            onTap: () => _showToast('Membuka panduan penggunaan...')),
                      ]),
                      const SizedBox(height: 32),

                      // Logout button
                      OutlinedButton(
                        onPressed: () => provider.logout(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFFEE2E2), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: const Color(0xFFEF4444),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // GH Modal
          if (_showGHModal)
            _GreenhouseModal(
              greenhouses: greenhouses.map((g) => {'name': g.namaLahan, 'topic': g.mqttTopic}).toList(),
              onClose: () => setState(() => _showGHModal = false),
            ),

          // Add Lahan Modal
          if (_showAddModal)
            _AddLahanModal(
              controller: _lahanController,
              isAdding: _isAdding,
              onClose: () { _lahanController.clear(); setState(() => _showAddModal = false); },
              onSave: _addLahan,
            ),

          // Toast
          if (_toastMessage != null)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: _Toast(message: _toastMessage!),
            ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFECFDF5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _MenuSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 16, color: Color(0xFFF8FAFC)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.trailing, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
            if (trailing != null) trailing!
            else const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _GreenhouseModal extends StatelessWidget {
  final List<Map<String, String>> greenhouses;
  final VoidCallback onClose;
  const _GreenhouseModal({required this.greenhouses, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Daftar Rumah Kaca', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)), onPressed: onClose),
              ]),
              const SizedBox(height: 12),
              if (greenhouses.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Belum ada lahan.', style: TextStyle(color: Color(0xFF94A3B8)))),
              ...greenhouses.map((gh) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(gh['name']!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(gh['topic']!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ]),
              )),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF1E293B),
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLahanModal extends StatelessWidget {
  final TextEditingController controller;
  final bool isAdding;
  final VoidCallback onClose, onSave;
  const _AddLahanModal({required this.controller, required this.isAdding, required this.onClose, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tambah Lahan Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)), onPressed: onClose),
              ]),
              const SizedBox(height: 16),
              const Text('NAMA LAHAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Misal: Rumah Kaca B',
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isAdding ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isAdding ? 'Menyimpan...' : 'Simpan Lahan', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  final String message;
  const _Toast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Text('ℹ️', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB)))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(children: [
              Icon(Icons.eco_rounded, size: 22, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('SmartGreen', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
            ]),
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
