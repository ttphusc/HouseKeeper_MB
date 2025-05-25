import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class CleaningServiceScreen extends StatefulWidget {
  final int serviceId;

  const CleaningServiceScreen({super.key, required this.serviceId});

  @override
  State<CleaningServiceScreen> createState() => _CleaningServiceScreenState();
}

class _CleaningServiceScreenState extends State<CleaningServiceScreen> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _addresses = [];
  int? _selectedAddressId;
  String _propertyType = 'căn hộ'; // Default: apartment
  double _areaSizeMultiplier = 1.0; // Multiplier for area size
  int _staffCount = 2; // Default: 2 staff members
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '08:00';
  int _paymentMethod = 0; // 0: Ngân hàng, 2: Ví điện tử (no cash option)

  // Financial data
  double _basePrice = 0;
  double _totalPrice = 0;
  double _discountAmount = 0;
  double _finalPrice = 0;

  List<String> _timeSlots = [];
  final List<Map<String, dynamic>> _propertyTypes = [
    {'value': 'căn hộ', 'label': 'Căn hộ', 'icon': Icons.apartment},
    {'value': 'nhà mặt đất', 'label': 'Nhà mặt đất', 'icon': Icons.home},
    {'value': 'văn phòng', 'label': 'Văn phòng', 'icon': Icons.business},
    {'value': 'biệt thự', 'label': 'Biệt thự', 'icon': Icons.holiday_village},
  ];

  final List<Map<String, dynamic>> _areaSizes = [
    {'multiplier': 1.0, 'staff': 2, 'label': 'Dưới 60m2 Tổng sàn'},
    {'multiplier': 1.5, 'staff': 3, 'label': '60-90m2 Tổng sàn'},
    {'multiplier': 2.0, 'staff': 4, 'label': '90-120m2 Tổng sàn'},
    {'multiplier': 2.5, 'staff': 5, 'label': '120-150m2 Tổng sàn'},
    {'multiplier': 3.0, 'staff': 6, 'label': '150-180m2 Tổng sàn'},
    {'multiplier': 3.5, 'staff': 7, 'label': '180-210m2 Tổng sàn'},
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

  void _selectAreaSize(double multiplier, int staffCount) {
    setState(() {
      _areaSizeMultiplier = multiplier;
      _staffCount = staffCount;
      _updateTotalPrice();
    });
  }

  void _updateTotalPrice() {
    setState(() {
      _totalPrice = _basePrice * _areaSizeMultiplier * _staffCount;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final orderData = {
        'id_dia_chi': _selectedAddressId,
        'loai_nha': _propertyType,
        'dien_tich_tong_san': _areaSizeMultiplier,
        'so_luong_nv': _staffCount,
        'so_gio_phuc_vu': 6, // Fixed at 6 hours for total cleaning
        'ngay_bat_dau_lam': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'gio_bat_dau_lam_viec': _selectedTime,
        'phuong_thuc_thanh_toan': _paymentMethod,
        'ghi_chu': _notesController.text,
        'tong_tien': _totalPrice,
        'so_tien_thanh_toan': _finalPrice,
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
        title: const Text('Thuê tổng vệ sinh'),
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

                    // Property type selection
                    _buildSectionTitle(Icons.home_work, 'Loại nhà'),
                    _buildPropertyTypeSelector(),
                    const SizedBox(height: 20),

                    // Area size selection
                    _buildSectionTitle(Icons.area_chart, 'Diện tích'),
                    _buildAreaSizeSelector(),
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

  Widget _buildPropertyTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _propertyTypes.map((type) {
          bool isSelected = _propertyType == type['value'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _propertyType = type['value'];
              });
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFE0F7E9) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF28A745) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'],
                    color: isSelected
                        ? const Color(0xFF28A745)
                        : Colors.grey.shade700,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF28A745)
                          : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAreaSizeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _areaSizes.map((size) {
          bool isSelected = _areaSizeMultiplier == size['multiplier'] &&
              _staffCount == size['staff'];
          return GestureDetector(
            onTap: () => _selectAreaSize(size['multiplier'], size['staff']),
            child: Container(
              width: (MediaQuery.of(context).size.width - 42) /
                  2, // 2 columns with padding
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF06D7A0) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  size['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
                  '$_staffCount Nhân viên x 6 giờ',
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
      String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06D7A0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
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
