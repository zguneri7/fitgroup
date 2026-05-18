import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitgroup/ui/screens/measurement/measurement_screen.dart';



class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        actions: const [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // SON ÖLÇÜ KARTI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Son Ölçüm",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Kilo: 80.5 kg"),
                  Text("Bel: 95 cm"),
                  Text("Göğüs: 105 cm"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // HAFTALIK KILO GRAFIK (dummy)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
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
                  Text(
                    "Haftalık Kilo Grafiği",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: 70,
                      maxY: 90,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                              FlSpot(0, 85),
                              FlSpot(1, 84),
                              FlSpot(2, 83.5),
                              FlSpot(3, 82),
                              FlSpot(4, 81.5),
                              FlSpot(5, 80.8),
                              FlSpot(6, 80.5),
                            ],
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 4,
                            dotData: FlDotData(show: false),
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
                                const days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
                                return Text(days[value.toInt()]);
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
                ],
              ),
            ),

            const SizedBox(height: 25),

            // GUNLUK KALORI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
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
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: 0.45, // %45 dolu (dummy)
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
              onPressed: () {  Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MeasurementScreen()),
                          );
                          },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Ölçü Girişi Yap",
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.white
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
