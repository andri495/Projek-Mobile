import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/sensor_log.dart';
import '../models/activity_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = 'Hari Ini';
  final _filters = ['Hari Ini', 'Kemarin', '7 Hari'];

  // Hitung rentang waktu berdasarkan filter aktif
  (int start, int end) _getTimeRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd = todayStart + (24 * 3600 * 1000) - 1;

    switch (_activeFilter) {
      case 'Kemarin':
        final yesterdayStart = todayStart - (24 * 3600 * 1000);
        return (yesterdayStart, todayStart - 1);
      case '7 Hari':
        return (todayStart - (7 * 24 * 3600 * 1000), todayEnd);
      default: // 'Hari Ini'
        return (todayStart, todayEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeGreenhouse = provider.activeGreenhouse;
    final rawLogs = provider.sensorLogs;
    final activities = provider.activityLogs;

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
                child: const Icon(Icons.history_rounded, size: 48, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum ada lahan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      );
    }

    // Filter data berdasarkan rentang waktu
    final (rangeStart, rangeEnd) = _getTimeRange();
    final filteredLogs = rawLogs.where((l) =>
        l.waktuCatat >= rangeStart && l.waktuCatat <= rangeEnd).toList();
    final filteredActivities = activities.where((a) =>
        a.waktuKejadian >= rangeStart && a.waktuKejadian <= rangeEnd).toList();

    // Jika tidak ada data di filter terpilih, gunakan semua data untuk chart
    final chartData = _buildChartData(filteredLogs.isEmpty ? rawLogs : filteredLogs);
    final displayActivities = filteredActivities.isEmpty ? activities : filteredActivities;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // ── Header ──
          const _ScreenHeader(
            title: 'Riwayat Lahan',
            subtitle: 'Pantau grafik sensor & log alat',
            icon: Icons.auto_graph_rounded,
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((f) {
                        final isActive = _activeFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _activeFilter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                                      )
                                    : null,
                                color: isActive ? null : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive ? Colors.transparent : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info label filter aktif
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      filteredLogs.isEmpty
                          ? 'Masa ini kosong, menampilkan ringkasan data terakhir'
                          : 'Terdapat ${filteredLogs.length} data terekam di masa ini',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chart Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Grafik 24 Jam Terakhir',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                            Row(
                              children: [
                                _LegendDot(color: Color(0xFFF59E0B), label: 'Suhu'),
                                SizedBox(width: 12),
                                _LegendDot(color: Color(0xFF0EA5E9), label: 'Lembap'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 200,
                          child: chartData.isEmpty
                              ? const Center(child: Text('Tidak ada data', style: TextStyle(color: Color(0xFF94A3B8))))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 20,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: const Color(0xFFF1F5F9),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (val, _) {
                                            final idx = val.toInt();
                                            if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                                            if (idx % 2 != 0) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Text(
                                                chartData[idx].label,
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                                              ),
                                            );
                                          },
                                          reservedSize: 32,
                                        ),
                                      ),
                                    ),
                                    minY: 0, maxY: 100,
                                    lineBarsData: [
                                      _buildLine(chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.suhu)).toList(), const Color(0xFFF59E0B)),
                                      _buildLine(chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.lembab)).toList(), const Color(0xFF0EA5E9)),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Activity log Title
                  const Row(
                    children: [
                      Icon(Icons.history_edu_rounded, size: 20, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text(
                        'Buku Catatan Alat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Activity Log Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _ActivityTimeline(activities: displayActivities.take(10).toList()),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ChartPoint> _buildChartData(List<SensorLog> logs) {
    final sorted = [...logs]..sort((a, b) => a.waktuCatat.compareTo(b.waktuCatat));
    final last8 = sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;
    return last8.map((l) => _ChartPoint(
      label: DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(l.waktuCatat)),
      suhu: l.suhu.roundToDouble(),
      lembab: l.kelembaban.roundToDouble(),
    )).toList();
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ),
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

class _ChartPoint {
  final String label;
  final double suhu, lembab;
  _ChartPoint({required this.label, required this.suhu, required this.lembab});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, 
          height: 10, 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3), 
            color: color,
          )
        ),
        const SizedBox(width: 6),
        Text(
          label, 
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  final List<ActivityLog> activities;
  const _ActivityTimeline({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Belum ada aktivitas tercatat', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      );
    }
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left line
          Column(
            children: [
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: 2, 
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                )
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Items
          Expanded(
            child: Column(
              children: activities.asMap().entries.map((e) {
                final isLast = e.key == activities.length - 1;
                final log = e.value;
                // Determine icon and color based on activity content if possible
                Color dotColor = const Color(0xFF059669);
                IconData actIcon = Icons.notifications_none_rounded;
                
                final lowerKet = log.keterangan.toLowerCase();
                if (lowerKet.contains('suhu') || lowerKet.contains('kipas') || lowerKet.contains('panas')) {
                  dotColor = const Color(0xFFF59E0B);
                  actIcon = Icons.thermostat_rounded;
                } else if (lowerKet.contains('lembab') || lowerKet.contains('embun') || lowerKet.contains('pompa')) {
                  dotColor = const Color(0xFF0EA5E9);
                  actIcon = Icons.water_drop_rounded;
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dot icon (placed relative to the line)
                      Transform.translate(
                        offset: const Offset(-33, 0),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          ),
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                        ),
                      ),
                      
                      Transform.translate(
                        offset: const Offset(-8, 0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(actIcon, size: 16, color: dotColor),
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.keterangan, 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(DateTime.fromMillisecondsSinceEpoch(log.waktuKejadian)),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
