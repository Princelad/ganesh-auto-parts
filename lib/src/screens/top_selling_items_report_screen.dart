import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/invoice_repository.dart';
import '../utils/currency_helper.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

/// Top Selling Items Report Screen
/// Shows best-performing products by quantity sold
class TopSellingItemsReportScreen extends ConsumerStatefulWidget {
  const TopSellingItemsReportScreen({super.key});

  @override
  ConsumerState<TopSellingItemsReportScreen> createState() =>
      _TopSellingItemsReportScreenState();
}

class _TopSellingItemsReportScreenState
    extends ConsumerState<TopSellingItemsReportScreen> {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>>? _topItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopSellingItems();
  }

  Future<void> _loadTopSellingItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _invoiceRepository.getTopSellingItems(
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
        limit: 50,
      );

      setState(() {
        _topItems = items;
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
      _loadTopSellingItems();
    }
  }

  void _setQuickDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      switch (period) {
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
    _loadTopSellingItems();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Selling Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTopSellingItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading sales data...')
          : _error != null
              ? ErrorStateWidget(
                  error: _error!,
                  onRetry: _loadTopSellingItems,
                )
              : RefreshIndicator(
                  onRefresh: _loadTopSellingItems,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info card
                      Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Best-performing products ranked by quantity sold. Use this to optimize inventory and identify popular items.',
                                  style:
                                      TextStyle(color: Colors.amber.shade700),
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

                      // Quick filters
                      _buildQuickFilters(),
                      const SizedBox(height: 24),

                      // Top items list
                      if (_topItems != null && _topItems!.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Top ${_topItems!.length} Items',
                        ),
                        const SizedBox(height: 12),
                        ..._topItems!.asMap().entries.map((entry) {
                          return _buildTopItemCard(
                            entry.key + 1,
                            entry.value,
                          );
                        }),
                      ],

                      // Empty state
                      if (_topItems != null && _topItems!.isEmpty) ...[
                        const SizedBox(height: 48),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sales data',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No items sold in selected period',
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
                          ?.copyWith(color: Colors.grey.shade600),
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
              const Icon(Icons.arrow_forward_ios, size: 16),
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
      backgroundColor: Colors.amber.shade50,
      labelStyle: TextStyle(color: Colors.amber.shade900),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTopItemCard(int rank, Map<String, dynamic> data) {
    final name = data['name'] as String;
    final sku = data['sku'] as String;
    final company = data['company'] as String?;
    final totalQtySold = data['totalQtySold'] as int;
    final totalRevenue = data['totalRevenue'] as double;
    final invoiceCount = data['invoiceCount'] as int;
    final avgSellingPrice = data['avgSellingPrice'] as double;

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
                // Item info
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
                      Text(
                        '${company ?? 'No Brand'} • SKU: $sku',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
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
                    'Quantity Sold',
                    '$totalQtySold units',
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Revenue',
                    CurrencyHelper.format(totalRevenue),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Invoices',
                    '$invoiceCount',
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Avg Price',
                    CurrencyHelper.format(avgSellingPrice),
                    Icons.trending_up,
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
}
