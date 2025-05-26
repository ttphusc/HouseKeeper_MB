import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/order_detail_item.dart';

class PeriodicDetailScreen extends StatefulWidget {
  final String orderId;

  const PeriodicDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PeriodicDetailScreen> createState() => _PeriodicDetailScreenState();
}

class _PeriodicDetailScreenState extends State<PeriodicDetailScreen> {
  final Dio _dio = Dio();
  Map<String, dynamic> _orderDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 ₫';
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';
  }

  List<String> _getNgayTrongTuan(String soNgay) {
    soNgay = soNgay.replaceAll(RegExp(r'[\[\]\s]'), '');
    final ngayTrongTuan = [
      'Chủ Nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    return soNgay
        .split(',')
        .map((ngay) => ngayTrongTuan[int.parse(ngay.trim())])
        .toList();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/chi-tiet-don-hang/getData/${widget.orderId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        setState(() {
          _orderDetails = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải thông tin đơn hàng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Chi tiết Đơn Định Kỳ'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  OrderDetailItem(
                    label: 'Mã Đơn dịch vụ',
                    value: _orderDetails['ma_don_hang'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Ngày bắt đầu làm',
                    value: _orderDetails['ngay_bat_dau_lam'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Ngày kết thúc làm',
                    value: _orderDetails['ngay_ket_thuc'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Ngày Làm Việc Trong Tuần',
                    value:
                        '${_getNgayTrongTuan(_orderDetails['so_ngay_phuc_vu_hang_tuan'] ?? '').join(', ')} Hàng tuần',
                  ),
                  OrderDetailItem(
                    label: 'Số tháng phục vụ',
                    value: '${_orderDetails['so_thang_phuc_vu'] ?? ''}',
                  ),
                  OrderDetailItem(
                    label: 'Tổng số buổi làm',
                    value:
                        '${_orderDetails['tong_so_buoi_phuc_vu_theo_so_thang_phuc_vu'] ?? ''}',
                  ),
                  OrderDetailItem(
                    label: 'Giờ bắt đầu làm việc',
                    value: _orderDetails['gio_bat_dau_lam_viec'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Giờ kết thúc làm việc',
                    value: _orderDetails['gio_ket_thuc_lam_viec'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Địa chỉ khách hàng',
                    value: _orderDetails['dia_chi_nguoi_nhan'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Ghi Chú Đơn dịch vụ',
                    value: _orderDetails['ghi_chu'] ?? 'Không có ghi chú',
                  ),
                  OrderDetailItem(
                    label: 'Người sử dụng dịch vụ',
                    value: _orderDetails['ten_nguoi_nhan'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Số điện thoại người sử dụng',
                    value: _orderDetails['so_dien_thoai_nguoi_nhan'] ?? '',
                  ),
                  OrderDetailItem(
                    label: 'Số Tiền',
                    value: _formatCurrency(_orderDetails['so_tien_thanh_toan']),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Về Trang Chủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
