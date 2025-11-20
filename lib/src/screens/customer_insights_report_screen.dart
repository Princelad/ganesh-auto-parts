import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/invoice_repository.dart';
import '../utils/currency_helper.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

/// Customer Insights Report Screen
/// Shows top customers and buying patterns
class CustomerInsightsReportScreen extends ConsumerStatefulWidget {
  const CustomerInsightsReportScreen({super.key});

  @override
  ConsumerState<CustomerInsightsReportScreen> createState() =>
      _CustomerInsightsReportScreenState();
}

class _CustomerInsightsReportScreenState
    extends ConsumerState<CustomerInsightsReportScreen> {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>>? _customerData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _invoiceRepository.getCustomerPurchaseSummary(
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
        limit: 50,
      );

      setState(() {
        _customerData = data;
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
      _loadCustomerData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomerData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading customer data...')
          : _error != null
              ? ErrorStateWidget(
                  error: _error!,
                  onRetry: _loadCustomerData,
                )
              : RefreshIndicator(
                  onRefresh: _loadCustomerData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info card
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_circle, color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Top customers and buying patterns. Identify valuable customers.',
                                  style: TextStyle(color: Colors.green.shade700),
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
                                    Icons.date_range,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
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
                      const SizedBox(height: 24),

                      // Customer data list
                      if (_customerData != null && _customerData!.isNotEmpty) ...[
                        Text(
                          'Top ${_customerData!.length} Customers',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ..._customerData!.asMap().entries.map((entry) {
                          return _buildCustomerCard(
                            entry.key + 1,
                            entry.value,
                          );
                        }),
                      ],

                      // Empty state
                      if (_customerData != null && _customerData!.isEmpty) ...[
                        const SizedBox(height: 48),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No customer data',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No customer purchases in selected period',
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

  Widget _buildCustomerCard(int rank, Map<String, dynamic> data) {
    final name = data['name'] as String;
    final phone = data['phone'] as String;
    final balance = data['balance'] as double;
    final invoiceCount = data['invoiceCount'] as int;
    final totalRevenue = data['totalRevenue'] as double;
    final avgOrderValue = data['avgOrderValue'] as double;
    final lastPurchaseDate = data['lastPurchaseDate'] as int;

    // Medal colors for top 3
    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = Colors.amber.shade700;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade600;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade600;
      rankIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor != null
                        ? rankColor.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: rankIcon != null
                        ? Icon(rankIcon, color: rankColor, size: 24)
                        : Text(
                            '#$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Customer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (balance > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: Colors.orange.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Total Revenue',
                    CurrencyHelper.format(totalRevenue),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Avg Order',
                    CurrencyHelper.format(avgOrderValue),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Purchases',
                    '$invoiceCount orders',
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Last Purchase',
                    _formatDate(lastPurchaseDate),
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (balance > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: Colors.orange.shade900,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Outstanding Balance: ${CurrencyHelper.format(balance)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
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

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }
}
