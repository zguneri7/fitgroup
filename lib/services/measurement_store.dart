class MeasurementEntry {
  const MeasurementEntry({
    required this.date,
    required this.chest,
    required this.waist,
    required this.belly,
    required this.lowerBelly,
    required this.hip,
    required this.leg,
    required this.weight,
  });

  final DateTime date;
  final double? chest;
  final double? waist;
  final double? belly;
  final double? lowerBelly;
  final double? hip;
  final double? leg;
  final double? weight;
}

class MeasurementStore {
  MeasurementStore._();

  static final MeasurementStore instance = MeasurementStore._();

  final List<MeasurementEntry> _entries = [];

  List<MeasurementEntry> get entries => List.unmodifiable(_entries);

  void save(MeasurementEntry entry) {
    _entries.removeWhere((item) => _sameDay(item.date, entry.date));
    _entries.add(entry);
    _entries.sort((a, b) => a.date.compareTo(b.date));
  }

  List<MeasurementEntry> latestTwo() {
    if (_entries.length <= 2) {
      return List.unmodifiable(_entries);
    }

    return List.unmodifiable(_entries.sublist(_entries.length - 2));
  }

  bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}