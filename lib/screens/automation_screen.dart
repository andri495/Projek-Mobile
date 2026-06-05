import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/plant_preset.dart';
import '../widgets/toggle_switch.dart';
import '../utils/app_colors.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  bool _masterToggle = true;
  bool _showAddPreset = false;
  int? _editingPresetId;
  final _namaController = TextEditingController();
  double _batasSuhu = 30;
  double _batasKelembaban = 60;

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _openAddPreset({PlantPreset? preset}) {
    if (preset != null) {
      _namaController.text = preset.namaTanaman;
      _batasSuhu = preset.batasSuhu;
      _batasKelembaban = preset.batasKelembaban;
      _editingPresetId = preset.presetId;
    } else {
      _namaController.clear();
      _batasSuhu = 30;
      _batasKelembaban = 60;
      _editingPresetId = null;
    }
    setState(() => _showAddPreset = true);
  }

  void _cancelEdit() {
    setState(() {
      _showAddPreset = false;
      _editingPresetId = null;
    });
  }

  Future<void> _savePreset() async {
    final provider = context.read<AppProvider>();
    await provider.savePreset(
      namaTanaman: _namaController.text,
      batasSuhu: _batasSuhu,
      batasKelembaban: _batasKelembaban,
      editingPresetId: _editingPresetId,
    );
    _cancelEdit();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeGreenhouse = provider.activeGreenhouse;
    final rules = provider.rules;
    final devices = provider.devices;
    final presets = provider.presets;
    final isDark = provider.isDarkMode;

    if (activeGreenhouse == null) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg(isDark),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_mode_rounded,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum ada lahan',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDark)),
              ),
            ],
          ),
        ),
      );
    }

    final suhuRule = rules.where((r) => r.parameter == 'suhu').firstOrNull;
    final lembabRule =
        rules.where((r) => r.parameter == 'kelembaban').firstOrNull;

    String getDeviceName(int deviceId) =>
        devices.where((d) => d.deviceId == deviceId).firstOrNull?.namaAlat ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──
              _ScreenHeader(
                title: 'Otomasi',
                subtitle: 'Atur batas aman secara otomatis',
                icon: Icons.auto_mode_rounded,
              ),
              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Master Toggle ──
                      _MasterToggleCard(
                        isOn: _masterToggle,
                        onToggle: () =>
                            setState(() => _masterToggle = !_masterToggle),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 22),

                      // ── Section Title ──
                      _SectionTitle(
                          title: 'Batas Aman', icon: Icons.shield_rounded, isDark: isDark),
                      const SizedBox(height: 14),

                      // ── Suhu Rule Card ──
                      if (suhuRule != null)
                        AnimatedOpacity(
                          opacity: _masterToggle ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_masterToggle,
                            child: _RuleCard(
                              icon: Icons.thermostat_rounded,
                              title: 'Batas Suhu',
                              condition:
                                  'Jika suhu ${suhuRule.kondisi == '>' ? 'lebih' : 'kurang'} dari',
                              value: suhuRule.nilaiAmbang.round(),
                              unit: '°C',
                              gradientColors: const [
                                Color(0xFFFF6B6B),
                                Color(0xFFFF8E53)
                              ],
                              bgColor: isDark ? const Color(0xFF3F1919) : const Color(0xFFFFF5F5),
                              sliderValue: suhuRule.nilaiAmbang,
                              sliderMin: 20,
                              sliderMax: 40,
                              sliderMinLabel: '20°C',
                              sliderMaxLabel: '40°C',
                              actionLabel:
                                  'Nyalakan ${getDeviceName(suhuRule.deviceId).replaceAll('Pendingin', '').trim()}',
                              isRuleActive: suhuRule.statusAktif,
                              onRuleToggle: () => provider.toggleRule(
                                  suhuRule.ruleId!, suhuRule.statusAktif),
                              isDark: isDark,
                            ),
                          ),
                        ),

                      // ── Kelembaban Rule Card ──
                      if (lembabRule != null)
                        AnimatedOpacity(
                          opacity: _masterToggle ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_masterToggle,
                            child: _RuleCard(
                              icon: Icons.water_drop_rounded,
                              title: 'Batas Kelembaban',
                              condition:
                                  'Jika lembap ${lembabRule.kondisi == '<' ? 'kurang' : 'lebih'} dari',
                              value: lembabRule.nilaiAmbang.round(),
                              unit: '%',
                              gradientColors: const [
                                Color(0xFF4FACFE),
                                Color(0xFF00F2FE)
                              ],
                              bgColor: isDark ? const Color(0xFF132F42) : const Color(0xFFF0F9FF),
                              sliderValue: lembabRule.nilaiAmbang,
                              sliderMin: 40,
                              sliderMax: 90,
                              sliderMinLabel: '40%',
                              sliderMaxLabel: '90%',
                              actionLabel: 'Nyalakan Semprotan',
                              isRuleActive: lembabRule.statusAktif,
                              onRuleToggle: () => provider.toggleRule(
                                  lembabRule.ruleId!, lembabRule.statusAktif),
                              isDark: isDark,
                            ),
                          ),
                        ),

                      const SizedBox(height: 6),

                      // ── Section Title ──
                      _SectionTitle(
                          title: 'Mode Tanaman', icon: Icons.eco_rounded, isDark: isDark),
                      const SizedBox(height: 14),

                      // ── Presets Grid ──
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        children: [
                          ...presets.map((preset) {
                            final isActive = activeGreenhouse.activePresetId ==
                                preset.presetId;
                            return _PresetCard(
                              preset: preset,
                              isActive: isActive,
                              onTap: () => provider.applyPreset(preset),
                              onEdit: (e) {
                                e.stopPropagation();
                                _openAddPreset(preset: preset);
                              },
                              onDelete: (e) {
                                e.stopPropagation();
                                provider.deletePreset(preset.presetId!);
                              },
                              isDark: isDark,
                            );
                          }),
                          _AddPresetButton(onTap: () => _openAddPreset(), isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Modal overlay
          if (_showAddPreset)
            _PresetModal(
              namaController: _namaController,
              batasSuhu: _batasSuhu,
              batasKelembaban: _batasKelembaban,
              isEditing: _editingPresetId != null,
              onSuhuChanged: (v) => setState(() => _batasSuhu = v),
              onKelembapanChanged: (v) => setState(() => _batasKelembaban = v),
              onCancel: _cancelEdit,
              onSave: _savePreset,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Screen Header
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
// Section Title
// ═══════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionTitle({required this.title, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Master Toggle Card
// ═══════════════════════════════════════════════════
class _MasterToggleCard extends StatelessWidget {
  final bool isOn;
  final VoidCallback onToggle;
  final bool isDark;

  const _MasterToggleCard({required this.isOn, required this.onToggle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isOn
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF047857), Color(0xFF10B981)],
              )
            : null,
        color: isOn ? null : AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? const Color(0xFF059669).withValues(alpha: isDark ? 0.4 : 0.2)
                : AppColors.shadow(isDark),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOn
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.cardBgLighter(isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOn ? Icons.bolt_rounded : Icons.power_settings_new_rounded,
              size: 22,
              color: isOn ? Colors.white : AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Otomatis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isOn ? Colors.white : AppColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOn ? 'Sistem berjalan otomatis' : 'Otomasi dinonaktifkan',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary(isDark),
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
// Rule Card
// ═══════════════════════════════════════════════════
class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String condition;
  final int value;
  final String unit;
  final List<Color> gradientColors;
  final Color bgColor;
  final double sliderValue, sliderMin, sliderMax;
  final String sliderMinLabel, sliderMaxLabel;
  final String actionLabel;
  final bool isRuleActive;
  final VoidCallback onRuleToggle;
  final bool isDark;

  const _RuleCard({
    required this.icon,
    required this.title,
    required this.condition,
    required this.value,
    required this.unit,
    required this.gradientColors,
    required this.bgColor,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderMinLabel,
    required this.sliderMaxLabel,
    required this.actionLabel,
    required this.isRuleActive,
    required this.onRuleToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        ((sliderValue - sliderMin) / (sliderMax - sliderMin)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : gradientColors[0].withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: icon + title + value
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: gradientColors[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      condition,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              // Value badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value$unit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress slider visual
          LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return Column(
              children: [
                SizedBox(
                  height: 20,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Fill
                      Container(
                        width: w * pct,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Thumb
                      Positioned(
                        left: (w * pct - 8).clamp(0.0, w - 16),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border:
                                Border.all(color: gradientColors[0], width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sliderMinLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint(isDark))),
                    Text(sliderMaxLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint(isDark))),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: AppColors.divider(isDark)),
          const SizedBox(height: 12),

          // Action toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRuleActive
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: isRuleActive
                        ? AppColors.primary
                        : AppColors.textHint(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(isDark),
                    ),
                  ),
                ],
              ),
              ToggleSwitch(
                checked: isRuleActive,
                onChange: onRuleToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Hack: wrap for stopPropagation behavior
// ═══════════════════════════════════════════════════
class _TapEvent {
  void stopPropagation() {}
}

// ═══════════════════════════════════════════════════
// Preset Card
// ═══════════════════════════════════════════════════
class _PresetCard extends StatelessWidget {
  final PlantPreset preset;
  final bool isActive;
  final VoidCallback onTap;
  final void Function(_TapEvent) onEdit;
  final void Function(_TapEvent) onDelete;
  final bool isDark;

  const _PresetCard(
      {required this.preset,
      required this.isActive,
      required this.onTap,
      required this.onEdit,
      required this.onDelete,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          border: Border.all(
            color: isActive ? AppColors.primaryLight : AppColors.border(isDark),
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppColors.shadow(isDark),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF047857), Color(0xFF10B981)],
                          )
                        : null,
                    color: isActive ? null : AppColors.cardBgLighter(isDark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 22,
                    color: isActive ? Colors.white : AppColors.textHint(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  preset.namaTanaman,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? AppColors.textPrimary(isDark)
                        : AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                // Status indicator
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Aktif',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryLight : AppColors.primary),
                    ),
                  ),
              ],
            ),
            // Edit / delete buttons
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    _MiniIconButton(
                      icon: Icons.edit_rounded,
                      onTap: () => onEdit(_TapEvent()),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _MiniIconButton(
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () => onDelete(_TapEvent()),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Mini Icon Button
// ═══════════════════════════════════════════════════
class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isDark;

  const _MiniIconButton({
    required this.icon,
    this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          border: Border.all(color: AppColors.border(isDark)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(isDark),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 12, color: color ?? AppColors.textSecondary(isDark)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Add Preset Button
// ═══════════════════════════════════════════════════
class _AddPresetButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _AddPresetButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          border: Border.all(color: AppColors.border(isDark), width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBgLighter(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_rounded,
                  size: 24, color: AppColors.textSecondary(isDark)),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah Preset',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Preset Modal
// ═══════════════════════════════════════════════════
class _PresetModal extends StatefulWidget {
  final TextEditingController namaController;
  final double batasSuhu, batasKelembaban;
  final bool isEditing;
  final ValueChanged<double> onSuhuChanged, onKelembapanChanged;
  final VoidCallback onCancel, onSave;
  final bool isDark;

  const _PresetModal({
    required this.namaController,
    required this.batasSuhu,
    required this.batasKelembaban,
    required this.isEditing,
    required this.onSuhuChanged,
    required this.onKelembapanChanged,
    required this.onCancel,
    required this.onSave,
    required this.isDark,
  });

  @override
  State<_PresetModal> createState() => _PresetModalState();
}

class _PresetModalState extends State<_PresetModal> {
  late TextEditingController _suhuController;
  late TextEditingController _lembabController;
  late double _suhu, _lembab;

  @override
  void initState() {
    super.initState();
    _suhu = widget.batasSuhu;
    _lembab = widget.batasKelembaban;
    _suhuController = TextEditingController(text: _suhu.toStringAsFixed(0));
    _lembabController = TextEditingController(text: _lembab.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _suhuController.dispose();
    _lembabController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, String suffix) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint(widget.isDark)),
      filled: true,
      fillColor: AppColors.cardBgDarker(widget.isDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(widget.isDark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(widget.isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixText: suffix,
      suffixStyle: TextStyle(
          color: AppColors.textSecondary(widget.isDark), fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss on modal tap
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(widget.isDark),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg(widget.isDark),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                widget.isEditing
                                    ? Icons.edit_rounded
                                    : Icons.add_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.isEditing
                                  ? 'Edit Preset'
                                  : 'Tambah Preset',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(widget.isDark)),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: widget.onCancel,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLighter(widget.isDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textSecondary(widget.isDark)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    Text(
                      'NAMA TANAMAN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted(widget.isDark),
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.namaController,
                      autofocus: true,
                      style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
                      decoration: _inputDecoration('Misal: Tomat', ''),
                    ),
                    const SizedBox(height: 18),

                    // Suhu & Kelembaban fields
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BATAS SUHU',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted(widget.isDark),
                                    letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                controller: _suhuController,
                                style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
                                onChanged: (v) {
                                  final d = double.tryParse(v);
                                  if (d != null) {
                                    _suhu = d;
                                    widget.onSuhuChanged(d);
                                  }
                                },
                                decoration: _inputDecoration('20–40', '°C'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BATAS LEMBAP',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted(widget.isDark),
                                    letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                controller: _lembabController,
                                style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
                                onChanged: (v) {
                                  final d = double.tryParse(v);
                                  if (d != null) {
                                    _lembab = d;
                                    widget.onKelembapanChanged(d);
                                  }
                                },
                                decoration: _inputDecoration('40–90', '%'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    ListenableBuilder(
                      listenable: widget.namaController,
                      builder: (context, _) {
                        final isEnabled =
                            widget.namaController.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: isEnabled ? widget.onSave : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: isEnabled
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF047857),
                                        Color(0xFF10B981)
                                      ],
                                    )
                                  : null,
                              color: isEnabled ? null : AppColors.border(widget.isDark),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isEnabled
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF059669)
                                            .withValues(alpha: widget.isDark ? 0.4 : 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                widget.isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Preset',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isEnabled
                                      ? Colors.white
                                      : AppColors.textSecondary(widget.isDark),
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
        ),
      ),
    );
  }
}
