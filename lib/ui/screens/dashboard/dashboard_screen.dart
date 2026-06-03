import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitgroup/ui/screens/measurement/measurement_screen.dart';
import 'package:fitgroup/services/measurement_store.dart';
import 'package:fitgroup/services/measurement_service.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MeasurementService _measurementService = MeasurementService();
  static const int _dashboardMeasurementLimit = 10;
  late Future<List<MeasurementEntry>> _measurementsFuture;

  @override
  void initState() {
    super.initState();
    _measurementsFuture = _loadMeasurements();
  }

  Future<List<MeasurementEntry>> _loadMeasurements() async {
    final measurements = await _measurementService.fetchLatestMeasurements(
      limit: _dashboardMeasurementLimit,
    );
    if (measurements.isNotEmpty) {
      for (final entry in measurements) {
        MeasurementStore.instance.save(entry);
      }
      return measurements;
    }

    return MeasurementStore.instance.entries;
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MeasurementEntry>>(
      future: _measurementsFuture,
      builder: (context, snapshot) {
        final latestEntries = snapshot.data ?? MeasurementStore.instance.entries;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F4),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              "Hoş Geldin, Kullanıcı",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _handleLogout(context),
                tooltip: 'Cikis Yap',
                icon: const Icon(Icons.logout, color: Colors.black87),
              ),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMeasurementSummary(latestEntries),
                const SizedBox(height: 25),
                _buildChartCard(latestEntries),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Günlük Kalori",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: 0.45,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 10),
                      const Text("1450 / 2000 kcal"),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MeasurementScreen()),
                    ).then((result) {
                      if (result is MeasurementEntry) {
                        MeasurementStore.instance.save(result);
                        setState(() {
                          _measurementsFuture = Future.value(MeasurementStore.instance.entries);
                        });

                        _loadMeasurements().then((measurements) {
                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _measurementsFuture = Future.value(measurements);
                          });
                        });
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Gunluk Olcu Girisi",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementSummary(List<MeasurementEntry> entries) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Ölçümler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text('Henüz ölçü girilmedi.')
          else
            ...entries.reversed.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _measurementDayTile(entry),
              );
            }),
        ],
      ),
    );
  }

  Widget _measurementDayTile(MeasurementEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(entry.date),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text('Kilo: ${_formatValue(entry.weight, 'kg')}'),
          Text('Bel: ${_formatValue(entry.waist, 'cm')}'),
          Text('Göğüs: ${_formatValue(entry.chest, 'cm')}'),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<MeasurementEntry> entries) {
    final orderedEntries = [...entries]..sort((left, right) => left.date.compareTo(right.date));
    final spots = <FlSpot>[];
    for (var index = 0; index < orderedEntries.length; index++) {
      final entry = orderedEntries[index];
      final weight = entry.weight;
      if (weight != null) {
        spots.add(FlSpot(index.toDouble(), weight));
      }
    }

    final minY = spots.isEmpty ? 70.0 : spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.isEmpty ? 90.0 : spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olcum Grafiği',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: spots.length < 2
                  ? const Center(child: Text('Grafik icin en az 2 kilo girisi gerekiyor.'))
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (spots.length - 1).toDouble(),
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 4,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= orderedEntries.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  _shortDate(orderedEntries[index].date),
                                  textDirection: TextDirection.ltr,
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double? value, String unit) {
    if (value == null) {
      return '-';
    }

    final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
