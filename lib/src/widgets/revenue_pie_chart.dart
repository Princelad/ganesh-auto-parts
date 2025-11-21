import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A pie chart widget showing revenue breakdown by category or company
class RevenuePieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String labelKey;
  final String valueKey;

  const RevenuePieChart({
    super.key,
    required this.data,
    this.title = 'Revenue Breakdown',
    this.labelKey = 'category',
    this.valueKey = 'totalRevenue',
  });

  @override
  State<RevenuePieChart> createState() => _RevenuePieChartState();
}

class _RevenuePieChartState extends State<RevenuePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.data.length > 8 ? 300 : 250,
                maxHeight: widget.data.length > 12 ? 400 : 350,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie chart
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: widget.data.length > 5 ? 1 : 2,
                        centerSpaceRadius: widget.data.length > 7 ? 30 : 35,
                        sections: _buildSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Expanded(child: _buildLegend()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = _getTotal();
    if (total == 0) return [];

    final colors = _generateColors(widget.data.length);

    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;

      // Adjust sizes based on number of sections
      final baseRadius = widget.data.length > 10
          ? 55.0
          : widget.data.length > 7
          ? 58.0
          : 60.0;
      final touchRadius = baseRadius + 12.0;

      final baseFontSize = widget.data.length > 10
          ? 9.0
          : widget.data.length > 7
          ? 10.0
          : 11.0;
      final touchFontSize = baseFontSize + 2.0;

      final fontSize = isTouched ? touchFontSize : baseFontSize;
      final radius = isTouched ? touchRadius : baseRadius;

      final value = widget.data[i][widget.valueKey] as double;
      final percentage = (value / total * 100);

      return PieChartSectionData(
        color: colors[i],
        value: value,
        title: percentage >= 3 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      );
    });
  }

  Widget _buildLegend() {
    final colors = _generateColors(widget.data.length);
    final total = _getTotal();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.data.length, (i) {
          final item = widget.data[i];
          final label = item[widget.labelKey] as String;
          final value = item[widget.valueKey] as double;
          final percentage = total > 0 ? (value / total * 100) : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            '₹${NumberFormat('#,##,##0').format(value)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  double _getTotal() {
    double total = 0;
    for (var item in widget.data) {
      total += item[widget.valueKey] as double;
    }
    return total;
  }

  List<Color> _generateColors(int count) {
    // Predefined color palette for better distinction
    const predefinedColors = [
      Color(0xFF2196F3), // Blue
      Color(0xFFFF9800), // Orange
      Color(0xFF4CAF50), // Green
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFF5722), // Deep Orange
      Color(0xFF8BC34A), // Light Green
      Color(0xFF673AB7), // Deep Purple
      Color(0xFFFFC107), // Amber
      Color(0xFF009688), // Teal
      Color(0xFFCDDC39), // Lime
      Color(0xFF3F51B5), // Indigo
      Color(0xFFF44336), // Red
    ];

    if (count <= predefinedColors.length) {
      return predefinedColors.take(count).toList();
    }

    // For more colors, generate with varying hue and saturation
    return List.generate(count, (index) {
      if (index < predefinedColors.length) {
        return predefinedColors[index];
      }
      final hue =
          ((index - predefinedColors.length) *
              360 /
              (count - predefinedColors.length)) %
          360;
      final saturation = 0.6 + (index % 3) * 0.15;
      final lightness = 0.5 + (index % 2) * 0.1;
      return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    });
  }
}
