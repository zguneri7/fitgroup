import 'package:flutter/material.dart';

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
              onPressed: () {
                _saveMeasurements();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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

  void _saveMeasurements() {
    debugPrint("Göğüs: ${chestController.text}");
    debugPrint("Bel: ${waistController.text}");
    debugPrint("Göbek: ${bellyController.text}");
    debugPrint("Göbek Altı: ${lowerBellyController.text}");
    debugPrint("Kalça: ${hipController.text}");
    debugPrint("Bacak: ${legController.text}");
    debugPrint("Kilo: ${weightController.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ölçüler kaydedildi!")),
    );
  }
}
