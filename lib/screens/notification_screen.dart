import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import 'order_details/hourly_detail_screen.dart';
import 'order_details/periodic_detail_screen.dart';
import 'order_details/general_cleaning_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;
  int _currentUserId = 0;
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['nguoi_dung_id'] != null) {
        setState(() {
          _currentUserId = response.data['nguoi_dung_id'];
        });
    _loadNotifications();
        _setupWebSocket();
      }
    } catch (e) {
      print('Error loading user ID: $e');
      _showError('Không thể tải ID người dùng');
    }
  }

  void _setupWebSocket() {
    _webSocketService.connect();
    _webSocketService.listenToNotifications(_currentUserId, (notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
      _showNewNotification(notification['loi_nhan']);
    });
  }

  void _showNewNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF46DFB1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao/getNhanDonTuNV',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
        if (response.data['status'] == true && response.data['data'] != null) {
          _notifications =
              List<Map<String, dynamic>>.from(response.data['data']);
        }
      });
    } catch (e) {
      _showError('Không thể tải thông báo. Vui lòng thử lại sau.');
      print('Error loading notifications: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thay-doi-trang-thai-doc/$notificationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Reload notifications to update UI
      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
      _showError('Không thể đánh dấu đã đọc. Vui lòng thử lại.');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }

  void _navigateToOrderDetail(Map<String, dynamic> notification) {
    if (notification['id_don_hang'] == null) return;

    // Mark notification as read when viewing details
    _markAsRead(notification['id']);

    Widget? screen;
    switch (notification['id_dich_vu']) {
      case 1:
        screen =
            HourlyDetailScreen(orderId: notification['id_don_hang'].toString());
        break;
      case 2:
        screen = PeriodicDetailScreen(
            orderId: notification['id_don_hang'].toString());
        break;
      case 3:
        screen = GeneralCleaningDetailScreen(
            orderId: notification['id_don_hang'].toString());
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Thông báo'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyNotificationState()
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyNotificationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận thông báo về đơn hàng và cập nhật khác tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] == 1;
    final int index = _notifications.indexOf(notification) + 1;

    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
        'Thông Báo: $index',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
            notification['loi_nhan'] ?? 'Không có nội dung',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () => _navigateToOrderDetail(notification),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF46DFB1),
          foregroundColor: Colors.white,
        ),
        child: const Text('Xem Chi Tiết'),
      ),
        tileColor: isRead ? null : const Color(0xFF46DFB1).withOpacity(0.05),
      onTap: () => _navigateToOrderDetail(notification),
    );
  }
}
