import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitgroup/services/group_service.dart';
import 'package:fitgroup/services/measurement_service.dart';
import 'package:fitgroup/services/measurement_store.dart';
import 'package:fitgroup/services/session_service.dart';
import 'package:fitgroup/ui/screens/measurement/measurement_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MeasurementService _measurementService = MeasurementService();
  final GroupService _groupService = GroupService();
  static const int _dashboardMeasurementLimit = 10;

  late Future<List<MeasurementEntry>> _measurementsFuture;
  List<GroupInfo> _myGroups = [];
  List<GroupFlowEntry> _groupFlow = [];
  int? _selectedGroupId;
  int? _selectedFlowUserId;
  final Set<int> _hiddenSeriesUserIds = <int>{};
  bool _groupLoading = false;

  @override
  void initState() {
    super.initState();
    _measurementsFuture = _loadMeasurements();
    _loadGroupsAndFlow();
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
    SessionService.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _loadGroupsAndFlow() async {
    if (!SessionService.isLoggedIn) {
      return;
    }

    setState(() {
      _groupLoading = true;
    });

    final groups = await _groupService.fetchMyGroups();
    _myGroups = groups;

    if (groups.isNotEmpty) {
      final current = _selectedGroupId;
      final hasCurrent = current != null && groups.any((group) => group.id == current);
      final active = hasCurrent ? groups.firstWhere((group) => group.id == current) : groups.first;

      _selectedGroupId = active.id;
      SessionService.activeGroupId = active.id;
      SessionService.activeGroupName = active.name;
      SessionService.activeGroupCode = active.code;
      _groupFlow = await _groupService.fetchGroupFlow(groupId: active.id, limit: 30);

      final availableUserIds = _groupFlow.map((entry) => entry.userId).toSet();
      if (_selectedFlowUserId != null && !availableUserIds.contains(_selectedFlowUserId)) {
        _selectedFlowUserId = null;
      }
      _hiddenSeriesUserIds.removeWhere((userId) => !availableUserIds.contains(userId));
    } else {
      _selectedGroupId = null;
      _selectedFlowUserId = null;
      _hiddenSeriesUserIds.clear();
      _groupFlow = [];
      SessionService.activeGroupId = null;
      SessionService.activeGroupName = null;
      SessionService.activeGroupCode = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _groupLoading = false;
    });
  }

  Future<void> _showCreateGroupDialog() async {
    if (!SessionService.isLoggedIn) {
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grup Olustur'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Grup adi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgec'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Olustur'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final created = await _groupService.createGroup(name: name);
    if (created == null) {
      _showSnack('Grup olusturulamadi.');
      return;
    }

    _selectedGroupId = created.id;
    SessionService.activeGroupId = created.id;
    SessionService.activeGroupName = created.name;
    SessionService.activeGroupCode = created.code;
    await _loadGroupsAndFlow();
    _showSnack('Grup olusturuldu. Kod: ${created.code}');
  }

  Future<void> _showJoinGroupDialog() async {
    if (!SessionService.isLoggedIn) {
      return;
    }

    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gruba Katil'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Grup kodu'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgec'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Katil'),
            ),
          ],
        );
      },
    );

    if (code == null || code.isEmpty) {
      return;
    }

    final joined = await _groupService.joinGroup(code: code);
    if (joined == null) {
      _showSnack('Grup bulunamadi.');
      return;
    }

    _selectedGroupId = joined.id;
    SessionService.activeGroupId = joined.id;
    SessionService.activeGroupName = joined.name;
    SessionService.activeGroupCode = joined.code;
    await _loadGroupsAndFlow();
    _showSnack('Gruba katildin: ${joined.name}');
  }

  Future<void> _onGroupChanged(int? groupId) async {
    if (groupId == null) {
      return;
    }

    setState(() {
      _selectedGroupId = groupId;
      _selectedFlowUserId = null;
      _hiddenSeriesUserIds.clear();
    });

    await _loadGroupsAndFlow();
  }

  void _toggleSeriesVisibility(int userId) {
    setState(() {
      if (_hiddenSeriesUserIds.contains(userId)) {
        _hiddenSeriesUserIds.remove(userId);
      } else {
        _hiddenSeriesUserIds.add(userId);
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            title: Text(
              'Hos Geldin, ${SessionService.fullName ?? 'Kullanici'}',
              style: const TextStyle(
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
                _buildGroupCard(),
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
                        'Gunluk Kalori',
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
                      const Text('1450 / 2000 kcal'),
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

                          _loadGroupsAndFlow();
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
                    'Gunluk Olcu Girisi',
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

  Widget _buildGroupCard() {
    final activeGroupName = SessionService.activeGroupName;
    final activeGroupCode = SessionService.activeGroupCode;

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
            'Grup Akisi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (activeGroupName != null) ...[
            Text('Aktif grup: $activeGroupName'),
            Text('Kod: ${activeGroupCode ?? '-'}'),
          ] else
            const Text('Henuz bir gruba dahil degilsin.'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _showCreateGroupDialog,
                  child: const Text('Grup Olustur'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showJoinGroupDialog,
                  child: const Text('Gruba Katil'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_myGroups.isNotEmpty)
            DropdownButtonFormField<int>(
              initialValue: _selectedGroupId,
              decoration: const InputDecoration(
                labelText: 'Aktif Grup',
                border: OutlineInputBorder(),
              ),
              items: _myGroups.map((group) {
                return DropdownMenuItem<int>(
                  value: group.id,
                  child: Text('${group.name} (${group.code})'),
                );
              }).toList(),
              onChanged: _onGroupChanged,
            ),
          if (_myGroups.isNotEmpty)
            const SizedBox(height: 12),
          if (_groupLoading)
            const Center(child: CircularProgressIndicator())
          else if (_groupFlow.isEmpty)
            const Text('Akis verisi henuz yok.')
          else ...[
            DropdownButtonFormField<int?>(
              initialValue: _selectedFlowUserId,
              decoration: const InputDecoration(
                labelText: 'Kullanici Filtresi',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tum Uyeler'),
                ),
                ..._groupFlow
                    .map((entry) => entry.userId)
                    .toSet()
                    .map((userId) {
                      final sample = _groupFlow.firstWhere((entry) => entry.userId == userId);
                      return DropdownMenuItem<int?>(
                        value: userId,
                        child: Text(sample.userName),
                      );
                    }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFlowUserId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildGroupFlowChart(
              _selectedFlowUserId == null
                  ? _groupFlow
                  : _groupFlow.where((entry) => entry.userId == _selectedFlowUserId).toList(),
            ),
            const SizedBox(height: 8),
            ...(_selectedFlowUserId == null
                    ? _groupFlow
                    : _groupFlow.where((entry) => entry.userId == _selectedFlowUserId))
                .take(8)
                .map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${entry.userName} - ${_formatDate(entry.date)}'),
                subtitle: Text(
                  "Kilo: ${_formatValue(entry.weight, 'kg')} | Bel: ${_formatValue(entry.waist, 'cm')}",
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupFlowChart(List<GroupFlowEntry> flow) {
    final ordered = [...flow]..sort((left, right) => left.date.compareTo(right.date));
    final byUser = <int, List<GroupFlowEntry>>{};
    final users = <int, String>{};
    final dateToX = <String, int>{};
    final indexToDate = <int, DateTime>{};
    var cursor = 0;

    for (final entry in ordered) {
      byUser.putIfAbsent(entry.userId, () => []).add(entry);
      users[entry.userId] = entry.userName;

      final key = _isoDate(entry.date);
      if (!dateToX.containsKey(key)) {
        dateToX[key] = cursor;
        indexToDate[cursor] = entry.date;
        cursor++;
      }
    }

    final bars = <LineChartBarData>[];
    final points = <FlSpot>[];
    final palette = <Color>[
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    final userIds = byUser.keys.toList();
    var colorIndex = 0;
    byUser.forEach((userId, entries) {
      if (_hiddenSeriesUserIds.contains(userId)) {
        colorIndex++;
        return;
      }

      final spots = <FlSpot>[];
      for (final entry in entries) {
        if (entry.weight == null) {
          continue;
        }

        final x = dateToX[_isoDate(entry.date)]?.toDouble();
        if (x != null) {
          final spot = FlSpot(x, entry.weight!);
          spots.add(spot);
          points.add(spot);
        }
      }

      if (spots.length >= 2) {
        final color = palette[colorIndex % palette.length];
        colorIndex++;
        bars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        );
      }
    });

    if (bars.isEmpty || points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Grup grafigi icin en az 2 kilo verisi gerekli.'),
      );
    }

    final minY = points.map((point) => point.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = points.map((point) => point.y).reduce((a, b) => a > b ? a : b) + 2;
    final maxX = (dateToX.length - 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grup Kilo Grafigi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: userIds.map((userId) {
            final idx = userIds.indexOf(userId);
            final color = palette[idx % palette.length];
            final isHidden = _hiddenSeriesUserIds.contains(userId);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _toggleSeriesVisibility(userId),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isHidden ? color.withValues(alpha: 0.25) : color,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          users[userId] ?? 'Uye',
                          style: TextStyle(
                            color: isHidden ? Colors.black38 : Colors.black87,
                            decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              lineBarsData: bars,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final date = indexToDate[value.toInt()];
                      if (date == null) {
                        return const SizedBox.shrink();
                      }
                      return Text(_shortDate(date));
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
            'Son Olcumler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text('Henuz olcu girilmedi.')
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
          Text('Gogus: ${_formatValue(entry.chest, 'cm')}'),
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
            'Olcum Grafigi',
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

  String _isoDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }
}
