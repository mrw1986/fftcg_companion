// lib/widgets/price_history_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';

class PriceHistoryChart extends StatelessWidget {
  final String cardId;
  final List<PricePoint> priceHistory;
  final bool showFoil;

  const PriceHistoryChart({
    super.key,
    required this.cardId,
    required this.priceHistory,
    this.showFoil = true,
  });

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return const Center(
        child: Text('No price history available'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toStringAsFixed(2)}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          _buildLineChartBarData(false, Colors.blue),
          if (showFoil) _buildLineChartBarData(true, Colors.purple),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(bool isFoil, Color color) {
    return LineChartBarData(
      spots: priceHistory.map((point) {
        return FlSpot(
          point.date.millisecondsSinceEpoch.toDouble(),
          isFoil ? (point.foilPrice ?? 0) : point.normalPrice,
        );
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(25), // Replace withOpacity with withAlpha
      ),
    );
  }
}
