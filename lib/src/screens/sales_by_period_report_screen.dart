import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/invoice_repository.dart';
import '../utils/currency_helper.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

/// Sales by Period Report Screen
/// Shows sales analysis by day, week, or month
class SalesByPeriodReportScreen extends ConsumerStatefulWidget {
  const SalesByPeriodReportScreen({super.key});

  @override
  ConsumerState<SalesByPeriodReportScreen> createState() =>
      _SalesByPeriodReportScreenState();
}

class _SalesByPeriodReportScreenState
    extends ConsumerState<SalesByPeriodReportScreen> {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'day'; // 'day', 'week', 'month'

  List<Map<String, dynamic>>? _periodData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _invoiceRepository.getSalesByPeriod(
        period: _selectedPeriod,
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
      );

      setState(() {
        _periodData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSalesData();
    }
  }

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadSalesData();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales by Period'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalesData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading sales data...')
          : _error != null
          ? ErrorStateWidget(error: _error!, onRetry: _loadSalesData)
          : RefreshIndicator(
              onRefresh: _loadSalesData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info card
                  Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: Colors.teal.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Analyze sales trends across different time periods.',
                              style: TextStyle(color: Colors.teal.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date range selection
                  Card(
                    child: InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Range',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period selection
                  Row(
                    children: [
                      Expanded(child: _buildPeriodButton('Daily', 'day')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPeriodButton('Weekly', 'week')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPeriodButton('Monthly', 'month')),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Period data list
                  if (_periodData != null && _periodData!.isNotEmpty) ...[
                    Text(
                      'Sales Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._periodData!.map(_buildPeriodCard),
                  ],

                  // Empty state
                  if (_periodData != null && _periodData!.isEmpty) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sales data',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No sales in selected period',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => _setPeriod(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> data) {
    final period = data['period'] as String;
    final invoiceCount = data['invoiceCount'] as int;
    final totalRevenue = data['totalRevenue'] as double;
    final totalCollected = data['totalCollected'] as double;
    final totalTax = data['totalTax'] as double;

    // Format period string
    String periodLabel = period;
    try {
      if (_selectedPeriod == 'day') {
        final date = DateTime.parse(period);
        periodLabel = DateFormat('EEE, dd MMM yyyy').format(date);
      } else if (_selectedPeriod == 'month') {
        final parts = period.split('-');
        if (parts.length == 2) {
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          periodLabel = DateFormat('MMMM yyyy').format(date);
        }
      }
    } catch (e) {
      // Keep original if parsing fails
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    periodLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$invoiceCount invoices',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Revenue',
                    CurrencyHelper.format(totalRevenue),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Collected',
                    CurrencyHelper.format(totalCollected),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Tax',
                    CurrencyHelper.format(totalTax),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
