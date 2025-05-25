import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? _onNotificationReceived;

  void connect() {
    try {
      _channel = IOWebSocketChannel.connect(
        'ws://127.0.0.1:6001/app/notifications_key',
      );

      _channel?.stream.listen(
        (message) {
          if (_onNotificationReceived != null) {
            // Parse message and call callback
            final notification = {
              'id': message['id'],
              'loi_nhan': message['message'],
              'id_don_hang': message['order_id'],
              'id_dich_vu': message['service_id'],
              'is_read': 0,
            };
            _onNotificationReceived!(notification);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          reconnect();
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void listenToNotifications(
    int userId,
    Function(Map<String, dynamic>) onNotificationReceived,
  ) {
    _onNotificationReceived = onNotificationReceived;

    // Subscribe to user's notification channel
    final data = {
      'event': 'pusher:subscribe',
      'data': {
        'channel': 'notifications.$userId',
      },
    };
    _channel?.sink.add(data);
  }

  void reconnect() {
    disconnect();
    connect();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
