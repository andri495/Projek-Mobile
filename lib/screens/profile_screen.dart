import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/greenhouse.dart';
import '../widgets/toggle_switch.dart';
import '../utils/app_colors.dart';

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

  String _language = 'Indonesia';

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
    final provider = context.read<AppProvider>();
    final isDark = provider.isDarkMode;
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Lahan?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textPrimary(isDark))),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${gh.namaLahan}"? Semua data alat dan riwayat pada lahan ini akan terhapus.',
            style: TextStyle(color: AppColors.textSecondary(isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: AppColors.textMuted(isDark), fontWeight: FontWeight.w700)),
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
    final isDark = provider.isDarkMode;

    if (user == null) {
      return Scaffold(
          backgroundColor: AppColors.background(isDark), body: const SizedBox.shrink());
    }

    final isNetworkPhoto = user.fotoProfil.startsWith('http');

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
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
                                      color: AppColors.background(isDark), width: 6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                                    color: AppColors.cardBg(isDark),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: AppColors.primary, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.namaLengkap,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary(isDark),
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
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
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
                      _MenuSection(title: 'KELOLA LAHAN', isDark: isDark, children: [
                        _MenuItem(
                            icon: Icons.grid_view_rounded,
                            label: 'Daftar Rumah Kaca',
                            onTap: () => setState(() => _showGHModal = true),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.add_business_rounded,
                            label: 'Tambah Lahan Baru',
                            iconColor: AppColors.primary,
                            onTap: () => setState(() => _showAddModal = true),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.group_add_rounded,
                            label: 'Berbagi Akses Lahan',
                            onTap: () => _showToast('Membuka pengaturan akses...'),
                            isDark: isDark),
                      ]),
                      const SizedBox(height: 24),

                      _MenuSection(title: 'PREFERENSI', isDark: isDark, children: [
                        _MenuItem(
                          icon: Icons.notifications_active_rounded,
                          label: 'Notifikasi & Peringatan',
                          onTap: () =>
                              setState(() => _notifEnabled = !_notifEnabled),
                          trailing: ToggleSwitch(
                              checked: _notifEnabled,
                              onChange: () => setState(
                                  () => _notifEnabled = !_notifEnabled)),
                          isDark: isDark,
                        ),
                        _MenuItem(
                          icon: Icons.dark_mode_rounded,
                          label: 'Mode Gelap',
                          onTap: () => provider.toggleDarkMode(),
                          trailing: ToggleSwitch(
                              checked: isDark,
                              onChange: () => provider.toggleDarkMode()),
                          isDark: isDark,
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
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary(isDark),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Icon(Icons.swap_horiz_rounded,
                                  size: 16, color: AppColors.textHint(isDark)),
                            ],
                          ),
                          isDark: isDark,
                        ),
                        _MenuItem(
                          icon: Icons.language_rounded,
                          label: 'Bahasa',
                          onTap: () => setState(() => _language =
                              _language == 'Indonesia'
                                  ? 'English'
                                  : 'Indonesia'),
                          trailing: Row(
                            children: [
                              Text(_language,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary(isDark),
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Icon(Icons.swap_horiz_rounded,
                                  size: 16, color: AppColors.textHint(isDark)),
                            ],
                          ),
                          isDark: isDark,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _MenuSection(title: 'INTEGRASI & LANJUTAN', isDark: isDark, children: [
                        _MenuItem(
                            icon: Icons.mic_rounded,
                            label: 'Integrasi Asisten Pintar',
                            onTap: () => _showToast('Menghubungkan ke Google/Alexa...'),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.picture_as_pdf_rounded,
                            label: 'Ekspor Data Laporan',
                            onTap: () => _showToast('Menyiapkan dokumen laporan...'),
                            isDark: isDark),
                      ]),
                      const SizedBox(height: 24),

                      _MenuSection(title: 'KEAMANAN & BANTUAN', isDark: isDark, children: [
                        _MenuItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Ganti Kata Sandi',
                            onTap: () => _showToast('Membuka pengaturan keamanan...'),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.help_outline_rounded,
                            label: 'Panduan Penggunaan',
                            onTap: () =>
                                _showToast('Membuka panduan penggunaan...'),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.support_agent_rounded,
                            label: 'Hubungi Dukungan',
                            onTap: () => _showToast('Menghubungkan ke CS...'),
                            isDark: isDark),
                        _MenuItem(
                            icon: Icons.info_outline_rounded,
                            label: 'Tentang Aplikasi',
                            onTap: () => _showToast('Smart Greenhouse v1.0.0'),
                            isDark: isDark),
                      ]),
                      const SizedBox(height: 40),

                      // Logout button
                      GestureDetector(
                        onTap: () => provider.logout(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFECACA).withValues(alpha: isDark ? 0.2 : 1), width: 1.5),
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
              isDark: isDark,
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
              isDark: isDark,
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
              isDark: isDark,
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
  final bool isDark;
  const _MenuSection({required this.title, required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHint(isDark),
                  letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(isDark),
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
                    Divider(
                        height: 1,
                        indent: 52,
                        endIndent: 20,
                        color: AppColors.divider(isDark)),
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
  final bool isDark;

  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.trailing,
      this.iconColor,
      required this.isDark});

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
                color: (iconColor ?? AppColors.textSecondary(isDark))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: iconColor ?? AppColors.textSecondary(isDark)),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDark)))),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textHint(isDark)),
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
  final bool isDark;

  const _GreenhouseModal({
    required this.greenhouses,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
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
              color: AppColors.cardBg(isDark),
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
                        color: AppColors.primaryBg(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grid_view_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Daftar Rumah Kaca',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(isDark))),
                  ],
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLighter(isDark),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary(isDark)),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              if (greenhouses.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('Belum ada lahan.',
                            style: TextStyle(
                                color: AppColors.textHint(isDark),
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
                                color: AppColors.cardBg(isDark),
                                border:
                                    Border.all(color: AppColors.border(isDark)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          AppColors.shadow(isDark),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.cardBgDarker(isDark),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.eco_rounded,
                                        color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(gh.namaLahan,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary(isDark))),
                                          const SizedBox(height: 4),
                                          Text('Topik: ${gh.mqttTopic}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary(isDark),
                                                  fontWeight: FontWeight.w500)),
                                        ]),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_rounded,
                                            size: 18, color: AppColors.textSecondary(isDark)),
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
  final bool isDark;
  const _AddLahanModal(
      {required this.controller,
      required this.isAdding,
      required this.onClose,
      required this.onSave,
      required this.isDark});

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
                color: AppColors.cardBg(isDark),
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
                              color: AppColors.primaryBg(isDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_business_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text('Lahan Baru',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(isDark))),
                        ],
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLighter(isDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary(isDark)),
                        ),
                      ),
                    ]),
                const SizedBox(height: 24),
                Text('NAMA LAHAN BARU',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted(isDark),
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Misal: Rumah Kaca B',
                    hintStyle: TextStyle(
                        color: AppColors.textHint(isDark), fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: AppColors.cardBgDarker(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border(isDark))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border(isDark))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                          color: isEnabled ? null : AppColors.border(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: isDark ? 0.4 : 0.3),
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
                                  : AppColors.textSecondary(isDark),
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
  final bool isDark;
  const _EditLahanModal(
      {required this.controller,
      required this.isEditing,
      required this.onClose,
      required this.onSave,
      required this.isDark});

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
                color: AppColors.cardBg(isDark),
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
                              color: AppColors.primaryBg(isDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text('Edit Lahan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(isDark))),
                        ],
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLighter(isDark),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary(isDark)),
                        ),
                      ),
                    ]),
                const SizedBox(height: 24),
                Text('NAMA LAHAN BARU',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted(isDark),
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    hintText: 'Misal: Rumah Kaca B',
                    hintStyle: TextStyle(
                        color: AppColors.textHint(isDark), fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: AppColors.cardBgDarker(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border(isDark))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border(isDark))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                          color: isEnabled ? null : AppColors.border(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF059669)
                                          .withValues(alpha: isDark ? 0.4 : 0.3),
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
                                  : AppColors.textSecondary(isDark),
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
