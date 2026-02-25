import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/payment.dart';
import '../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _apiService = ApiService();

  Map<String, dynamic> _todaysPayments = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodaysPayments();
  }

  Future<void> _loadTodaysPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payments = await _apiService.getTodaysPayments();

      if (mounted) {
        setState(() {
          _todaysPayments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    );
    final total = _todaysPayments['total'] ?? 0.0;
    final count = _todaysPayments['count'] ?? 0;
    final byMethod = _todaysPayments['by_method'] ?? {};
    final payments = _todaysPayments['payments'] as List<Payment>? ?? [];

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTodaysPayments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTodaysPayments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Summary Card
                      Card(
                        elevation: 4,
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 48,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Today\'s Collections',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(total),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count ${count == 1 ? 'payment' : 'payments'}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // By Payment Method
                      const Text(
                        'By Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _PaymentMethodRow(
                                icon: Icons.money,
                                label: 'Cash',
                                amount: (byMethod['CASH'] ?? 0.0).toDouble(),
                                color: Colors.green,
                              ),
                              _PaymentMethodRow(
                                icon: Icons.phone_android,
                                label: 'Mobile Money',
                                amount: (byMethod['MOMO'] ?? 0.0).toDouble(),
                                color: Colors.blue,
                              ),
                              _PaymentMethodRow(
                                icon: Icons.receipt,
                                label: 'Cheque',
                                amount: (byMethod['CHEQUE'] ?? 0.0).toDouble(),
                                color: Colors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment List
                      const Text(
                        'Recent Payments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (payments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No payments today'),
                          ),
                        )
                      else
                        ...payments.map((payment) {
                          final paymentTime = DateFormat.jm().format(
                            payment.paymentDate,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  Icons.check,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              title: Text(
                                payment.customerName ?? 'Customer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(payment.methodDisplay),
                                  Text(
                                    paymentTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (payment.receivedByName != null)
                                    Text(
                                      'Received by: ${payment.receivedByName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                currencyFormat.format(payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _PaymentMethodRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amount > 0 ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
