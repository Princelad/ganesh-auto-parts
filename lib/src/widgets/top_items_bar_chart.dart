import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A bar chart widget showing top selling items
class TopItemsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final Color barColor;

  const TopItemsBarChart({
    super.key,
    required this.data,
    this.title = 'Top Selling Items',
    this.barColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              const Text('No data available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: data.isEmpty ? 200 : (data.length > 5 ? 350 : 280),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = data[groupIndex];
                        final name = item['name'] as String;
                        final quantity = item['totalQuantity'] as double;
                        final revenue = item['totalRevenue'] as double;

                        return BarTooltipItem(
                          '$name\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Qty: ${quantity.toStringAsFixed(0)}\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '₹${NumberFormat('#,##,##0').format(revenue)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final name = data[index]['name'] as String;
                            // Show only first word or first 8 chars
                            final displayName = name.split(' ').first;
                            final truncated = displayName.length > 8
                                ? '${displayName.substring(0, 8)}...'
                                : displayName;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  truncated,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getYAxisInterval(),
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatValue(value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getYAxisInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(data.length, (index) {
      final quantity = data[index]['totalQuantity'] as double;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: quantity,
            color: barColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;

    double max = 0;
    for (var item in data) {
      final value = item['totalQuantity'] as double;
      if (value > max) max = value;
    }

    // Add 20% padding to the top
    return max * 1.2;
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Calculate smart Y-axis interval for grid lines and labels
  double _getYAxisInterval() {
    final maxY = _getMaxY();
    if (maxY <= 0) return 1;

    // Aim for about 4-5 grid lines
    final rawInterval = maxY / 4;

    // Round to nice numbers
    if (rawInterval >= 1000) {
      return (rawInterval / 1000).ceil() * 1000;
    } else if (rawInterval >= 100) {
      return (rawInterval / 100).ceil() * 100;
    } else if (rawInterval >= 10) {
      return (rawInterval / 10).ceil() * 10;
    } else if (rawInterval >= 5) {
      return 5;
    } else {
      return rawInterval.ceilToDouble().clamp(1, double.infinity);
    }
  }
}
