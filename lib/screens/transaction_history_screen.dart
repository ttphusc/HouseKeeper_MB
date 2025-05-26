import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/getData-giao-dich',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status']) {
        setState(() {
          _transactions =
              List<Map<String, dynamic>>.from(response.data['data']);
          _isLoading = false;
        });
      } else {
        _showError(response.data['message']);
      }
    } catch (e) {
      print('Error loading transactions: $e');
      _showError('Không thể tải lịch sử giao dịch');
    }
  }

  Future<void> _searchTransactions(String query) async {
    if (query.trim().isEmpty) {
      _loadTransactions();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/search-giao-dich',
        queryParameters: {
          'noi_dung_tim': query,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['data'] != null) {
        setState(() {
          _transactions =
              List<Map<String, dynamic>>.from(response.data['data']);
        });
      } else {
        _showError(response.data['message']);
      }
    } catch (e) {
      print('Error searching transactions: $e');
      _showError('Không thể tìm kiếm giao dịch');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 ₫';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  Color _getStatusColor(int type) {
    switch (type) {
      case 1:
        return const Color(0xFF80EE98); // Nạp tiền
      case 2:
        return const Color(0xFF46DFB1); // Rút tiền
      default:
        return const Color(0xFF09D1C7); // Thanh toán
    }
  }

  String _getTransactionType(int type) {
    switch (type) {
      case 1:
        return 'Nạp tiền vào ví';
      case 2:
        return 'Rút tiền từ ví';
      default:
        return 'Thanh toán đơn dịch vụ';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Lịch Sử Giao Dịch'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo nội dung giao dịch hoặc số tiền',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: _searchTransactions,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('Không có giao dịch nào'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(transaction['created_at']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              transaction['type']),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getTransactionType(
                                              transaction['type']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Đã chuyển',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(
                                                transaction['creditAmount']),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Đã nhận',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(
                                                transaction['debitAmount']),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    transaction['description'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
