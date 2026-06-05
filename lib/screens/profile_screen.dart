import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/greenhouse.dart';
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
  bool _showEditModal = false;

  Greenhouse? _editingGreenhouse;
  final _lahanController = TextEditingController();
  final _editLahanController = TextEditingController();

  bool _isAdding = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _lahanController.dispose();
    _editLahanController.dispose();
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

  Future<void> _editLahan() async {
    if (_editLahanController.text.trim().isEmpty || _editingGreenhouse == null)
      return;
    setState(() => _isEditing = true);
    try {
      final provider = context.read<AppProvider>();
      await provider.updateGreenhouse(
          _editingGreenhouse!.greenhouseId!, _editLahanController.text.trim());
      _editLahanController.clear();
      setState(() {
        _showEditModal = false;
        _editingGreenhouse = null;
        _showGHModal = true; // Buka kembali list setelah edit
      });
      _showToast('Lahan berhasil diperbarui');
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  Future<void> _deleteLahan(Greenhouse gh) async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Lahan?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${gh.namaLahan}"? Semua data alat dan riwayat pada lahan ini akan terhapus.',
            style: const TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<AppProvider>();
      await provider.deleteGreenhouse(gh.greenhouseId!);
      _showToast('Lahan berhasil dihapus');
      if (provider.greenhouses.length <= 1) {
        // since it's already deleted in db but provider might update later
        // wait for refresh
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && provider.greenhouses.isEmpty) {
            setState(() => _showGHModal = false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final greenhouses = provider.greenhouses;

    if (user == null)
      return const Scaffold(
          backgroundColor: Color(0xFFF6F8FB), body: SizedBox.shrink());

    final isNetworkPhoto = user.fotoProfil.startsWith('http');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header & Profile Avatar ──
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 60),
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
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: const SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Profil Pengguna',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Avatar Box
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFF6F8FB), width: 6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: ClipOval(
                                  child: isNetworkPhoto
                                      ? Image.network(user.fotoProfil,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _AvatarFallback(user.namaLengkap))
                                      : Image.file(File(user.fotoProfil),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _AvatarFallback(
                                                  user.namaLengkap)),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: Color(0xFF059669), size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.namaLengkap,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.peran.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                                letterSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Menu Sections ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: [
                      _MenuSection(title: 'KELOLA LAHAN', children: [
                        _MenuItem(
                            icon: Icons.grid_view_rounded,
                            label: 'Daftar Rumah Kaca',
                            onTap: () => setState(() => _showGHModal = true)),
                        _MenuItem(
                            icon: Icons.add_business_rounded,
                            label: 'Tambah Lahan Baru',
                            iconColor: const Color(0xFF059669),
                            onTap: () => setState(() => _showAddModal = true)),
                      ]),
                      const SizedBox(height: 24),

                      _MenuSection(title: 'PENGATURAN APLIKASI', children: [
                        _MenuItem(
                          icon: Icons.notifications_active_rounded,
                          label: 'Notifikasi & Peringatan',
                          onTap: () =>
                              setState(() => _notifEnabled = !_notifEnabled),
                          trailing: ToggleSwitch(
                              checked: _notifEnabled,
                              onChange: () => setState(
                                  () => _notifEnabled = !_notifEnabled)),
                        ),
                        _MenuItem(
                          icon: Icons.thermostat_rounded,
                          label: 'Format Suhu',
                          onTap: () => setState(() => _tempFormat =
                              _tempFormat == 'Celcius'
                                  ? 'Fahrenheit'
                                  : 'Celcius'),
                          trailing: Row(
                            children: [
                              Text(_tempFormat,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              const Icon(Icons.swap_horiz_rounded,
                                  size: 16, color: Color(0xFFCBD5E1)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _MenuSection(title: 'BANTUAN', children: [
                        _MenuItem(
                            icon: Icons.help_outline_rounded,
                            label: 'Panduan Penggunaan',
                            onTap: () =>
                                _showToast('Membuka panduan penggunaan...')),
                      ]),
                      const SizedBox(height: 40),

                      // Logout button
                      GestureDetector(
                        onTap: () => provider.logout(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFECACA), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 20, color: Color(0xFFEF4444)),
                              SizedBox(width: 10),
                              Text('KELUAR AKUN',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEF4444),
                                      letterSpacing: 0.5,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // GH Modal (List with CRUD)
          if (_showGHModal)
            _GreenhouseModal(
              greenhouses: greenhouses,
              onClose: () => setState(() => _showGHModal = false),
              onEdit: (gh) {
                _editLahanController.text = gh.namaLahan;
                setState(() {
                  _editingGreenhouse = gh;
                  _showEditModal = true;
                  _showGHModal = false;
                });
              },
              onDelete: _deleteLahan,
            ),

          // Add Lahan Modal
          if (_showAddModal)
            _AddLahanModal(
              controller: _lahanController,
              isAdding: _isAdding,
              onClose: () {
                _lahanController.clear();
                setState(() => _showAddModal = false);
              },
              onSave: _addLahan,
            ),

          // Edit Lahan Modal
          if (_showEditModal)
            _EditLahanModal(
              controller: _editLahanController,
              isEditing: _isEditing,
              onClose: () {
                _editLahanController.clear();
                setState(() {
                  _showEditModal = false;
                  _showGHModal = true;
                });
              },
              onSave: _editLahan,
            ),

          // Toast
          if (_toastMessage != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
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
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      )),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Color(0xFF047857)),
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
          child: Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 52,
                        endIndent: 20,
                        color: Color(0xFFF1F5F9)),
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

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.trailing,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF64748B))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: iconColor ?? const Color(0xFF64748B)),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155)))),
            if (trailing != null)
              trailing!
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _GreenhouseModal extends StatelessWidget {
  final List<Greenhouse> greenhouses;
  final VoidCallback onClose;
  final void Function(Greenhouse) onEdit;
  final void Function(Greenhouse) onDelete;

  const _GreenhouseModal({
    required this.greenhouses,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grid_view_rounded,
                          size: 18, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Daftar Rumah Kaca',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B))),
                  ],
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              if (greenhouses.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('Belum ada lahan.',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500)))),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: greenhouses
                        .map((gh) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.eco_rounded,
                                        color: Color(0xFF059669), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(gh.namaLahan,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B))),
                                          const SizedBox(height: 4),
                                          Text('Topik: ${gh.mqttTopic}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500)),
                                        ]),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded,
                                            size: 18, color: Color(0xFF64748B)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => onEdit(gh),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFEF4444)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => onDelete(gh),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
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

class _AddLahanModal extends StatelessWidget {
  final TextEditingController controller;
  final bool isAdding;
  final VoidCallback onClose, onSave;
  const _AddLahanModal(
      {required this.controller,
      required this.isAdding,
      required this.onClose,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_business_rounded,
                                size: 18, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Lahan Baru',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ]),
                const SizedBox(height: 24),
                const Text('NAMA LAHAN BARU',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Misal: Rumah Kaca B',
                    hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF059669), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 28),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final isEnabled =
                        controller.text.trim().isNotEmpty && !isAdding;
                    return GestureDetector(
                      onTap: isEnabled ? onSave : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isEnabled
                              ? const LinearGradient(colors: [
                                  Color(0xFF047857),
                                  Color(0xFF10B981)
                                ])
                              : null,
                          color: isEnabled ? null : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            isAdding ? 'Menyimpan...' : 'Simpan Lahan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isEnabled
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditLahanModal extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onClose, onSave;
  const _EditLahanModal(
      {required this.controller,
      required this.isEditing,
      required this.onClose,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.5),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 18, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Edit Lahan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B))),
                        ],
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ]),
                const SizedBox(height: 24),
                const Text('NAMA LAHAN BARU',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Misal: Rumah Kaca B',
                    hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF059669), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 28),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final isEnabled =
                        controller.text.trim().isNotEmpty && !isEditing;
                    return GestureDetector(
                      onTap: isEnabled ? onSave : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isEnabled
                              ? const LinearGradient(colors: [
                                  Color(0xFF047857),
                                  Color(0xFF10B981)
                                ])
                              : null,
                          color: isEnabled ? null : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            isEditing ? 'Menyimpan...' : 'Perbarui Lahan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isEnabled
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
