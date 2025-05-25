import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EmailActivationScreen extends StatefulWidget {
  final String email;
  final bool isFromLogin;

  const EmailActivationScreen({
    super.key,
    required this.email,
    this.isFromLogin = false,
  });

  @override
  State<EmailActivationScreen> createState() => _EmailActivationScreenState();
}

class _EmailActivationScreenState extends State<EmailActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final Dio _dio = Dio();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  // Timer for countdown
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/kich-hoat-email',
        data: {
          'email': widget.email,
          'ma_kich_hoat': _codeController.text.trim(),
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.data['status'] == true) {
        setState(() {
          _successMessage =
              response.data['message'] ?? 'Email đã được kích hoạt thành công';
        });

        // Navigate back to login after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (widget.isFromLogin) {
            // Go directly to home screen
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Go back to login
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ??
              'Mã kích hoạt không đúng. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Đã xảy ra lỗi khi kích hoạt email. Vui lòng thử lại sau.';
      });
      print('Error activating email: $e');
    }
  }

  Future<void> _resendActivationCode() async {
    if (_isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _dio.post(
        'http://127.0.0.1:8000/api/nguoi-dung/gui-lai-ma-kich-hoat',
        data: {
          'email': widget.email,
        },
      );

      setState(() {
        _isResending = false;
      });

      if (response.data['status'] == true) {
        setState(() {
          _successMessage = response.data['message'] ??
              'Đã gửi lại mã kích hoạt qua email của bạn.';
          _remainingSeconds = 60; // Start countdown for 60 seconds
        });

        // Start countdown timer
        _startCountdownTimer();
      } else {
        setState(() {
          _errorMessage = response.data['message'] ??
              'Không thể gửi lại mã. Vui lòng thử lại sau.';
        });
      }
    } catch (e) {
      setState(() {
        _isResending = false;
        _errorMessage = 'Đã xảy ra lỗi khi gửi lại mã. Vui lòng thử lại sau.';
      });
      print('Error resending activation code: $e');
    }
  }

  void _startCountdownTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _startCountdownTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Kích hoạt tài khoản'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.email,
              size: 80,
              color: Color(0xFF46DFB1),
            ),
            const SizedBox(height: 24),
            const Text(
              'Xác nhận email của bạn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi đã gửi mã kích hoạt đến:\n${widget.email}',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng nhập mã kích hoạt để xác minh email của bạn.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Mã kích hoạt',
                      hintText: 'Nhập mã 6 chữ số',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.vpn_key),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mã kích hoạt';
                      }
                      if (value.length != 6) {
                        return 'Mã kích hoạt phải có 6 chữ số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF46DFB1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _verifyEmail,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Xác nhận',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Không nhận được mã?',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                TextButton(
                  onPressed: _remainingSeconds > 0 || _isResending
                      ? null
                      : _resendActivationCode,
                  child: Text(
                    _remainingSeconds > 0
                        ? 'Gửi lại sau (${_remainingSeconds}s)'
                        : 'Gửi lại mã',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds > 0 || _isResending
                          ? Colors.grey
                          : const Color(0xFF46DFB1),
                    ),
                  ),
                ),
              ],
            ),
            if (_isResending)
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF46DFB1)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang gửi mã...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Quay lại',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
