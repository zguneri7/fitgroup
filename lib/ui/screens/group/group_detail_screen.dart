import 'package:fl_chart/fl_chart.dart';
import 'package:fitgroup/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _GroupMetric {
  weight,
  waist,
  chest,
}

class _GroupDetailData {
  const _GroupDetailData({
    required this.detail,
    required this.flow,
    required this.latestMeasurements,
  });

  final GroupDetail detail;
  final List<GroupFlowEntry> flow;
  final List<GroupLatestMeasurement> latestMeasurements;
}

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  final int groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  late Future<_GroupDetailData?> _detailFuture;
  _GroupMetric _selectedMetric = _GroupMetric.weight;
  int? _selectedMemberId;
  final Set<int> _hiddenMemberIds = <int>{};

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetailData();
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = _loadDetailData();
    });
    await _detailFuture;
  }

  Future<_GroupDetailData?> _loadDetailData() async {
    final detail = await _groupService.fetchGroupDetail(groupId: widget.groupId);
    if (detail == null) {
      return null;
    }

    final flow = await _groupService.fetchGroupFlow(groupId: widget.groupId, limit: 120);
    final latestMeasurements = await _groupService.fetchGroupLatestMeasurements(groupId: widget.groupId);
    final memberIds = detail.members.map((member) => member.id).toSet();

    _hiddenMemberIds.removeWhere((memberId) => !memberIds.contains(memberId));

    if (_selectedMemberId == null || !memberIds.contains(_selectedMemberId)) {
      _selectedMemberId = _pickDefaultMemberId(detail.members, flow);
    }

    return _GroupDetailData(
      detail: detail,
      flow: flow,
      latestMeasurements: latestMeasurements,
    );
  }

  int? _pickDefaultMemberId(List<GroupMember> members, List<GroupFlowEntry> flow) {
    final memberIdsWithWeight = flow.where((entry) => entry.weight != null).map((entry) => entry.userId).toSet();

    for (final member in members) {
      if (memberIdsWithWeight.contains(member.id)) {
        return member.id;
      }
    }

    return members.isNotEmpty ? members.first.id : null;
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }

    final copied = await Clipboard.getData('text/plain');
    final success = copied?.text == text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '$label panoya kopyalandi.' : '$label kopyalandi fakat pano dogrulanamadi.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  String _shortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m';
  }

  String _metricLabel(_GroupMetric metric) {
    switch (metric) {
      case _GroupMetric.weight:
        return 'Kilo';
      case _GroupMetric.waist:
        return 'Bel';
      case _GroupMetric.chest:
        return 'Gogus';
    }
  }

  double? _metricValue(GroupFlowEntry entry, _GroupMetric metric) {
    switch (metric) {
      case _GroupMetric.weight:
        return entry.weight;
      case _GroupMetric.waist:
        return entry.waist;
      case _GroupMetric.chest:
        return entry.chest;
    }
  }

  void _toggleMemberVisibility(int memberId) {
    setState(() {
      if (_hiddenMemberIds.contains(memberId)) {
        _hiddenMemberIds.remove(memberId);
      } else {
        _hiddenMemberIds.add(memberId);
      }
    });
  }

  String _isoDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  GroupMember? _memberById(List<GroupMember> members, int? memberId) {
    if (memberId == null) {
      return null;
    }

    for (final member in members) {
      if (member.id == memberId) {
        return member;
      }
    }

    return null;
  }

  Widget _buildMetricChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _GroupMetric.values.map((metric) {
        return ChoiceChip(
          label: Text(_metricLabel(metric)),
          selected: _selectedMetric == metric,
          onSelected: (_) {
            setState(() {
              _selectedMetric = metric;
            });
          },
        );
      }).toList(),
    );
  }

  String _formatMetricValue(double? value, _GroupMetric metric) {
    if (value == null) {
      return '-';
    }

    final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$text ${_metricUnit(metric)}';
  }

  String _metricUnit(_GroupMetric metric) {
    switch (metric) {
      case _GroupMetric.weight:
        return 'kg';
      case _GroupMetric.waist:
      case _GroupMetric.chest:
        return 'cm';
    }
  }

  Widget _buildLatestMeasurementsSection(_GroupDetailData data) {
    final byMemberId = <int, GroupLatestMeasurement>{
      for (final item in data.latestMeasurements) item.userId: item,
    };

    if (byMemberId.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Grup icin henüz son ölçüm verisi yok.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Ölçümler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.detail.members.map((member) {
              final latest = byMemberId[member.id];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (member.id == _selectedMemberId)
                          const Chip(label: Text('Seçili')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (latest == null)
                      const Text('Henüz ölçüm girmedi.')
                    else ...[
                      Text('Tarih: ${_formatDate(latest.date)}'),
                      Text('Kilo: ${_formatMetricValue(latest.weight, _GroupMetric.weight)}'),
                      Text('Bel: ${_formatMetricValue(latest.waist, _GroupMetric.waist)}'),
                      Text('Gögüs: ${_formatMetricValue(latest.chest, _GroupMetric.chest)}'),
                      Text('Göbek: ${_formatMetricValue(latest.belly, _GroupMetric.waist)}'),
                      Text('Göbek Altı: ${_formatMetricValue(latest.lowerBelly, _GroupMetric.waist)}'),
                      Text('Kalça: ${_formatMetricValue(latest.hip, _GroupMetric.waist)}'),
                      Text('Bacak: ${_formatMetricValue(latest.leg, _GroupMetric.waist)}'),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChart(List<GroupMember> members, List<GroupFlowEntry> flow) {
    final ordered = [...flow]..sort((left, right) => left.date.compareTo(right.date));
    final groupedByMember = <int, List<GroupFlowEntry>>{};
    final memberNames = <int, String>{};
    final dateToX = <String, int>{};
    final indexToDate = <int, DateTime>{};
    var cursor = 0;

    for (final entry in ordered) {
      groupedByMember.putIfAbsent(entry.userId, () => []).add(entry);
      memberNames[entry.userId] = entry.userName;

      final key = _isoDate(entry.date);
      if (!dateToX.containsKey(key)) {
        dateToX[key] = cursor;
        indexToDate[cursor] = entry.date;
        cursor++;
      }
    }

    final points = <FlSpot>[];
    final bars = <LineChartBarData>[];
    const palette = <Color>[
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    var colorIndex = 0;
    for (final member in members) {
      final entries = groupedByMember[member.id];
      if (entries == null || entries.isEmpty) {
        continue;
      }

      if (_hiddenMemberIds.contains(member.id)) {
        colorIndex++;
        continue;
      }

      final spots = <FlSpot>[];
      for (final entry in entries) {
        final value = _metricValue(entry, _selectedMetric);
        if (value == null) {
          continue;
        }

        final x = dateToX[_isoDate(entry.date)]?.toDouble();
        if (x != null) {
          final spot = FlSpot(x, value);
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
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    if (bars.isEmpty || points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Grup grafigi icin en az 2 ${_metricLabel(_selectedMetric).toLowerCase()} verisi gerekli.'),
      );
    }

    final minY = points.map((point) => point.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = points.map((point) => point.y).reduce((a, b) => a > b ? a : b) + 2;
    final maxX = (dateToX.length - 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grup ${_metricLabel(_selectedMetric)} Grafigi',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: members.where((member) => groupedByMember.containsKey(member.id)).map((member) {
            final idx = members.indexOf(member);
            final color = palette[idx % palette.length];
            final isHidden = _hiddenMemberIds.contains(member.id);
            return InkWell(
              onTap: () => _toggleMemberVisibility(member.id),
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
                      memberNames[member.id] ?? member.displayName,
                      style: TextStyle(
                        color: isHidden ? Colors.black38 : Colors.black87,
                        decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Directionality(
            textDirection: TextDirection.ltr,
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
        ),
      ],
    );
  }

  Widget _buildMemberChart(GroupMember member, List<GroupFlowEntry> flow) {
    final memberEntries = flow.where((entry) => entry.userId == member.id).toList()
      ..sort((left, right) => left.date.compareTo(right.date));

    final metricEntries = memberEntries.where((entry) => _metricValue(entry, _selectedMetric) != null).toList();
    if (metricEntries.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('${member.displayName} icin grafik olusturmak icin en az 2 ${_metricLabel(_selectedMetric).toLowerCase()} verisi gerekli.'),
      );
    }

    final spots = <FlSpot>[];
    for (var index = 0; index < metricEntries.length; index++) {
      final value = _metricValue(metricEntries[index], _selectedMetric);
      if (value != null) {
        spots.add(FlSpot(index.toDouble(), value));
      }
    }

    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${member.displayName} ${_metricLabel(_selectedMetric)} Grafigi',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LineChart(
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
                    dotData: const FlDotData(show: true),
                  ),
                ],
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
                        final index = value.toInt();
                        if (index < 0 || index >= metricEntries.length) {
                          return const SizedBox.shrink();
                        }

                        return Text(_shortDate(metricEntries[index].date));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingSection(_GroupDetailData data) {
    final detail = data.detail;
    final selectedMember = _memberById(detail.members, _selectedMemberId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Takip GrafiklerI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMetricChips(),
            const SizedBox(height: 16),
            _buildGroupChart(detail.members, data.flow),
            const SizedBox(height: 20),
            if (detail.members.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedMemberId,
                decoration: const InputDecoration(
                  labelText: 'Bireysel takip',
                  border: OutlineInputBorder(),
                ),
                items: detail.members.map((member) {
                  return DropdownMenuItem<int>(
                    value: member.id,
                    child: Text(member.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMemberId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (selectedMember != null)
                _buildMemberChart(selectedMember, data.flow)
              else
                const Text('Bireysel grafik icin bir uye sec.'),
            ],
            const SizedBox(height: 16),
            _buildLatestMeasurementsSection(data),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup Detayi'),
      ),
      body: FutureBuilder<_GroupDetailData?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Grup bilgisi yuklenemedi.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = data.detail;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.group.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Grup Kodu: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyText(detail.group.code, 'Grup kodu'),
                                child: Text(
                                  detail.group.code,
                                  style: const TextStyle(decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _copyText(detail.group.code, 'Grup kodu'),
                              child: const Text('Kopyala'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Davet Linki', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _copyText(detail.inviteLink, 'Davet linki'),
                          child: SelectableText(
                            detail.inviteLink,
                            style: const TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _copyText(detail.inviteLink, 'Davet linki'),
                              icon: const Icon(Icons.link),
                              label: const Text('Linki Kopyala'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _copyText(detail.inviteMessage, 'Davet metni'),
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Davet Metnini Kopyala'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _copyText(detail.inviteMessage, 'Davet metni'),
                          child: Text(
                            detail.inviteMessage,
                            style: const TextStyle(
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTrackingSection(data),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uyeler (${detail.members.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (detail.members.isEmpty)
                          const Text('Henuz uye yok.')
                        else
                          ...detail.members.map((member) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(member.displayName),
                              subtitle: Text('${member.email}\nKatilma: ${_formatDate(member.joinedAt)}'),
                              isThreeLine: true,
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
