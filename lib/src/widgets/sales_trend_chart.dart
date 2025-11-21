import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A line chart widget showing sales trends over time
class SalesTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final Color lineColor;
  final bool showGrid;

  const SalesTrendChart({
    super.key,
    required this.data,
    this.title = 'Sales Trend',
    this.lineColor = Colors.blue,
    this.showGrid = true,
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
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: showGrid,
                    drawVerticalLine: true,
                    horizontalInterval: _getGridInterval(),
                    verticalInterval: _getXAxisInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
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
                        reservedSize: 35,
                        interval: _getXAxisInterval(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              data[index]['date'] as int,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM\ndd').format(date),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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
                        interval: null,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${_formatCurrency(value)}',
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
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildSpots(),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              data[index]['date'] as int,
                            );
                            final totalSales =
                                data[index]['totalSales'] as double;
                            final invoiceCount =
                                data[index]['invoiceCount'] as int;

                            return LineTooltipItem(
                              '${DateFormat('MMM dd').format(date)}\n'
                              '₹${NumberFormat('#,##,##0.00').format(totalSales)}\n'
                              '$invoiceCount invoices',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return List.generate(data.length, (index) {
      final totalSales = data[index]['totalSales'] as double;
      return FlSpot(index.toDouble(), totalSales);
    });
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;

    double max = 0;
    for (var item in data) {
      final value = item['totalSales'] as double;
      if (value > max) max = value;
    }

    // Add 20% padding to the top
    return max * 1.2;
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Calculate smart interval for X-axis labels to avoid overcrowding
  double _getXAxisInterval() {
    if (data.isEmpty) return 1;

    final length = data.length;
    if (length <= 7) return 1; // Show all labels for 7 or fewer days
    if (length <= 14) return 2; // Show every other day for 2 weeks
    if (length <= 30) return 3; // Show every 3rd day for a month
    if (length <= 60) return 7; // Show weekly for 2 months
    return (length / 10).ceil().toDouble(); // Show ~10 labels max
  }

  /// Calculate smart Y-axis grid interval
  double _getGridInterval() {
    final maxY = _getMaxY();
    if (maxY <= 0) return 1;

    // Aim for about 5-6 grid lines
    final rawInterval = maxY / 5;

    // Round to nice numbers
    if (rawInterval >= 100000) {
      return (rawInterval / 100000).ceil() * 100000;
    } else if (rawInterval >= 10000) {
      return (rawInterval / 10000).ceil() * 10000;
    } else if (rawInterval >= 1000) {
      return (rawInterval / 1000).ceil() * 1000;
    } else if (rawInterval >= 100) {
      return (rawInterval / 100).ceil() * 100;
    } else if (rawInterval >= 10) {
      return (rawInterval / 10).ceil() * 10;
    } else {
      return rawInterval.ceilToDouble();
    }
  }
}
