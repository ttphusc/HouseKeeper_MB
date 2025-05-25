import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final Dio _dio = Dio();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _errorMessage;

  late TabController _tabController;
  final List<String> _tabs = ['Mới đặt', 'Đang làm', 'Hoàn thành', 'Đã hủy'];
  final List<int> _orderStatusIds = [1, 2, 3, 4]; // Status IDs matching website

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadOrders(_orderStatusIds[0]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _tabController.previousIndex) {
      _loadOrders(_orderStatusIds[_tabController.index]);
    }
  }

  Future<void> _loadOrders(int statusId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Vui lòng đăng nhập lại';
        });
        return;
      }

      String endpoint;
      switch (statusId) {
        case 1:
          endpoint = 'lich-su-don-hang-moi-dat/getDataLSDDToND';
          break;
        case 2:
          endpoint = 'lich-su-don-hang-da-nhan-don/getDataLSNDToND';
          break;
        case 3:
          endpoint = 'lich-su-don-hang-da-hoan-thanh/getDataLSHTToND';
          break;
        case 4:
          endpoint = 'lich-su-don-hang-da-huy-don/getDataLSHDToND';
          break;
        default:
          endpoint = 'lich-su-don-hang-moi-dat/getDataLSDDToND';
      }

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/$endpoint',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
        if (response.data['status'] == true) {
          if (response.data['data'] != null) {
            _orders = List<Map<String, dynamic>>.from(response.data['data']);
          } else {
            _orders = [];
          }
        } else {
          _errorMessage = response.data['message'] ?? 'Không thể tải đơn hàng';
          _orders = [];
        }
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải đơn hàng. Vui lòng thử lại sau.';
        _orders = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Đã xảy ra lỗi khi tải đơn hàng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/huy-don-hang/delete/$orderId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data['message'] ?? 'Đã hủy đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload current tab
        _loadOrders(_orderStatusIds[_tabController.index]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Không thể hủy đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error canceling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy đơn hàng. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewOrderDetail(int orderId, int serviceId) {
    // Navigate to order detail screen based on service type
    // Replace with your actual navigation code when OrderDetailScreen is implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Xem chi tiết đơn hàng #$orderId, Dịch vụ ID: $serviceId'),
        backgroundColor: Colors.blue,
      ),
    );

    // Example navigation code:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => OrderDetailScreen(orderId: orderId, serviceId: serviceId),
    //   ),
    // );
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
      case 1:
        return 'Mới đặt';
      case 2:
        return 'Đang thực hiện';
      case 3:
        return 'Đã hoàn thành';
      case 4:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Color _getOrderStatusColor(int statusId) {
    switch (statusId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 4:
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
        title: const Text('Lịch sử đơn hàng'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) {
          return _buildOrderList(_orderStatusIds[index]);
        }),
      ),
    );
  }

  Widget _buildOrderList(int statusId) {
    if (_isLoading &&
        _tabController.index == _orderStatusIds.indexOf(statusId)) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(statusId),
      child: _orders.isEmpty
          ? _buildEmptyOrderState(statusId)
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(_orders[index]);
              },
            ),
    );
  }

  Widget _buildEmptyOrderState(int statusId) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có đơn hàng ${_getOrderStatusName(statusId).toLowerCase()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các đơn hàng ${_getOrderStatusName(statusId).toLowerCase()} sẽ hiển thị ở đây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final int statusId =
        int.tryParse(order['tinh_trang_don_hang']?.toString() ?? '1') ?? 1;
    final int serviceId =
        int.tryParse(order['id_dich_vu']?.toString() ?? '1') ?? 1;
    final int orderId = int.tryParse(order['id']?.toString() ?? '0') ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewOrderDetail(orderId, serviceId),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã đơn: #${order['ma_don_hang']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(statusId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getOrderStatusName(statusId),
                      style: TextStyle(
                        color: _getOrderStatusColor(statusId),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (order['nhanViens'] != null &&
                  (order['nhanViens'] as List).isNotEmpty)
                _buildInfoRow(
                  Icons.person,
                  'Nhân viên:',
                  (order['nhanViens'] as List)
                      .map((nv) =>
                          '${nv['ten_nhan_vien']} (${nv['so_dien_thoai']})')
                      .join('\n'),
                ),
              _buildInfoRow(Icons.calendar_today, 'Ngày bắt đầu:',
                  _formatDate(order['ngay_bat_dau_lam'])),
              _buildInfoRow(Icons.calendar_today, 'Ngày kết thúc:',
                  _formatDate(order['ngay_ket_thuc'])),
              _buildInfoRow(Icons.attach_money, 'Tổng tiền:',
                  _formatCurrency(order['so_tien_thanh_toan'])),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _viewOrderDetail(orderId, serviceId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Xem thêm'),
                  ),
                  if (statusId == 1) // Mới đặt
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: () => _showCancelConfirmDialog(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Hủy đơn'),
                      ),
                    ),
                  if (statusId == 2) // Đang thực hiện
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: () => _completeOrder(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334fff),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Đã hoàn thành'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(int orderId) {
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
                _cancelOrder(orderId);
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

  Future<void> _completeOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thay-doi-status-don-hang/changeStaTusHoanThanh/$orderId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response.data['message'] ?? 'Đã cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to rating screen
        Navigator.pushNamed(context, '/nguoi-dung/danhgia/$orderId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ??
                'Không thể cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error completing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Không thể cập nhật trạng thái đơn hàng. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
