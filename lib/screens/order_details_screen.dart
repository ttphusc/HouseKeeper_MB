import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';
import 'staff_detail_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final int? serviceId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.serviceId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  String? _errorMessage;
  bool _canCancel = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/don-hang/chi-tiet/${widget.orderId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
        if (response.data['data'] != null) {
          _orderDetails = Map<String, dynamic>.from(response.data['data']);

          // Check if order can be cancelled (status is "Mới đặt" - 0)
          final statusId =
              int.tryParse(_orderDetails?['trang_thai']?.toString() ?? '') ??
                  -1;
          _canCancel = statusId == 0;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Không thể tải thông tin đơn hàng. Vui lòng thử lại sau.';
      });

      print('Error loading order details: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_errorMessage ?? 'Đã xảy ra lỗi khi tải thông tin đơn hàng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/don-hang/huy-don-hang/${widget.orderId}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data['message'] ?? 'Đã hủy đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload order details to reflect changes
        _loadOrderDetails();
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Không thể hủy đơn hàng';
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
        _errorMessage = 'Có lỗi xảy ra khi hủy đơn hàng. Vui lòng thử lại sau.';
      });

      print('Error canceling order: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPayment() {
    if (_orderDetails == null) return;

    final serviceId =
        int.tryParse(_orderDetails!['id_dich_vu']?.toString() ?? '0') ?? 0;
    final amount = double.tryParse(
            _orderDetails!['so_tien_thanh_toan']?.toString() ?? '0') ??
        0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: widget.orderId,
          serviceId: serviceId,
          amount: amount,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Payment was successful, reload order details
        _loadOrderDetails();
      }
    });
  }

  void _viewStaffDetails() {
    if (_orderDetails == null || _orderDetails!['id_nhan_vien'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có nhân viên được phân công cho đơn hàng này'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final staffId =
        int.tryParse(_orderDetails!['id_nhan_vien'].toString()) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffDetailScreen(staffId: staffId),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 ₫';

    try {
      final formatter =
          NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      return formatter.format(double.parse(value.toString()));
    } catch (e) {
      return '$value ₫';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _getOrderStatusName(int statusId) {
    switch (statusId) {
      case 0:
        return 'Mới đặt';
      case 1:
        return 'Đang làm';
      case 2:
        return 'Hoàn thành';
      case 3:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Color _getOrderStatusColor(int statusId) {
    switch (statusId) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeName(int serviceId) {
    switch (serviceId) {
      case 1:
        return 'Giúp việc theo giờ';
      case 2:
        return 'Giúp việc định kỳ';
      case 3:
        return 'Tổng vệ sinh';
      default:
        return 'Dịch vụ khác';
    }
  }

  IconData _getServiceTypeIcon(int serviceId) {
    switch (serviceId) {
      case 1:
        return Icons.access_time;
      case 2:
        return Icons.calendar_month;
      case 3:
        return Icons.cleaning_services;
      default:
        return Icons.home_repair_service;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: Text('Chi tiết đơn hàng #${widget.orderId}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetails == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderStatusSection(),
                        const SizedBox(height: 16),
                        _buildOrderInfoSection(),
                        const SizedBox(height: 16),
                        _buildServiceDetailsSection(),
                        const SizedBox(height: 16),
                        _buildPaymentSection(),
                        const SizedBox(height: 16),
                        if (_orderDetails!['id_nhan_vien'] != null)
                          _buildStaffSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông tin đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Vui lòng thử lại sau',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46DFB1),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    final statusId =
        int.tryParse(_orderDetails!['trang_thai']?.toString() ?? '0') ?? 0;
    final serviceId =
        int.tryParse(_orderDetails!['id_dich_vu']?.toString() ?? '1') ?? 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getServiceTypeIcon(serviceId),
                      color: const Color(0xFF46DFB1),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getServiceTypeName(serviceId),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(statusId).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getOrderStatusName(statusId),
                    style: TextStyle(
                      color: _getOrderStatusColor(statusId),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Ngày đặt: ${_formatDate(_orderDetails!['created_at'])}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Người đặt:',
                _orderDetails!['ten_nguoi_dat'] ?? 'Không có thông tin'),
            _buildInfoRow(Icons.phone, 'Số điện thoại:',
                _orderDetails!['so_dien_thoai'] ?? 'Không có thông tin'),
            _buildInfoRow(Icons.location_on, 'Địa chỉ:',
                _orderDetails!['dia_chi'] ?? 'Không có thông tin'),
            _buildInfoRow(Icons.calendar_today, 'Ngày làm:',
                _formatDate(_orderDetails!['ngay_bat_dau_lam'])),
            _buildInfoRow(Icons.access_time, 'Giờ bắt đầu:',
                _orderDetails!['gio_bat_dau_lam_viec'] ?? 'Không có thông tin'),
            if (_orderDetails!['ghi_chu'] != null &&
                _orderDetails!['ghi_chu'].toString().isNotEmpty)
              _buildInfoRow(Icons.note, 'Ghi chú:', _orderDetails!['ghi_chu']),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsSection() {
    final serviceId =
        int.tryParse(_orderDetails!['id_dich_vu']?.toString() ?? '1') ?? 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết dịch vụ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Display different fields based on service type
            if (serviceId == 1) // Hourly service
              Column(
                children: [
                  _buildInfoRow(Icons.timer, 'Số giờ làm:',
                      '${_orderDetails!['so_gio_lam_viec'] ?? 0} giờ'),
                  _buildInfoRow(Icons.cleaning_services, 'Công việc:',
                      _orderDetails!['cong_viec'] ?? 'Không có thông tin'),
                ],
              )
            else if (serviceId == 2) // Recurring service
              Column(
                children: [
                  _buildInfoRow(Icons.repeat, 'Số buổi:',
                      '${_orderDetails!['so_buoi'] ?? 0} buổi'),
                  _buildInfoRow(Icons.calendar_view_week, 'Số buổi/tuần:',
                      '${_orderDetails!['so_buoi_mot_tuan'] ?? 0} buổi'),
                  _buildInfoRow(Icons.cleaning_services, 'Công việc:',
                      _orderDetails!['cong_viec'] ?? 'Không có thông tin'),
                ],
              )
            else if (serviceId == 3) // Cleaning service
              Column(
                children: [
                  _buildInfoRow(Icons.home, 'Loại nhà:',
                      _orderDetails!['loai_nha'] ?? 'Không có thông tin'),
                  _buildInfoRow(Icons.straighten, 'Diện tích:',
                      '${_orderDetails!['dien_tich'] ?? 0} m²'),
                  _buildInfoRow(Icons.cleaning_services, 'Dịch vụ thêm:',
                      _orderDetails!['dich_vu_them'] ?? 'Không có'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final isPaid = _orderDetails!['trang_thai_thanh_toan'] == 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông tin thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                    style: TextStyle(
                      color: isPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.money, 'Tổng tiền:',
                _formatCurrency(_orderDetails!['so_tien_thanh_toan'])),
            if (_orderDetails!['phuong_thuc_thanh_toan'] != null)
              _buildInfoRow(
                  Icons.payment,
                  'Phương thức:',
                  _orderDetails!['phuong_thuc_thanh_toan'] == 0
                      ? 'Chuyển khoản ngân hàng'
                      : 'Ví điện tử'),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin nhân viên',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF46DFB1).withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF46DFB1),
                ),
              ),
              title: Text(
                _orderDetails!['ten_nhan_vien'] ?? 'Chưa phân công',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _orderDetails!['sdt_nhan_vien'] ?? '',
              ),
              trailing: TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Chi tiết'),
                onPressed: _viewStaffDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final statusId =
        int.tryParse(_orderDetails!['trang_thai']?.toString() ?? '0') ?? 0;
    final isPaid = _orderDetails!['trang_thai_thanh_toan'] == 1;

    return Row(
      children: [
        if (_canCancel)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCancelConfirmDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy đơn'),
            ),
          ),
        if (_canCancel && !isPaid) const SizedBox(width: 12),
        if (!isPaid && statusId != 3) // Not paid and not cancelled
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46DFB1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng'),
          content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Hủy đơn'),
            ),
          ],
        );
      },
    );
  }
}
