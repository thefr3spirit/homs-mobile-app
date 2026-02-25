import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import '../services/api_service.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  final int days;

  const RevenueAnalyticsScreen({super.key, required this.days});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  final _apiService = ApiService();
  List<DailySummary> _summaries = [];
  bool _isLoading = false;
  String? _error;
  late int _selectedDays;

  final _currencyFormat = NumberFormat.currency(
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.days;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedDays));

      final summaries = await _apiService.getSummaryRange(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _summaries = summaries;
          // Sort chronologically (oldest first) for proper graph x-axis
          _summaries.sort((a, b) => a.date.compareTo(b.date));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Trends'),
        backgroundColor: const Color(0xFF3D5A80),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<int>(
              value: _selectedDays,
              dropdownColor: const Color(0xFF3D5A80),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
              ],
              onChanged: (value) {
                if (value != null && value != _selectedDays) {
                  setState(() {
                    _selectedDays = value;
                  });
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _summaries.isEmpty
          ? _buildEmpty()
          : _buildAnalytics(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading data'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No data available for the selected period'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    // Calculate statistics
    final totalRevenue = _summaries.isEmpty
        ? 0.0
        : _summaries.map((s) => s.totalCollected).reduce((a, b) => a + b);
    final avgRevenue = _summaries.isEmpty
        ? 0.0
        : totalRevenue / _summaries.length;
    final maxRevenue = _summaries.isEmpty
        ? 0.0
        : _summaries
              .map((s) => s.totalCollected)
              .reduce((a, b) => a > b ? a : b);
    final minRevenue = _summaries.isEmpty
        ? 0.0
        : _summaries
              .map((s) => s.totalCollected)
              .reduce((a, b) => a < b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Revenue',
                  value: _currencyFormat.format(totalRevenue),
                  color: Colors.green,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Daily Average',
                  value: _currencyFormat.format(avgRevenue),
                  color: Colors.blue,
                  icon: Icons.analytics,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Highest Day',
                  value: _currencyFormat.format(maxRevenue),
                  color: Colors.teal,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Lowest Day',
                  value: _currencyFormat.format(minRevenue),
                  color: Colors.orange,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Line Chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  NumberFormat.compact().format(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < _summaries.length) {
                                  final date = _summaries[value.toInt()].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('M/d').format(date),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        minX: 0,
                        maxX: (_summaries.length - 1).toDouble(),
                        minY: minRevenue > 0 ? minRevenue * 0.8 : 0,
                        maxY: maxRevenue * 1.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _summaries.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value.totalCollected,
                              );
                            }).toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.green,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method Breakdown
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBreakdownRow(
                    'Cash',
                    _summaries
                        .map((s) => s.cashCollected)
                        .reduce((a, b) => a + b),
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownRow(
                    'Mobile Money',
                    _summaries
                        .map((s) => s.momoCollected)
                        .reduce((a, b) => a + b),
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownRow(
                    'Cheque',
                    _summaries
                        .map((s) => s.chequeCollected)
                        .reduce((a, b) => a + b),
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Table
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._summaries.reversed
                      .take(10)
                      .map(
                        (summary) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(summary.date),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currencyFormat.format(
                                    summary.totalCollected,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (_summaries.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '+ ${_summaries.length - 10} more days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
