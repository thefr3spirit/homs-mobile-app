import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  List<DailySummary> _summaries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaries = await _apiService.getSummaryHistory(
        limit: 100,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _summaries = summaries;
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'UGX ${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, y').format(date);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(forceRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _summaries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No summary history yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _summaries.length,
                itemBuilder: (context, index) {
                  final summary = _summaries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _showSummaryDetails(summary),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(summary.date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${summary.occupancyRate.toStringAsFixed(0)}% occupied',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Key metrics row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricChip(
                                    context,
                                    'Rooms',
                                    '${summary.roomsOccupied}/${summary.roomsTotal}',
                                    Icons.hotel,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildMetricChip(
                                    context,
                                    'Collected',
                                    _formatCurrency(summary.totalCollected),
                                    Icons.monetization_on,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Payment breakdown
                            Row(
                              children: [
                                _buildPaymentDetail(
                                  'Cash',
                                  summary.cashCollected,
                                  Colors.green.shade700,
                                ),
                                const SizedBox(width: 12),
                                _buildPaymentDetail(
                                  'MOMO',
                                  summary.momoCollected,
                                  Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                _buildPaymentDetail(
                                  'Cheque',
                                  summary.chequeCollected,
                                  Colors.orange.shade700,
                                ),
                              ],
                            ),

                            // User tracking info
                            if (summary.updatedByName != null ||
                                summary.createdByName != null) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      summary.updatedByName != null
                                          ? 'Updated by ${summary.updatedByName}'
                                          : 'Submitted by ${summary.createdByName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(summary.lastUpdated),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String method, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          method,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showSummaryDetails(DailySummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(summary.date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Room Statistics
              _buildDetailSection('Room Statistics', [
                _buildDetailRow('Total Rooms', summary.roomsTotal.toString()),
                _buildDetailRow('Occupied', summary.roomsOccupied.toString()),
                _buildDetailRow('Available', summary.roomsAvailable.toString()),
                _buildDetailRow(
                  'Occupancy Rate',
                  '${summary.occupancyRate.toStringAsFixed(1)}%',
                ),
              ]),

              const SizedBox(height: 16),

              // Financial Summary
              _buildDetailSection('Financial Summary', [
                _buildDetailRow(
                  'Cash Collected',
                  _formatCurrency(summary.cashCollected),
                ),
                _buildDetailRow(
                  'MOMO Collected',
                  _formatCurrency(summary.momoCollected),
                ),
                _buildDetailRow(
                  'Cheque Collected',
                  _formatCurrency(summary.chequeCollected),
                ),
                _buildDetailRow(
                  'Total Collected',
                  _formatCurrency(summary.totalCollected),
                  bold: true,
                ),
                _buildDetailRow(
                  'Expected Balance',
                  _formatCurrency(summary.expectedBalance),
                ),
                _buildDetailRow(
                  'Expenses Logged',
                  _formatCurrency(summary.expensesLogged),
                ),
                _buildDetailRow(
                  'Net Revenue',
                  _formatCurrency(summary.netRevenue),
                  bold: true,
                ),
              ]),

              // User Tracking
              if (summary.createdByName != null ||
                  summary.updatedByName != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Tracking Information', [
                  if (summary.createdByName != null)
                    _buildDetailRow('Submitted By', summary.createdByName!),
                  if (summary.updatedByName != null)
                    _buildDetailRow('Last Updated By', summary.updatedByName!),
                  _buildDetailRow(
                    'Last Updated',
                    _formatTime(summary.lastUpdated),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
