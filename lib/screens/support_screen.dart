import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pusher_client/pusher_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final Dio _dio = Dio();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  int? _currentUserId;
  int? _adminId;
  Map<String, dynamic> _adminInfo = {};
  bool _isLoading = true;
  bool _isSending = false;

  PusherClient? pusher;
  Channel? channel;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Thêm delay ngắn để đảm bảo widget đã được render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _initializeChat() async {
    await _loadCurrentUserId();
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

      if (response.statusCode == 200) {
        setState(() {
          _currentUserId = response.data['nguoi_dung_id'];
        });
        print('Current User ID: $_currentUserId');

        // Sau khi lấy được ID chính xác, khởi tạo Pusher
        await _initializePusher();

        // Sau đó load admin info và tin nhắn
        await _loadAdminInfo();
      }
    } catch (e) {
      print('Lỗi khi lấy ID người dùng hiện tại: $e');
      _showError('Không thể lấy thông tin người dùng');
    }
  }

  Future<void> _loadAdminInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/admin/info',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _adminId = response.data['admin_id'];
          _adminInfo = response.data;
        });
        await _loadMessages();
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin admin: $e');
      _showError('Không thể lấy thông tin admin');
    }
  }

  Future<void> _loadMessages() async {
    if (_adminId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/chi-tiet-tin-nhan',
        data: {
          'nguoi_gui_id': _adminId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
        // Thêm delay ngắn để đảm bảo tin nhắn đã được render
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
        print('Chi tiết tin nhắn với admin: $_messages');
      }
    } catch (e) {
      print('Lỗi khi tải tin nhắn với admin: $e');
      setState(() => _isLoading = false);
      _showError('Không thể tải tin nhắn');
    }
  }

  Future<void> _initializePusher() async {
    if (_currentUserId == null) {
      print('currentUserId chưa được gán, không thể đăng ký channel.');
      return;
    }

    if (kIsWeb) {
      print('Đang chạy trên web - bỏ qua khởi tạo Pusher');
      return;
    }

    try {
      print('Initializing Pusher for user ID: $_currentUserId');

      // Disconnect existing connection if any
      channel?.unbind('.message-sent-event');
      pusher?.unsubscribe('chat_user.$_currentUserId');
      await pusher?.disconnect();

      pusher = PusherClient(
        '0911c58bf746f219ad1d',
        PusherOptions(
          cluster: 'ap1',
          encrypted: true,
        ),
      );

      await pusher?.connect();

      // Subscribe to chat channel exactly like website
      String channelName = 'chat_user.$_currentUserId';
      print('Subscribing to channel: $channelName');

      channel = pusher?.subscribe(channelName);

      channel?.bind('.message-sent-event', (PusherEvent? event) {
        print('Received event: ${event?.data}');

        if (event?.data != null) {
          try {
            Map<String, dynamic> eventData = event!.data is String
                ? jsonDecode(event.data as String)
                : Map<String, dynamic>.from(event.data as Map);

            print('Parsed event data: $eventData');

            // Match exactly website's condition
            if (eventData['sender_type'] != 1) {
              print('✅ Received message from admin');
              setState(() {
                _messages = [..._messages, eventData];
              });
              _scrollToBottom();

              // Show notification like website
              _showSuccess(
                  '🔔 Tin nhắn mới từ admin: ${eventData['noi_dung']}');
            }
          } catch (e) {
            print('Error processing event: $e');
            print('Raw event data: ${event?.data}');
          }
        }
      });

      pusher?.onConnectionStateChange((state) {
        print('Pusher connection state: ${state?.currentState}');

        print('Successfully connected to Pusher');
        print('Listening on channel: $channelName');
        if (state?.currentState == 'failed') {
          print('Connection failed - retrying in 3 seconds...');
          Future.delayed(const Duration(seconds: 3), () {
            _initializePusher();
          });
        }
      });
    } catch (e) {
      print('Error initializing Pusher: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : ''}');
      // Retry connection after delay
      Future.delayed(const Duration(seconds: 3), () {
        _initializePusher();
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_nguoi_dung');
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty || _adminId == null) return;

    setState(() => _isSending = true);

    // Tạo message object mới
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch, // Temporary ID
      'nguoi_gui_id': _currentUserId,
      'nguoi_nhan_id': _adminId,
      'noi_dung': messageContent,
      'sender_type': 1,
      'created_at': DateTime.now().toIso8601String(),
      'nguoi_gui_ten': '', // Sẽ được cập nhật từ response
      'nguoi_gui_avatar': null,
    };

    // Thêm tin nhắn vào danh sách ngay lập tức
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Cuộn xuống cuối ngay sau khi thêm tin nhắn
    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/gui-tin-nhan',
        data: {
          'nguoi_nhan_id': _adminId,
          'noi_dung': messageContent,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('Response from sendTinNhan: ${response.data}');

        // Cập nhật tin nhắn với thông tin từ server
        final serverMessage = response.data['data'];
        setState(() {
          final index =
              _messages.indexWhere((msg) => msg['noi_dung'] == messageContent);
          if (index != -1) {
            _messages[index] = {
              'id': serverMessage['id'],
              'nguoi_gui_id': _currentUserId,
              'nguoi_nhan_id': _adminId,
              'noi_dung': messageContent,
              'sender_type': 1,
              'created_at': serverMessage['created_at'],
              'nguoi_gui_ten': serverMessage['nguoi_gui_ten'] ?? '',
              'nguoi_gui_avatar': serverMessage['nguoi_gui_avatar'],
            };
          }
        });

        _showSuccess('Tin nhắn đã gửi thành công!');
      }
    } catch (e) {
      print('Error in sendTinNhan: $e');
      _showError('Không thể gửi tin nhắn');

      // Nếu gửi thất bại, xóa tin nhắn tạm
      setState(() {
        _messages.removeWhere((msg) =>
            msg['noi_dung'] == messageContent &&
            msg['id'] is int &&
            msg['id'].toString().length > 10);
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = (date.month).toString().padLeft(2, '0');
      final year = date.year;
      return '$hours:$minutes / $day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _refreshChat() async {
    try {
      // Disconnect current Pusher connection
      channel?.unbind('.message-sent-event');
      pusher?.unsubscribe('chat_user.$_currentUserId');
      pusher?.unsubscribe('notifications.$_currentUserId');
      pusher?.disconnect();

      // Reinitialize everything
      await _loadCurrentUserId(); // This will also reinitialize Pusher
      await _loadAdminInfo();
      await _loadMessages();

      _showSuccess('Đã cập nhật tin nhắn');
    } catch (e) {
      print('Error refreshing chat: $e');
      _showError('Không thể cập nhật tin nhắn');
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isSentByMe = message['sender_type'] == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                message['nguoi_gui_avatar'] ?? 'https://via.placeholder.com/30',
              ),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSentByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isSentByMe ? const Color(0xFF007AFF) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message['noi_dung'] ?? 'Không có nội dung',
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message['created_at']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _refreshChat();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF46DFB1),
          leading: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChat,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _adminInfo['ho_va_ten'] ?? 'Admin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _adminInfo['tinh_trang'] == 1
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _adminInfo['tinh_trang'] == 1 ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _buildMessageItem(_messages[index]),
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide:
                                const BorderSide(color: Color(0xFF46DFB1)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        enabled: !_isSending,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF46DFB1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isSending ? 'Đang gửi...' : 'Gửi',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('Disposing chat screen - cleaning up Pusher connection');
    channel?.unbind('.message-sent-event');
    pusher?.unsubscribe('chat_user.$_currentUserId');
    pusher?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
