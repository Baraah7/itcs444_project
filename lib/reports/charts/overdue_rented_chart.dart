import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverdueChart extends StatelessWidget {
  final Map<String, dynamic> overdueData;

  const OverdueChart({super.key, required this.overdueData});

  @override
  Widget build(BuildContext context) {
    final overdueEquipment = overdueData['overdueEquipment'] as Map<String, dynamic>;
    
    if (overdueEquipment.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 16),
              Text('No Overdue Equipment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('All equipment is returned on time!', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final data = overdueEquipment.entries.take(5).toList();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipment with Overdue Rentals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: data.asMap().entries.map((entry) {
                        final colors = [
                          Colors.red,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.redAccent,
                          Colors.pink,
                        ];
                        
                        return PieChartSectionData(
                          color: colors[entry.key % colors.length],
                          value: entry.value.value.toDouble(),
                          title: '${entry.value.value}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                        enabled: true,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: data.asMap().entries.map((entry) {
                      final colors = [
                        Colors.red,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.redAccent,
                        Colors.pink,
                      ];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[entry.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value.key,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.value.value}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverdueMetricsCard extends StatelessWidget {
  final Map<String, dynamic> overdueData;

  const OverdueMetricsCard({super.key, required this.overdueData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Overdue Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Total Overdue',
                  overdueData['overdueCount'].toString(),
                  Icons.schedule,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Overdue Rate',
                  '${overdueData['overdueRate'].toStringAsFixed(1)}%',
                  Icons.trending_down,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Late Fees',
                  '\$${overdueData['totalLateFees'].toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Equipment Types',
                  overdueData['overdueEquipment'].length.toString(),
                  Icons.category,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}