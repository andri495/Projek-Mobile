import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/plant_preset.dart';
import '../widgets/toggle_switch.dart';

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

    if (activeGreenhouse == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Belum ada lahan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
      );
    }

    final suhuRule = rules.where((r) => r.parameter == 'suhu').firstOrNull;
    final lembabRule = rules.where((r) => r.parameter == 'kelembaban').firstOrNull;

    String getDeviceName(int deviceId) =>
        devices.where((d) => d.deviceId == deviceId).firstOrNull?.namaAlat ?? '';

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master toggle card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Otomasi Lahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                SizedBox(height: 2),
                                Text('Aktifkan Mode Otomatis', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                            ToggleSwitch(checked: _masterToggle, onChange: () => setState(() => _masterToggle = !_masterToggle)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('Setingan Batas Aman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),

                      // Suhu Rule
                      if (suhuRule != null)
                        Opacity(
                          opacity: _masterToggle ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: !_masterToggle,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.thermostat_rounded, size: 18, color: Color(0xFFEF4444)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Jika Suhu ${suhuRule.kondisi == '>' ? 'Lebih' : 'Kurang'} Dari:',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                        ),
                                      ]),
                                      Text(
                                        '${suhuRule.nilaiAmbang.round()}°C',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFEF4444), letterSpacing: -1),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _SliderVisual(
                                    value: suhuRule.nilaiAmbang,
                                    min: 20, max: 40,
                                    color: const Color(0xFFEF4444),
                                    trackColor: const Color(0xFFFEE2E2),
                                    minLabel: '20°C', maxLabel: '40°C',
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nyalakan ${getDeviceName(suhuRule.deviceId).replaceAll('Pendingin', '').trim()}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                      ),
                                      ToggleSwitch(
                                        checked: suhuRule.statusAktif,
                                        onChange: () => provider.toggleRule(suhuRule.ruleId!, suhuRule.statusAktif),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Kelembaban Rule
                      if (lembabRule != null)
                        Opacity(
                          opacity: _masterToggle ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: !_masterToggle,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFD1FAE5)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.08), blurRadius: 20)],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0, top: 0, bottom: 0,
                                    child: Container(
                                      width: 4,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF059669),
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(children: [
                                              const Icon(Icons.water_drop_rounded, size: 18, color: Color(0xFF0D9488)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Jika Lembap ${lembabRule.kondisi == '<' ? 'Kurang' : 'Lebih'} Dari:',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              ),
                                            ]),
                                            Text(
                                              '${lembabRule.nilaiAmbang.round()}%',
                                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0D9488), letterSpacing: -1),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _SliderVisual(
                                          value: lembabRule.nilaiAmbang,
                                          min: 40, max: 90,
                                          color: const Color(0xFF059669),
                                          trackColor: const Color(0xFFECFDF5),
                                          minLabel: '40%', maxLabel: '90%',
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(color: Color(0xFFECFDF5)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Nyalakan Semprotan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                                            ToggleSwitch(
                                              checked: lembabRule.statusAktif,
                                              onChange: () => provider.toggleRule(lembabRule.ruleId!, lembabRule.statusAktif),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Presets
                      const Text('Mode Tanaman (Preset)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ...presets.map((preset) {
                            final isActive = activeGreenhouse.activePresetId == preset.presetId;
                            return _PresetCard(
                              preset: preset,
                              isActive: isActive,
                              onTap: () => provider.applyPreset(preset),
                              onEdit: (e) { e.stopPropagation(); _openAddPreset(preset: preset); },
                              onDelete: (e) { e.stopPropagation(); provider.deletePreset(preset.presetId!); },
                            );
                          }),
                          _AddPresetButton(onTap: () => _openAddPreset()),
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
            ),
        ],
      ),
    );
  }
}

class _SliderVisual extends StatelessWidget {
  final double value, min, max;
  final Color color, trackColor;
  final String minLabel, maxLabel;

  const _SliderVisual({
    required this.value, required this.min, required this.max,
    required this.color, required this.trackColor,
    required this.minLabel, required this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(builder: (ctx, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 8, decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(4))),
                Container(width: w * pct, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4))),
                Positioned(
                  left: (w * pct - 8).clamp(0.0, w - 16),
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(minLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
          Text(maxLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
        ]),
      ],
    );
  }
}

// Hack: wrap GestureTapDetails to allow stopPropagation-like behavior
class _TapEvent {
  void stopPropagation() {}
}

class _PresetCard extends StatelessWidget {
  final PlantPreset preset;
  final bool isActive;
  final VoidCallback onTap;
  final void Function(_TapEvent) onEdit;
  final void Function(_TapEvent) onDelete;

  const _PresetCard({required this.preset, required this.isActive, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFF6EE7B7) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                  ),
                  child: Icon(Icons.eco_rounded, size: 20, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                Text(
                  preset.namaTanaman,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            if (isActive)
              Positioned(
                top: 0, right: 0,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onEdit(_TapEvent()),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onDelete(_TapEvent()),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.delete_rounded, size: 12, color: Color(0xFF94A3B8)),
                      ),
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

class _AddPresetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPresetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            SizedBox(height: 4),
            Text('Tambah Preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _PresetModal extends StatefulWidget {
  final TextEditingController namaController;
  final double batasSuhu, batasKelembaban;
  final bool isEditing;
  final ValueChanged<double> onSuhuChanged, onKelembapanChanged;
  final VoidCallback onCancel, onSave;

  const _PresetModal({
    required this.namaController, required this.batasSuhu,
    required this.batasKelembaban, required this.isEditing,
    required this.onSuhuChanged, required this.onKelembapanChanged,
    required this.onCancel, required this.onSave,
  });

  @override
  State<_PresetModal> createState() => _PresetModalState();
}

class _PresetModalState extends State<_PresetModal> {
  // FIX: Gunakan controller sebagai state variable, BUKAN inline di build()
  // Sebelumnya: TextEditingController(text: _suhu.toString()) di dalam build()
  // Bug: controller dibuat ulang setiap rebuild → cursor lompat ke awal
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(widget.isEditing ? 'Edit Preset' : 'Tambah Preset',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)), onPressed: widget.onCancel),
                ]),
                const SizedBox(height: 16),
                const Text('NAMA TANAMAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8)),
                const SizedBox(height: 6),
                TextField(
                  controller: widget.namaController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Misal: Tomat',
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('BATAS SUHU (°C)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _suhuController,
                      onChanged: (v) {
                        final d = double.tryParse(v);
                        if (d != null) {
                          _suhu = d;
                          widget.onSuhuChanged(d);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '20–40',
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixText: '°C',
                        suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('BATAS LEMBAP (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _lembabController,
                      onChanged: (v) {
                        final d = double.tryParse(v);
                        if (d != null) {
                          _lembab = d;
                          widget.onKelembapanChanged(d);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '40–90',
                        filled: true, fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF059669))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixText: '%',
                        suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ])),
                ]),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: widget.namaController,
                  builder: (context, _) => ElevatedButton(
                    onPressed: widget.namaController.text.trim().isEmpty ? null : widget.onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Preset',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
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
