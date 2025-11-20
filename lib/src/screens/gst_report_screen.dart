import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/invoice_repository.dart';
import '../utils/currency_helper.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

/// GST/Tax Collection Report Screen
class GstReportScreen extends ConsumerStatefulWidget {
  const GstReportScreen({super.key});

  @override
  ConsumerState<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends ConsumerState<GstReportScreen> {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  // Date range selection
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Data
  Map<String, dynamic>? _gstSummary;
  List<Map<String, dynamic>>? _gstBreakdown;
  List<Map<String, dynamic>>? _monthlyGstSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGstData();
  }

  Future<void> _loadGstData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startMillis = _startDate.millisecondsSinceEpoch;
      final endMillis = _endDate.millisecondsSinceEpoch;

      final summary = await _invoiceRepository.getGstSummary(
        startMillis,
        endMillis,
      );
      final breakdown = await _invoiceRepository.getGstBreakdownByRate(
        startMillis,
        endMillis,
      );
      final monthlySummary = await _invoiceRepository.getMonthlyGstSummary(6);

      setState(() {
        _gstSummary = summary;
        _gstBreakdown = breakdown;
        _monthlyGstSummary = monthlySummary;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadGstData();
    }
  }

  void _setQuickDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'quarter':
          _startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'year':
          _startDate = DateTime(now.year - 1, now.month, now.day);
          break;
      }
    });
    _loadGstData();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST/Tax Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGstData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading GST data...')
          : _error != null
          ? ErrorStateWidget(error: _error!, onRetry: _loadGstData)
          : RefreshIndicator(
              onRefresh: _loadGstData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'GST/Tax collection report for your business. Select a date range to view tax details.',
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date range selection
                  _buildDateRangeCard(dateFormat),
                  const SizedBox(height: 16),

                  // Quick date filters
                  _buildQuickFilters(),
                  const SizedBox(height: 24),

                  // Summary section
                  if (_gstSummary != null) ...[
                    _buildSectionHeader('Summary'),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                  ],

                  // Breakdown by tax rate
                  if (_gstBreakdown != null && _gstBreakdown!.isNotEmpty) ...[
                    _buildSectionHeader('Tax Rate Breakdown'),
                    const SizedBox(height: 12),
                    ..._gstBreakdown!.map(_buildBreakdownCard),
                    const SizedBox(height: 24),
                  ],

                  // Monthly trend
                  if (_monthlyGstSummary != null &&
                      _monthlyGstSummary!.isNotEmpty) ...[
                    _buildSectionHeader('Monthly Trend (Last 6 Months)'),
                    const SizedBox(height: 12),
                    ..._monthlyGstSummary!.map(_buildMonthlyCard),
                  ],

                  // Empty state
                  if (_gstSummary?['invoiceCount'] == 0) ...[
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
                            'No invoices found',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create invoices to see GST reports',
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

  Widget _buildDateRangeCard(DateFormat dateFormat) {
    return Card(
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
                child: Icon(Icons.date_range, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Today', () => _setQuickDateRange('today')),
          const SizedBox(width: 8),
          _buildFilterChip('Last 7 Days', () => _setQuickDateRange('week')),
          const SizedBox(width: 8),
          _buildFilterChip('Last Month', () => _setQuickDateRange('month')),
          const SizedBox(width: 8),
          _buildFilterChip('Last Quarter', () => _setQuickDateRange('quarter')),
          const SizedBox(width: 8),
          _buildFilterChip('Last Year', () => _setQuickDateRange('year')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _gstSummary!;
    final invoiceCount = summary['invoiceCount'] as int;
    final totalSubtotal = summary['totalSubtotal'] as double;
    final totalTax = summary['totalTax'] as double;
    final totalAmount = summary['totalAmount'] as double;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Invoice count
            _buildSummaryRow(
              'Total Invoices',
              invoiceCount.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            const Divider(height: 24),

            // Subtotal (before tax)
            _buildSummaryRow(
              'Subtotal (Before Tax)',
              CurrencyHelper.format(totalSubtotal),
              Icons.attach_money,
              Colors.green,
            ),
            const Divider(height: 24),

            // Total tax collected
            _buildSummaryRow(
              'Total Tax Collected',
              CurrencyHelper.format(totalTax),
              Icons.account_balance,
              Colors.orange,
              isHighlight: true,
            ),
            const Divider(height: 24),

            // Grand total
            _buildSummaryRow(
              'Grand Total (With Tax)',
              CurrencyHelper.format(totalAmount),
              Icons.payment,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? color : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(Map<String, dynamic> data) {
    final taxRate = data['taxRate'] as double;
    final invoiceCount = data['invoiceCount'] as int;
    final totalSubtotal = data['totalSubtotal'] as double;
    final totalTax = data['totalTax'] as double;
    final totalAmount = data['totalAmount'] as double;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: taxRate > 0
                            ? Colors.orange.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        taxRate > 0
                            ? '${taxRate.toStringAsFixed(0)}% GST'
                            : 'No Tax',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: taxRate > 0
                              ? Colors.orange.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$invoiceCount ${invoiceCount == 1 ? 'invoice' : 'invoices'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Subtotal',
                    CurrencyHelper.format(totalSubtotal),
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    'Tax Amount',
                    CurrencyHelper.format(totalTax),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    'Total',
                    CurrencyHelper.format(totalAmount),
                    isBold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> data) {
    final month = data['month'] as String;
    final invoiceCount = data['invoiceCount'] as int;
    final totalTax = data['totalTax'] as double;
    final totalAmount = data['totalAmount'] as double;

    // Format month string (YYYY-MM to MMM YYYY)
    DateTime? monthDate;
    try {
      final parts = month.split('-');
      if (parts.length == 2) {
        monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (e) {
      // Ignore parsing errors
    }

    final monthLabel = monthDate != null
        ? DateFormat('MMM yyyy').format(monthDate)
        : month;

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
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$invoiceCount invoices',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Tax Collected',
                    CurrencyHelper.format(totalTax),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    'Total Sales',
                    CurrencyHelper.format(totalAmount),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
