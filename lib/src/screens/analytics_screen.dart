import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../db/invoice_repository.dart';
import '../db/item_repository.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/revenue_pie_chart.dart';
import '../widgets/top_items_bar_chart.dart';

/// Analytics screen showing sales trends, revenue breakdowns, and top items
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = '7d'; // 7d, 30d, 90d, 1y
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case '7d':
        _startDate = today.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case '30d':
        _startDate = today.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case '90d':
        _startDate = today.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case '1y':
        _startDate = DateTime(today.year - 1, today.month, today.day);
        _endDate = now;
        break;
      case 'custom':
        // Keep existing dates
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: '7d', label: Text('7D')),
                          ButtonSegment(value: '30d', label: Text('30D')),
                          ButtonSegment(value: '90d', label: Text('90D')),
                          ButtonSegment(value: '1y', label: Text('1Y')),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedPeriod = newSelection.first;
                            _updateDateRange();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedPeriod == 'custom' &&
                    _startDate != null &&
                    _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),

          // Charts content
          Expanded(child: _buildChartsContent()),
        ],
      ),
    );
  }

  Widget _buildChartsContent() {
    if (_startDate == null || _endDate == null) {
      return const Center(child: Text('Select a date range to view analytics'));
    }

    final startTimestamp = _startDate!.millisecondsSinceEpoch;
    final endTimestamp = _endDate!.millisecondsSinceEpoch;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Trigger rebuild
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCards(startTimestamp, endTimestamp),
            const SizedBox(height: 16),

            // Sales trend line chart
            FutureBuilder<List<Map<String, dynamic>>>(
              future: InvoiceRepository().getDailySales(
                startDate: startTimestamp,
                endDate: endTimestamp,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                return SalesTrendChart(
                  data: snapshot.data ?? [],
                  title: 'Daily Sales Trend',
                );
              },
            ),
            const SizedBox(height: 16),

            // Revenue by company pie chart
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ItemRepository().getSalesByCompany(
                startDate: startTimestamp,
                endDate: endTimestamp,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                return RevenuePieChart(
                  data: snapshot.data ?? [],
                  title: 'Revenue by Company',
                  labelKey: 'company',
                  valueKey: 'totalRevenue',
                );
              },
            ),
            const SizedBox(height: 16),

            // Top selling items bar chart
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ItemRepository().getTopSellingItems(
                limit: 10,
                startDate: startTimestamp,
                endDate: endTimestamp,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                return TopItemsBarChart(
                  data: snapshot.data ?? [],
                  title: 'Top 10 Selling Items',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int startTimestamp, int endTimestamp) {
    return FutureBuilder<Map<String, dynamic>>(
      future: InvoiceRepository().getSalesTrends(
        (_endDate!.difference(_startDate!).inDays),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final totalSales = data['totalSales'] as double;
        final totalInvoices = data['totalInvoices'] as int;
        final avgSale = data['avgSale'] as double;

        return Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sales',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##,##0').format(totalSales)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoices',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalInvoices.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Sale',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${NumberFormat('#,##,##0').format(avgSale)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
