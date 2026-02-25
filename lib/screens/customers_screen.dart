import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../services/api_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _showPendingOnly = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = _showPendingOnly
          ? await _apiService.getCustomersWithPendingBalances()
          : await _apiService.getCustomers(
              search: _searchController.text.isNotEmpty
                  ? _searchController.text
                  : null,
            );

      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Show user-friendly error message
          final errorString = e.toString();
          if (errorString.contains('Authentication required')) {
            _errorMessage = 'Please login again';
          } else if (errorString.contains('SocketException') ||
              errorString.contains('Connection')) {
            _errorMessage = 'No internet connection';
          } else if (errorString.contains('TimeoutException')) {
            _errorMessage = 'Request timed out. Please try again';
          } else {
            _errorMessage = 'Unable to load customers. Pull to refresh';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'regular';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Customer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Name required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Phone required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Customer Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'regular', child: Text('Regular')),
                    DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                    DropdownMenuItem(
                      value: 'CORPORATE',
                      child: Text('Corporate'),
                    ),
                  ],
                  onChanged: (value) => selectedType = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                try {
                  await _apiService.createCustomer(
                    fullName: nameController.text,
                    phone: phoneController.text,
                    email: emailController.text.isNotEmpty
                        ? emailController.text
                        : null,
                    address: addressController.text.isNotEmpty
                        ? addressController.text
                        : null,
                    customerType: selectedType,
                  );
                  _loadCustomers();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer created!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadCustomers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _loadCustomers(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Pending Balance Only'),
                      selected: _showPendingOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showPendingOnly = selected;
                        });
                        _loadCustomers();
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadCustomers,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCustomers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      itemCount: _customers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        final hasBalance = customer.hasBalance;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: hasBalance ? Colors.red.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasBalance
                                  ? Colors.red
                                  : customer.isVip
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.primary,
                              child: Text(
                                customer.fullName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(customer.fullName),
                                if (customer.isVip) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VIP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.phone),
                                if (hasBalance)
                                  Text(
                                    'Balance: ${currencyFormat.format(customer.pendingBalance)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  'Total visits: ${customer.totalVisits}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (customer.updatedByName != null)
                                  Text(
                                    'Updated by: ${customer.updatedByName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else if (customer.createdByName != null)
                                  Text(
                                    'Added by: ${customer.createdByName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              hasBalance
                                  ? Icons.warning_amber
                                  : Icons.check_circle_outline,
                              color: hasBalance ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCustomerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
