import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
        if (response.data['data'] != null) {
          _notifications =
              List<Map<String, dynamic>>.from(response.data['data']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải thông báo. Vui lòng thử lại sau.';
      });

      print('Error loading notifications: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Đã xảy ra lỗi khi tải thông báo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao/danh-dau-da-doc/$notificationId',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đánh dấu đã đọc. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao/danh-dau-tat-ca-da-doc',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh dấu tất cả đã đọc'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload notifications to update UI
      _loadNotifications();
    } catch (e) {
      print('Error marking all notifications as read: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đánh dấu tất cả đã đọc. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao/xoa-thong-bao/$notificationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Đã xóa thông báo'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload notifications to update UI
      _loadNotifications();
    } catch (e) {
      print('Error deleting notification: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa thông báo. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  void _navigateToNotificationDetail(Map<String, dynamic> notification) {
    // Implement navigation to detailed notification view based on notification type
    // You would need to add more logic here based on your notification structure
    if (notification['id_don_hang'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển đến chi tiết đơn hàng'),
          backgroundColor: Colors.blue,
        ),
      );
      // Navigate to order details
      // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: notification['id_don_hang'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Thông báo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
          ),
        ],
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
    final bool isRead = notification['trang_thai'] == 1;

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xóa thông báo'),
              content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF46DFB1).withOpacity(0.1),
          foregroundColor: const Color(0xFF46DFB1),
          child: Icon(
            _getNotificationIcon(notification['loai']),
            size: 24,
          ),
        ),
        title: Text(
          notification['tieu_de'] ?? 'Không có tiêu đề',
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
              notification['noi_dung'] ?? 'Không có nội dung',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification['created_at'] ?? ''),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? IconButton(
                icon:
                    const Icon(Icons.check_circle_outline, color: Colors.blue),
                tooltip: 'Đánh dấu đã đọc',
                onPressed: () => _markAsRead(notification['id']),
              )
            : null,
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          _navigateToNotificationDetail(notification);
        },
        tileColor: isRead ? null : const Color(0xFF46DFB1).withOpacity(0.05),
      ),
    );
  }

  IconData _getNotificationIcon(dynamic type) {
    switch (type) {
      case 'don_hang':
        return Icons.shopping_bag;
      case 'thanh_toan':
        return Icons.payment;
      case 'he_thong':
        return Icons.notifications;
      case 'khac':
      default:
        return Icons.notifications_active;
    }
  }
}
