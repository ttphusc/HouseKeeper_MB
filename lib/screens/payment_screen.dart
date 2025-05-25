import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final double amount;
  final int orderId;
  final int serviceId;

  const PaymentScreen({
    super.key,
    this.orderData,
    required this.amount,
    required this.orderId,
    required this.serviceId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Dio _dio = Dio();
  bool _isLoading = false;
  String? _errorMessage;

  // Payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 0,
      'name': 'Chuyển khoản ngân hàng',
      'icon': Icons.account_balance,
      'description': 'Thanh toán qua tài khoản ngân hàng',
    },
    {
      'id': 2,
      'name': 'Ví điện tử',
      'icon': Icons.account_balance_wallet,
      'description': 'Thanh toán qua ví điện tử (MoMo, ZaloPay...)',
    },
  ];

  // Selected payment method
  Map<String, dynamic>? _selectedPaymentMethod;

  // Bank accounts for transfer
  final List<Map<String, dynamic>> _bankAccounts = [
    {
      'bank_name': 'Vietcombank',
      'account_number': '1234567890',
      'account_holder': 'NGUYEN VAN A',
      'branch': 'Chi nhánh Hà Nội',
      'logo': 'assets/images/vietcombank.png',
    },
    {
      'bank_name': 'MB Bank',
      'account_number': '9876543210',
      'account_holder': 'NGUYEN VAN A',
      'branch': 'Chi nhánh TP.HCM',
      'logo': 'assets/images/mbbank.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default to bank transfer
    _selectedPaymentMethod = _paymentMethods[0];
  }

  String _formatCurrency(double value) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(value);
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn phương thức thanh toán';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      // Prepare payment data
      final paymentData = {
        'id_don_hang': widget.orderId,
        'id_dich_vu': widget.serviceId,
        'phuong_thuc_thanh_toan': _selectedPaymentMethod!['id'],
        'so_tien_thanh_toan': widget.amount,
      };

      // Add order data if provided
      if (widget.orderData != null) {
        paymentData.addAll(widget.orderData!);
      }

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thanh-toan',
        data: paymentData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.data['status'] == true) {
        // Payment successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Thanh toán thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home or order confirmation screen after delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true); // Return true to indicate success
        });
      } else {
        // Payment failed
        setState(() {
          _errorMessage = response.data['message'] ?? 'Thanh toán thất bại';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Có lỗi xảy ra trong quá trình thanh toán. Vui lòng thử lại sau.';
      });

      print('Payment error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate random transaction reference code
  String _generateTransactionRef() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'HK${widget.orderId}$random';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Thanh toán'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment amount
                    _buildAmountSection(),
                    const SizedBox(height: 24),

                    // Payment method selection
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 24),

                    // Payment details based on selected method
                    _buildPaymentDetails(),
                    const SizedBox(height: 24),

                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Payment button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF46DFB1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Thanh toán ${_formatCurrency(widget.amount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mã đơn hàng:',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  '#${widget.orderId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số tiền thanh toán:',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatCurrency(widget.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mã giao dịch:',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  _generateTransactionRef(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final bool isSelected = _selectedPaymentMethod == method;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF46DFB1)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF46DFB1)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        method['icon'],
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<Map<String, dynamic>>(
                      value: method,
                      groupValue: _selectedPaymentMethod,
                      activeColor: const Color(0xFF46DFB1),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    // Bank transfer details
    if (_selectedPaymentMethod?['id'] == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chuyển khoản',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_bankAccounts.length, (index) {
            final bankAccount = _bankAccounts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.shade100,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.account_balance,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bankAccount['bank_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildBankInfoRow(
                        'Tên tài khoản:', bankAccount['account_holder']),
                    const SizedBox(height: 4),
                    _buildBankInfoRow(
                        'Số tài khoản:', bankAccount['account_number'],
                        isCopyable: true),
                    const SizedBox(height: 4),
                    _buildBankInfoRow('Chi nhánh:', bankAccount['branch']),
                    const SizedBox(height: 4),
                    _buildBankInfoRow('Nội dung CK:',
                        'HKS${widget.serviceId}O${widget.orderId}',
                        isCopyable: true),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vui lòng ghi đúng nội dung chuyển khoản để hệ thống xác nhận thanh toán của bạn.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }
    // E-wallet details
    else if (_selectedPaymentMethod?['id'] == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin ví điện tử',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn "Thanh toán" để chuyển đến trang thanh toán ví điện tử.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/momo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.pink.shade100,
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.pink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/zalopay.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.blue.shade100,
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/vnpay.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.red.shade100,
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Default empty state
    return const SizedBox.shrink();
  }

  Widget _buildBankInfoRow(String label, String value,
      {bool isCopyable = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              // Copy to clipboard functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã sao chép: $value'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
      ],
    );
  }
}
