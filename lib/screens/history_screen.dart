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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Belum ada lahan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan & Laporan Lahan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 24),

                  // Filter buttons
                  Row(
                    children: _filters.map((f) {
                      final isActive = _activeFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF047857) : Colors.white,
                              border: Border.all(color: isActive ? const Color(0xFF047857) : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Info label filter aktif
                  Text(
                    filteredLogs.isEmpty
                        ? 'Tidak ada data untuk "$_activeFilter", menampilkan semua data'
                        : 'Menampilkan ${filteredLogs.length} data sensor untuk "$_activeFilter"',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),

                  // Chart header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Grafik 24 Jam Terakhir',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      Row(
                        children: [
                          _LegendDot(color: Color(0xFFFBBF24), label: 'Suhu\n(°C)'),
                          SizedBox(width: 16),
                          _LegendDot(color: Color(0xFF059669), label: 'Lembap\n(%)'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  SizedBox(
                    height: 192,
                    child: chartData.isEmpty
                        ? const Center(child: Text('Tidak ada data', style: TextStyle(color: Color(0xFF94A3B8))))
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
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
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          chartData[idx].label,
                                          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    },
                                    reservedSize: 28,
                                  ),
                                ),
                              ),
                              minY: 0, maxY: 100,
                              lineBarsData: [
                                _buildLine(chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.suhu)).toList(), const Color(0xFFFBBF24)),
                                _buildLine(chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.lembab)).toList(), const Color(0xFF059669)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 40),

                  // Activity log
                  const Text('Buku Catatan Alat',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  _ActivityTimeline(activities: displayActivities.take(10).toList()),
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
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.05),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Belum ada aktivitas.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
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
              Expanded(child: Container(width: 2, color: const Color(0xFFF1F5F9))),
            ],
          ),
          const SizedBox(width: 16),
          // Items
          Expanded(
            child: Column(
              children: activities.asMap().entries.map((e) {
                final log = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dot (placed relative to the line)
                      Transform.translate(
                        offset: const Offset(-24, 4),
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF059669), width: 2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(log.waktuKejadian)),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 2),
                            Text(log.keterangan, style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4)),
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
