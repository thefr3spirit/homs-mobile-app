import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import '../services/api_service.dart';
import 'pending_balances_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  DailySummary? _todaySummary;
  int _pendingBalanceCount = 0;
  double _totalPendingBalance = 0.0;
  bool _isLoading = true;
  bool _isLoadingBalances = true;
  String? _errorMessage;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPendingBalances();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _apiService.getTodaySummary(
        forceRefresh: forceRefresh,
      );
      setState(() {
        _todaySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingBalances() async {
    setState(() {
      _isLoadingBalances = true;
    });

    try {
      final summary = await _apiService.getCustomerBalancesSummary();
      if (mounted) {
        setState(() {
          _pendingBalanceCount = summary['customer_count'] ?? 0;
          _totalPendingBalance = (summary['total_pending'] ?? 0.0).toDouble();
          _isLoadingBalances = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalances = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData(forceRefresh: true);
          await _loadPendingBalances();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget()
            : _todaySummary == null
            ? _buildNoDataWidget()
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error loading summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _loadData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.onNavigateToTab != null
                      ? () => widget.onNavigateToTab!(1)
                      : null,
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Pending Balances card - always visible
        _buildPendingBalancesCard(),
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'No daily summary yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for today\'s summary from the counter app',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _loadData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.onNavigateToTab != null
                      ? () => widget.onNavigateToTab!(1)
                      : null,
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Pending Balances card - always visible
        _buildPendingBalancesCard(),

        const SizedBox(height: 16),

        // Info card
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can still view pending balances and access history while waiting for today\'s summary.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    final summary = _todaySummary!;
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(summary.date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Updated by text
                    if (summary.updatedByName != null ||
                        summary.createdByName != null)
                      Text(
                        summary.updatedByName != null
                            ? 'Updated by ${summary.updatedByName}'
                            : 'Submitted by ${summary.createdByName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadData(forceRefresh: true),
                tooltip: 'Refresh data',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Room occupancy card
          _buildCard(
            title: 'Room Occupancy',
            icon: Icons.hotel,
            color: Colors.blue,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Total', '${summary.roomsTotal}'),
                    _buildStat('Occupied', '${summary.roomsOccupied}'),
                    _buildStat('Available', '${summary.roomsAvailable}'),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: summary.occupancyRate / 100,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.occupancyRate.toStringAsFixed(1)}% Occupancy',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Revenue card
          _buildCard(
            title: 'Revenue',
            icon: Icons.attach_money,
            color: Colors.green,
            child: Column(
              children: [
                _buildMoneyRow('Cash', summary.cashCollected),
                const Divider(),
                _buildMoneyRow('Mobile Money', summary.momoCollected),
                const Divider(),
                _buildMoneyRow('Cheque', summary.chequeCollected),
                const Divider(),
                _buildMoneyRow(
                  'Total Collected',
                  summary.totalCollected,
                  isHighlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Expenses card
          _buildCard(
            title: 'Expenses',
            icon: Icons.money_off,
            color: Colors.red,
            child: _buildMoneyRow('Total Expenses', summary.expensesLogged),
          ),
          const SizedBox(height: 16),

          // Net revenue card
          _buildCard(
            title: 'Net Revenue',
            icon: Icons.account_balance_wallet,
            color: summary.netRevenue >= 0 ? Colors.teal : Colors.deepOrange,
            child: Text(
              _currencyFormat.format(summary.netRevenue),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Pending Balances card
          _buildPendingBalancesCard(),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMoneyRow(
    String label,
    double amount, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: isHighlight ? 20 : 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBalancesCard() {
    if (_isLoadingBalances) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Balances',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final hasBalances = _pendingBalanceCount > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PendingBalancesScreen()),
        ).then((_) => _loadPendingBalances());
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        color: hasBalances ? Colors.orange.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasBalances ? Icons.warning_amber : Icons.check_circle,
                    color: hasBalances ? Colors.orange.shade700 : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Balances',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasBalances
                          ? Colors.orange.shade700
                          : Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: hasBalances
                        ? Colors.grey.shade600
                        : Colors.green.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasBalances) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_pendingBalanceCount',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Text(
                          'Customers',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(_totalPendingBalance),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const Text(
                          'Total Outstanding',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.orange.shade900,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to view customers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All clear!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No pending balances to collect',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.green.shade900,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tap to view all customers',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
