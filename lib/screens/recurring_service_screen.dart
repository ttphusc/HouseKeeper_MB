import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class RecurringServiceScreen extends StatefulWidget {
  final int serviceId;

  const RecurringServiceScreen({super.key, required this.serviceId});

  @override
  State<RecurringServiceScreen> createState() => _RecurringServiceScreenState();
}

class _RecurringServiceScreenState extends State<RecurringServiceScreen> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedAddressId;
  double _durationHours = 2;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '08:00';
  int _paymentMethod = 0; // 0: Ngân hàng, 2: Ví điện tử - không hỗ trợ tiền mặt
  int _months = 3; // Default package: 3 months
  final List<int> _selectedDays =
      []; // Days of week: 0 = Sunday, 1-6 = Monday-Saturday

  // Financial data
  double _basePrice = 0;
  double _totalPrice = 0;
  double _discountAmount = 0;
  double _finalPrice = 0;

  List<String> _timeSlots = [];
  final List<Map<String, dynamic>> _weekdays = [
    {'value': 1, 'label': 'T2'},
    {'value': 2, 'label': 'T3'},
    {'value': 3, 'label': 'T4'},
    {'value': 4, 'label': 'T5'},
    {'value': 5, 'label': 'T6'},
    {'value': 6, 'label': 'T7'},
    {'value': 0, 'label': 'CN'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadBasePrice();
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 8; hour <= 17; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      if (hour < 17) {
        slots.add('${hour.toString().padLeft(2, '0')}:30');
      }
    }
    setState(() {
      _timeSlots = slots;
      _selectedTime = slots[0];
    });
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/dia-chi/data',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final addresses = (response.data['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        setState(() {
          _addresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddressId = addresses[0]['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBasePrice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/so-tien-mac-dinh/${widget.serviceId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['so_tien'] != null) {
        setState(() {
          _basePrice = double.parse(response.data['so_tien'].toString());
          _updateTotalPrice();
        });
      }
    } catch (e) {
      print('Error loading base price: $e');
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _updateTotalPrice();
    });
  }

  void _updateTotalPrice() {
    // Each day of the week is a session
    int sessionsPerMonth = _selectedDays.length * 4; // 4 weeks per month
    int totalSessions = sessionsPerMonth * _months;

    setState(() {
      _totalPrice = _basePrice * totalSessions * _durationHours;
      _finalPrice = _totalPrice - _discountAmount;
    });
  }

  Future<void> _applyDiscountCode(String code) async {
    if (code.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/ma-giam-gia/kiem-tra',
        data: {'code': code},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        final coupon = response.data['coupon'];

        if (_totalPrice >= coupon['dk_toi_thieu_don_hang']) {
          double discount = 0;
          if (coupon['loai_giam_gia'] == 1) {
            // Fixed amount discount
            discount = double.parse(coupon['so_giam_gia'].toString());
          } else {
            // Percentage discount with maximum amount
            final percentDiscount =
                double.parse(coupon['so_giam_gia'].toString()) / 100;
            final maxDiscount =
                double.parse(coupon['so_tien_toi_da'].toString());
            discount = _totalPrice * percentDiscount;
            if (discount > maxDiscount) discount = maxDiscount;
          }

          setState(() {
            _discountAmount = discount;
            _finalPrice = _totalPrice - _discountAmount;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã áp dụng mã giảm giá thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Đơn hàng chưa đạt giá trị tối thiểu để áp dụng mã'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data['message'] ?? 'Mã giảm giá không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error applying discount code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi áp dụng mã giảm giá'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ làm việc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một ngày trong tuần'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final orderData = {
        'id_dia_chi': _selectedAddressId,
        'so_luong_nv': 1, // Fixed for recurring service
        'so_gio_phuc_vu': _durationHours,
        'ngay_bat_dau_lam': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'gio_bat_dau_lam_viec': _selectedTime,
        'phuong_thuc_thanh_toan': _paymentMethod,
        'ghi_chu': _notesController.text,
        'tong_tien': _totalPrice,
        'so_tien_thanh_toan': _finalPrice,
        'so_ngay_phuc_vu_hang_tuan': _selectedDays,
        'so_thang_phuc_vu': _months,
      };

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/dat-don-hang/create/${widget.serviceId}',
        data: orderData,
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
        final orderData = response.data['donHang'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data['message'] ?? 'Đặt đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );

        if (_paymentMethod == 0) {
          // Navigate to payment screen for bank transfer
          // TODO: Implement navigation to payment screen
        } else {
          // Navigate to order details
          // TODO: Implement navigation to order details
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e is DioException && e.response != null) {
        final errors = e.response!.data['errors'];
        if (errors != null && errors is Map) {
          final errorMessages = errors.values.first;
          if (errorMessages is List && errorMessages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessages[0].toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra khi đặt đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi đặt đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Thuê giúp việc định kỳ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading && _addresses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address selection
                    _buildSectionTitle(Icons.location_on, 'Địa điểm làm việc'),
                    _buildAddressDropdown(),
                    const SizedBox(height: 20),

                    // Duration selection
                    _buildSectionTitle(Icons.access_time, 'Thời gian dọn dẹp'),
                    _buildDurationSelector(),
                    const SizedBox(height: 20),

                    // Date and time selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                  Icons.calendar_today, 'Ngày bắt đầu làm'),
                              _buildDatePicker(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                  Icons.access_time, 'Giờ bắt đầu làm'),
                              _buildTimePicker(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Weekly schedule
                    _buildSectionTitle(Icons.date_range, 'Lịch làm hằng tuần'),
                    _buildWeekdaySelector(),
                    const SizedBox(height: 20),

                    // Package selection
                    _buildSectionTitle(Icons.inventory_2, 'Chọn gói'),
                    _buildPackageSelector(),
                    const SizedBox(height: 20),

                    // Payment method selection
                    _buildSectionTitle(
                        Icons.payment, 'Chọn Phương thức thanh toán'),
                    _buildPaymentMethodSelector(),
                    const SizedBox(height: 20),

                    // Notes section
                    _buildSectionTitle(Icons.note, 'Ghi chú'),
                    _buildNotesInput(),
                    const SizedBox(height: 20),

                    // Discount code
                    _buildSectionTitle(Icons.discount, 'Mã giảm giá'),
                    _buildDiscountCodeInput(),
                    const SizedBox(height: 20),

                    // Summary panel
                    _buildOrderSummary(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAddressId,
          isExpanded: true,
          hint: const Text('Chọn địa chỉ làm việc'),
          onChanged: (value) {
            setState(() {
              _selectedAddressId = value;
            });
          },
          items: _addresses.map((address) {
            return DropdownMenuItem<int>(
              value: address['id'],
              child: Text(
                '${address['ten_nguoi_nhan']} - ${address['so_dien_thoai']} - ${address['dia_chi']}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                '2 Giờ',
                _durationHours == 2,
                () {
                  setState(() {
                    _durationHours = 2;
                    _updateTotalPrice();
                  });
                },
                subtitle: 'Tối đa 60m2 Tổng sàn',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectionButton(
                '2.5 Giờ',
                _durationHours == 2.5,
                () {
                  setState(() {
                    _durationHours = 2.5;
                    _updateTotalPrice();
                  });
                },
                subtitle: 'Tối đa 90m2 Tổng sàn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectionButton(
                '4 Giờ',
                _durationHours == 4,
                () {
                  setState(() {
                    _durationHours = 4;
                    _updateTotalPrice();
                  });
                },
                subtitle: 'Tối đa 100m2 Tổng sàn',
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _weekdays.map((day) {
          bool isSelected = _selectedDays.contains(day['value']);
          return GestureDetector(
            onTap: () => _toggleDay(day['value']),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF06D7A0) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  day['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionButton(
            '3 Tháng',
            _months == 3,
            () {
              setState(() {
                _months = 3;
                _updateTotalPrice();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSelectionButton(
            '6 Tháng',
            _months == 6,
            () {
              setState(() {
                _months = 6;
                _updateTotalPrice();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSelectionButton(
            '12 Tháng',
            _months == 12,
            () {
              setState(() {
                _months = 12;
                _updateTotalPrice();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSelectionButton(
            '18 Tháng',
            _months == 18,
            () {
              setState(() {
                _months = 18;
                _updateTotalPrice();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
        );
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTime,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTime = value;
              });
            }
          },
          items: _timeSlots.map((time) {
            return DropdownMenuItem<String>(
              value: time,
              child: Text(time),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionButton(
            'Ngân hàng',
            _paymentMethod == 0,
            () {
              setState(() {
                _paymentMethod = 0;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSelectionButton(
            'Ví điện tử',
            _paymentMethod == 2,
            () {
              setState(() {
                _paymentMethod = 2;
              });
            },
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Các lưu ý của quý khách dành cho nhân viên giúp việc',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildDiscountCodeInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                hintText: 'Nhập mã giảm giá (Nếu có)',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _applyDiscountCode(_discountController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF46DFB1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Mã Giảm'),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    int sessionsPerWeek = _selectedDays.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Staff and hours info
              Expanded(
                child: _buildSummaryItem(
                  Icons.people,
                  '1 Nhân viên x $_durationHours giờ',
                ),
              ),

              // Total before discount
              Expanded(
                child: _buildSummaryItem(
                  Icons.receipt,
                  'Tổng tiền hoá đơn:',
                  value: _formatCurrency(_totalPrice),
                  valueColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Discount amount
              Expanded(
                child: _buildSummaryItem(
                  Icons.discount,
                  'Số tiền giảm:',
                  value: _formatCurrency(_discountAmount),
                  valueColor: Colors.red,
                ),
              ),

              // Final price
              Expanded(
                child: _buildSummaryItem(
                  Icons.account_balance_wallet,
                  'Tổng tiền:',
                  value: _formatCurrency(_finalPrice),
                  valueColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _createOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String title,
      {String? value, Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF46DFB1)),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        if (value != null)
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildSelectionButton(
      String title, bool isSelected, VoidCallback onTap,
      {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06D7A0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
