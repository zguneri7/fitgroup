import 'package:flutter/material.dart';
import 'package:fitgroup/services/measurement_store.dart';
import 'package:fitgroup/services/measurement_service.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  final TextEditingController chestController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController bellyController = TextEditingController();
  final TextEditingController lowerBellyController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController legController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final MeasurementService _measurementService = MeasurementService();
  bool _isSaving = false;

  @override
  void dispose() {
    chestController.dispose();
    waistController.dispose();
    bellyController.dispose();
    lowerBellyController.dispose();
    hipController.dispose();
    legController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Ölçü Girişi",
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: ListView(
        children: [
          _buildDateCard(),

          _buildSectionHeader("VÜCUT ÖLÇÜLERİ"),
          _buildInputRow("Göğüs", chestController),
          _divider(),
          _buildInputRow("Bel", waistController),
          _divider(),
          _buildInputRow("Göbek", bellyController),
          _divider(),
          _buildInputRow("Göbek Altı", lowerBellyController),
          _divider(),
          _buildInputRow("Kalça", hipController),
          _divider(),
          _buildInputRow("Bacak", legController),

          const SizedBox(height: 20),

          _buildSectionHeader("KİLO"),
          _buildInputRow("Kilo", weightController, unit: "kg"),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveMeasurements,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      "Kaydet",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 0.6, color: Colors.grey[300]);
  }

  Widget _buildDateCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olcum Tarihi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickDate,
            child: const Text('Tarih Sec'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Olcum tarihi sec',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller, {
    String unit = "cm",
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "0",
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(unit, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    final entry = MeasurementEntry(
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      chest: double.tryParse(chestController.text.replaceAll(',', '.')),
      waist: double.tryParse(waistController.text.replaceAll(',', '.')),
      belly: double.tryParse(bellyController.text.replaceAll(',', '.')),
      lowerBelly: double.tryParse(lowerBellyController.text.replaceAll(',', '.')),
      hip: double.tryParse(hipController.text.replaceAll(',', '.')),
      leg: double.tryParse(legController.text.replaceAll(',', '.')),
      weight: double.tryParse(weightController.text.replaceAll(',', '.')),
    );

    setState(() {
      _isSaving = true;
    });

    final savedRemotely = await _measurementService.saveMeasurement(entry);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!savedRemotely) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veri tabanina kaydedilemedi.')),
      );
      return;
    }

    MeasurementStore.instance.save(entry);

    debugPrint("Tarih: ${_formatDate(_selectedDate)}");
    debugPrint("Göğüs: ${chestController.text}");
    debugPrint("Bel: ${waistController.text}");
    debugPrint("Göbek: ${bellyController.text}");
    debugPrint("Göbek Altı: ${lowerBellyController.text}");
    debugPrint("Kalça: ${hipController.text}");
    debugPrint("Bacak: ${legController.text}");
    debugPrint("Kilo: ${weightController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Olculer ${_formatDate(_selectedDate)} tarihi icin kaydedildi!")),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context, entry);
    }
  }
}
