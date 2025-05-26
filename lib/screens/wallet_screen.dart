import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  Map<String, dynamic> _walletData = {};
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _lsGiaoDich = [];
  String? _errorMessage;
  String _selectedFilter = '';
  bool _hasBankAccount = false;
  final TextEditingController _withdrawAmountController =
      TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  String _selectedBank = '';
  String _rawInput = '';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _checkBankAccount();
    _loadTransactionsFromLocalStorage();
    _loadLSGiaoDich();
  }

  Future<void> _loadWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/vi-dien-tu/getData',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['data'] != null) {
        setState(() {
          _walletData = response.data['data'];
          _isLoading = false;
        });
        debugPrint("vi data: ${response.data['data']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadTransactionsFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('transactions');
    if (stored != null) {
      try {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(
            (jsonDecode(stored) as List)
                .map((x) => Map<String, dynamic>.from(x)),
          );
        });
      } catch (e) {
        debugPrint("Dữ liệu trong LocalStorage bị lỗi: $e");
        setState(() {
          _transactions = [];
        });
      }
    }
  }

  void _saveTransactionsToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', jsonEncode(_transactions));
  }

  void _addTransaction(String type, double amount) {
    final newTransaction = {
      'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'type': type,
      'amount': amount,
    };
    setState(() {
      _transactions.insert(0, newTransaction);
    });
    _saveTransactionsToLocalStorage();
  }

  Future<void> _loadLSGiaoDich() async {
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

      if (response.data['status'] == true) {
      setState(() {
          _lsGiaoDich = List<Map<String, dynamic>>.from(response.data['data']);
        });
        } else {
        _showErrorToast("Thông báo: ${response.data['message']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
    }
  }

  Future<void> _checkBankAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/ngan-hang-vi/check',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        setState(() {
          _hasBankAccount = true;
        });
        _showSuccessToast("Thông báo: ${response.data['message']}");
      } else {
        _showErrorToast("Thông báo: ${response.data['message']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
    }
  }

  Future<void> _updateBankAccount() async {
    if (_bankAccountController.text.isEmpty || _selectedBank.isEmpty) {
      _showErrorToast('Vui lòng điền đầy đủ thông tin tài khoản ngân hàng');
                            return;
                          }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/ngan-hang-vi/create',
        data: {
          'stk': _bankAccountController.text,
          'ten_ngan_hang': _selectedBank,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        _showSuccessToast("Thông báo: ${response.data['message']}");
        Navigator.pop(context);
        setState(() {
          _hasBankAccount = true;
        });
        debugPrint("Ngân hàng người dùng: $_selectedBank");
      } else {
        _showErrorToast("Thông báo: ${response.data['message']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
    }
  }

  Future<void> _topUpWallet() async {
    setState(() => _isLoading = true);
    _showInfoToast("Hệ thống đang xử lý giao dịch, hãy đợi trong ít phút.");
    Navigator.pop(context);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/vi-dien-tu/napTien',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        _showSuccessToast("Thông báo: ${response.data['message']}");
        _loadWalletData();
      } else {
        _showErrorToast("Thông báo: ${response.data['message']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _withdrawMoney() async {
    if (_withdrawAmountController.text.isEmpty) {
      _showErrorToast('Vui lòng nhập số tiền cần rút');
                            return;
                          }

    final amount = double.parse(_rawInput);
    if (amount < 10000) {
      _showErrorToast("Số tiền rút phải lớn hơn hoặc bằng 10,000 VNĐ!");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/vi-dien-tu/guiYeuCauRutTien',
        data: {
          'so_tien_rut': amount,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        _showSuccessToast("Thông báo: ${response.data['message']}");
        Navigator.pop(context);
                            _loadWalletData();
      } else {
        _showErrorToast("Thông báo: ${response.data['message']}");
      }
    } catch (error) {
      if (error is DioException && error.response?.data['errors'] != null) {
        final errors = error.response?.data['errors'] as Map;
        for (var value in errors.values) {
          _showErrorToast("Thông báo: $value");
        }
      }
    }
  }

  void _updateWithdrawAmount(String value) {
    _rawInput = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (_rawInput.isNotEmpty) {
      final amount = double.parse(_rawInput);
      setState(() {
        _withdrawAmountController.text = _formatCurrency(amount);
        _withdrawAmountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _withdrawAmountController.text.length),
        );
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (_selectedFilter.isEmpty) {
      return _lsGiaoDich
          .where((item) => item['type'] == 1 || item['type'] == 2)
          .toList();
    }
    final typeMapping = {
      'nạp tiền': 1,
      'rút tiền': 2,
    };
    final selectedType = typeMapping[_selectedFilter];
    return _lsGiaoDich.where((item) => item['type'] == selectedType).toList();
  }

  Map<String, dynamic> _formatTransaction(Map<String, dynamic> item) {
    final typeMapping = {
      1: 'nạp tiền',
      2: 'rút tiền',
    };
    final isCredit = item['type'] == 1;
    final amount = isCredit ? item['creditAmount'] : item['debitAmount'];
    final amountClass = isCredit ? 'text-success' : 'text-danger';

    return {
      'date':
          DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at'])),
      'type': typeMapping[item['type']],
      'amount': _formatCurrency(amount?.toDouble() ?? 0),
      'isCredit': isCredit,
    };
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showInfoToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  String _getQRCodeUrl() {
    final addInfo = Uri.encodeComponent(
        '${_walletData['so_dien_thoai']} , ${_walletData['ho_va_ten']}');
    return 'https://img.vietqr.io/image/MB-0369396097-qr_only.png?addInfo=$addInfo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví điện tử'),
        backgroundColor: const Color(0xFF46DFB1),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      // Balance Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số dư hiện tại',
            style: TextStyle(
              fontSize: 16,
                                        color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
                                      _formatCurrency(
                                          _walletData['so_du']?.toDouble() ??
                                              0),
            style: const TextStyle(
                                        fontSize: 24,
              fontWeight: FontWeight.bold,
                                        color: Color(0xFF46DFB1),
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showTopUpDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nạp tiền'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF46DFB1),
                                    foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bank Account Update Button
                      ElevatedButton.icon(
                        onPressed: () => _showBankAccountDialog(),
                        icon: const Icon(Icons.account_balance),
                        label: const Text('Cập nhật số tài khoản ngân hàng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF46DFB1),
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Color(0xFF46DFB1)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transaction History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                          const Text(
                            'Lịch sử giao dịch',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedFilter.isEmpty
                                ? null
                                : _selectedFilter,
                            hint: const Text('Tất cả'),
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('Tất cả'),
                              ),
                              DropdownMenuItem(
                                value: 'nạp tiền',
                                child: Text('Nạp tiền'),
                              ),
                              DropdownMenuItem(
                                value: 'rút tiền',
                                child: Text('Rút tiền'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value ?? '';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Transactions List
                      _getFilteredTransactions().isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'Không có giao dịch nào được tìm thấy.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _getFilteredTransactions().length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final transaction = _formatTransaction(
                                    _getFilteredTransactions()[index]);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: transaction['isCredit']
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    child: Icon(
                                      transaction['isCredit']
                                          ? Icons.add
                                          : Icons.remove,
                                      color: transaction['isCredit']
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    transaction['type'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(transaction['date']),
                                  trailing: Text(
                                    '${transaction['isCredit'] ? '+' : '-'} ${transaction['amount']}',
                                    style: TextStyle(
                                      color: transaction['isCredit']
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                ),
              );
            },
          ),

                      const SizedBox(height: 24),

                      // Withdraw Button
                      ElevatedButton.icon(
                        onPressed: () => _showWithdrawDialog(),
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('Rút tiền'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF46DFB1),
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Color(0xFF46DFB1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _showBankAccountDialog() {
    final List<Map<String, String>> banks = [
      {
        'value': 'Agribank',
        'label':
            'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam (Agribank)'
      },
      {
        'value': 'Vietcombank',
        'label': 'Ngân hàng TMCP Ngoại thương Việt Nam (Vietcombank)'
      },
      {
        'value': 'BIDV',
        'label': 'Ngân hàng Đầu tư và Phát triển Việt Nam (BIDV)'
      },
      {
        'value': 'VietinBank',
        'label': 'Ngân hàng Thương mại Việt Nam (VietinBank)'
      },
      {
        'value': 'Techcombank',
        'label': 'Ngân hàng TMCP Kỹ Thương (Techcombank)'
      },
      {'value': 'MBBank', 'label': 'Ngân hàng Quân đội (MB Bank)'},
      {
        'value': 'Sacombank',
        'label': 'Ngân hàng Sài Gòn Thương Tín (Sacombank)'
      },
      {'value': 'ACB', 'label': 'Ngân hàng Á Châu (ACB)'},
      {'value': 'SCB', 'label': 'Ngân hàng TMCP Sài Gòn (SCB)'},
      {'value': 'HDBank', 'label': 'Ngân hàng TMCP Phát Triển TP.HCM (HDBank)'},
      {'value': 'SHB', 'label': 'Ngân hàng TMCP Sài Gòn - Hà Nội (SHB)'},
      {
        'value': 'BaoVietBank',
        'label': 'Ngân hàng TMCP Bảo Việt (BaoViet Bank)'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật tài khoản ngân hàng'),
        content: SingleChildScrollView(
      child: Column(
            mainAxisSize: MainAxisSize.min,
        children: [
              TextField(
                controller: _bankAccountController,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  hintText: 'Nhập số tài khoản ngân hàng',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBank.isEmpty ? null : _selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Chọn ngân hàng',
                ),
                items: banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank['value'],
                    child: Text(
                      bank['label']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _updateBankAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nạp tiền vào ví'),
        content: _hasBankAccount
            ? Column(
                mainAxisSize: MainAxisSize.min,
          children: [
                  Image.network(
                    _getQRCodeUrl(),
                    height: 200,
                    width: 200,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.qr_code_2,
                      size: 200,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 16),
                  const Text(
                    'Vui lòng quét mã QR để thanh toán.\nSau khi chuyển khoản, nhấn "Xác nhận".',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : const Text(
                'Bạn cần cập nhật thông tin tài khoản ngân hàng trước khi nạp tiền.',
                textAlign: TextAlign.center,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          if (_hasBankAccount)
            ElevatedButton(
              onPressed: _topUpWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
    }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút tiền'),
        content: _hasBankAccount
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _withdrawAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền cần rút',
                      hintText: 'Nhập số tiền (VNĐ)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _updateWithdrawAmount,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lưu ý: Số tiền rút phải nhỏ hơn số dư hiện có và tối thiểu 10,000 VNĐ',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Text(
                'Bạn cần cập nhật thông tin tài khoản ngân hàng trước khi rút tiền.',
                textAlign: TextAlign.center,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          if (_hasBankAccount)
            ElevatedButton(
              onPressed: _withdrawMoney,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Xác nhận'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _withdrawAmountController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }
}
